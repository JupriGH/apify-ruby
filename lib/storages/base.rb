module Apify

	"""A class for managing storage clients."""
	class StorageClientManager

		attr_accessor :_config, :_local_client, :_cloud_client

		@_default_instance = nil

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
				raise if default_instance._cloud_client.nil?
				return default_instance._cloud_client
			end
			
			raise "### TODO: local_client not implemented"
			
			if !default_instance._local_client
				# default_instance._local_client = MemoryStorageClient.new(
				#	persist_storage=default_instance._config.persist_storage, write_metadata=true
				# )
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
		
		def self._get_default_instance = @_default_instance ||= new
	end

	 """A class for managing storages."""
	class BaseStorage

		attr_accessor :_id, :_name
		
		@_storage_client
		@_config
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
		def initialize id: nil, name: nil, client: nil, config: nil
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

		def self._get_default_id config
			raise 'You must override this method in the subclass!' # NotImplementedError
		end
		
		def self._get_single_storage_client id, client
			raise 'You must override this method in the subclass!' # NotImplementedError
		end

		def self._get_storage_collection_client client
			raise 'You must override this method in the subclass!' # NotImplementedError
		end
=end 
		###=================================================================================

		def self._ensure_class_initialized
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
		def self.open id: nil, name: nil, force_cloud: false, config: nil
			_ensure_class_initialized

			raise if !@_cache_by_id
			raise if !@_cache_by_name

			raise if (id && name)
			
			used_config = config || Configuration.get_global_configuration
			used_client = StorageClientManager.get_storage_client(force_cloud)

			# Fetch default ID if no ID or name was passed
			is_default_storage_on_local = false
			
			if ! (id || name)
				#if isinstance(used_client, MemoryStorageClient):
				#    is_default_storage_on_local = True
				id = _get_default_id used_config
			end
			
			# Try to get the storage instance from cache		
			cached_storage = nil
			if id
				cached_storage = @_cache_by_id[id]
			elsif name
				cached_storage = @_cache_by_name[name]
			end
			
			if cached_storage
				# This cast is needed since MyPy doesn't understand very well that Self and Storage are the same
				# return cast(Self, cached_storage)
				return cached_storage
			end
			
			# Purge default storages if configured
			"""
			if used_config.purge_on_start and isinstance(used_client, MemoryStorageClient):
				await used_client._purge_on_start()
			"""
			
			#assert cls._storage_creating_lock is not None
			#async with cls._storage_creating_lock:
				
				# Create the storage
				if id && !is_default_storage_on_local
					
					single_storage_client 	= _get_single_storage_client id, used_client				
					storage_info 			= single_storage_client.get 

					raise "#{self::HUMAN_FRIENDLY_LABEL} with id \"#{id}\" does not exist!" if !storage_info # RuntimeError

				elsif is_default_storage_on_local

					raise "TODO 1"
					#storage_collection_client = cls._get_storage_collection_client(used_client)
					#storage_info = await storage_collection_client.get_or_create(name=name, _id=id)

				else
					
					storage_collection_client = _get_storage_collection_client used_client
					storage_info = storage_collection_client.get_or_create name: name
				end
											
				storage = new id: storage_info['id'], name: storage_info['name'], client: used_client, config: used_config
				
				# Cache by id and name
				@_cache_by_id[storage._id] = storage
				@_cache_by_name[storage._name] = storage if storage._name
		
			return storage
		end

=begin

		def _remove_from_cache(self) -> None:
			if self.__class__._cache_by_id is not None:
				del self.__class__._cache_by_id[self._id]

			if self._name and self.__class__._cache_by_name is not None:
				del self.__class__._cache_by_name[self._name]
=end

	end

end
