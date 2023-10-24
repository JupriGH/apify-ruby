module Apify

module MemoryStorage

	"""Base class for resource clients."""
	class BaseResourceClient

		attr_accessor :_id, :_name, :_resource_directory
		
		### @abstractmethod
		
		"""Initialize the BaseResourceClient."""
		def initialize base_storage_directory, memory_storage_client, id: nil
			raise 'You must override this method in the subclass!' # NotImplementedError
		end

		"""Retrieve the storage.

		Returns:
			dict, optional: The retrieved storage, or None, if it does not exist
		"""	
		def get
			raise NotImplementedError.new 'You must override this method in the subclass!'
		end
		
		def self._get_storages_dir memory_storage_client
			raise NotImplementedError.new 'You must override this method in the subclass!'
		end
		
		def self._get_storage_client_cache memory_storage_client
			raise NotImplementedError.new 'You must override this method in the subclass!'
		end
		
		def _to_resource_info
			raise NotImplementedError.new 'You must override this method in the subclass!'
		end
		
		def self._create_from_directory storage_directory, memory_storage_client, id, name
			raise NotImplementedError.new 'You must override this method in the subclass!'
		end

		###

		def self._find_or_create_client_by_id_or_name memory_storage_client, id: nil, name: nil

			raise unless id || name
			
			storage_client_cache = _get_storage_client_cache memory_storage_client
			storages_dir = _get_storages_dir memory_storage_client

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

			resource_client = _create_from_directory storage_path, memory_storage_client, id, name
			storage_client_cache << resource_client

			return resource_client
		end
	end


	### BaseResourceCollectionClient

	"""Base class for resource collection clients."""
	class BaseResourceCollectionClient
	
		"""Initialize the DatasetCollectionClient with the passed arguments."""
		def initialize base_storage_directory, memory_storage_client
			@_base_storage_directory = base_storage_directory
			@_memory_storage_client = memory_storage_client
		end
		
		#@abstractmethod
		def _get_storage_client_cache
			raise NotImplementedError.new 'You must override this method in the subclass!'
		end
		
		#@abstractmethod
		def _get_resource_client_class
			raise NotImplementedError.new 'You must override this method in the subclass!'
		end
		
		"""List the available storages.

		Returns:
			ListPage: The list of available storages matching the specified filters.
		"""
		#@abstractmethod
		def list
			raise
			"""
			storage_client_cache = _get_storage_client_cache

			items = [storage._to_resource_info() for storage in storage_client_cache]

			return ListPage({
				'total': len(items),
				'count': len(items),
				'offset': 0,
				'limit': len(items),
				'desc': False,
				'items': sorted(items, key=itemgetter('createdAt')),
			})
			"""
		end

		"""Retrieve a named storage, or create a new one when it doesn't exist.

		Args:
			name (str, optional): The name of the storage to retrieve or create.
			schema (Dict, optional): The schema of the storage

		Returns:
			dict: The retrieved or newly-created storage.
		"""		
		#@abstractmethod
		def get_or_create name: nil, schema: nil, _id: nil

			resource_client_class = self.class::CLIENT_CLASS #_get_resource_client_class
			storage_client_cache = _get_storage_client_cache

			if name || _id
				found = resource_client_class._find_or_create_client_by_id_or_name @_memory_storage_client, name: name, id: _id
				return found._to_resource_info if found
			end

			new_resource = resource_client_class.new(
				@_base_storage_directory,
				@_memory_storage_client,
				id: _id,
				name: name,
			)
			storage_client_cache << new_resource

			# Write to the disk
			resource_info = new_resource._to_resource_info
			Utils::_update_metadata(
				data: resource_info,
				entity_directory: new_resource._resource_directory,
				write_metadata: @_memory_storage_client._write_metadata
			)

			return resource_info
		end
	end

end
end