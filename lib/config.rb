require_relative 'consts'

def getenv(key, default=nil)
	val = ENV[key] # string or nil	
	if val.nil? || val.empty?
		val = default
	end
	return val
end

module Apify

class Configuration
	
	attr_accessor \
		:actor_build_id,
		:actor_build_number,
		:actor_events_ws_url,
		:actor_id,
		:actor_run_id,
		:actor_task_id,
		:api_base_url,
		:api_public_base_url,
		:chrome_executable_path,
		:container_port,
		:container_url,
		:dedicated_cpus,
		:default_browser_path,
		:default_dataset_id,
		:default_key_value_store_id,
		:default_request_queue_id,
		:disable_browser_sandbox,
		:headless,
		:input_key,
		:input_secrets_private_key_file,
		:input_secrets_private_key_passphrase,
		:is_at_home,
		:max_used_cpu_ratio,
		:memory_mbytes,
		:meta_origin,
		:metamorph_after_sleep_millis,
		:persist_state_interval_millis,
		:persist_storage,
		:proxy_hostname,
		:proxy_password,
		:proxy_port,
		:proxy_status_url,
		:purge_on_start,
		:started_at,
		:timeout_at,
		:token,
		:user_id,
		:xvfb,
		:system_info_interval_millis
	
	@@_default_instance = nil
	
	def initialize
		
		
		@actor_build_id 				= getenv(ActorEnvVars::BUILD_ID)
		@actor_build_number 			= getenv(ActorEnvVars::BUILD_NUMBER)
		#@actor_events_ws_url = getenv(ActorEnvVars::EVENTS_WEBSOCKET_URL)
		@actor_id 						= getenv(ActorEnvVars::ID)
		@actor_run_id 					= getenv(ActorEnvVars::RUN_ID)
		@actor_task_id 					= getenv(ActorEnvVars::TASK_ID)
		@api_base_url 					= getenv(ApifyEnvVars::API_BASE_URL, 'https://api.apify.com').sub(/\/+$/, '')
		@api_public_base_url 			= getenv(ApifyEnvVars::API_PUBLIC_BASE_URL, 'https://api.apify.com').sub(/\/+$/, '')
		#@chrome_executable_path = getenv(ApifyEnvVars::CHROME_EXECUTABLE_PATH)
		@container_port 				= getenv(ActorEnvVars::WEB_SERVER_PORT, 4321)
		@container_url 					= getenv(ActorEnvVars::WEB_SERVER_URL, 'http://localhost:4321').sub(/\/+$/, '')
		#@dedicated_cpus = getenv(ApifyEnvVars::DEDICATED_CPUS)
		#@default_browser_path = getenv(ApifyEnvVars::DEFAULT_BROWSER_PATH)
		@default_dataset_id 			= getenv(ActorEnvVars::DEFAULT_DATASET_ID, 'default')
		@default_key_value_store_id 	= getenv(ActorEnvVars::DEFAULT_KEY_VALUE_STORE_ID, 'default')
		@default_request_queue_id 		= getenv(ActorEnvVars::DEFAULT_REQUEST_QUEUE_ID, 'default')
		#@disable_browser_sandbox = getenv(ApifyEnvVars::DISABLE_BROWSER_SANDBOX, False)
		#@headless = getenv(ApifyEnvVars::HEADLESS, True)
		@input_key 						= getenv(ActorEnvVars::INPUT_KEY, 'INPUT')
		@input_secrets_private_key_file 		= getenv(ApifyEnvVars::INPUT_SECRETS_PRIVATE_KEY_FILE)
		@input_secrets_private_key_passphrase 	= getenv(ApifyEnvVars::INPUT_SECRETS_PRIVATE_KEY_PASSPHRASE)
		@is_at_home 					= getenv(ApifyEnvVars::IS_AT_HOME) == "1"
		#@max_used_cpu_ratio = max_used_cpu_ratio or getenv(ApifyEnvVars::MAX_USED_CPU_RATIO, 0.95)
		#@memory_mbytes = getenv(ActorEnvVars::MEMORY_MBYTES)
		#@meta_origin = getenv(ApifyEnvVars::META_ORIGIN)
		#@metamorph_after_sleep_millis = metamorph_after_sleep_millis or getenv(ApifyEnvVars::METAMORPH_AFTER_SLEEP_MILLIS, 300000)  # noqa: E501
		#@persist_state_interval_millis = persist_state_interval_millis or getenv(ApifyEnvVars::PERSIST_STATE_INTERVAL_MILLIS, 60000)  # noqa: E501
		#@persist_storage = persist_storage or getenv(ApifyEnvVars::PERSIST_STORAGE, True)
		@proxy_hostname 				= getenv(ApifyEnvVars::PROXY_HOSTNAME, 'proxy.apify.com')
		@proxy_password 				= getenv(ApifyEnvVars::PROXY_PASSWORD)
		@proxy_port 					= getenv(ApifyEnvVars::PROXY_PORT, 8000)
		@proxy_status_url 				= getenv(ApifyEnvVars::PROXY_STATUS_URL, 'http://proxy.apify.com')
		#@purge_on_start = purge_on_start or getenv(ApifyEnvVars::PURGE_ON_START, False)
		#@started_at = getenv(ActorEnvVars::STARTED_AT)
		#@timeout_at = getenv(ActorEnvVars::TIMEOUT_AT)		
		@token 							= getenv(ApifyEnvVars::TOKEN)
		@user_id 						= getenv(ApifyEnvVars::USER_ID)
		#@xvfb = getenv(ApifyEnvVars::XVFB, False)
		#@system_info_interval_millis = system_info_interval_millis or getenv(ApifyEnvVars::SYSTEM_INFO_INTERVAL_MILLIS, 60000)
		
		#ENV.each do |key, val|
		#	p "#{key}=#{val}"
		#end
	end

	def self._get_default_instance
		@@_default_instance ||= new
	end
	
	def self.get_global_configuration
		"""Retrive the global configuration.

		The global configuration applies when you call actor methods via their static versions, e.g. `Actor.init()`.
		Also accessible via `Actor.config`.
		"""
		_get_default_instance
	end

end
	
end
