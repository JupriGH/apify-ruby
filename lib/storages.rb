require 'json'
require 'csv'

############################################################################################
# 9MB
MAX_PAYLOAD_SIZE_BYTES = 9437184

SAFETY_BUFFER_PERCENT = 0.01 / 100
EFFECTIVE_LIMIT_BYTES = MAX_PAYLOAD_SIZE_BYTES - (MAX_PAYLOAD_SIZE_BYTES * SAFETY_BUFFER_PERCENT).ceil

def _check_and_serialize item: nil, index: nil
    """Accept a JSON serializable object as an input, validate its serializability and its serialized size against `EFFECTIVE_LIMIT_BYTES`."""
    s = index ? " at index #{index} " : " "

    #try:
        payload = item.to_json
    #except Exception as e:
    #    raise ValueError(f'Data item{s}is not serializable to JSON.') from e

    length_bytes = payload.length # len(payload.encode('utf-8'))
    if length_bytes > EFFECTIVE_LIMIT_BYTES
        raise "Data item#{s}is too large (size: #{length_bytes} bytes, limit: #{EFFECTIVE_LIMIT_BYTES} bytes)" # ValueError
	end
	
    return payload
end

=begin
def _chunk_by_size items
    """Take an array of JSONs, produce iterator of chunked JSON arrays respecting `EFFECTIVE_LIMIT_BYTES`.

    Takes an array of JSONs (payloads) as input and produces an iterator of JSON strings
    where each string is a JSON array of payloads with a maximum size of `EFFECTIVE_LIMIT_BYTES` per one
    JSON array. Fits as many payloads as possible into a single JSON array and then moves
    on to the next, preserving item order.

    The function assumes that none of the items is larger than `EFFECTIVE_LIMIT_BYTES` and does not validate.
    """
	"""
    last_chunk_bytes = 2  # Add 2 bytes for [] wrapper.
    current_chunk = []

    for payload in items:
        length_bytes = len(payload.encode('utf-8'))

        if last_chunk_bytes + length_bytes <= EFFECTIVE_LIMIT_BYTES:
            current_chunk.append(payload)
            last_chunk_bytes += length_bytes + 1  # Add 1 byte for ',' separator.
        else:
            yield f'[{",".join(current_chunk)}]'
            current_chunk = [payload]
            last_chunk_bytes = length_bytes + 2  # Add 2 bytes for [] wrapper.

    yield f'[{",".join(current_chunk)}]'
	"""
end
=end

############################################################################################

module Apify

class StorageClientManager

    """A class for managing storage clients."""

	attr_accessor \
		:_config,
		:_local_client,
		:_cloud_client

    @_default_instance = nil

    def initialize
        """Create a `StorageClientManager` instance."""
        @_config = Configuration.get_global_configuration()
	end
	
    def self.set_config config
        """Set the config for the StorageClientManager.

        Args:
            config (Configuration): The configuration this StorageClientManager should use.
        """
        _get_default_instance._config = config
	end
	

    def self.get_storage_client force_cloud=false # Union[ApifyClientAsync, MemoryStorageClient]:
        """Get the current storage client instance.

        Returns:
            ApifyClientAsync or MemoryStorageClient: The current storage client instance.
        """
        default_instance = _get_default_instance
		
        if not default_instance._local_client
			p "### TODO: if not default_instance._local_client"
			# default_instance._local_client = MemoryStorageClient.new(
			#	persist_storage=default_instance._config.persist_storage, write_metadata=true
			# )
		end
		
        if true # default_instance._config.is_at_home or force_cloud

			# assert default_instance._cloud_client is not None
            raise unless !default_instance._cloud_client.nil?
			return default_instance._cloud_client
			
		end
		
        default_instance._local_client
	end
	
    def self.set_cloud_client client
        """Set the storage client.

        Args:
            client (ApifyClientAsync or MemoryStorageClient): The instance of a storage client.
        """
        _get_default_instance._cloud_client = client
	end
	
    def self._get_default_instance
        @_default_instance ||= new
	end
end

#################################################################################################################

class BaseStorage # (ABC, Generic[BaseResourceClientType, BaseResourceCollectionClientType]):
    """A class for managing storages."""

	attr_accessor :_id, :_name
	
    @_storage_client
    @_config

    @_cache_by_id
    @_cache_by_name
    
	# _storage_creating_lock: Optional[asyncio.Lock] = None

    def initialize id: nil, name: nil, client: nil, config: nil
        """Initialize the storage.

        Do not use this method directly, but use `Actor.open_<STORAGE>()` instead.

        Args:
            id (str): The storage id
            name (str, optional): The storage name
            client (ApifyClientAsync or MemoryStorageClient): The storage client
            config (Configuration): The configuration
        """
        @_id = id
        @_name = name
        @_storage_client = client
        @_config = config
	end
	
	###================================================================================= ABSTRACTS
	#@human_friendly_label = "HUMAN_FRIENDLY_LABEL"
	"""
    def self._get_human_friendly_label
        raise 'You must override this method in the subclass!' # NotImplementedError
	end
	"""
=begin	
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

    # async 
	def self.open id: nil, name: nil, force_cloud: false, config: nil	
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

				raise "#{@human_friendly_label} with id \"#{id}\" does not exist!" if !storage_info # RuntimeError

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
            if storage._name
                @_cache_by_name[storage._name] = storage
			end
	
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

#################################################################################################################

class KeyValueStore < BaseStorage

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

    #_id: str
    #_name: Optional[str]
    @_key_value_store_client # Union[KeyValueStoreClientAsync, KeyValueStoreClient]

    def initialize id: nil, name: nil, client: nil, config: nil
		"""Create a `KeyValueStore` instance.

        Do not use the constructor directly, use the `Actor.open_key_value_store()` function instead.

        Args:
            id (str): ID of the key-value store.
            name (str, optional): Name of the key-value store.
            client (ApifyClientAsync or MemoryStorageClient): The storage client which should be used.
            config (Configuration): The configuration which should be used.
        """
		
		
        super id: id, name: name, client: client, config: config

        # self.get_value = _wrap_internal(self._get_value_internal, self.get_value)  # type: ignore
        # self.set_value = _wrap_internal(self._set_value_internal, self.set_value)  # type: ignore
        # self.get_public_url = _wrap_internal(self._get_public_url_internal, self.get_public_url)  # type: ignore
        
		# self._id = id
        # self._name = name
		
        @_key_value_store_client = client.key_value_store(@_id)
		
	end

	@human_friendly_label = 'Key-value store'
    #def self._get_human_friendly_label
    #    'Key-value store'
	#end

    def self._get_default_id config
        config.default_key_value_store_id
	end
	
    def self._get_single_storage_client id, client # Union[ApifyClientAsync, MemoryStorageClient],
        client.key_value_store id
	end
	
    def self._get_storage_collection_client client # Union[ApifyClientAsync, MemoryStorageClient],
        client.key_value_stores
	end
	
=begin
    @overload
    @classmethod
    async def get_value(cls, key: str) -> Any:
        ...

    @overload
    @classmethod
    async def get_value(cls, key: str, default_value: T) -> T:
        ...

    @overload
    @classmethod
    async def get_value(cls, key: str, default_value: Optional[T] = None) -> Optional[T]:
        ...
=end

    def self.get_value key: nil, default_value: nil
        """Get a value from the key-value store.

        Args:
            key (str): Key of the record to retrieve.
            default_value (Any, optional): Default value returned in case the record does not exist.

        Returns:
            Any: The value associated with the given key. `default_value` is used in case the record does not exist.
        """

        open.get_value(key, default_value)
	end
    def get_value key, default_value
        record = @_key_value_store_client.get_record(key)
		record ? record[:value] : default_value
	end
	
=begin
    async def iterate_keys(self, exclusive_start_key: Optional[str] = None) -> AsyncIterator[IterateKeysTuple]:
        """Iterate over the keys in the key-value store.

        Args:
            exclusive_start_key (str, optional): All keys up to this one (including) are skipped from the result.

        Yields:
            IterateKeysTuple: A tuple `(key, info)`,
                where `key` is the record key, and `info` is an object that contains a single property `size`
                indicating size of the record in bytes.
        """
        while True:
            list_keys = await self._key_value_store_client.list_keys(exclusive_start_key=exclusive_start_key)
            for item in list_keys['items']:
                yield IterateKeysTuple(item['key'], {'size': item['size']})

            if not list_keys['isTruncated']:
                break
            exclusive_start_key = list_keys['nextExclusiveStartKey']
=end

    def self.set_value key, value=nil, content_type=nil
        """Set or delete a value in the key-value store.

        Args:
            key (str): The key under which the value should be saved.
            value (Any, optional): The value to save. If the value is `None`, the corresponding key-value pair will be deleted.
            content_type (str, optional): The content type of the saved value.
        """
        open.set_value key, value, content_type
	end
    def set_value key, value=nil, content_type=nil
        if value.nil?
			raise "TODO"
            @_key_value_store_client.delete_record key
		else
			@_key_value_store_client.set_record key, value, content_type
		end
	end
	
=begin
    @classmethod
    async def get_public_url(cls, key: str) -> str:
        """Get a URL for the given key that may be used to publicly access the value in the remote key-value store.

        Args:
            key (str): The key for which the URL should be generated.
        """
        store = await cls.open()
        return await store.get_public_url(key)

=end
    def get_public_url key
        # if not isinstance(self._key_value_store_client, KeyValueStoreClientAsync):
        #    raise RuntimeError('Cannot generate a public URL for this key-value store as it is not on the Apify Platform!')

        "#{@_config.api_public_base_url}/v2/key-value-stores/#{@_id}/records/#{key}"
	end
	
=begin
    async def drop(self) -> None:
        """Remove the key-value store either from the Apify cloud storage or from the local directory."""
        await self._key_value_store_client.delete()
        self._remove_from_cache()

	# async

    def self.open id: nil, name: nil, force_cloud: false, config: nil
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
	
		# await
		p "@@@ KeyValueStore.open ... "
        superclass.open( id:id, name:name, force_cloud:force_cloud, config:config )
		raise "@@@ KeyValueStore.open =>"
		
		p ret
		return ret
	end
=end

end

#################################################################################################################

class Dataset < BaseStorage
    """The `Dataset` class represents a store for structured data where each object stored has the same attributes.

    You can imagine it as a table, where each object is a row and its attributes are columns.
    Dataset is an append-only storage - you can only add new records to it but you cannot modify or remove existing records.
    Typically it is used to store crawling results.

    Do not instantiate this class directly, use the `Actor.open_dataset()` function instead.

    `Dataset` stores its data either on local disk or in the Apify cloud,
    depending on whether the `APIFY_LOCAL_STORAGE_DIR` or `APIFY_TOKEN` environment variables are set.

    If the `APIFY_LOCAL_STORAGE_DIR` environment variable is set, the data is stored in
    the local directory in the following files:
    ```
    {APIFY_LOCAL_STORAGE_DIR}/datasets/{DATASET_ID}/{INDEX}.json
    ```
    Note that `{DATASET_ID}` is the name or ID of the dataset. The default dataset has ID: `default`,
    unless you override it by setting the `APIFY_DEFAULT_DATASET_ID` environment variable.
    Each dataset item is stored as a separate JSON file, where `{INDEX}` is a zero-based index of the item in the dataset.

    If the `APIFY_TOKEN` environment variable is set but `APIFY_LOCAL_STORAGE_DIR` is not, the data is stored in the
    [Apify Dataset](https://docs.apify.com/storage/dataset) cloud storage.
    """

    #_id: str
    #_name: Optional[str]
    @_dataset_client

    def initialize id: nil, name: nil, client: nil, config: nil
        """Create a `Dataset` instance.

        Do not use the constructor directly, use the `Actor.open_dataset()` function instead.

        Args:
            id (str): ID of the dataset.
            name (str, optional): Name of the dataset.
            client (ApifyClientAsync or MemoryStorageClient): The storage client which should be used.
            config (Configuration): The configuration which should be used.
        """
				
        super id: id, name: name, client: client, config: config

        # self.get_data = _wrap_internal(self._get_data_internal, self.get_data)  # type: ignore
        # self.push_data = _wrap_internal(self._push_data_internal, self.push_data)  # type: ignore
        # self.export_to_json = _wrap_internal(self._export_to_json_internal, self.export_to_json)  # type: ignore
        # self.export_to_csv = _wrap_internal(self._export_to_csv_internal, self.export_to_csv)  # type: ignore

        @_dataset_client = client.dataset(@_id)
	end
	
	@human_friendly_label = 'Dataset'    
	# def _get_human_friendly_label(cls) -> str:
    #    'Dataset'
	# end

    def self._get_default_id config
        config.default_dataset_id
	end

    def self._get_single_storage_client id, client
        client.dataset id
	end

    def self._get_storage_collection_client client
        client.datasets
	end
=begin
    def self.push_data data
        """Store an object or an array of objects to the dataset.

        The size of the data is limited by the receiving API and therefore `push_data()` will only
        allow objects whose JSON representation is smaller than 9MB. When an array is passed,
        none of the included objects may be larger than 9MB, but the array itself may be of any size.

        Args:
            data (JSONSerializable): dict or array of dicts containing data to be stored in the default dataset.
                The JSON representation of each item must be smaller than 9MB.
        """
        dataset = open
        dataset.push_data data
	end
=end
    def push_data data
		# Handle singular items
		if data.class != Array
			payload = _check_and_serialize(item: data)
            return @_dataset_client.push_items(payload)
		end
		
        # Handle lists
		"""
        payloads_generator = (_check_and_serialize(item, index) for index, item in enumerate(data))

        # Invoke client in series to preserve the order of data
        for chunk in _chunk_by_size(payloads_generator):
            await self._dataset_client.push_items(chunk)
		"""

		part, size = "[", 2		
		
		data.each_with_index do |item, index|
			item = _check_and_serialize(item: item, index: index)
			
			if (size + 1 + item.length) > EFFECTIVE_LIMIT_BYTES			
				# SEND
				part << "]"
				@_dataset_client.push_items(part)
				
				# RESET
				part, size = "[", 2
			end

			if size > 2
				part << ","
			end	
			
			part << item
			size += 1 + item.length
		end
		# LAST
		if size > 2
			part << "]"
			@_dataset_client.push_items(part)
		end		
	end
	
=begin
    @classmethod
    async def get_data(
        cls,
        *,
        offset: Optional[int] = None,
        limit: Optional[int] = None,
        clean: Optional[bool] = None,
        desc: Optional[bool] = None,
        fields: Optional[List[str]] = None,
        omit: Optional[List[str]] = None,
        unwind: Optional[str] = None,
        skip_empty: Optional[bool] = None,
        skip_hidden: Optional[bool] = None,
        flatten: Optional[List[str]] = None,
        view: Optional[str] = None,
    ) -> ListPage:
        """Get items from the dataset.

        Args:
            offset (int, optional): Number of items that should be skipped at the start. The default value is 0
            limit (int, optional): Maximum number of items to return. By default there is no limit.
            desc (bool, optional): By default, results are returned in the same order as they were stored.
                To reverse the order, set this parameter to True.
            clean (bool, optional): If True, returns only non-empty items and skips hidden fields (i.e. fields starting with the # character).
                The clean parameter is just a shortcut for skip_hidden=True and skip_empty=True parameters.
                Note that since some objects might be skipped from the output, that the result might contain less items than the limit value.
            fields (list of str, optional): A list of fields which should be picked from the items,
                only these fields will remain in the resulting record objects.
                Note that the fields in the outputted items are sorted the same way as they are specified in the fields parameter.
                You can use this feature to effectively fix the output format.
            omit (list of str, optional): A list of fields which should be omitted from the items.
            unwind (str, optional): Name of a field which should be unwound.
                If the field is an array then every element of the array will become a separate record and merged with parent object.
                If the unwound field is an object then it is merged with the parent object.
                If the unwound field is missing or its value is neither an array nor an object and therefore cannot be merged with a parent object,
                then the item gets preserved as it is. Note that the unwound items ignore the desc parameter.
            skip_empty (bool, optional): If True, then empty items are skipped from the output.
                Note that if used, the results might contain less items than the limit value.
            skip_hidden (bool, optional): If True, then hidden fields are skipped from the output, i.e. fields starting with the # character.
            flatten (list of str, optional): A list of fields that should be flattened
            view (str, optional): Name of the dataset view to be used

        Returns:
            ListPage: A page of the list of dataset items according to the specified filters.
        """
        dataset = await cls.open()
        return await dataset.get_data(
            offset=offset,
            limit=limit,
            desc=desc,
            clean=clean,
            fields=fields,
            omit=omit,
            unwind=unwind,
            skip_empty=skip_empty,
            skip_hidden=skip_hidden,
            flatten=flatten,
            view=view,
        )
=end

    def get_data offset: nil, limit: nil, clean: nil, desc: nil, fields: nil, omit: nil, unwind: nil, skip_empty: nil, skip_hidden: nil, flatten: nil, view: nil
    
        # try {
        #     return await this.client.listItems(options);
        # } catch (e) {
        #     const error = e as Error;
        #     if (error.message.includes('Cannot create a string longer than')) {
        #         throw new Error('dataset.getData(): The response is too large for parsing. You can fix this by lowering the "limit" option.');
        #     }
        #     throw e;
        # }
        # TODO: Simulate the above error in Python and handle accordingly...
        
		@_dataset_client.list_items(
            offset: offset,
            limit: limit,
            desc: desc,
            clean: clean,
            fields: fields,
            omit: omit,
            unwind: unwind,
            skip_empty: skip_empty,
            skip_hidden: skip_hidden,
            flatten: flatten,
            view: view
        )
	end
	
    def export_to key, to_key_value_store_id: nil, to_key_value_store_name: nil, content_type: nil
        """Save the entirety of the dataset's contents into one file within a key-value store.

        Args:
            key (str): The key to save the data under.
            to_key_value_store_id (str, optional): The id of the key-value store in which the result will be saved.
            to_key_value_store_name (str, optional): The name of the key-value store in which the result will be saved.
                You must specify only one of `to_key_value_store_id` and `to_key_value_store_name` arguments.
                If you omit both, it uses the default key-value store.
            content_type (str, optional): Either 'text/csv' or 'application/json'. Defaults to JSON.
        """
        key_value_store = KeyValueStore.open id: to_key_value_store_id, name: to_key_value_store_name

        items, offset, limit = [], 0, 1000

        while true
            list_items = @_dataset_client.list_items limit: limit, offset: offset			
			items.push *list_items[:items]
            
			o = offset + list_items[:count]
			break if list_items[:total] <= o
			
            offset = o
		end
		
        raise 'Cannot export an empty dataset' if items.empty? # ValueError

        if content_type == 'text/csv'

            #output = io.StringIO()
            #writer = csv.writer(output, quoting=csv.QUOTE_MINIMAL)
            #writer.writerows([items[0].keys(), *[item.values() for item in items]])
            #value = output.getvalue()
            #return await key_value_store.set_value(key, value, content_type)

			p "TODO: csv check columns orders!"
			
			csv_string = CSV.generate do |csv|
				csv << items[0].keys
				items.each { |row| csv << row.values }
			end
			p csv_string
			
			return key_value_store.set_value key, csv_string, content_type
		end
		
        if content_type == 'application/json'
            return key_value_store.set_value key, items, content_type
		end
		
        raise "Unsupported content type: #{content_type}" # ValueError
	end

	###---------------------------------------------------------------------------------------------------------------- export_to_json
=begin
    @classmethod
    async def export_to_json(
        cls,
        key: str,
        *,
        from_dataset_id: Optional[str] = None,
        from_dataset_name: Optional[str] = None,
        to_key_value_store_id: Optional[str] = None,
        to_key_value_store_name: Optional[str] = None,
    ) -> None:
        """Save the entirety of the dataset's contents into one JSON file within a key-value store.

        Args:
            key (str): The key to save the data under.
            from_dataset_id (str, optional): The ID of the dataset in case of calling the class method. Uses default dataset if omitted.
            from_dataset_name (str, optional): The name of the dataset in case of calling the class method. Uses default dataset if omitted.
                You must specify only one of `from_dataset_id` and `from_dataset_name` arguments.
                If you omit both, it uses the default dataset.
            to_key_value_store_id (str, optional): The id of the key-value store in which the result will be saved.
            to_key_value_store_name (str, optional): The name of the key-value store in which the result will be saved.
                You must specify only one of `to_key_value_store_id` and `to_key_value_store_name` arguments.
                If you omit both, it uses the default key-value store.
        """
        dataset = await cls.open(id=from_dataset_id, name=from_dataset_name)
        await dataset.export_to_json(key, to_key_value_store_id=to_key_value_store_id, to_key_value_store_name=to_key_value_store_name)
=end
    def export_to_json(
        key,
        #from_dataset_id: Optional[str] = None,  # noqa: U100
        #from_dataset_name: Optional[str] = None,  # noqa: U100
        to_key_value_store_id: nil,
        to_key_value_store_name: nil
    )
        export_to(
			key, 
			to_key_value_store_id: to_key_value_store_id, 
			to_key_value_store_name: to_key_value_store_name, 
			content_type: 'application/json'
		)
	end
	
	###---------------------------------------------------------------------------------------------------------------- export_to_csv
=begin
    @classmethod
    async def export_to_csv(
        cls,
        key: str,
        *,
        from_dataset_id: Optional[str] = None,
        from_dataset_name: Optional[str] = None,
        to_key_value_store_id: Optional[str] = None,
        to_key_value_store_name: Optional[str] = None,
    ) -> None:
        """Save the entirety of the dataset's contents into one CSV file within a key-value store.

        Args:
            key (str): The key to save the data under.
            from_dataset_id (str, optional): The ID of the dataset in case of calling the class method. Uses default dataset if omitted.
            from_dataset_name (str, optional): The name of the dataset in case of calling the class method. Uses default dataset if omitted.
                You must specify only one of `from_dataset_id` and `from_dataset_name` arguments.
                If you omit both, it uses the default dataset.
            to_key_value_store_id (str, optional): The id of the key-value store in which the result will be saved.
            to_key_value_store_name (str, optional): The name of the key-value store in which the result will be saved.
                You must specify only one of `to_key_value_store_id` and `to_key_value_store_name` arguments.
                If you omit both, it uses the default key-value store.
        """
        dataset = await cls.open(id=from_dataset_id, name=from_dataset_name)
        await dataset.export_to_csv(key, to_key_value_store_id=to_key_value_store_id, to_key_value_store_name=to_key_value_store_name)
=end
    def export_to_csv(
        key,
        #from_dataset_id: Optional[str] = None,  # noqa: U100
        #from_dataset_name: Optional[str] = None,  # noqa: U100
        to_key_value_store_id: nil,
        to_key_value_store_name: nil
    )
        export_to \
			key, to_key_value_store_id: to_key_value_store_id, to_key_value_store_name: to_key_value_store_name, content_type: 'text/csv'
	end
	
    def get_info
        """Get an object containing general information about the dataset.

        Returns:
            dict: Object returned by calling the GET dataset API endpoint.
        """
        @_dataset_client.get
	end

	
    def iterate_items(
        offset: 0,
        limit: nil,
        clean: nil,
        desc: nil,
        fields: nil,
        omit: nil,
        unwind: nil,
        skip_empty: nil,
        skip_hidden: nil
    )
        """Iterate over the items in the dataset.

        Args:
            offset (int, optional): Number of items that should be skipped at the start. The default value is 0
            limit (int, optional): Maximum number of items to return. By default there is no limit.
            desc (bool, optional): By default, results are returned in the same order as they were stored.
                To reverse the order, set this parameter to True.
            clean (bool, optional): If True, returns only non-empty items and skips hidden fields (i.e. fields starting with the # character).
                The clean parameter is just a shortcut for skip_hidden=True and skip_empty=True parameters.
                Note that since some objects might be skipped from the output, that the result might contain less items than the limit value.
            fields (list of str, optional): A list of fields which should be picked from the items,
                only these fields will remain in the resulting record objects.
                Note that the fields in the outputted items are sorted the same way as they are specified in the fields parameter.
                You can use this feature to effectively fix the output format.
            omit (list of str, optional): A list of fields which should be omitted from the items.
            unwind (str, optional): Name of a field which should be unwound.
                If the field is an array then every element of the array will become a separate record and merged with parent object.
                If the unwound field is an object then it is merged with the parent object.
                If the unwound field is missing or its value is neither an array nor an object and therefore cannot be merged with a parent object,
                then the item gets preserved as it is. Note that the unwound items ignore the desc parameter.
            skip_empty (bool, optional): If True, then empty items are skipped from the output.
                Note that if used, the results might contain less items than the limit value.
            skip_hidden (bool, optional): If True, then hidden fields are skipped from the output, i.e. fields starting with the # character.

        Yields:
            dict: An item from the dataset
        """
        @_dataset_client.iterate_items(
            offset: offset,
            limit: limit,
            clean: clean,
            desc: desc,
            fields: fields,
            omit: omit,
            unwind: unwind,
            skip_empty: skip_empty,
            skip_hidden: skip_hidden
        ) do |item|
			yield item
		end
	end
	
=begin

    async def drop(self) -> None:
        """Remove the dataset either from the Apify cloud storage or from the local directory."""
        await self._dataset_client.delete()
        self._remove_from_cache()

    @classmethod
    async def open(
        cls,
        *,
        id: Optional[str] = None,
        name: Optional[str] = None,
        force_cloud: bool = False,
        config: Optional[Configuration] = None,
    ) -> 'Dataset':
        """Open a dataset.

        Datasets are used to store structured data where each object stored has the same attributes,
        such as online store products or real estate offers.
        The actual data is stored either on the local filesystem or in the Apify cloud.

        Args:
            id (str, optional): ID of the dataset to be opened.
                If neither `id` nor `name` are provided, the method returns the default dataset associated with the actor run.
                If the dataset with the given ID does not exist, it raises an error.
            name (str, optional): Name of the dataset to be opened.
                If neither `id` nor `name` are provided, the method returns the default dataset associated with the actor run.
                If the dataset with the given name does not exist, it is created.
            force_cloud (bool, optional): If set to True, it will open a dataset on the Apify Platform even when running the actor locally.
                Defaults to False.
            config (Configuration, optional): A `Configuration` instance, uses global configuration if omitted.

        Returns:
            Dataset: An instance of the `Dataset` class for the given ID or name.
        """
        return await super().open(id=id, name=name, force_cloud=force_cloud, config=config)
=end
end

end