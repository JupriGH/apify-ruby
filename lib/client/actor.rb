def _get_actor_representation(
    name: nil,
    title: nil,
    description: nil,
    seo_title: nil,
    seo_description: nil,
    versions: nil,
    restart_on_error: nil,
    is_public: nil,
    is_deprecated: nil,
    is_anonymously_runnable: nil,
    categories: nil,
    default_run_build: nil,
    default_run_max_items: nil,
    default_run_memory_mbytes: nil,
    default_run_timeout_secs: nil,
    example_run_input_body: nil,
    example_run_input_content_type: nil
) = ({
	name: name,
	title: title,
	description: description,
	seoTitle: seo_title,
	seoDescription: seo_description,
	versions: versions,
	restartOnError: restart_on_error,
	isPublic: is_public,
	isDeprecated: is_deprecated,
	isAnonymouslyRunnable: is_anonymously_runnable,
	categories: categories,
	defaultRunOptions: {
		build: default_run_build,
		maxItems: default_run_max_items,
		memoryMbytes: default_run_memory_mbytes,
		timeoutSecs: default_run_timeout_secs,
	},
	exampleRunInput: {
		body: example_run_input_body,
		contentType: example_run_input_content_type,
	},
})

module Apify

	"""Sub-client for manipulating a single actor."""
	class ActorClient < ResourceClient

		"""Initialize the ActorClient."""
		def initialize(**kwargs) = super resource_path: 'acts', **kwargs

		"""Retrieve the actor.

		https://docs.apify.com/api/v2#/reference/actors/actor-object/get-actor

		Returns:
			dict, optional: The retrieved actor
		"""
		def get = _get

		"""Update the actor with the specified fields.

		https://docs.apify.com/api/v2#/reference/actors/actor-object/update-actor

		Args:
			name (str, optional): The name of the actor
			title (str, optional): The title of the actor (human-readable)
			description (str, optional): The description for the actor
			seo_title (str, optional): The title of the actor optimized for search engines
			seo_description (str, optional): The description of the actor optimized for search engines
			versions (list of dict, optional): The list of actor versions
			restart_on_error (bool, optional): If true, the main actor run process will be restarted whenever it exits with a non-zero status code.
			is_public (bool, optional): Whether the actor is public.
			is_deprecated (bool, optional): Whether the actor is deprecated.
			is_anonymously_runnable (bool, optional): Whether the actor is anonymously runnable.
			categories (list of str, optional): The categories to which the actor belongs to.
			default_run_build (str, optional): Tag or number of the build that you want to run by default.
			default_run_max_items (int, optional): Default limit of the number of results that will be returned by runs of this Actor,
												   if the Actor is charged per result.
			default_run_memory_mbytes (int, optional): Default amount of memory allocated for the runs of this actor, in megabytes.
			default_run_timeout_secs (int, optional): Default timeout for the runs of this actor in seconds.
			example_run_input_body (Any, optional): Input to be prefilled as default input to new users of this actor.
			example_run_input_content_type (str, optional): The content type of the example run input.

		Returns:
			dict: The updated actor
		"""
		def update(
			name: nil,
			title: nil,
			description: nil,
			seo_title: nil,
			seo_description: nil,
			versions: nil,
			restart_on_error: nil,
			is_public: nil,
			is_deprecated: nil,
			is_anonymously_runnable: nil,
			categories: nil,
			default_run_build: nil,
			default_run_max_items: nil,
			default_run_memory_mbytes: nil,
			default_run_timeout_secs: nil,
			example_run_input_body: nil,
			example_run_input_content_type: nil
		)
			_update _get_actor_representation(
				name: name,
				title: title,
				description: description,
				seo_title: seo_title,
				seo_description: seo_description,
				versions: versions,
				restart_on_error: restart_on_error,
				is_public: is_public,
				is_deprecated: is_deprecated,
				is_anonymously_runnable: is_anonymously_runnable,
				categories: categories,
				default_run_build: default_run_build,
				default_run_max_items: default_run_max_items,
				default_run_memory_mbytes: default_run_memory_mbytes,
				default_run_timeout_secs: default_run_timeout_secs,
				example_run_input_body: example_run_input_body,
				example_run_input_content_type: example_run_input_content_type
			)
		end

		"""Delete the actor.

		https://docs.apify.com/api/v2#/reference/actors/actor-object/delete-actor
		"""
		def delete = _delete

		"""Start the actor and immediately return the Run object.

		https://docs.apify.com/api/v2#/reference/actors/run-collection/run-actor

		Args:
			run_input (Any, optional): The input to pass to the actor run.
			content_type (str, optional): The content type of the input.
			build (str, optional): Specifies the actor build to run. It can be either a build tag or build number.
								   By default, the run uses the build specified in the default run configuration for the actor (typically latest).
			max_items (int, optional): Maximum number of results that will be returned by this run.
									   If the Actor is charged per result, you will not be charged for more results than the given limit.
			memory_mbytes (int, optional): Memory limit for the run, in megabytes.
										   By default, the run uses a memory limit specified in the default run configuration for the actor.
			timeout_secs (int, optional): Optional timeout for the run, in seconds.
										  By default, the run uses timeout specified in the default run configuration for the actor.
			wait_for_finish (int, optional): The maximum number of seconds the server waits for the run to finish.
											   By default, it is 0, the maximum value is 60.
			webhooks (list of dict, optional): Optional ad-hoc webhooks (https://docs.apify.com/webhooks/ad-hoc-webhooks)
											   associated with the actor run which can be used to receive a notification,
											   e.g. when the actor finished or failed.
											   If you already have a webhook set up for the actor or task, you do not have to add it again here.
											   Each webhook is represented by a dictionary containing these items:
											   * ``event_types``: list of ``WebhookEventType`` values which trigger the webhook
											   * ``request_url``: URL to which to send the webhook HTTP request
											   * ``payload_template`` (optional): Optional template for the request payload

		Returns:
			dict: The run object
		"""
		def start(
			run_input = nil,
			content_type: nil, build: nil, max_items: nil, memory_mbytes: nil, timeout_secs: nil, wait_for_finish: nil, webhooks: nil
		)
			raise "TODO: webhooks" if webhooks 

			run_input, content_type = Utils::_encode_key_value_store_record_value(run_input, content_type)

			request_params = _params(
				build: build,
				maxItems: max_items,
				memory: memory_mbytes,
				timeout: timeout_secs,
				waitForFinish: wait_for_finish,
				webhooks: nil # _encode_webhook_list_to_base64(webhooks) if webhooks is not None else None, # TODO: webhooks
			)

			_http_post(
				'runs',
				headers: {'content-type' => content_type},
				data: run_input,
				params: request_params,
				pluck_data: true
			)
		end
		
		"""Start the actor and wait for it to finish before returning the Run object.

		It waits indefinitely, unless the wait_secs argument is provided.

		https://docs.apify.com/api/v2#/reference/actors/run-collection/run-actor

		Args:
			run_input (Any, optional): The input to pass to the actor run.
			content_type (str, optional): The content type of the input.
			build (str, optional): Specifies the actor build to run. It can be either a build tag or build number.
								   By default, the run uses the build specified in the default run configuration for the actor (typically latest).
			max_items (int, optional): Maximum number of results that will be returned by this run.
									   If the Actor is charged per result, you will not be charged for more results than the given limit.
			memory_mbytes (int, optional): Memory limit for the run, in megabytes.
										   By default, the run uses a memory limit specified in the default run configuration for the actor.
			timeout_secs (int, optional): Optional timeout for the run, in seconds.
										  By default, the run uses timeout specified in the default run configuration for the actor.
			webhooks (list, optional): Optional webhooks (https://docs.apify.com/webhooks) associated with the actor run,
									   which can be used to receive a notification, e.g. when the actor finished or failed.
									   If you already have a webhook set up for the actor, you do not have to add it again here.
			wait_secs (int, optional): The maximum number of seconds the server waits for the run to finish. If not provided, waits indefinitely.

		Returns:
			dict: The run object
		"""
		def call(
			run_input = nil,
			content_type: nil, build: nil, max_items: nil, memory_mbytes: nil, timeout_secs: nil, webhooks: nil, wait_secs: nil
		)
			started_run = start( 
				run_input,
				content_type: content_type, build: build, max_items: max_items, memory_mbytes: memory_mbytes, timeout_secs: timeout_secs, webhooks: webhooks
			)
			
			@root_client.run(started_run['id']).wait_for_finish wait_secs
		end

		"""Build the actor.

		https://docs.apify.com/api/v2#/reference/actors/build-collection/build-actor

		Args:
			version_number (str): Actor version number to be built.
			beta_packages (bool, optional): If True, then the actor is built with beta versions of Apify NPM packages.
											By default, the build uses latest stable packages.
			tag (str, optional): Tag to be applied to the build on success. By default, the tag is taken from the actor version's buildTag property.
			use_cache (bool, optional): If true, the actor's Docker container will be rebuilt using layer cache
										(https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#leverage-build-cache).
										This is to enable quick rebuild during development.
										By default, the cache is not used.
			wait_for_finish (int, optional): The maximum number of seconds the server waits for the build to finish before returning.
											 By default it is 0, the maximum value is 60.

		Returns:
			dict: The build object
		"""	
		def build(
			version_number,
			beta_packages: nil,
			tag: nil,
			use_cache: nil,
			wait_for_finish: nil
		)
			request_params = _params(
				version: version_number,
				betaPackages: beta_packages,
				tag: tag,
				useCache: use_cache,
				waitForFinish: wait_for_finish
			)

			_http_post 'builds', params: request_params, pluck_data: true
		end

		"""Retrieve a client for the builds of this actor."""
		def builds = BuildCollectionClient.new(**_sub_resource_init_options(resource_path: 'builds'))
		
		"""Retrieve a client for the runs of this actor."""
		def runs = RunCollectionClient.new(**_sub_resource_init_options(resource_path: 'runs'))

		"""Retrieve the client for the last run of this actor.

		Last run is retrieved based on the start time of the runs.

		Args:
			status (ActorJobStatus, optional): Consider only runs with this status.
			origin (MetaOrigin, optional): Consider only runs started with this origin.

		Returns:
			RunClient: The resource client for the last run of this actor.
		"""
		def last_run status: nil, origin: nil
			RunClient.new(
				**_sub_resource_init_options(
					resource_id: 'last',
					resource_path: 'runs',
					params: _params(
						status: status, # maybe_extract_enum_member_value(status),
						origin: origin 	# maybe_extract_enum_member_value(origin),
					),
				)
			)
		end

		"""Retrieve a client for the versions of this actor."""	
		def versions = ActorVersionCollectionClient.new(**_sub_resource_init_options)

		"""Retrieve the client for the specified version of this actor.

		Args:
			version_number (str): The version number for which to retrieve the resource client.

		Returns:
			ActorVersionClient: The resource client for the specified actor version.
		"""
		def version(version_number) = ActorVersionClient.new(**_sub_resource_init_options(resource_id: version_number))

		"""Retrieve a client for webhooks associated with this actor."""
		def webhooks = WebhookCollectionClient.new(**_sub_resource_init_options)
	end

	### ActorCollectionClient
	
	"""Sub-client for manipulating actors."""
	class ActorCollectionClient < ResourceCollectionClient

		"""Initialize the ActorCollectionClient."""
		def initialize(**kwargs) = super(resource_path: 'acts', **kwargs) 

		"""List the actors the user has created or used.

		https://docs.apify.com/api/v2#/reference/actors/actor-collection/get-list-of-actors

		Args:
			my (bool, optional): If True, will return only actors which the user has created themselves.
			limit (int, optional): How many actors to list
			offset (int, optional): What actor to include as first when retrieving the list
			desc (bool, optional): Whether to sort the actors in descending order based on their creation date

		Returns:
			ListPage: The list of available actors matching the specified filters.
		"""
		def list(my: nil, limit: nil, offset: nil, desc: nil) = _list(my: my, limit: limit, offset: offset, desc: desc)

		"""Create a new actor.

		https://docs.apify.com/api/v2#/reference/actors/actor-collection/create-actor

		Args:
			name (str): The name of the actor
			title (str, optional): The title of the actor (human-readable)
			description (str, optional): The description for the actor
			seo_title (str, optional): The title of the actor optimized for search engines
			seo_description (str, optional): The description of the actor optimized for search engines
			versions (list of dict, optional): The list of actor versions
			restart_on_error (bool, optional): If true, the main actor run process will be restarted whenever it exits with a non-zero status code.
			is_public (bool, optional): Whether the actor is public.
			is_deprecated (bool, optional): Whether the actor is deprecated.
			is_anonymously_runnable (bool, optional): Whether the actor is anonymously runnable.
			categories (list of str, optional): The categories to which the actor belongs to.
			default_run_build (str, optional): Tag or number of the build that you want to run by default.
			default_run_max_items (int, optional): Default limit of the number of results that will be returned by runs of this Actor,
												   if the Actor is charged per result.
			default_run_memory_mbytes (int, optional): Default amount of memory allocated for the runs of this actor, in megabytes.
			default_run_timeout_secs (int, optional): Default timeout for the runs of this actor in seconds.
			example_run_input_body (Any, optional): Input to be prefilled as default input to new users of this actor.
			example_run_input_content_type (str, optional): The content type of the example run input.

		Returns:
			dict: The created actor.
		"""
		def create(
			name,
			title: nil,
			description: nil,
			seo_title: nil,
			seo_description: nil,
			versions:  nil,
			restart_on_error: nil,
			is_public: nil,
			is_deprecated: nil,
			is_anonymously_runnable: nil,
			categories: nil,
			default_run_build: nil,
			default_run_max_items: nil,
			default_run_memory_mbytes: nil,
			default_run_timeout_secs: nil,
			example_run_input_body: nil,
			example_run_input_content_type: nil
		)
			_create _get_actor_representation(
				name: name,
				title: title,
				description: description,
				seo_title: seo_title,
				seo_description: seo_description,
				versions: versions,
				restart_on_error: restart_on_error,
				is_public: is_public,
				is_deprecated: is_deprecated,
				is_anonymously_runnable: is_anonymously_runnable,
				categories: categories,
				default_run_build: default_run_build,
				default_run_max_items: default_run_max_items,
				default_run_memory_mbytes: default_run_memory_mbytes,
				default_run_timeout_secs: default_run_timeout_secs,
				example_run_input_body: example_run_input_body,
				example_run_input_content_type: example_run_input_content_type
			)
		end
	end

end