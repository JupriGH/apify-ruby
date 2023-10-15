require 'net/http'
require 'open-uri'
#require "HTTParty"
require 'json'

require_relative 'config'

module Apify

	include Config
	
	#################################################
	class HttpClient
		@base_url
		@token
		def initialize(base_url, token)
			@base_url 	= base_url # eg: https://api.apify.com/v2
			@token 		= token
		end
		
		def request(method, path)
			
			url = "#{@base_url}/#{path}"
			return url
			
			#url = "https://api.apify.com/v2/key-value-stores/Zt2dICDo5OnrCzxZi/records/INPUT"
			
			###
			uri = URI.parse(url)
			
			req 					= Net::HTTP::Get.new(uri)
			req['Accept'] 			= 'application/json'
			if @token 
				req['Authorization'] = @token
			end
			
			req_options 			= { use_ssl: uri.scheme == 'https'}

			res = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
				http.request(req)
			end

			tmp = JSON.parse(res.body)			
		end
	end

	################################################
	class BaseStore
		@path
		@client	
		
		def initialize config
			@client = Apify::HttpClient.new("#{config.api_public_base_url}/v2", config.token)
		end
	end
	class DatasetStore < BaseStore
		def initialize config, name			
			super config
			@path = "dataset-stores/#{name}"
		end
		def push_data(item)
			raise "push_data"
		end
	end
	
	#----------------------------------------------
	class KeyValueStore < BaseStore
		def initialize config, name			
			super config
			@path = "key-value-stores/#{name}"
		end
		def get_value(key)
			@client.request("GET", "#{@path}/records/#{key}")
		end
	end
	
	#################################################
	class StorageClientManager
		"""A class for managing storage clients."""
		
		attr_accessor \
			:_config,			# Configuration
			:_local_client, 	# Optional[MemoryStorageClient]
			:_cloud_client 		# Optional[ApifyClientAsync]

		@@_default_instance = nil
	
		def initialize
			"""Create a `StorageClientManager` instance."""
			@_config = Apify::Configuration.get_global_configuration()
		end

=begin
		def self.set_config config
			"""Set the config for the StorageClientManager.

			Args:
				config (Configuration): The configuration this StorageClientManager should use.
			"""
			self._get_default_instance._config = config
		end
=end
		def self.get_storage_client force_cloud=false
			"""Get the current storage client instance.

			Returns:
				ApifyClientAsync or MemoryStorageClient: The current storage client instance.
			"""
			
			default_instance = self._get_default_instance
						
			if not default_instance._local_client
				# default_instance._local_client = MemoryStorageClient(persist_storage=default_instance._config.persist_storage, write_metadata=True)
			end
			
			#if default_instance._config.is_at_home or force_cloud
			if true or force_cloud
				if default_instance._cloud_client != nil
					raise "default_instance._cloud_client != nil"
				end
				return default_instance._cloud_client
			end
			
			raise "TODO"
			default_instance._local_client
		end
		
		def self._get_default_instance
			if @@_default_instance == nil
				@@_default_instance = self.new()
			end
			@@_default_instance		
		end
	end

	#################################################	
	class BaseStorage

		@@_cache_by_id 		= nil
		@@_cache_by_name 	= nil

		def self._ensure_class_initialized
			if @@_cache_by_id == nil
				@@_cache_by_id = {}
			end
			if @@_cache_by_name == nil
				@@_cache_by_name = {}
			end
			#if cls._storage_creating_lock is None:
			#	cls._storage_creating_lock = asyncio.Lock()
		end
		
		def self.open id=nil, name=nil, force_cloud=false, config=nil
			self._ensure_class_initialized

			raise unless @@_cache_by_id
			raise unless @@_cache_by_name
			
			# assert not (id and name)
			
			used_config = config or Configuration.get_global_configuration
			used_client = StorageClientManager.get_storage_client(force_cloud)
			
			is_default_storage_on_local = false
			
			# Fetch default ID if no ID or name was passed
			if not (id or name)
				#if isinstance(used_client, MemoryStorageClient):
				#	is_default_storage_on_local = true
				id = _get_default_id(used_config)
			end
=begin
			# Try to get the storage instance from cache
			cached_storage = nil
			if id
				cached_storage = self::_cache_by_id.get(id)
			elsif name
				cached_storage = self::_cache_by_name.get(name)

			if cached_storage is not None:
				# This cast is needed since MyPy doesn't understand very well that Self and Storage are the same
				return cast(Self, cached_storage)
=end

=begin
			# Purge default storages if configured
			if used_config.purge_on_start and isinstance(used_client, MemoryStorageClient):
				await used_client._purge_on_start()

=end

			#assert cls._storage_creating_lock is not None
			#async with cls._storage_creating_lock:
				# Create the storage
				if id and not is_default_storage_on_local

					single_storage_client = self._get_single_storage_client(id, used_client)
					storage_info = single_storage_client.get()
					if not storage_info
						raise "#{self._get_human_friendly_label()} with id \"#{id}\" does not exist!" # RuntimeError
					end
					
				elsif is_default_storage_on_local
=begin
					storage_collection_client = cls._get_storage_collection_client(used_client)
					storage_info = await storage_collection_client.get_or_create(name=name, _id=id)
=end
					raise "TODO"

				else
=begin
					storage_collection_client = cls._get_storage_collection_client(used_client)
					storage_info = await storage_collection_client.get_or_create(name=name)
=end
					raise "TODO"

				end
				
				#storage = cls(storage_info['id'], storage_info.get('name'), used_client, used_config)

				# Cache by id and name
				#cls._cache_by_id[storage._id] = storage
				#if storage._name is not None:
				#	cls._cache_by_name[storage._name] = storage

			raise "TODO"
			
			return storage
			
		end
		

		### ABSTRACT
		
		# def self._get_default_id config
	
	end
	
	#----------------------------------------------
	class Dataset < BaseStorage
		#def self.open id=nil, name=nil, force_cloud=false, config=nil		
		#	raise "OPEN"
		#	
		#	#super.open(id, name, force_cloud, config)
		#end
		def self._get_default_id config
			config.default_dataset_id
		end

		def self._get_single_storage_client id, client
			p id
			client.dataset(id)
		end
	end
	
	#----------------------------------------------
	class ActorClass
		
		@config

		# default stores	
		@ds_store
		@kv_store
		
		def initialize
			@config 	= Apify::Configuration.new()
			@ds_store	= Apify::DatasetStore.new(@config, @config.default_dataset_id)
			@kv_store	= Apify::KeyValueStore.new(@config, @config.default_key_value_store_id)
		end
		
		def get_input
			get_value(@config.input_key)
		end
		
		def get_value key
			@kv_store.get_value(key)
		end

		#def set_value key, value
		#end

		def open_dataset id=nil, name=nil, force_cloud=false
			#self._raise_if_not_initialized()
			Apify::Dataset.open(id, name, force_cloud, @config)
		end
		
		def push_data data
			#self._raise_if_not_initialized()
			if data 
				dataset = open_dataset()
				dataset.push_data(data)
			end
		end
		
		
		#def on
		#def off
		#def is_at_home
		
		def create_proxy_configuration
		end
	end
	
	#################################################
	Actor 	= ActorClass.new()

end