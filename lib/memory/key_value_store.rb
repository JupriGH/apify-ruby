require 'mime/types'

def _filename_from_record record
	return record[:filename] if record[:filename]

	content_type = record[:contentType]
	return record[:key] if !content_type || content_type == 'application/octet-stream'

	extension = Apify::Utils::_guess_file_extension content_type
	return record[:key] if record[:key].end_with?(".#{extension}")

	"#{record[:key]}.#{extension}"
end

module Apify

	module MemoryStorage

	"""Sub-client for manipulating a single key-value store."""
	class KeyValueStoreClient < BaseResourceClient

		STORAGE_TYPE = StorageTypes::KEY_VALUE_STORE

		attr_accessor :_records
		
		"""Initialize the KeyValueStoreClient."""
		def initialize memory_storage_client, id: nil, name: nil
			super memory_storage_client, id: id, name: name
			@_records = {}
		end
		
		"""Retrieve the key-value store.

		Returns:
			dict, optional: The retrieved key-value store, or None if it does not exist
		"""
		# def get = super
	 
		"""Update the key-value store with specified fields.

		Args:
			name (str, optional): The new name for key-value store

		Returns:
			dict: The updated key-value store
		"""
=begin
		async def update(self, *, name: Optional[str] = None) -> Dict:
			# Check by id
			existing_store_by_id = self._find_or_create_client_by_id_or_name(
				memory_storage_client=self._memory_storage_client, id=self._id, name=self._name)

			if existing_store_by_id is None:
				_raise_on_non_existing_storage(_StorageTypes.KEY_VALUE_STORE, self._id)

			# Skip if no changes
			if name is None:
				return existing_store_by_id._to_resource_info()

			async with existing_store_by_id._file_operation_lock:
				# Check that name is not in use already
				existing_store_by_name = next(
					(store for store in self._memory_storage_client._key_value_stores_handled if store._name and store._name.lower() == name.lower()),
					None,
				)

				if existing_store_by_name is not None:
					_raise_on_duplicate_storage(_StorageTypes.KEY_VALUE_STORE, 'name', name)

				existing_store_by_id._name = name

				previous_dir = existing_store_by_id._resource_directory

				existing_store_by_id._resource_directory = os.path.join(self._memory_storage_client._key_value_stores_directory, name)

				await _force_rename(previous_dir, existing_store_by_id._resource_directory)

				# Update timestamps
				await existing_store_by_id._update_timestamps(True)

			return existing_store_by_id._to_resource_info()
=end

		"""Delete the key-value store."""
		def delete
			store = @_memory_storage_client._pop_client self.class, id: @_id
			return unless store

			#async with store._file_operation_lock:
				store._records.clear

				FileUtils.rm_rf store._resource_directory
		end
			
		"""List the keys in the key-value store.

		Args:
			limit (int, optional): Number of keys to be returned. Maximum value is 1000
			exclusive_start_key (str, optional): All keys up to this one (including) are skipped from the result

		Returns:
			dict: The list of keys in the key-value store matching the given arguments
		"""
		def list_keys limit: Apify::DEFAULT_API_PARAM_LIMIT, exclusive_start_key: nil
			# Check by id
			store = _check_id

			items = store._records.each_value.map { |record| {'key' => record[:key], 'size' => record[:key]&.length} }

			if items.empty? 
				return {
					'count' => items.length,
					'limit' => limit,
					'exclusiveStartKey' => exclusive_start_key,
					'isTruncated' => false,
					'nextExclusiveStartKey' => nil,
					'items' => items,
				}
			end
			
			# Lexically sort to emulate the API
			items.sort_by! {|i| i['key']}
			
			key_pos = exclusive_start_key ? (items.find_index {|i| i['key'] == exclusive_start_key} || -1) : -1
			
			limited_items = items[key_pos+1, limit]
			
			truncated = items[-1] != limited_items[-1]
			next_key = truncated ? last_selected_item['key'] : nil

			#async with store._file_operation_lock:
				store._update_timestamps false

			{
				'count' => items.length,
				'limit' => limit,
				'exclusiveStartKey' => exclusive_start_key,
				'isTruncated' =>  truncated,
				'nextExclusiveStartKey' => next_key,
				'items' => limited_items,
			}
		end
		
		def _get_record_internal key, as_bytes=nil
			# Check by id
			store = _check_id

			stored_record = store._records[key]
			return if !stored_record

			record = {
				key: stored_record[:key],
				value: stored_record[:value],
				contentType: stored_record[:contentType],
			}

			if !as_bytes
				begin
					record[:value] = Apify::Utils::_maybe_parse_body(record[:value], record[:contentType])
				rescue Exception => e # ValueError:
					Log.fatal 'Error parsing key-value store record'
				end
			end
			#async with store._file_operation_lock:
				store._update_timestamps false
			
			return record
		end

		"""Retrieve the given record from the key-value store.

		Args:
			key (str): Key of the record to retrieve

		Returns:
			dict, optional: The requested record, or None, if the record does not exist
		"""
		def get_record(key) = _get_record_internal key

		"""Retrieve the given record from the key-value store, without parsing it.

		Args:
			key (str): Key of the record to retrieve

		Returns:
			dict, optional: The requested record, or None, if the record does not exist
		"""
		def get_record_as_bytes(key) = _get_record_internal key, true
		
		def stream_record(_key) = raise NotImplementedError.new 'This method is not supported in local memory storage.'

		"""Set a value to the given record in the key-value store.

		Args:
			key (str): The key of the record to save the value to
			value (Any): The value to save into the record
			content_type (str, optional): The content type of the saved value
		"""
		def set_record key, value, content_type=nil
			# Check by id
			store = _check_id
				
			#if isinstance(value, io.IOBase):
			#    raise NotImplementedError('File-like values are not supported in local memory storage')

			if !content_type			
				if nil # is_file_or_bytes(value):
					# content_type = 'application/octet-stream'
				elsif value.class == String
					content_type = 'text/plain; charset=utf-8'
				else
					content_type = 'application/json; charset=utf-8'
				end
			end
			if content_type.start_with?('application/json') && (value.class != String) #&& !is_file_or_bytes(value)
				value = value.to_json.encode('utf-8')
			end
			
			#async with store._file_operation_lock:
				store._update_timestamps true
				
				# WARNING: contentType => camelCase for compatibility (Apify Client API)
				record = { key: key, value: value, contentType: content_type } 

				old_record = store._records[key]
				store._records[key] = record

				if @_memory_storage_client._persist_storage
					if old_record && (_filename_from_record(old_record) != _filename_from_record(record))
						store._delete_persisted_record old_record
					end
					store._persist_record record
				end
		end

		def _persist_record record 
			record_filename = _filename_from_record(record)
			record[:filename] = record_filename

			# Ensure the directory for the entity exists
			FileUtils.mkdir_p(@_resource_directory)

			# Create files for the record
			record_path = File.join(@_resource_directory, record_filename)
			record_metadata_path = File.join(@_resource_directory, "#{record_filename}.__metadata__.json")

			# Convert to bytes if string
			record[:value] = record[:value].encode('utf-8') if record[:value].class == String

			File.write record_path, record[:value]

			if @_memory_storage_client._write_metadata
				#async with aiofiles.open(record_metadata_path, mode='wb') as f:
					metadata = {key: record[:key], contentType: record[:contentType]}.to_json
					File.write(record_metadata_path, metadata, encoding: 'UTF-8')
			end
		end

		"""Delete the specified record from the key-value store.

		Args:
			key (str): The key of the record which to delete
		"""	
		def delete_record key
			# Check by id
			store = _check_id
			record = store._records[key]

			if record
				# async with existing_store_by_id._file_operation_lock:
					store._records.delete key
					store._update_timestamps true
					store._delete_persisted_record(record) if @_memory_storage_client._persist_storage
			end
		end

		def _delete_persisted_record record
			record_filename = _filename_from_record(record)

			# Ensure the directory for the entity exists
			#await makedirs(@_resource_directory, exist_ok=True)

			# Create files for the record
			record_path = File.join(@_resource_directory, record_filename)
			record_metadata_path = File.join(@_resource_directory, "#{record_filename}.__metadata__.json")

			File.delete(record_path)
			File.delete(record_metadata_path)
		end

		"""Retrieve the key-value store info."""
		def _to_resource_info
			{
				'id' => @_id,
				'name' => @_name,
				'accessedAt' => @_accessed_at,
				'createdAt' => @_created_at,
				'modifiedAt' => @_modified_at,
				'userId' => '1',
			}
		end

		def self._create_from_directory storage_directory, memory_storage_client, id, name=nil
			created_at = accessed_at = modified_at = Time.now

			store_metadata_path = File.join storage_directory, '__metadata__.json'
			if File.file?(store_metadata_path)
				metadata = File.read(store_metadata_path, encoding: 'utf-8')
				metadata = JSON.parse metadata

				id = metadata['id']
				name = metadata['name']
				created_at = Time.parse metadata['createdAt']
				accessed_at = Time.parse metadata['accessedAt']
				modified_at = Time.parse metadata['modifiedAt']
			end
			
			new_client = new  memory_storage_client, id: id, name: name

			# Overwrite internal properties
			new_client._accessed_at = accessed_at
			new_client._created_at = created_at
			new_client._modified_at = modified_at

			# Scan the key value store folder, check each entry in there and parse it as a store record
			Dir.foreach(storage_directory) do |entry_name|
				# Ignore metadata files on their own
				next if entry_name.end_with?('__metadata__.json')

				entry_path = File.join(storage_directory, entry_name)
				next unless File.file?(entry_path)
							
				file_content = File.read(entry_path) # binary

				# Try checking if this file has a metadata file associated with it
				metadata = nil
				metadata_file = File.join(storage_directory, "#{entry_name}.__metadata__.json")
				
				if File.file?(metadata_file)
					begin
						metadata = JSON.parse File.read(metadata_file, encoding: 'utf-8'), symbolize_names: true
						raise if metadata[:key].nil?
						raise if metadata[:contentType].nil?
					rescue Exception => e
						Log.warn(
							"Metadata of key-value store entry \"#{entry_name}\" for store \"#{name || id}\" could not be parsed. The metadata file will be ignored."#,
							#exc_info=True,
						)
					end
				end
				if !metadata
					content_type = MIME::Types.type_for(entry_name)[0]&.to_s || 'application/octet-stream'
					metadata = { key: File.basename(entry_name, '.*'), contentType: content_type }
				end
				
				begin
					Apify::Utils::_maybe_parse_body(file_content, metadata[:contentType])
				rescue Exception => e # ValueError 
					metadata[:contentType] = 'application/octet-stream'
					Log.warn(
						"Key-value store entry \"#{metadata[:key]}\" for store \"#{name or id}\" could not be parsed. The entry will be assumed as binary."
						#exc_info=True,
					)
				end
				
				new_client._records[metadata[:key]] = {
					key: metadata[:key],
					contentType: metadata[:contentType],
					filename: entry_name,
					value: file_content
				}
			end
			
			return new_client
		end
	end


	"""Sub-client for manipulating key-value stores."""
	class KeyValueStoreCollectionClient < BaseResourceCollectionClient
		
		CLIENT_CLASS = KeyValueStoreClient

		"""List the available key-value stores.

		Returns:
			ListPage: The list of available key-value stores matching the specified filters.
		"""
		# def list = super

		"""Retrieve a named key-value store, or create a new one when it doesn't exist.

		Args:
			name (str, optional): The name of the key-value store to retrieve or create.
			schema (Dict, optional): The schema of the key-value store

		Returns:
			dict: The retrieved or newly-created key-value store.
		"""
		# def get_or_create(name: nil, schema: nil, _id: nil) = super name: name, schema: schema, _id: _id
	end

	end
end