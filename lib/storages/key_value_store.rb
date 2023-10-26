module Apify

	"""The `KeyValueStore` class represents a key-value store.

	You can imagine it as a simple data storage that is used
	for saving and reading data records or files. Each data record is
	represented by a unique key and associated with a MIME content type.

	Do not instantiate this class directly, use the `Actor.open_key_value_store()` function instead.

	Each crawler run is associated with a default key-value store, which is created exclusively
	for the run. By convention, the crawler input and output are stored into the
	default key-value store under the `INPUT` and `OUTPUT` key, respectively.
	Typically, input and output are JSON files, although it can be any other format.
	To access the default key-value store directly, you can use the
	`KeyValueStore.get_value` and `KeyValueStore.set_value` convenience functions.

	`KeyValueStore` stores its data either on local disk or in the Apify cloud,
	depending on whether the `APIFY_LOCAL_STORAGE_DIR` or `APIFY_TOKEN` environment variables are set.

	If the `APIFY_LOCAL_STORAGE_DIR` environment variable is set, the data is stored in
	the local directory in the following files:
	```
	{APIFY_LOCAL_STORAGE_DIR}/key_value_stores/{STORE_ID}/{INDEX}.{EXT}
	```
	Note that `{STORE_ID}` is the name or ID of the key-value store. The default key-value store has ID: `default`,
	unless you override it by setting the `APIFY_DEFAULT_KEY_VALUE_STORE_ID` environment variable.
	The `{KEY}` is the key of the record and `{EXT}` corresponds to the MIME content type of the data value.

	If the `APIFY_TOKEN` environment variable is set but `APIFY_LOCAL_STORAGE_DIR` is not, the data is stored in the
	[Apify Key-value store](https://docs.apify.com/storage/key-value-store) cloud storage.
	"""
		
	class KeyValueStore < BaseStorage
		
		HUMAN_FRIENDLY_LABEL = StorageTypes::KEY_VALUE_STORE
		
		"""Create a `KeyValueStore` instance.

		Do not use the constructor directly, use the `Actor.open_key_value_store()` function instead.

		Args:
			id (str): ID of the key-value store.
			name (str, optional): Name of the key-value store.
			client (ApifyClientAsync or MemoryStorageClient): The storage client which should be used.
			config (Configuration): The configuration which should be used.
		"""

		def initialize id=nil, name: nil, client: nil, config: nil				
			super id, name: name, client: client, config: config	
			@_key_value_store_client = client.key_value_store @_id
			
		end

		#def self._get_human_friendly_label
		#    'Key-value store'
		#end

		def self._get_default_id(config) = config.default_key_value_store_id
		
		def self._get_single_storage_client(id, client) = client.key_value_store id
		
		def self._get_storage_collection_client(client) = client.key_value_stores
			
		"""Get a value from the key-value store.

		Args:
			key (str): Key of the record to retrieve.
			default_value (Any, optional): Default value returned in case the record does not exist.

		Returns:
			Any: The value associated with the given key. `default_value` is used in case the record does not exist.
		"""
		def self.get_value(key, default_value=nil) = open.get_value key, default_value
		
		def get_value key, default_value=nil
			record = @_key_value_store_client.get_record key
			record ? record[:value] : default_value
		end

		"""Iterate over the keys in the key-value store.

		Args:
			exclusive_start_key (str, optional): All keys up to this one (including) are skipped from the result.

		Yields:
			IterateKeysTuple: A tuple `(key, info)`,
				where `key` is the record key, and `info` is an object that contains a single property `size`
				indicating size of the record in bytes.
		"""		
		def iterate_keys exclusive_start_key: nil
			while true
				list_keys = @_key_value_store_client.list_keys exclusive_start_key: exclusive_start_key

				list_keys['items'].each { |item|
					yield [item['key'], {'size' => item['size']}]
					# yield IterateKeysTuple(item['key'], {'size': item['size']})
				}
				
				break if !list_keys['isTruncated']
				
				exclusive_start_key = list_keys['nextExclusiveStartKey']
			end
		end

		"""Set or delete a value in the key-value store.

		Args:
			key (str): The key under which the value should be saved.
			value (Any, optional): The value to save. If the value is `None`, the corresponding key-value pair will be deleted.
			content_type (str, optional): The content type of the saved value.
		"""
		def self.set_value(key, value=nil, content_type=nil) = open.set_value key, value, content_type
		
		def set_value key, value=nil, content_type=nil
			if value.nil?
				@_key_value_store_client.delete_record key
			else
				@_key_value_store_client.set_record key, value, content_type
			end
		end
		
		"""Get a URL for the given key that may be used to publicly access the value in the remote key-value store.

		Args:
			key (str): The key for which the URL should be generated.
		"""
		def self.get_public_url(key) = open.get_public_url key

		def get_public_url key
			# if not isinstance(self._key_value_store_client, KeyValueStoreClientAsync):
			#    raise RuntimeError('Cannot generate a public URL for this key-value store as it is not on the Apify Platform!')
			"#{@_config.api_public_base_url}/v2/key-value-stores/#{@_id}/records/#{key}"
		end
		
		"""Remove the key-value store either from the Apify cloud storage or from the local directory."""
		def drop
			@_key_value_store_client.delete
			_remove_from_cache
		end

		"""Open a key-value store.

		Key-value stores are used to store records or files, along with their MIME content type.
		The records are stored and retrieved using a unique key.
		The actual data is stored either on a local filesystem or in the Apify cloud.

		Args:
			id (str, optional): ID of the key-value store to be opened.
				If neither `id` nor `name` are provided, the method returns the default key-value store associated with the actor run.
				If the key-value store with the given ID does not exist, it raises an error.
			name (str, optional): Name of the key-value store to be opened.
				If neither `id` nor `name` are provided, the method returns the default key-value store associated with the actor run.
				If the key-value store with the given name does not exist, it is created.
			force_cloud (bool, optional): If set to True, it will open a key-value store on the Apify Platform even when running the actor locally.
				Defaults to False.
			config (Configuration, optional): A `Configuration` instance, uses global configuration if omitted.

		Returns:
			KeyValueStore: An instance of the `KeyValueStore` class for the given ID or name.
		"""
		def self.open(id=nil, name: nil, force_cloud: false, config: nil) = _open_internal id, name: name, force_cloud: force_cloud, config: config
	end

end