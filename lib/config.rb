module Apify

    """A class for specifying the configuration of an actor.

    Can be used either globally via `Configuration.get_global_configuration()`,
    or it can be specific to each `Actor` instance on the `actor.config` property.
    """
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

        """Create a `Configuration` instance.

        All the parameters are loaded by default from environment variables when running on the Apify platform.
        You can override them here in the Configuration constructor, which might be useful for local testing of your actors.

        Args:
            api_base_url (str, optional): The URL of the Apify API.
                This is the URL actually used for connecting to the API, so it can contain an IP address when running in a container on the platform.
            api_public_base_url (str, optional): The public URL of the Apify API.
                This will always contain the public URL of the API, even when running in a container on the platform.
                Useful for generating shareable URLs to key-value store records or datasets.
            container_port (int, optional): The port on which the container can listen for HTTP requests.
            container_url (str, optional): The URL on which the container can listen for HTTP requests.
            default_dataset_id (str, optional): The ID of the default dataset for the actor.
            default_key_value_store_id (str, optional): The ID of the default key-value store for the actor.
            default_request_queue_id (str, optional): The ID of the default request queue for the actor.
            input_key (str, optional): The key of the input record in the actor's default key-value store
            max_used_cpu_ratio (float, optional): The CPU usage above which the SYSTEM_INFO event will report the CPU is overloaded.
            metamorph_after_sleep_millis (int, optional): How long should the actor sleep after calling metamorph.
            persist_state_interval_millis (int, optional): How often should the actor emit the PERSIST_STATE event.
            persist_storage (bool, optional): Whether the actor should persist its used storages to the filesystem when running locally.
            proxy_hostname (str, optional): The hostname of Apify Proxy.
            proxy_password (str, optional): The password for Apify Proxy.
            proxy_port (str, optional): The port of Apify Proxy.
            proxy_status_url (str, optional): The URL on which the Apify Proxy status page is available.
            purge_on_start (str, optional): Whether the actor should purge its default storages on startup, when running locally.
            token (str, optional): The API token for the Apify API this actor should use.
            system_info_interval_millis (str, optional): How often should the actor emit the SYSTEM_INFO event when running locally.
        """		
		def initialize(
			api_base_url: nil,
			api_public_base_url: nil,
			container_port: nil,
			container_url: nil,
			default_dataset_id: nil,
			default_key_value_store_id: nil,
			default_request_queue_id: nil,
			input_key: nil,
			max_used_cpu_ratio: nil,
			metamorph_after_sleep_millis: nil,
			persist_state_interval_millis: nil,
			persist_storage: nil,
			proxy_hostname: nil,
			proxy_password: nil,
			proxy_port: nil,
			proxy_status_url: nil,
			purge_on_start: nil,
			token: nil,
			system_info_interval_millis: nil
		)
			@actor_build_id 				= getenv(ActorEnvVars::BUILD_ID)
			@actor_build_number 			= getenv(ActorEnvVars::BUILD_NUMBER)
			@actor_events_ws_url 			= getenv(ActorEnvVars::EVENTS_WEBSOCKET_URL)
			@actor_id 						= getenv(ActorEnvVars::ID)
			@actor_run_id 					= getenv(ActorEnvVars::RUN_ID)
			@actor_task_id 					= getenv(ActorEnvVars::TASK_ID)
			@api_base_url 					= api_base_url || getenv(ApifyEnvVars::API_BASE_URL, 'https://api.apify.com').sub(/\/+$/, '')
			@api_public_base_url 			= api_public_base_url || getenv(ApifyEnvVars::API_PUBLIC_BASE_URL, 'https://api.apify.com').sub(/\/+$/, '')
			@chrome_executable_path 		= getenv(ApifyEnvVars::CHROME_EXECUTABLE_PATH)
			@container_port 				= container_port || getenv(ActorEnvVars::WEB_SERVER_PORT, 4321)
			@container_url 					= container_url || getenv(ActorEnvVars::WEB_SERVER_URL, 'http://localhost:4321').sub(/\/+$/, '')
			@dedicated_cpus 				= getenv(ApifyEnvVars::DEDICATED_CPUS)
			@default_browser_path 			= getenv(ApifyEnvVars::DEFAULT_BROWSER_PATH)
			@default_dataset_id 			= default_dataset_id || getenv(ActorEnvVars::DEFAULT_DATASET_ID, 'default')
			@default_key_value_store_id 	= default_key_value_store_id || getenv(ActorEnvVars::DEFAULT_KEY_VALUE_STORE_ID, 'default')
			@default_request_queue_id 		= default_request_queue_id || getenv(ActorEnvVars::DEFAULT_REQUEST_QUEUE_ID, 'default')
			@disable_browser_sandbox 		= getenv(ApifyEnvVars::DISABLE_BROWSER_SANDBOX, false)
			@headless 						= getenv(ApifyEnvVars::HEADLESS, true)
			@input_key 						= input_key || getenv(ActorEnvVars::INPUT_KEY, 'INPUT')
			@input_secrets_private_key_file 		= getenv(ApifyEnvVars::INPUT_SECRETS_PRIVATE_KEY_FILE)
			@input_secrets_private_key_passphrase 	= getenv(ApifyEnvVars::INPUT_SECRETS_PRIVATE_KEY_PASSPHRASE)
			@is_at_home 					= getenv(ApifyEnvVars::IS_AT_HOME, false)
			@max_used_cpu_ratio 			= max_used_cpu_ratio || getenv(ApifyEnvVars::MAX_USED_CPU_RATIO, 0.95)
			@memory_mbytes 					= getenv(ActorEnvVars::MEMORY_MBYTES)
			@meta_origin 					= getenv(ApifyEnvVars::META_ORIGIN)
			@metamorph_after_sleep_millis 	= metamorph_after_sleep_millis || getenv(ApifyEnvVars::METAMORPH_AFTER_SLEEP_MILLIS, 300000)  # noqa: E501
			@persist_state_interval_millis 	= persist_state_interval_millis || getenv(ApifyEnvVars::PERSIST_STATE_INTERVAL_MILLIS, 60000)  # noqa: E501
			@persist_storage 				= _is_bool(persist_storage) ? persist_storage : getenv(ApifyEnvVars::PERSIST_STORAGE, true)
			@proxy_hostname 				= proxy_hostname || getenv(ApifyEnvVars::PROXY_HOSTNAME, 'proxy.apify.com')
			@proxy_password 				= proxy_password || getenv(ApifyEnvVars::PROXY_PASSWORD)
			@proxy_port 					= proxy_port || getenv(ApifyEnvVars::PROXY_PORT, 8000)
			@proxy_status_url 				= proxy_status_url || getenv(ApifyEnvVars::PROXY_STATUS_URL, 'http://proxy.apify.com')
			@purge_on_start 				= _is_bool(purge_on_start) ? purge_on_start : getenv(ApifyEnvVars::PURGE_ON_START, false)
			@started_at 					= getenv(ActorEnvVars::STARTED_AT)
			@timeout_at 					= getenv(ActorEnvVars::TIMEOUT_AT)	
			@token 							= token || getenv(ApifyEnvVars::TOKEN)
			@user_id 						= getenv(ApifyEnvVars::USER_ID)
			@xvfb 							= getenv(ApifyEnvVars::XVFB, false)
			@system_info_interval_millis 	= system_info_interval_millis || getenv(ApifyEnvVars::SYSTEM_INFO_INTERVAL_MILLIS, 60000)
			
			#ENV.each do |key, val|
			#	p "#{key}=#{val}"
			#end
			#pp self
		end
		
		### Helpers
		def to_json = to_h.to_json
		def to_h = instance_variables.map { |a| [a, instance_variable_get(a)] }.to_h
		def _is_bool(var) = var.is_a?(TrueClass) || var.is_a?(FalseClass) 		
		def getenv(*args) = Utils::_fetch_and_parse_env_var(*args)

		def self._get_default_instance = @@_default_instance ||= new

		"""Retrive the global configuration.

		The global configuration applies when you call actor methods via their static versions, e.g. `Actor.init()`.
		Also accessible via `Actor.config`.
		"""		
		def self.get_global_configuration = _get_default_instance

	end
	
end
