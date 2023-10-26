module Apify

module MemoryStorage

	"""Base class for resource clients."""
	class BaseResourceClient

		# STORAGE_TYPE = "..."
		
		attr_accessor :_id, :_name, :_resource_directory, :_created_at, :_accessed_at, :_modified_at
		
		"""Initialize the BaseResourceClient."""
		def initialize memory_storage_client, id: nil, name: nil
			@_memory_storage_client = memory_storage_client
			@_id = id || Crypto::_crypto_random_object_id
			@_name = name
			@_resource_directory = File.join(memory_storage_client._directory[self.class], name||@_id)
			@_created_at = @_accessed_at = @_modified_at = Time.now
			@_file_operation_lock = Async::Semaphore.new(1) # lock
		end

		"""Retrieve the storage.

		Returns:
			dict, optional: The retrieved storage, or None, if it does not exist
		"""	
		#def get
		#	raise NotImplementedError.new 'You must override this method in the subclass!'
		#end
		def get
			found = @_memory_storage_client._find_or_create_client self.class, id: @_id, name: @_name
			if found
				#async with found._file_operation_lock:
					found._update_timestamps false
					found._to_resource_info
			end
		end
			
		def _to_resource_info
			raise NotImplementedError.new 'You must override this method in the subclass!'
		end
		
		def self._create_from_directory storage_directory, memory_storage_client, id, name
			raise NotImplementedError.new 'You must override this method in the subclass!'
		end
		
		"""Update the timestamps of the store."""	
		def _update_timestamps has_been_modified=nil
			now = Time.now
			@_accessed_at = now
			@_modified_at = now if has_been_modified
				
			store_info = _to_resource_info
			Utils::_update_metadata(
				data: store_info,
				entity_directory: @_resource_directory,
				write_metadata: @_memory_storage_client._write_metadata,
			)
		end

		def _check_id
			store = @_memory_storage_client._find_or_create_client self.class, id: @_id, name: @_name
			Apify::Utils::_raise_on_non_existing_storage(self.class::STORAGE_TYPE, @_id) if !store
			return store	
		end
	end

	### BaseResourceCollectionClient

	"""Base class for resource collection clients."""
	class BaseResourceCollectionClient
		
		# CLIENT_CLASS = "...."
		
		"""Initialize the DatasetCollectionClient with the passed arguments."""
		def initialize(memory_storage_client) = (@_memory_storage_client = memory_storage_client)
		
		def _get_storage_client_cache = @_memory_storage_client._cache[self.class::CLIENT_CLASS]
		
		"""List the available storages.

		Returns:
			ListPage: The list of available storages matching the specified filters.
		"""
		def list
			storage_client_cache =  _get_storage_client_cache

			items = storage_client_cache.map {|storage| storage._to_resource_info}

			Apify::Models::ListPage.new({
				'total' => items.length,
				'count' => items.length,
				'offset' => 0,
				'limit' => items.length,
				'desc' => false,
				'items' => items.sort_by {|it| it['createdAt']}
			})
		end

		"""Retrieve a named storage, or create a new one when it doesn't exist.

		Args:
			name (str, optional): The name of the storage to retrieve or create.
			schema (Dict, optional): The schema of the storage

		Returns:
			dict: The retrieved or newly-created storage.
		"""		
		def get_or_create name: nil, schema: nil, _id: nil	
			resource_client_class = self.class::CLIENT_CLASS #_get_resource_client_class
			storage_client_cache = _get_storage_client_cache

			if name || _id
				found =  @_memory_storage_client._find_or_create_client resource_client_class, name: name, id: _id
				return found._to_resource_info if found
			end

			new_resource = resource_client_class.new(@_memory_storage_client, id: _id, name: name)
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