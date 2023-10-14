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

		def open_dataset
		end
		
		def push_data data
			#self._raise_if_not_initialized()

			if data 
				dataset = self.open_dataset()
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