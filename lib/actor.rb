module Apify

	"""The main class of the SDK, through which all the actor operations should be done."""
	class Actor

		@@_default_instance = nil

		#_memory_storage_client: MemoryStorageClient
		#_was_final_persist_state_emitted = False

		"""Create an Actor instance.

		Note that you don't have to do this, all the methods on this class function as classmethods too,
		and that is their preferred usage.

		Args:
			config (Configuration, optional): The actor configuration to be used. If not passed, a new Configuration instance will be created.
		"""
		# To have methods which work the same as classmethods and instance methods,
		# so you can do both Actor.xxx() and Actor().xxx(),
		# we need to have an `_xxx_internal` instance method which contains the actual implementation of the method,
		# and then in the instance constructor overwrite the `xxx` classmethod with the `_xxx_internal` instance method,
		# while copying the annotations, types and so on.

		def initialize config: nil
			@_config = config || Configuration.new		
			@_apify_client = new_client
			@_event_manager = EventManager.new @_config
			@_is_initialized = false
			@_is_exiting = false
			@_send_system_info_interval_task = nil 
			@_send_persist_state_interval_task = nil
		end

=begin
		@ignore_docs
		async def __aenter__(self) -> 'Actor':
			"""Initialize the Actor.

			Automatically initializes the Actor instance when you use it in an `async with ...` statement.

			When you exit the `async with` block, the `Actor.exit()` method is called,
			and if any exception happens while executing the block code,
			the `Actor.fail` method is called.
			"""
			await self.init()
			return self

		@ignore_docs
		async def __aexit__(
			self,
			_exc_type: Optional[Type[BaseException]],
			exc_value: Optional[BaseException],
			_exc_traceback: Optional[TracebackType],
		) -> None:
			"""Exit the Actor, handling any exceptions properly.

			When you exit the `async with` block, the `Actor.exit()` method is called,
			and if any exception happens while executing the block code,
			the `Actor.fail` method is called.
			"""
			if not self._is_exiting:
				if exc_value:
					await self.fail(
						exit_code=ActorExitCodes.ERROR_USER_FUNCTION_THREW.value,
						exception=exc_value,
					)
				else:
					await self.exit()
=end

		def self._get_default_instance = @@_default_instance ||= new(config: Configuration.get_global_configuration)

		"""The ApifyClientAsync instance the Actor instance uses."""	
		def self.apify_client = _get_default_instance.apify_client
		def apify_client = @_apify_client

		"""The Configuration instance the Actor instance uses."""
		def self.config = _get_default_instance.config
		def config = @_config

		"""The EventManager instance the Actor instance uses."""  # noqa: D401		
		def self.event_manager = _get_default_instance.event_manager
		def event_manager = @_event_manager

		"""The logging.Logger instance the Actor uses."""  # noqa: D401
		#def self.log = LOGGER # noqa: N805
		#def log = LOGGER

		def _raise_if_not_initialized
			raise 'The actor was not initialized!' unless @_is_initialized # RuntimeError()
		end

		"""Initialize the actor instance.

		This initializes the Actor instance.
		It configures the right storage client based on whether the actor is running locally or on the Apify platform,
		it initializes the event manager for processing actor events,
		and starts an interval for regularly sending `PERSIST_STATE` events,
		so that the actor can regularly persist its state in response to these events.

		This method should be called immediately before performing any additional actor actions,
		and it should be called only once.
		"""

		def self.init = _get_default_instance.init
		
		def init
			raise 'The actor was already initialized!' if @_is_initialized # RuntimeError
			
			@_is_exiting = false
			@_was_final_persist_state_emitted = false

			Log.info 'Initializing actor...'
			Log.info 'System info', extra: Utils::_get_system_info

			# TODO: Print outdated SDK version warning (we need a new env var for this)

			StorageClientManager.set_config(@_config)		
			StorageClientManager.set_cloud_client(@_apify_client) if @_config.token

			if Async::Task.current?
				@_event_manager.init

				@_send_persist_state_interval_task = Async { #asyncio.create_task(
					Utils::_run_func_at_interval_async(
						lambda { @_event_manager.emit(ActorEventTypes::PERSIST_STATE, {'isMigrating': false}) },
						@_config.persist_state_interval_millis / 1000
					)
				}
				if !is_at_home
					@_send_system_info_interval_task = Async { #asyncio.create_task(
						Utils::_run_func_at_interval_async(
							lambda { @_event_manager.emit(ActorEventTypes::SYSTEM_INFO, _get_system_info) },
							@_config.system_info_interval_millis / 1000
						)
					}
				end
				
				@_event_manager.on ActorEventTypes::MIGRATING, method(:_respond_to_migrating_event)
			else
				Log.fatal "No event loop is currently running. EventManager will be disabled."
			end
			
			# The CPU usage is calculated as an average between two last calls to psutil
			# We need to make a first, dummy call, so the next calls have something to compare itself agains
			
			# Utils::_get_cpu_usage_percent
			
			@_is_initialized = true
		end

		def _get_system_info
			cpu_usage_percent 	= Utils::_get_cpu_usage_percent
			memory_usage_bytes 	= Utils::_get_memory_usage_bytes
			# This is in camel case to be compatible with the events from the platform
			result = {
				'createdAt'			=> Time.now.utc, # datetime.now(timezone.utc),
				'cpuCurrentUsage' 	=> cpu_usage_percent,
				'memCurrentBytes'	=> memory_usage_bytes,
			}
			if @_config.max_used_cpu_ratio
				result['isCpuOverloaded'] = (cpu_usage_percent > 100 * @_config.max_used_cpu_ratio)
			end
			result
		end		

		# Don't emit any more regular persist state events		
		def _respond_to_migrating_event _event_data
			Log.debug "TODO: _respond_to_migrating_event()"
=begin
			if self._send_persist_state_interval_task and not self._send_persist_state_interval_task.cancelled():
				self._send_persist_state_interval_task.cancel()
				with contextlib.suppress(asyncio.CancelledError):
					await self._send_persist_state_interval_task

			self._event_manager.emit(ActorEventTypes.PERSIST_STATE, {'isMigrating': True})
			self._was_final_persist_state_emitted = True
=end
		end
		
		def _cancel_event_emitting_intervals
			Log.debug "TODO: _cancel_event_emitting_intervals()"
=begin
			if self._send_persist_state_interval_task and not self._send_persist_state_interval_task.cancelled():
				self._send_persist_state_interval_task.cancel()
				with contextlib.suppress(asyncio.CancelledError):
					await self._send_persist_state_interval_task

			if self._send_system_info_interval_task and not self._send_system_info_interval_task.cancelled():
				self._send_system_info_interval_task.cancel()
				with contextlib.suppress(asyncio.CancelledError):
					await self._send_system_info_interval_task
=end
		end
		
		"""Exit the actor instance.

		This stops the Actor instance.
		It cancels all the intervals for regularly sending `PERSIST_STATE` events,
		sends a final `PERSIST_STATE` event,
		waits for all the event listeners to finish,
		and stops the event manager.

		Args:
			exit_code (int, optional): The exit code with which the actor should fail (defaults to `0`).
			event_listeners_timeout_secs (float, optional): How long should the actor wait for actor event listeners to finish before exiting.
			status_message (str, optional): The final status message that the actor should display.
		"""	
		def self.exit_ exit_code=0, status_message: nil, event_listeners_timeout_secs: EVENT_LISTENERS_TIMEOUT_SECS
			_get_default_instance.exit_ exit_code,  status_message: status_message, event_listeners_timeout_secs: event_listeners_timeout_secs
		end

		def exit_ exit_code = 0, status_message: nil, event_listeners_timeout_secs: EVENT_LISTENERS_TIMEOUT_SECS
			_raise_if_not_initialized

			@_is_exiting = true

			# TODO
			# exit_code = Utils::maybe_extract_enum_member_value(exit_code)
			Log.info 'Exiting actor', extra: {'exit_code': exit_code}

			_cancel_event_emitting_intervals

			# Send final persist state event
			"""
			if not self._was_final_persist_state_emitted:
				self._event_manager.emit(ActorEventTypes.PERSIST_STATE, {'isMigrating': False})
				self._was_final_persist_state_emitted = True
			"""
			
			if status_message
				set_status_message status_message, is_terminal: true
			end
			
			# Sleep for a bit so that the listeners have a chance to trigger
			#await asyncio.sleep(0.1)

			@_event_manager.close event_listeners_timeout_secs: event_listeners_timeout_secs
			
			@_is_initialized = false

			if nil # _is_running_in_ipython():
				#self.log.debug(f'Not calling sys.exit({exit_code}) because actor is running in IPython')
			elsif nil # os.getenv('PYTEST_CURRENT_TEST', False):
				#self.log.debug(f'Not calling sys.exit({exit_code}) because actor is running in an unit test')
			elsif nil # hasattr(asyncio, '_nest_patched'):
				#self.log.debug(f'Not calling sys.exit({exit_code}) because actor is running in a nested event loop')
			else
				exit exit_code
			end
		end

		"""Fail the actor instance.

		This performs all the same steps as Actor.exit(),
		but it additionally sets the exit code to `1` (by default).

		Args:
			exit_code (int, optional): The exit code with which the actor should fail (defaults to `1`).
			exception (BaseException, optional): The exception with which the actor failed.
			status_message (str, optional): The final status message that the actor should display.
		"""	
		def self.fail_ exit_code=1, exception: nil, status_message: nil
			_get_default_instance.fail_ exit_code, exception: exception, status_message: status_message
		end

		def fail_ exit_code=1, exception: nil, status_message: nil
			_raise_if_not_initialized

			# In IPython, we don't run `sys.exit()` during actor exits,
			# so the exception traceback will be printed on its own
			
			# TODO:
			if exception ## and not _is_running_in_ipython():
				Log.error('Actor failed with an exception', exc_info: exception)
			end
			exit_ exit_code, status_message: status_message
		end

		"""Initialize the actor, run the passed function and finish the actor cleanly.

		**The `Actor.main()` function is optional** and is provided merely for your convenience.
		It is mainly useful when you're running your code as an actor on the [Apify platform](https://apify.com/actors).

		The `Actor.main()` function performs the following actions:

		- When running on the Apify platform (i.e. `APIFY_IS_AT_HOME` environment variable is set),
		  it sets up a connection to listen for platform events.
		  For example, to get a notification about an imminent migration to another server.
		- It invokes the user function passed as the `main_actor_function` parameter.
		- If the user function was an async function, it awaits it.
		- If the user function throws an exception or some other error is encountered,
		  it prints error details to console so that they are stored to the log,
		  and finishes the actor cleanly.
		- Finally, it exits the Python process, with zero exit code on success and non-zero on errors.

		Args:
			main_actor_function (Callable): The user function which should be run in the actor
		"""
		def self.main main_actor_function
			_get_default_instance.main main_actor_function
		end

		def main main_actor_function
			Async do |task|
				#if not inspect.isfunction(main_actor_function):
				#	raise TypeError(f'First argument passed to Actor.main() must be a function, but instead it was {type(main_actor_function)}')
				raise unless [Method, Proc].include?( main_actor_function.class )
				
				init
				
				res = main_actor_function.call(self)
				
				#if inspect.iscoroutinefunction(main_actor_function):
				#	res = await main_actor_function()
				#else:
				#	res = main_actor_function()
				
				exit_
				
				#return cast(MainReturnType, res)
				return res
			
			rescue SystemExit => e
				Log.debug '# SystemExit #'
				
			rescue Exception => e
				fail_ ActorExitCodes::ERROR_USER_FUNCTION_THREW, exception: e
			
			ensure 
				Log.debug '# Main Stop #'
				task.stop
			end
		end

		"""Return a new instance of the Apify API client.

		The `ApifyClientAsync` class is provided by the [apify-client](https://github.com/apify/apify-client-python) package,
		and it is automatically configured using the `APIFY_API_BASE_URL` and `APIFY_TOKEN` environment variables.

		You can override the token via the available options.
		That's useful if you want to use the client as a different Apify user than the SDK internals are using.

		Args:
			token (str, optional): The Apify API token
			api_url (str, optional): The URL of the Apify API server to which to connect to. Defaults to https://api.apify.com
			max_retries (int, optional): How many times to retry a failed request at most
			min_delay_between_retries_millis (int, optional): How long will the client wait between retrying requests
				(increases exponentially from this value)
			timeout_secs (int, optional): The socket timeout of the HTTP requests sent to the Apify API
		"""
		def self.new_client token=nil, api_url: nil, max_retries: nil, min_delay_between_retries_millis: nil, timeout_secs: nil
			_get_default_instance.new_client(
				token, 
				api_url: api_url, 
				max_retries: max_retries, 
				in_delay_between_retries_millis: 
				min_delay_between_retries_millis, 
				timeout_secs: timeout_secs )
		end

		def new_client token=nil, api_url: nil, max_retries: nil, min_delay_between_retries_millis: nil, timeout_secs: nil
			token 	||= @_config.token
			api_url ||= @_config.api_base_url

			ApifyClient.new(
				token, 
				api_url: api_url,
				max_retries: max_retries, 
				min_delay_between_retries_millis: min_delay_between_retries_millis, 
				timeout_secs: timeout_secs 
			)
		end


=begin
		def _get_storage_client(self, force_cloud: bool) -> Optional[ApifyClientAsync]:
			return self._apify_client if force_cloud else None
=end

		"""Open a dataset.

		Datasets are used to store structured data where each object stored has the same attributes,
		such as online store products or real estate offers.
		The actual data is stored either on the local filesystem or in the Apify cloud.

		Args:
			id (str, optional): ID of the dataset to be opened.
				If neither `id` nor `name` are provided, the method returns the default dataset associated with the actor run.
			name (str, optional): Name of the dataset to be opened.
				If neither `id` nor `name` are provided, the method returns the default dataset associated with the actor run.
			force_cloud (bool, optional): If set to `True` then the Apify cloud storage is always used.
				This way it is possible to combine local and cloud storage.

		Returns:
			Dataset: An instance of the `Dataset` class for the given ID or name.

		"""
		def self.open_dataset id: nil, name: nil, force_cloud: false
			_get_default_instance.open_dataset id: id, name: name, force_cloud: force_cloud
		end

		def open_dataset id: nil, name: nil, force_cloud: false
			_raise_if_not_initialized
			Dataset.open id: id, name: name, force_cloud: force_cloud, config: @_config
		end

		"""Open a key-value store.

		Key-value stores are used to store records or files, along with their MIME content type.
		The records are stored and retrieved using a unique key.
		The actual data is stored either on a local filesystem or in the Apify cloud.

		Args:
			id (str, optional): ID of the key-value store to be opened.
				If neither `id` nor `name` are provided, the method returns the default key-value store associated with the actor run.
			name (str, optional): Name of the key-value store to be opened.
				If neither `id` nor `name` are provided, the method returns the default key-value store associated with the actor run.
			force_cloud (bool, optional): If set to `True` then the Apify cloud storage is always used.
				This way it is possible to combine local and cloud storage.

		Returns:
			KeyValueStore: An instance of the `KeyValueStore` class for the given ID or name.
		"""
		def self.open_key_value_store id: nil, name: nil, force_cloud: false
			_get_default_instance.open_key_value_store id: id, name: name, force_cloud: force_cloud
		end
		
		def open_key_value_store id: nil, name: nil, force_cloud: false	
			_raise_if_not_initialized
			KeyValueStore.open id: id, name: name, force_cloud: force_cloud, config: @_config
		end

		"""Open a request queue.

		Request queue represents a queue of URLs to crawl, which is stored either on local filesystem or in the Apify cloud.
		The queue is used for deep crawling of websites, where you start with several URLs and then
		recursively follow links to other pages. The data structure supports both breadth-first
		and depth-first crawling orders.

		Args:
			id (str, optional): ID of the request queue to be opened.
				If neither `id` nor `name` are provided, the method returns the default request queue associated with the actor run.
			name (str, optional): Name of the request queue to be opened.
				If neither `id` nor `name` are provided, the method returns the default request queue associated with the actor run.
			force_cloud (bool, optional): If set to `True` then the Apify cloud storage is always used.
				This way it is possible to combine local and cloud storage.

		Returns:
			RequestQueue: An instance of the `RequestQueue` class for the given ID or name.
		"""
		def self.open_request_queue id: nil, name: nil, force_cloud: nil
			_get_default_instance.open_request_queue id: id, name: name, force_cloud: force_cloud
		end
		
		def open_request_queue id: nil, name: nil, force_cloud: nil
			_raise_if_not_initialized
			RequestQueue.open id: id, name: name, force_cloud: force_cloud, config: @_config
		end

		"""Store an object or a list of objects to the default dataset of the current actor run.

		Args:
			data (object or list of objects, optional): The data to push to the default dataset.
		"""
		def self.push_data data
			_get_default_instance.push_data data
		end
		
		def push_data data
			_raise_if_not_initialized
			data && open_dataset.push_data( data )
		end

		"""Get the actor input value from the default key-value store associated with the current actor run."""
		def self.get_input
			_get_default_instance.get_input
		end

		def get_input
			_raise_if_not_initialized
				
			input_secrets_private_key 		= @_config.input_secrets_private_key_file
			input_secrets_key_passphrase 	= @_config.input_secrets_private_key_passphrase

			input_value 					= get_value(@_config.input_key)
			
			if input_secrets_private_key and input_secrets_key_passphrase
				private_key = Crypto._load_private_key( input_secrets_private_key, input_secrets_key_passphrase )
				input_value = Crypto._decrypt_input_secrets( private_key, input_value )
			end
			input_value # return input_value
		end

		"""Get a value from the default key-value store associated with the current actor run.

		Args:
			key (str): The key of the record which to retrieve.
			default_value (Any, optional): Default value returned in case the record does not exist.
		"""
		def self.get_value key, default_value=nil
			_get_default_instance.get_value(key=key, default_value=default_value)
		end

		def get_value key, default_value=nil
			_raise_if_not_initialized
			open_key_value_store.get_value key, default_value: default_value
		end

		"""Set or delete a value in the default key-value store associated with the current actor run.

		Args:
			key (str): The key of the record which to set.
			value (any): The value of the record which to set, or None, if the record should be deleted.
			content_type (str, optional): The content type which should be set to the value.
		"""
		def self.set_value key, value=nil, content_type=nil
			_get_default_instance.set_value key, value, content_type
		end
		def set_value key, value=nil, content_type=nil
			_raise_if_not_initialized
			open_key_value_store.set_value key, value, content_type
		end

		"""Add an event listener to the actor's event manager.

		The following events can be emitted:
		 - `ActorEventTypes.SYSTEM_INFO`:
			Emitted every minute, the event data contains info about the resource usage of the actor.
		 - `ActorEventTypes.MIGRATING`:
			Emitted when the actor running on the Apify platform is going to be migrated to another worker server soon.
			You can use it to persist the state of the actor and gracefully stop your in-progress tasks,
			so that they are not interrupted by the migration..
		 - `ActorEventTypes.PERSIST_STATE`:
			Emitted in regular intervals (by default 60 seconds) to notify the actor that it should persist its state,
			in order to avoid repeating all work when the actor restarts.
			This event is automatically emitted together with the migrating event,
			in which case the `isMigrating` flag in the event data is set to True, otherwise the flag is False.
			Note that this event is provided merely for your convenience,
			you can achieve the same effect using an interval and listening for the migrating event.
		 - `ActorEventTypes.ABORTING`:
			When a user aborts an actor run on the Apify platform,
			they can choose to abort it gracefully, to allow the actor some time before getting terminated.
			This graceful abort emits the aborting event, which you can use to clean up the actor state.

		Args:
			event_name (ActorEventTypes): The actor event for which to listen to.
			listener (Callable): The function which is to be called when the event is emitted (can be async).
		"""
=begin
		@classmethod
		def on(cls, event_name: ActorEventTypes, listener: Callable) -> Callable:

			return cls._get_default_instance().on(event_name, listener)
=end
		def on event_name, listener
			_raise_if_not_initialized
			@_event_manager.on event_name, listener
		end

		"""Remove a listener, or all listeners, from an actor event.

		Args:
			event_name (ActorEventTypes): The actor event for which to remove listeners.
			listener (Callable, optional): The listener which is supposed to be removed. If not passed, all listeners of this event are removed.
		"""
=begin
		@classmethod
		def off(cls, event_name: ActorEventTypes, listener: Optional[Callable] = None) -> None:
			return cls._get_default_instance().off(event_name, listener)
=end
		def off event_name, listener
			_raise_if_not_initialized
			@_event_manager.off event_name, listener
		end

		"""Return `True` when the actor is running on the Apify platform, and `False` otherwise (for example when running locally)."""
		def self.is_at_home = _get_default_instance.is_at_home
		
		def is_at_home =  @_config.is_at_home

		"""Return a dictionary with information parsed from all the `APIFY_XXX` environment variables.

		For a list of all the environment variables,
		see the [Actor documentation](https://docs.apify.com/actors/development/environment-variables).
		If some variables are not defined or are invalid, the corresponding value in the resulting dictionary will be None.
		"""	
		def self.get_env = _get_default_instance.get_env
		
		def get_env
			_raise_if_not_initialized

			[ 	* ActorEnvVars.constants.map { |n| [n, ActorEnvVars.const_get(n)] }, 
				* ApifyEnvVars.constants.map { |n| [n, ApifyEnvVars.const_get(n)] } 
			].map { |p| [p[0].downcase.to_s, ENV[p[1]]] }.to_h

			# TODO: ENV => _fetch_and_parse_env_var
		end

		"""Run an actor on the Apify platform.

		Unlike `Actor.call`, this method just starts the run without waiting for finish.

		Args:
			actor_id (str): The ID of the actor to be run.
			run_input (Any, optional): The input to pass to the actor run.
			token (str, optional): The Apify API token to use for this request (defaults to the `APIFY_TOKEN` environment variable).
			content_type (str, optional): The content type of the input.
			build (str, optional): Specifies the actor build to run. It can be either a build tag or build number.
								   By default, the run uses the build specified in the default run configuration for the actor (typically latest).
			memory_mbytes (int, optional): Memory limit for the run, in megabytes.
										   By default, the run uses a memory limit specified in the default run configuration for the actor.
			timeout_secs (int, optional): Optional timeout for the run, in seconds.
										  By default, the run uses timeout specified in the default run configuration for the actor.
			wait_for_finish (int, optional): The maximum number of seconds the server waits for the run to finish.
											   By default, it is 0, the maximum value is 300.
			webhooks (list of dict, optional): Optional ad-hoc webhooks (https://docs.apify.com/webhooks/ad-hoc-webhooks)
											   associated with the actor run which can be used to receive a notification,
											   e.g. when the actor finished or failed.
											   If you already have a webhook set up for the actor or task, you do not have to add it again here.
											   Each webhook is represented by a dictionary containing these items:
											   * ``event_types``: list of ``WebhookEventType`` values which trigger the webhook
											   * ``request_url``: URL to which to send the webhook HTTP request
											   * ``payload_template`` (optional): Optional template for the request payload

		Returns:
			dict: Info about the started actor run
		"""	
		def self.start(
			actor_id, run_input = nil,
			token: nil,
			content_type: nil, build: nil, memory_mbytes: nil, timeout_secs: nil, wait_for_finish: nil, webhooks: nil
		)
			_get_default_instance.start(
				actor_id, run_input,
				token: token,
				content_type: content_type, build: build, memory_mbytes: memory_mbytes, timeout_secs: timeout_secs, 
				wait_for_finish: wait_for_finish, webhooks: webhooks
			)
		end
		
		def start(
			actor_id, run_input = nil,
			token: nil,
			content_type: nil, build: nil, memory_mbytes: nil, timeout_secs: nil, wait_for_finish: nil, webhooks: nil
		)
			_raise_if_not_initialized

			client = token ? new_client(token) : @_apify_client
			client.actor(actor_id).start(
				run_input,
				content_type: content_type, build: build, memory_mbytes: memory_mbytes, timeout_secs: timeout_secs, 
				wait_for_finish: wait_for_finish, webhooks: webhooks
			)
		end

		"""Abort given actor run on the Apify platform using the current user account (determined by the `APIFY_TOKEN` environment variable).

		Args:
			run_id (str): The ID of the actor run to be aborted.
			token (str, optional): The Apify API token to use for this request (defaults to the `APIFY_TOKEN` environment variable).
			gracefully (bool, optional): If True, the actor run will abort gracefully.
				It will send ``aborting`` and ``persistStates`` events into the run and force-stop the run after 30 seconds.
				It is helpful in cases where you plan to resurrect the run later.

		Returns:
			dict: Info about the aborted actor run
		"""

		def self.abort run_id, token: nil, gracefully: nil
			_get_default_instance.abort run_id, token: token, gracefully: gracefully
		end
		
		def abort run_id, token: nil, status_message: nil, gracefully: nil
			_raise_if_not_initialized

			client = token ? new_client(token) : @_apify_client

			run = client.run(run_id)
			run.update(status_message: status_message) if status_message
			run.abort gracefully: gracefully
		end

		"""Start an actor on the Apify Platform and wait for it to finish before returning.

		It waits indefinitely, unless the wait_secs argument is provided.

		Args:
			actor_id (str): The ID of the actor to be run.
			run_input (Any, optional): The input to pass to the actor run.
			token (str, optional): The Apify API token to use for this request (defaults to the `APIFY_TOKEN` environment variable).
			content_type (str, optional): The content type of the input.
			build (str, optional): Specifies the actor build to run. It can be either a build tag or build number.
								   By default, the run uses the build specified in the default run configuration for the actor (typically latest).
			memory_mbytes (int, optional): Memory limit for the run, in megabytes.
										   By default, the run uses a memory limit specified in the default run configuration for the actor.
			timeout_secs (int, optional): Optional timeout for the run, in seconds.
										  By default, the run uses timeout specified in the default run configuration for the actor.
			webhooks (list, optional): Optional webhooks (https://docs.apify.com/webhooks) associated with the actor run,
									   which can be used to receive a notification, e.g. when the actor finished or failed.
									   If you already have a webhook set up for the actor, you do not have to add it again here.
			wait_secs (int, optional): The maximum number of seconds the server waits for the run to finish. If not provided, waits indefinitely.

		Returns:
			dict: Info about the started actor run
		"""
		
		def self.call(
			actor_id, run_input = nil,
			token: nil, 
			content_type: nil, build: nil, memory_mbytes: nil, timeout_secs: nil, webhooks: nil, wait_secs: nil
		)
			_get_default_instance.call(
				actor_id, run_input,
				token: token, 
				content_type: content_type, build: build, memory_mbytes: memory_mbytes, timeout_secs: timeout_secs, webhooks: webhooks, wait_secs: wait_secs
			)
		end
		
		def call(
			actor_id, run_input = nil,
			token: nil, 
			content_type: nil, build: nil, memory_mbytes: nil, timeout_secs: nil, webhooks: nil, wait_secs: nil
		)
			_raise_if_not_initialized

			client = token ? new_client(token) : @_apify_client
			client.actor(actor_id).call(
				run_input,
				content_type: content_type, build: build, memory_mbytes: memory_mbytes, timeout_secs: timeout_secs, webhooks: webhooks, wait_secs: wait_secs
			)
		end

		"""Start an actor task on the Apify Platform and wait for it to finish before returning.

		It waits indefinitely, unless the wait_secs argument is provided.

		Note that an actor task is a saved input configuration and options for an actor.
		If you want to run an actor directly rather than an actor task, please use the `Actor.call`

		Args:
			task_id (str): The ID of the actor to be run.
			task_input (Any, optional): Overrides the input to pass to the actor run.
			token (str, optional): The Apify API token to use for this request (defaults to the `APIFY_TOKEN` environment variable).
			content_type (str, optional): The content type of the input.
			build (str, optional): Specifies the actor build to run. It can be either a build tag or build number.
								   By default, the run uses the build specified in the default run configuration for the actor (typically latest).
			memory_mbytes (int, optional): Memory limit for the run, in megabytes.
										   By default, the run uses a memory limit specified in the default run configuration for the actor.
			timeout_secs (int, optional): Optional timeout for the run, in seconds.
										  By default, the run uses timeout specified in the default run configuration for the actor.
			webhooks (list, optional): Optional webhooks (https://docs.apify.com/webhooks) associated with the actor run,
									   which can be used to receive a notification, e.g. when the actor finished or failed.
									   If you already have a webhook set up for the actor, you do not have to add it again here.
			wait_secs (int, optional): The maximum number of seconds the server waits for the run to finish. If not provided, waits indefinitely.

		Returns:
			dict: Info about the started actor run
		"""
		def self.call_task(
			task_id, task_input = nil,
			build: nil, memory_mbytes: nil, timeout_secs: nil, webhooks: nil, wait_secs: nil, token: nil
		)
			_get_default_instance.call_task(
				task_id, task_input,
				token: token,
				build: build,
				memory_mbytes: memory_mbytes,
				timeout_secs: timeout_secs,
				webhooks: webhooks,
				wait_secs: wait_secs
			)
		end

		def call_task(
			task_id, task_input = nil,
			build: nil, memory_mbytes: nil, timeout_secs: nil, webhooks: nil, wait_secs: nil, token: nil
		)
			_raise_if_not_initialized

			client = token ? new_client(token) : @_apify_client
			client.task(task_id).call(
				task_input,
				build: build,
				memory_mbytes: memory_mbytes,
				timeout_secs: timeout_secs,
				webhooks: webhooks,
				wait_secs: wait_secs
			)
		end

		"""Transform this actor run to an actor run of a different actor.

		The platform stops the current actor container and starts a new container with the new actor instead.
		All the default storages are preserved,
		and the new input is stored under the `INPUT-METAMORPH-1` key in the same default key-value store.

		Args:
			target_actor_id (str): ID of the target actor that the run should be transformed into
			run_input (Any, optional): The input to pass to the new run.
			target_actor_build (str, optional): The build of the target actor. It can be either a build tag or build number.
				By default, the run uses the build specified in the default run configuration for the target actor (typically the latest build).
			content_type (str, optional): The content type of the input.
			custom_after_sleep_millis (int, optional): How long to sleep for after the metamorph, to wait for the container to be stopped.

		Returns:
			dict: The actor run data.
		"""
=begin
		@classmethod
		async def metamorph(
			cls,
			target_actor_id: str,
			run_input: Optional[Any] = None,
			*,
			target_actor_build: Optional[str] = None,
			content_type: Optional[str] = None,
			custom_after_sleep_millis: Optional[int] = None,
		) -> None:

			return await cls._get_default_instance().metamorph(
				target_actor_id=target_actor_id,
				target_actor_build=target_actor_build,
				run_input=run_input,
				content_type=content_type,
				custom_after_sleep_millis=custom_after_sleep_millis,
			)

		async def _metamorph_internal(
			self,
			target_actor_id: str,
			run_input: Optional[Any] = None,
			*,
			target_actor_build: Optional[str] = None,
			content_type: Optional[str] = None,
			custom_after_sleep_millis: Optional[int] = None,
		) -> None:
			self._raise_if_not_initialized()

			if not self.is_at_home():
				self.log.error('Actor.metamorph() is only supported when running on the Apify platform.')
				return

			if not custom_after_sleep_millis:
				custom_after_sleep_millis = self._config.metamorph_after_sleep_millis

			# If is_at_home() is True, config.actor_run_id is always set
			assert self._config.actor_run_id is not None

			await self._apify_client.run(self._config.actor_run_id).metamorph(
				target_actor_id=target_actor_id,
				run_input=run_input,
				target_actor_build=target_actor_build,
				content_type=content_type,
			)

			if custom_after_sleep_millis:
				await asyncio.sleep(custom_after_sleep_millis / 1000)
=end

		"""Internally reboot this actor.

		The system stops the current container and starts a new one, with the same run ID and default storages.

		Args:
			event_listeners_timeout_secs (int, optional): How long should the actor wait for actor event listeners to finish before exiting
			custom_after_sleep_millis (int, optional): How long to sleep for after the reboot, to wait for the container to be stopped.
		"""
		def self.reboot event_listeners_timeout_secs: EVENT_LISTENERS_TIMEOUT_SECS, custom_after_sleep_millis: nil
			_get_default_instance.reboot(
				event_listeners_timeout_secs: event_listeners_timeout_secs,
				custom_after_sleep_millis: custom_after_sleep_millis,
			)
		end
		
		def reboot event_listeners_timeout_secs: EVENT_LISTENERS_TIMEOUT_SECS, custom_after_sleep_millis: nil
			_raise_if_not_initialized

			if !is_at_home
				Log.error 'Actor.reboot() is only supported when running on the Apify platform.'
				return
			end
			
			custom_after_sleep_millis ||= @_config.metamorph_after_sleep_millis

			"""
			await self._cancel_event_emitting_intervals()

			self._event_manager.emit(ActorEventTypes.PERSIST_STATE, {'isMigrating': True})
			self._was_final_persist_state_emitted = True

			await self._event_manager.close(event_listeners_timeout_secs=event_listeners_timeout_secs)
			"""
			
			raise unless @_config.actor_run_id
			@_apify_client.run(@_config.actor_run_id).reboot

			sleep(custom_after_sleep_millis / 1000) if custom_after_sleep_millis
		end
		
		"""Create an ad-hoc webhook for the current actor run.

		This webhook lets you receive a notification when the actor run finished or failed.

		Note that webhooks are only supported for actors running on the Apify platform.
		When running the actor locally, the function will print a warning and have no effect.

		For more information about Apify actor webhooks, please see the [documentation](https://docs.apify.com/webhooks).

		Args:
			event_types (list of WebhookEventType): List of event types that should trigger the webhook. At least one is required.
			request_url (str): URL that will be invoked once the webhook is triggered.
			payload_template (str, optional): Specification of the payload that will be sent to request_url
			ignore_ssl_errors (bool, optional): Whether the webhook should ignore SSL errors returned by request_url
			do_not_retry (bool, optional): Whether the webhook should retry sending the payload to request_url upon
										   failure.
			idempotency_key (str, optional): A unique identifier of a webhook. You can use it to ensure that you won't
											 create the same webhook multiple times.

		Returns:
			dict: The created webhook
		"""
=begin
		@classmethod
		async def add_webhook(
			cls,
			*,
			event_types: List[WebhookEventType],
			request_url: str,
			payload_template: Optional[str] = None,
			ignore_ssl_errors: Optional[bool] = None,
			do_not_retry: Optional[bool] = None,
			idempotency_key: Optional[str] = None,
		) -> Dict:

			return await cls._get_default_instance().add_webhook(
				event_types=event_types,
				request_url=request_url,
				payload_template=payload_template,
				ignore_ssl_errors=ignore_ssl_errors,
				do_not_retry=do_not_retry,
				idempotency_key=idempotency_key,
			)

		async def _add_webhook_internal(
			self,
			*,
			event_types: List[WebhookEventType],
			request_url: str,
			payload_template: Optional[str] = None,
			ignore_ssl_errors: Optional[bool] = None,
			do_not_retry: Optional[bool] = None,
			idempotency_key: Optional[str] = None,
		) -> Optional[Dict]:
			self._raise_if_not_initialized()

			if not self.is_at_home():
				self.log.error('Actor.add_webhook() is only supported when running on the Apify platform.')
				return None

			# If is_at_home() is True, config.actor_run_id is always set
			assert self._config.actor_run_id is not None

			return await self._apify_client.webhooks().create(
				actor_run_id=self._config.actor_run_id,
				event_types=event_types,
				request_url=request_url,
				payload_template=payload_template,
				ignore_ssl_errors=ignore_ssl_errors,
				do_not_retry=do_not_retry,
				idempotency_key=idempotency_key,
			)
=end

		"""Set the status message for the current actor run.

		Args:
			status_message (str): The status message to set to the run.
			is_terminal (bool, optional): Set this flag to True if this is the final status message of the Actor run.

		Returns:
			dict: The updated actor run object
		"""
		def self.set_status_message status_message, is_terminal: nil
			_get_default_instance.set_status_message status_message, is_terminal: is_terminal
		end

		def set_status_message status_message, is_terminal: nil
			_raise_if_not_initialized

			if !is_at_home
				title = is_terminal ? 'Terminal status message' : 'Status message'
				Log.info "[#{title}]: #{status_message}"
				return
			end
			
			# If is_at_home() is True, config.actor_run_id is always set
			raise unless @_config.actor_run_id

			@_apify_client.run(@_config.actor_run_id).update status_message: status_message, is_status_message_terminal: is_terminal
		end

		"""Create a ProxyConfiguration object with the passed proxy configuration.

		Configures connection to a proxy server with the provided options.
		Proxy servers are used to prevent target websites from blocking your crawlers based on IP address rate limits or blacklists.

		For more details and code examples, see the `ProxyConfiguration` class.

		Args:
			actor_proxy_input (dict, optional): Proxy configuration field from the actor input, if actor has such input field.
				If you pass this argument, all the other arguments will be inferred from it.
			password (str, optional): Password for the Apify Proxy. If not provided, will use os.environ['APIFY_PROXY_PASSWORD'], if available.
			groups (list of str, optional): Proxy groups which the Apify Proxy should use, if provided.
			country_code (str, optional): Country which the Apify Proxy should use, if provided.
			proxy_urls (list of str, optional): Custom proxy server URLs which should be rotated through.
			new_url_function (Callable, optional): Function which returns a custom proxy URL to be used.

		Returns:
			ProxyConfiguration, optional: ProxyConfiguration object with the passed configuration,
										  or None, if no proxy should be used based on the configuration.
		"""
		def self.create_proxy_configuration(
			actor_proxy_input = nil,  # this is the raw proxy input from the actor run input, it is not spread or snake_cased in here
			password: nil,
			groups: nil,
			country_code: nil,
			proxy_urls: nil,
			new_url_function: nil # Optional[Union[Callable[[Optional[str]], str], Callable[[Optional[str]], Awaitable[str]]]] = None,
		)
			_get_default_instance.create_proxy_configuration(
				actor_proxy_input, 
				password: password, 
				groups: groups, 
				country_code: country_code, 
				proxy_urls: proxy_urls, 
				new_url_function: new_url_function )
		end
		
		def create_proxy_configuration(
			actor_proxy_input = nil, # this is the raw proxy input from the actor run input, it is not spread or snake_cased in here
			password: nil,
			groups:  nil,
			country_code:  nil,
			proxy_urls:  nil,
			new_url_function: nil # Optional[Union[Callable[[Optional[str]], str], Callable[[Optional[str]], Awaitable[str]]]] = None,
		)
			_raise_if_not_initialized

			if (actor_proxy_input.class == Hash) && (actor_proxy_input.length > 0)
				if actor_proxy_input['useApifyProxy'] # bool
					country_code 	||= actor_proxy_input['apifyProxyCountry']
					groups 			||= actor_proxy_input['apifyProxyGroups']
				else
					proxy_urls = actor_proxy_input['proxyUrls'] # []
					return if !proxy_urls || proxy_urls.empty? 
				end
			end
			
			proxy_configuration = ProxyConfiguration.new(
				password: password, 
				groups: groups, 
				country_code: country_code, 
				proxy_urls: proxy_urls, 
				new_url_function: new_url_function, 
				_actor_config: @_config, 
				_apify_client: @_apify_client
			)
			
			# NOTE: "initialize" is Ruby class constructor
			proxy_configuration.__initialize
			proxy_configuration
		end
	end

end
