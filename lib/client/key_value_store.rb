module Apify

class KeyValueStoreClient < ResourceClient
    """Sub-client for manipulating a single key-value store."""

    def initialize **kwargs # *args: Any, **kwargs: Any
		"""Initialize the KeyValueStoreClient."""
		super resource_path: 'key-value-stores', **kwargs
	end
	
    def get
        """Retrieve the key-value store.

        https://docs.apify.com/api/v2#/reference/key-value-stores/store-object/get-store

        Returns:
            dict, optional: The retrieved key-value store, or None if it does not exist
        """
        _get
	end
=begin
    def update(self, *, name: Optional[str] = None) -> Dict:
        """Update the key-value store with specified fields.

        https://docs.apify.com/api/v2#/reference/key-value-stores/store-object/update-store

        Args:
            name (str, optional): The new name for key-value store

        Returns:
            dict: The updated key-value store
        """
        updated_fields = {
            'name': name,
        }

        return self._update(filter_out_none_values_recursively(updated_fields))

    def delete(self) -> None:
        """Delete the key-value store.

        https://docs.apify.com/api/v2#/reference/key-value-stores/store-object/delete-store
        """
        return self._delete()
=end
    def list_keys limit: nil, exclusive_start_key: nil
        """List the keys in the key-value store.

        https://docs.apify.com/api/v2#/reference/key-value-stores/key-collection/get-list-of-keys

        Args:
            limit (int, optional): Number of keys to be returned. Maximum value is 1000
            exclusive_start_key (str, optional): All keys up to this one (including) are skipped from the result

        Returns:
            dict: The list of keys in the key-value store matching the given arguments
        """
        request_params = _params limit: limit, exclusiveStartKey: exclusive_start_key

        res = @http_client.call url: _url('keys'), method: 'GET', params: request_params

		res.dig(:parsed, "data")
        #return parse_date_fields(_pluck_data(response.json()))
	end

    def get_record key #, as_bytes: false, as_file: false
        """Retrieve the given record from the key-value store.

        https://docs.apify.com/api/v2#/reference/key-value-stores/record/get-record

        Args:
            key (str): Key of the record to retrieve
            as_bytes (bool, optional): Deprecated, use `get_record_as_bytes()` instead. Whether to retrieve the record as raw bytes, default False
            as_file (bool, optional): Deprecated, use `stream_record()` instead. Whether to retrieve the record as a file-like object, default False

        Returns:
            dict, optional: The requested record, or None, if the record does not exist
        """
        #try:
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

            { 
				key: key, 
				value: res[:parsed], 
				content_type: res[:response]['content-type'] 
			}

        # except ApifyApiError as exc:
        #    _catch_not_found_or_throw(exc)
		
		#return nil
	end

    def get_record_as_bytes key
        """Retrieve the given record from the key-value store, without parsing it.

        https://docs.apify.com/api/v2#/reference/key-value-stores/record/get-record

        Args:
            key (str): Key of the record to retrieve

        Returns:
            dict, optional: The requested record, or None, if the record does not exist
        """
        #try:
            res = @http_client.call url: _url("records/#{key}"), method: 'GET', params: _params, parse_response: false

            {
                key: key,
                value: res[:response].body,
                content_type: res[:response]['content-type']
            }

        #except ApifyApiError as exc:
        #    _catch_not_found_or_throw(exc)

        #return None
	end

=begin
    @contextmanager
    def stream_record(self, key: str) -> Iterator[Optional[Dict]]:
        """Retrieve the given record from the key-value store, as a stream.

        https://docs.apify.com/api/v2#/reference/key-value-stores/record/get-record

        Args:
            key (str): Key of the record to retrieve

        Returns:
            dict, optional: The requested record as a context-managed streaming Response, or None, if the record does not exist
        """
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

    def set_record key, value=nil, content_type=nil
        """Set a value to the given record in the key-value store.

        https://docs.apify.com/api/v2#/reference/key-value-stores/record/put-record

        Args:
            key (str): The key of the record to save the value to
            value (Any): The value to save into the record
            content_type (str, optional): The content type of the saved value
        """
        value, content_type = Utils::_encode_key_value_store_record_value value, content_type

		headers = content_type ? {'Content-Type': content_type} : nil
		
        @http_client.call \
			url: _url(path: "records/#{key}"), method:'PUT', params:_params, data:value, headers:headers
	end
	
=begin
    def delete_record(self, key: str) -> None:
        """Delete the specified record from the key-value store.

        https://docs.apify.com/api/v2#/reference/key-value-stores/record/delete-record

        Args:
            key (str): The key of the record which to delete
        """
        self.http_client.call(
            url=self._url(f'records/{key}'),
            method='DELETE',
            params=self._params(),
        )
=end
end

################################################################################################################################
class KeyValueStoreCollectionClient < ResourceCollectionClient
    """Sub-client for manipulating key-value stores."""

    def initialize **kwargs
        """Initialize the KeyValueStoreCollectionClient with the passed arguments."""
		super resource_path: 'key-value-stores', **kwargs
	end

    def list unnamed: nil, limit: nil, offset: nil, desc: nil
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
        _list unnamed: unnamed, limit: limit, offset: offset, desc: desc
	end

    def get_or_create name: nil, schema: nil
        """Retrieve a named key-value store, or create a new one when it doesn't exist.

        https://docs.apify.com/api/v2#/reference/key-value-stores/store-collection/create-key-value-store

        Args:
            name (str, optional): The name of the key-value store to retrieve or create.
            schema (Dict, optional): The schema of the key-value store

        Returns:
            dict: The retrieved or newly-created key-value store.
        """
		## TODO
		raise "TODO: filter_out_none_values_recursively" if schema
		
        _get_or_create name: name #, resource=filter_out_none_values_recursively({'schema': schema}))
	end
	
end

end
