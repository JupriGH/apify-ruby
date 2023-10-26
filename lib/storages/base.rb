module Apify
	
	"""A class for managing storage clients."""
	class StorageClientManager

		attr_accessor :_config, :_local_client, :_cloud_client

		@@_default_instance = nil

		"""Create a `StorageClientManager` instance."""
		def initialize
			@_config = Configuration.get_global_configuration
		end

		"""Set the config for the StorageClientManager.

		Args:
			config (Configuration): The configuration this StorageClientManager should use.
		"""	
		def self.set_config config
			_get_default_instance._config = config
		end	

		"""Get the current storage client instance.

		Returns:
			ApifyClientAsync or MemoryStorageClient: The current storage client instance.
		"""
		def self.get_storage_client force_cloud=false # Union[ApifyClientAsync, MemoryStorageClient]:
			default_instance = _get_default_instance

			if default_instance._config.is_at_home || force_cloud
				# assert default_instance._cloud_client is not None
				raise "Cloud client not set!" if default_instance._cloud_client.nil?
				return default_instance._cloud_client
			end

			# raise "### TODO: local_client not implemented"
			if !default_instance._local_client
				default_instance._local_client = MemoryStorage::Client.new(
					persist_storage: default_instance._config.persist_storage, write_metadata: true
				)
			end

			default_instance._local_client
		end

		"""Set the storage client.

		Args:
			client (ApifyClientAsync or MemoryStorageClient): The instance of a storage client.
		"""	
		def self.set_cloud_client client
			_get_default_instance._cloud_client = client
		end
		
		def self._get_default_instance = @@_default_instance ||= new
	end

	 """A class for managing storages."""
	class BaseStorage

		attr_accessor :_id, :_name
		
		@_cache_by_id
		@_cache_by_name
		# _storage_creating_lock: Optional[asyncio.Lock] = None

		"""Initialize the storage.

		Do not use this method directly, but use `Actor.open_<STORAGE>()` instead.

		Args:
			id (str): The storage id
			name (str, optional): The storage name
			client (ApifyClientAsync or MemoryStorageClient): The storage client
			config (Configuration): The configuration
		"""
		def initialize id=nil, name: nil, client: nil, config: nil
			@_id = id
			@_name = name
			@_storage_client = client
			@_config = config
		end
		
		###================================================================================= ABSTRACTS
=begin
		def self._get_human_friendly_label
			raise 'You must override this method in the subclass!' # NotImplementedError
		end
=end
		def self._get_default_id config
			raise NotImplementedError.new 'You must override this method in the subclass!'
		end
		
		def self._get_single_storage_client id, client
			raise NotImplementedError.new 'You must override this method in the subclass!'
		end

		def self._get_storage_collection_client client
			raise NotImplementedError.new 'You must override this method in the subclass!'
		end
 
		###=================================================================================

		def self._ensure_class_initialized
			# TODO: cache type force_cloud / local
			@_cache_by_id 		||= {} 
			@_cache_by_name 	||= {}

			#if cls._storage_creating_lock is None:
			#    cls._storage_creating_lock = asyncio.Lock()
		end

		"""Open a storage, or return a cached storage object if it was opened before.

		Opens a storage with the given ID or name.
		Returns the cached storage object if the storage was opened before.

		Args:
			id (str, optional): ID of the storage to be opened.
				If neither `id` nor `name` are provided, the method returns the default storage associated with the actor run.
				If the storage with the given ID does not exist, it raises an error.
			name (str, optional): Name of the storage to be opened.
				If neither `id` nor `name` are provided, the method returns the default storage associated with the actor run.
				If the storage with the given name does not exist, it is created.
			force_cloud (bool, optional): If set to True, it will open a storage on the Apify Platform even when running the actor locally.
				Defaults to False.
			config (Configuration, optional): A `Configuration` instance, uses global configuration if omitted.

		Returns:
			An instance of the storage.
		"""		
		def self._open_internal id=nil, name: nil, force_cloud: false, config: nil
			_ensure_class_initialized

			raise if !@_cache_by_id
			raise if !@_cache_by_name

			raise "Can't use `id` and `name` at the same time!" if (id && name) # NEW: error message
			
			used_config = config || Configuration.get_global_configuration
			used_client = StorageClientManager.get_storage_client(force_cloud)

			# Fetch default ID if no ID or name was passed
			is_default_storage_on_local = false
			
			if !(id || name)
				is_default_storage_on_local = used_client.class == MemoryStorage::Client
				id = _get_default_id used_config # BUG-RUBY: can't calling abstract implemented method
			end
			
			# Try to get the storage instance from cache
			cached_storage = if id
				@_cache_by_id[id]
			elsif name
				@_cache_by_name[name]
			end
			
			# This cast is needed since MyPy doesn't understand very well that Self and Storage are the same
			# return cast(Self, cached_storage)
			return cached_storage if cached_storage

			# Purge default storages if configured	
			
			used_client._purge_on_start if
				used_config.purge_on_start && used_client.class == MemoryStorage::Client

			#assert cls._storage_creating_lock is not None
			#async with cls._storage_creating_lock:
				
				# Create the storage
				if id && !is_default_storage_on_local
					single_storage_client 	= _get_single_storage_client id, used_client				
					storage_info 			= single_storage_client.get 

					### Utils::_raise_on_non_existing_storage(self::HUMAN_FRIENDLY_LABEL, id) if !storage_info
					raise "#{self::HUMAN_FRIENDLY_LABEL} with id \"#{id}\" does not exist!" if !storage_info # RuntimeError
					
				else 
					storage_collection_client = _get_storage_collection_client used_client
					if is_default_storage_on_local
						storage_info = storage_collection_client.get_or_create name: name, _id: id
					else
						storage_info = storage_collection_client.get_or_create name: name
					end
				end
											
				storage = new storage_info['id'], name: storage_info['name'], client: used_client, config: used_config
				
				# Cache by id and name
				@_cache_by_id[storage._id] = storage
				@_cache_by_name[storage._name] = storage if storage._name

			return storage
		end

		def _remove_from_cache
			@_cache_by_id.delete(@_id) 	if @_cache_by_id
			@_cache_by_name.delete(@_name) if @_cache_by_name && @_name
		end
	end
end
