module Apify

	"""Sub-client for manipulating a single key-value store."""
	class KeyValueStoreClient < ResourceClient

		"""Initialize the KeyValueStoreClient."""
		def initialize(**kwargs) = super(resource_path: 'key-value-stores', **kwargs)
		
		"""Retrieve the key-value store.

		https://docs.apify.com/api/v2#/reference/key-value-stores/store-object/get-store

		Returns:
			dict, optional: The retrieved key-value store, or None if it does not exist
		"""
		def get = _get

		"""Update the key-value store with specified fields.

		https://docs.apify.com/api/v2#/reference/key-value-stores/store-object/update-store

		Args:
			name (str, optional): The new name for key-value store

		Returns:
			dict: The updated key-value store
		"""
		def update(name: nil, title: nil) = _update({name: name, title: title})

		"""Delete the key-value store.

		https://docs.apify.com/api/v2#/reference/key-value-stores/store-object/delete-store
		"""		
		def delete = _delete

		"""List the keys in the key-value store.

		https://docs.apify.com/api/v2#/reference/key-value-stores/key-collection/get-list-of-keys

		Args:
			limit (int, optional): Number of keys to be returned. Maximum value is 1000
			exclusive_start_key (str, optional): All keys up to this one (including) are skipped from the result

		Returns:
			dict: The list of keys in the key-value store matching the given arguments
		"""		
		def list_keys limit: nil, exclusive_start_key: nil
			_http_get 'keys', params: _params(limit: limit, exclusiveStartKey: exclusive_start_key), filter_null: true, pluck_data: true
		end

		"""Retrieve the given record from the key-value store.

		https://docs.apify.com/api/v2#/reference/key-value-stores/record/get-record

		Args:
			key (str): Key of the record to retrieve
			as_bytes (bool, optional): Deprecated, use `get_record_as_bytes()` instead. Whether to retrieve the record as raw bytes, default False
			as_file (bool, optional): Deprecated, use `stream_record()` instead. Whether to retrieve the record as a file-like object, default False

		Returns:
			dict, optional: The requested record, or None, if the record does not exist
		"""
		def get_record key #, as_bytes: false, as_file: false
=begin            
			raise 'You cannot have both as_bytes and as_file set.' if as_bytes and as_file # ValueError

			if as_bytes
				raise "TODO"
				"""
				warnings.warn(
					'`KeyValueStoreClient.get_record(..., as_bytes=True)` is deprecated, use `KeyValueStoreClient.get_record_as_bytes()` instead.',  # noqa: E501
					DeprecationWarning,
					stacklevel=2,
				)
				return self.get_record_as_bytes(key)
				"""
			end
			
			if as_file
				raise "TODO"
				"""
				warnings.warn(
					'`KeyValueStoreClient.get_record(..., as_file=True)` is deprecated, use `KeyValueStoreClient.stream_record()` instead.',
					DeprecationWarning,
					stacklevel=2,
				)
				return self.stream_record(key)  # type: ignore
				"""
			end
=end			
			res = @http_client.call url: _url("records/#{key}"), method: 'GET', params: _params
			return { key: key, value: res[:parsed], content_type: res[:response]['content-type'] } # WARNING: symbolic hash keys!
				
		rescue ApifyApiError => exc
			Utils::_catch_not_found_or_throw exc
		end

		"""Retrieve the given record from the key-value store, without parsing it.

		https://docs.apify.com/api/v2#/reference/key-value-stores/record/get-record

		Args:
			key (str): Key of the record to retrieve

		Returns:
			dict, optional: The requested record, or None, if the record does not exist
		"""
		def get_record_as_bytes key
			res = @http_client.call url: _url("records/#{key}"), method: 'GET', params: _params, parse_response: false
			return { key: key, value: res[:response].body, content_type: res[:response]['content-type'] }					
		rescue ApifyApiError => exc
			Utils::_catch_not_found_or_throw exc
		end

		"""Retrieve the given record from the key-value store, as a stream.

		https://docs.apify.com/api/v2#/reference/key-value-stores/record/get-record

		Args:
			key (str): Key of the record to retrieve

		Returns:
			dict, optional: The requested record as a context-managed streaming Response, or None, if the record does not exist
		"""
=begin
		@contextmanager
		def stream_record(self, key: str) -> Iterator[Optional[Dict]]:
			response = None
			try:
				response = self.http_client.call(
					url=self._url(f'records/{key}'),
					method='GET',
					params=self._params(),
					parse_response=False,
					stream=True,
				)

				yield {
					'key': key,
					'value': response,
					'content_type': response.headers['content-type'],
				}

			except ApifyApiError as exc:
				_catch_not_found_or_throw(exc)
				yield None
			finally:
				if response:
					response.close()
=end

		"""Set a value to the given record in the key-value store.

		https://docs.apify.com/api/v2#/reference/key-value-stores/record/put-record

		Args:
			key (str): The key of the record to save the value to
			value (Any): The value to save into the record
			content_type (str, optional): The content type of the saved value
		"""
		def set_record key, value, content_type=nil
			value, content_type = Utils::_encode_key_value_store_record_value value, content_type

			headers = content_type ? {'Content-Type': content_type} : nil
			
			@http_client.call url: _url("records/#{key}"), method:'PUT', params: _params, data: value, headers: headers
		end

		"""Delete the specified record from the key-value store.

		https://docs.apify.com/api/v2#/reference/key-value-stores/record/delete-record

		Args:
			key (str): The key of the record which to delete
		"""		
		def delete_record(key) = _http_del "records/#{key}", params: _params
	end

	### KeyValueStoreCollectionClient

    """Sub-client for manipulating key-value stores."""
	class KeyValueStoreCollectionClient < ResourceCollectionClient

		"""Initialize the KeyValueStoreCollectionClient with the passed arguments."""
		def initialize(**kwargs) = super(resource_path: 'key-value-stores', **kwargs)

		"""List the available key-value stores.

		https://docs.apify.com/api/v2#/reference/key-value-stores/store-collection/get-list-of-key-value-stores

		Args:
			unnamed (bool, optional): Whether to include unnamed key-value stores in the list
			limit (int, optional): How many key-value stores to retrieve
			offset (int, optional): What key-value store to include as first when retrieving the list
			desc (bool, optional): Whether to sort the key-value stores in descending order based on their modification date

		Returns:
			ListPage: The list of available key-value stores matching the specified filters.
		"""
		def list unnamed: nil, limit: nil, offset: nil, desc: nil
			_list unnamed: unnamed, limit: limit, offset: offset, desc: desc
		end

        """Retrieve a named key-value store, or create a new one when it doesn't exist.

        https://docs.apify.com/api/v2#/reference/key-value-stores/store-collection/create-key-value-store

        Args:
            name (str, optional): The name of the key-value store to retrieve or create.
            schema (Dict, optional): The schema of the key-value store

        Returns:
            dict: The retrieved or newly-created key-value store.
        """
		def get_or_create name: nil, schema: nil	
			_get_or_create name: name, resource: ({'schema': schema})
		end
	end

end
