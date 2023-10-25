module Apify

module MemoryStorage

	"""Base class for resource clients."""
	class BaseResourceClient

		attr_accessor :_id, :_name, :_resource_directory
		
		### @abstractmethod
		
		"""Initialize the BaseResourceClient."""
		#def initialize base_storage_directory, memory_storage_client, id: nil, name: nil
		def initialize memory_storage_client, id: nil, name: nil
			@_id = id || Crypto::_crypto_random_object_id
			
			@_resource_directory = File.join(memory_storage_client._directory[self.class], name || @_id)
	
			@_memory_storage_client = memory_storage_client
			@_name = name
			@_created_at = @_accessed_at = @_modified_at = Time.now.utc
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
			#found = self.class._find_or_create_client_by_id_or_name @_memory_storage_client, id: @_id, name: @_name
			
			#p self.class
			#raise
			found = @_memory_storage_client._find_or_create_client self.class, id: @_id, name: @_name
			
			if found
				#async with found._file_operation_lock:
					found._update_timestamps false
					found._to_resource_info
			end
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
	end


	### BaseResourceCollectionClient

	"""Base class for resource collection clients."""
	class BaseResourceCollectionClient
		
		# CLIENT_CLASS = "...."
		
		"""Initialize the DatasetCollectionClient with the passed arguments."""
		def initialize memory_storage_client
			@_memory_storage_client = memory_storage_client
		end
		
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