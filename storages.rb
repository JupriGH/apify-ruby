require_relative 'config'

module Apify

class StorageClientManager

    """A class for managing storage clients."""

	attr_accessor \
		:_config,
		:_local_client,
		:_cloud_client

    @@_default_instance = nil

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
            raise unless not default_instance._cloud_client.nil?
			
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
        @@_default_instance ||= self.new()
	end
end

#################################################################################################################

class BaseStorage # (ABC, Generic[BaseResourceClientType, BaseResourceCollectionClientType]):
    """A class for managing storages."""

    #_id: str
    #_name: Optional[str]
    #_storage_client: Union[ApifyClientAsync, MemoryStorageClient]
    #_config: Configuration

    @@_cache_by_id
    @@_cache_by_name
    
	# _storage_creating_lock: Optional[asyncio.Lock] = None

=begin
    def __init__(self, id: str, name: Optional[str], client: Union[ApifyClientAsync, MemoryStorageClient], config: Configuration):
        """Initialize the storage.

        Do not use this method directly, but use `Actor.open_<STORAGE>()` instead.

        Args:
            id (str): The storage id
            name (str, optional): The storage name
            client (ApifyClientAsync or MemoryStorageClient): The storage client
            config (Configuration): The configuration
        """
        self._id = id
        self._name = name
        self._storage_client = client
        self._config = config
	
=end
	
	###================================================================================= ABSTRACTS
	"""
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
	"""
	###=================================================================================

    def self._ensure_class_initialized
        @@_cache_by_id 		||= {}
        @@_cache_by_name 	||= {}

        #if cls._storage_creating_lock is None:
        #    cls._storage_creating_lock = asyncio.Lock()
	end

    # async 
	def self.open id=nil, name=nil, force_cloud=false, config=nil		
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
		
		# assert cls._cache_by_id is not None
        raise unless @@_cache_by_id
		# assert cls._cache_by_name is not None
		raise unless @@_cache_by_name
	
        # assert not (id and name)
		raise unless not (id and name)
		
        used_config = config or Configuration.get_global_configuration
        used_client = StorageClientManager.get_storage_client(force_cloud=force_cloud)

		# Fetch default ID if no ID or name was passed
        is_default_storage_on_local = false
        
        if not (id or name)
            #if isinstance(used_client, MemoryStorageClient):
            #    is_default_storage_on_local = True
            id = _get_default_id(used_config)
		end
		
        # Try to get the storage instance from cache
		"""
		cached_storage = nil
        if id
            cached_storage = cls._cache_by_id.get(id)
        elsif name
            cached_storage = cls._cache_by_name.get(name)
		end
		
        if cached_storage is not None:
            # This cast is needed since MyPy doesn't understand very well that Self and Storage are the same
            return cast(Self, cached_storage)
		"""
		
        # Purge default storages if configured
        """
		if used_config.purge_on_start and isinstance(used_client, MemoryStorageClient):
            await used_client._purge_on_start()
		"""
		
        #assert cls._storage_creating_lock is not None
        #async with cls._storage_creating_lock:
            
			# Create the storage
            if true # id and not is_default_storage_on_local

                single_storage_client 	= _get_single_storage_client(id, used_client)
                storage_info 			= single_storage_client.get() # await 
                if not storage_info
                    raise "#{_get_human_friendly_label} with id \"#{id}\" does not exist!" # RuntimeError
				end
				
            elsif is_default_storage_on_local

				raise "TODO"
                #storage_collection_client = cls._get_storage_collection_client(used_client)
                #storage_info = await storage_collection_client.get_or_create(name=name, _id=id)

            else
				raise "TODO"
                #storage_collection_client = cls._get_storage_collection_client(used_client)
                #storage_info = await storage_collection_client.get_or_create(name=name)
			end
			
			raise "TODO"
			
            storage = new(storage_info['id'], storage_info.get('name'), used_client, used_config)

            # Cache by id and name
            @@_cache_by_id[storage._id] = storage
            if storage._name
                @@_cache_by_name[storage._name] = storage
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

=begin

    _id: str
    _name: Optional[str]
    _key_value_store_client: Union[KeyValueStoreClientAsync, KeyValueStoreClient]

    @ignore_docs
    def __init__(self, id: str, name: Optional[str], client: Union[ApifyClientAsync, MemoryStorageClient], config: Configuration) -> None:
        """Create a `KeyValueStore` instance.

        Do not use the constructor directly, use the `Actor.open_key_value_store()` function instead.

        Args:
            id (str): ID of the key-value store.
            name (str, optional): Name of the key-value store.
            client (ApifyClientAsync or MemoryStorageClient): The storage client which should be used.
            config (Configuration): The configuration which should be used.
        """
        super().__init__(id=id, name=name, client=client, config=config)

        self.get_value = _wrap_internal(self._get_value_internal, self.get_value)  # type: ignore
        self.set_value = _wrap_internal(self._set_value_internal, self.set_value)  # type: ignore
        self.get_public_url = _wrap_internal(self._get_public_url_internal, self.get_public_url)  # type: ignore
        self._id = id
        self._name = name
        self._key_value_store_client = client.key_value_store(self._id)

    @classmethod
    def _get_human_friendly_label(cls) -> str:
        return 'Key-value store'
=end

    def self._get_default_id config
        config.default_key_value_store_id
	end
	
    def self._get_single_storage_client id, client # Union[ApifyClientAsync, MemoryStorageClient],
        client.key_value_store(id)
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

    @classmethod
    async def get_value(cls, key: str, default_value: Optional[T] = None) -> Optional[T]:
        """Get a value from the key-value store.

        Args:
            key (str): Key of the record to retrieve.
            default_value (Any, optional): Default value returned in case the record does not exist.

        Returns:
            Any: The value associated with the given key. `default_value` is used in case the record does not exist.
        """
        store = await cls.open()
        return await store.get_value(key, default_value)

    async def _get_value_internal(self, key: str, default_value: Optional[T] = None) -> Optional[T]:
        record = await self._key_value_store_client.get_record(key)
        return record['value'] if record else default_value

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

    @classmethod
    async def set_value(cls, key: str, value: Optional[T], content_type: Optional[str] = None) -> None:
        """Set or delete a value in the key-value store.

        Args:
            key (str): The key under which the value should be saved.
            value (Any, optional): The value to save. If the value is `None`, the corresponding key-value pair will be deleted.
            content_type (str, optional): The content type of the saved value.
        """
        store = await cls.open()
        return await store.set_value(key, value, content_type)

    async def _set_value_internal(self, key: str, value: Optional[T], content_type: Optional[str] = None) -> None:
        if value is None:
            return await self._key_value_store_client.delete_record(key)

        return await self._key_value_store_client.set_record(key, value, content_type)

    @classmethod
    async def get_public_url(cls, key: str) -> str:
        """Get a URL for the given key that may be used to publicly access the value in the remote key-value store.

        Args:
            key (str): The key for which the URL should be generated.
        """
        store = await cls.open()
        return await store.get_public_url(key)

    async def _get_public_url_internal(self, key: str) -> str:
        if not isinstance(self._key_value_store_client, KeyValueStoreClientAsync):
            raise RuntimeError('Cannot generate a public URL for this key-value store as it is not on the Apify Platform!')

        public_api_url = self._config.api_public_base_url

        return f'{public_api_url}/v2/key-value-stores/{self._id}/records/{key}'

    async def drop(self) -> None:
        """Remove the key-value store either from the Apify cloud storage or from the local directory."""
        await self._key_value_store_client.delete()
        self._remove_from_cache()
=end

	# async
    def self.open id=nil, name=nil, force_cloud=false, config=nil
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
        super.open(id=id, name=name, force_cloud=force_cloud, config=config)
	end
	
end

end