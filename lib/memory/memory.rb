require_relative 'base'
require_relative 'dataset'
require_relative 'key_value_store'
require_relative 'request_queue'
require_relative 'utils'

module Apify

	"""
	Memory storage emulates data storages that are available on the Apify platform.
	Specifically, it emulates clients for datasets, key-value stores and request queues.
	The data are held in-memory and persisted locally if `persist_storage` is True.
	The metadata of the storages is also persisted if `write_metadata` is True.
	"""	
	module MemoryStorage
	
	"""Class representing an in-memory storage."""	
	class Client

		attr_accessor :_cache, :_directory, :_write_metadata, :_persist_storage

		"""Initialize the MemoryStorageClient.

		Args:
			local_data_directory (str, optional): A local directory where all data will be persisted
			persist_storage (bool, optional): Whether to persist the data to the `local_data_directory` or just keep them in memory
			write_metadata (bool, optional): Whether to persist metadata of the storages as well
		"""

		def initialize local_data_directory: nil, write_metadata: nil, persist_storage: nil
			@_local_data_directory = local_data_directory || ENV[ApifyEnvVars::LOCAL_STORAGE_DIR] || './storage'			
			@_write_metadata = !write_metadata.nil? ? write_metadata : ENV['DEBUG']&.include("*")
			@_persist_storage = !persist_storage.nil? ? persist_storage : ['true', nil].include?( ENV[ApifyEnvVars::PERSIST_STORAGE] ) 
			
			@_directory = {
				DatasetClient => File.join(@_local_data_directory, 'datasets'),
				KeyValueStoreClient => File.join(@_local_data_directory, 'key_value_stores'),
				RequestQueueClient => File.join(@_local_data_directory, 'request_queues')		
			}			
			@_cache = {
				DatasetClient => [],
				KeyValueStoreClient => [],
				RequestQueueClient => [],
			}
			
			# Indicates whether a purge was already performed on this instance
			#@_purged_on_start = false
			#@_purge_lock = asyncio.Lock()
		end

		"""Retrieve the sub-client for manipulating datasets."""		
		def datasets = DatasetCollectionClient.new self

		"""Retrieve the sub-client for manipulating a single dataset.

		Args:
			dataset_id (str): ID of the dataset to be manipulated
		"""		
		def dataset(dataset_id) = DatasetClient.new self, id: dataset_id

		"""Retrieve the sub-client for manipulating key-value stores."""
		def key_value_stores = KeyValueStoreCollectionClient.new self

		"""Retrieve the sub-client for manipulating a single key-value store.

		Args:
			key_value_store_id (str): ID of the key-value store to be manipulated
		"""
		def key_value_store(key_value_store_id) = KeyValueStoreClient.new self, id: key_value_store_id

		"""Retrieve the sub-client for manipulating request queues."""
		def request_queues = RequestQueueCollectionClient.new self
		
		"""Retrieve the sub-client for manipulating a single request queue.

		Args:
			request_queue_id (str): ID of the request queue to be manipulated
			client_key (str): A unique identifier of the client accessing the request queue
		"""
		def request_queue request_queue_id, client_key: nil  # noqa: U100
			RequestQueueClient.new self, id: request_queue_id
		end

		def _find_or_create_client  client_class, id: nil, name: nil  
			raise "Required `id` or `name`!" unless id || name
			
			storage_client_cache = @_cache[client_class]
			storages_dir = @_directory[client_class]

			# First check memory cache			
			found = storage_client_cache.find { |s| s._id == id || (s._name && name && s._name.downcase == name.downcase) }
			return found if found

			storage_path = nil

			# First try to find the storage by looking up the directory by name			
			if name
				storage_path = File.join(storages_dir, name)
				storage_path = nil if !File.directory?(storage_path)
			end
			
			# As a last resort, try to check if the accessed storage is the default one,
			# and the folder has no metadata
			# TODO: make this respect the APIFY_DEFAULT_XXX_ID env var
			if !storage_path && id == 'default'
				storage_path = File.join(storages_dir, id)
				storage_path = nil if !File.directory?(storage_path)
			end
			
			# If it's not found, try going through the storages dir and finding it by metadata			
			if !storage_path && File.exist?(storages_dir)
				Dir.foreach(storages_dir) do |entry_name|
					entry_path = File.join(storages_dir, entry_name)
					next unless File.directory?(entry_path)

					metadata_path = File.join(entry_path, '__metadata__.json')
					next unless File.exist?(metadata_path)

					metadata = JSON.parse(File.read(metadata_path, encoding: 'utf-8'))

					if id && id == metadata['id']
						storage_path = entry_path
						name = metadata['name']
						break
					end
					if name && name == metadata['name']
						storage_path = entry_path
						id = metadata['id']
						break
					end
				end		
			end

			return if !storage_path

			resource_client = client_class._create_from_directory storage_path, self, id, name
			storage_client_cache << resource_client

			return resource_client
		end
=begin
		async def _purge_on_start(self) -> None:
			# Optimistic, non-blocking check
			if self._purged_on_start is True:
				return

			async with self._purge_lock:
				# Another check under the lock just to be sure
				if self._purged_on_start is True:
					return  # type: ignore[unreachable] # Mypy doesn't understand that the _purged_on_start can change while we're getting the async lock

				await self._purge()
				self._purged_on_start = True

		async def _purge(self) -> None:
			"""Clean up the default storage directories before the run starts.

			Specifically, `purge` cleans up:
			 - local directory containing the default dataset;
			 - all records from the default key-value store in the local directory, except for the "INPUT" key;
			 - local directory containing the default request queue.
			"""
			# Key-value stores
			if await ospath.exists(self._key_value_stores_directory):
				key_value_store_folders = await scandir(self._key_value_stores_directory)
				for key_value_store_folder in key_value_store_folders:
					if key_value_store_folder.name.startswith('__APIFY_TEMPORARY') or key_value_store_folder.name.startswith('__OLD'):
						await self._batch_remove_files(key_value_store_folder.path)
					elif key_value_store_folder.name == 'default':
						await self._handle_default_key_value_store(key_value_store_folder.path)

			# Datasets
			if await ospath.exists(self._datasets_directory):
				dataset_folders = await scandir(self._datasets_directory)
				for dataset_folder in dataset_folders:
					if dataset_folder.name == 'default' or dataset_folder.name.startswith('__APIFY_TEMPORARY'):
						await self._batch_remove_files(dataset_folder.path)
			# Request queues
			if await ospath.exists(self._request_queues_directory):
				request_queue_folders = await scandir(self._request_queues_directory)
				for request_queue_folder in request_queue_folders:
					if request_queue_folder.name == 'default' or request_queue_folder.name.startswith('__APIFY_TEMPORARY'):
						await self._batch_remove_files(request_queue_folder.path)

		async def _handle_default_key_value_store(self, folder: str) -> None:
			"""Remove everything from the default key-value store folder except `possible_input_keys`."""
			folder_exists = await ospath.exists(folder)
			temporary_path = os.path.normpath(os.path.join(folder, '../__APIFY_MIGRATING_KEY_VALUE_STORE__'))

			# For optimization, we want to only attempt to copy a few files from the default key-value store
			possible_input_keys = [
				'INPUT',
				'INPUT.json',
				'INPUT.bin',
				'INPUT.txt',
			]

			if folder_exists:
				# Create a temporary folder to save important files in
				Path(temporary_path).mkdir(parents=True, exist_ok=True)

				# Go through each file and save the ones that are important
				for entity in possible_input_keys:
					original_file_path = os.path.join(folder, entity)
					temp_file_path = os.path.join(temporary_path, entity)
					with contextlib.suppress(Exception):
						await rename(original_file_path, temp_file_path)

				# Remove the original folder and all its content
				counter = 0
				temp_path_for_old_folder = os.path.normpath(os.path.join(folder, f'../__OLD_DEFAULT_{counter}__'))
				done = False
				while not done:
					try:
						await rename(folder, temp_path_for_old_folder)
						done = True
					except Exception:
						counter += 1
						temp_path_for_old_folder = os.path.normpath(os.path.join(folder, f'../__OLD_DEFAULT_{counter}__'))

				# Replace the temporary folder with the original folder
				await rename(temporary_path, folder)

				# Remove the old folder
				await self._batch_remove_files(temp_path_for_old_folder)

		async def _batch_remove_files(self, folder: str, counter: int = 0) -> None:
			folder_exists = await ospath.exists(folder)

			if folder_exists:
				temporary_folder = folder if os.path.basename(folder).startswith('__APIFY_TEMPORARY_') else os.path.normpath(
					os.path.join(folder, f'../__APIFY_TEMPORARY_{counter}__'))

				try:
					# Rename the old folder to the new one to allow background deletions
					await rename(folder, temporary_folder)
				except Exception:
					# Folder exists already, try again with an incremented counter
					return await self._batch_remove_files(folder, counter + 1)

				await aioshutil.rmtree(temporary_folder, ignore_errors=True)
=end
	
	end
	end
end