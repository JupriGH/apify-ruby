=begin
from apify_shared.consts import ActorJobStatus, MetaOrigin
from apify_shared.utils import filter_out_none_values_recursively, ignore_docs, maybe_extract_enum_member_value, parse_date_fields

from ..._utils import _encode_key_value_store_record_value, _encode_webhook_list_to_base64, _pluck_data
from .actor_version import ActorVersionClient, ActorVersionClientAsync
from .actor_version_collection import ActorVersionCollectionClient, ActorVersionCollectionClientAsync

def _get_actor_representation(
    *,
    name: Optional[str],
    title: Optional[str] = None,
    description: Optional[str] = None,
    seo_title: Optional[str] = None,
    seo_description: Optional[str] = None,
    versions: Optional[List[Dict]] = None,
    restart_on_error: Optional[bool] = None,
    is_public: Optional[bool] = None,
    is_deprecated: Optional[bool] = None,
    is_anonymously_runnable: Optional[bool] = None,
    categories: Optional[List[str]] = None,
    default_run_build: Optional[str] = None,
    default_run_max_items: Optional[int] = None,
    default_run_memory_mbytes: Optional[int] = None,
    default_run_timeout_secs: Optional[int] = None,
    example_run_input_body: Optional[Any] = None,
    example_run_input_content_type: Optional[str] = None,
) -> Dict:
    return {
        'name': name,
        'title': title,
        'description': description,
        'seoTitle': seo_title,
        'seoDescription': seo_description,
        'versions': versions,
        'restartOnError': restart_on_error,
        'isPublic': is_public,
        'isDeprecated': is_deprecated,
        'isAnonymouslyRunnable': is_anonymously_runnable,
        'categories': categories,
        'defaultRunOptions': {
            'build': default_run_build,
            'maxItems': default_run_max_items,
            'memoryMbytes': default_run_memory_mbytes,
            'timeoutSecs': default_run_timeout_secs,
        },
        'exampleRunInput': {
            'body': example_run_input_body,
            'contentType': example_run_input_content_type,
        },
    }

=end

module Apify

	"""Sub-client for manipulating a single actor."""
	class ActorClient < ResourceClient

		"""Initialize the ActorClient."""
		def initialize(**kwargs) = super(resource_path: 'acts', **kwargs)

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
=begin
		def update(
			self,
			*,
			name: Optional[str] = None,
			title: Optional[str] = None,
			description: Optional[str] = None,
			seo_title: Optional[str] = None,
			seo_description: Optional[str] = None,
			versions: Optional[List[Dict]] = None,
			restart_on_error: Optional[bool] = None,
			is_public: Optional[bool] = None,
			is_deprecated: Optional[bool] = None,
			is_anonymously_runnable: Optional[bool] = None,
			categories: Optional[List[str]] = None,
			default_run_build: Optional[str] = None,
			default_run_max_items: Optional[int] = None,
			default_run_memory_mbytes: Optional[int] = None,
			default_run_timeout_secs: Optional[int] = None,
			example_run_input_body: Optional[Any] = None,
			example_run_input_content_type: Optional[str] = None,
		) -> Dict:
			actor_representation = _get_actor_representation(
				name=name,
				title=title,
				description=description,
				seo_title=seo_title,
				seo_description=seo_description,
				versions=versions,
				restart_on_error=restart_on_error,
				is_public=is_public,
				is_deprecated=is_deprecated,
				is_anonymously_runnable=is_anonymously_runnable,
				categories=categories,
				default_run_build=default_run_build,
				default_run_max_items=default_run_max_items,
				default_run_memory_mbytes=default_run_memory_mbytes,
				default_run_timeout_secs=default_run_timeout_secs,
				example_run_input_body=example_run_input_body,
				example_run_input_content_type=example_run_input_content_type,
			)

			return self._update(filter_out_none_values_recursively(actor_representation))
=end

		"""Delete the actor.

		https://docs.apify.com/api/v2#/reference/actors/actor-object/delete-actor
		"""
=begin
		def delete(self) -> None:
			return self._delete()
=end

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

			res = @http_client.call(
				url: _url('runs'),
				method: 'POST',
				headers: {'content-type': content_type},
				data: run_input,
				params: request_params
			)

			res.dig(:parsed, "data")
			# parse_date_fields(_pluck_data(response.json()))
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
=begin
		def build(
			self,
			*,
			version_number: str,
			beta_packages: Optional[bool] = None,
			tag: Optional[str] = None,
			use_cache: Optional[bool] = None,
			wait_for_finish: Optional[int] = None,
		) -> Dict:
			request_params = self._params(
				version=version_number,
				betaPackages=beta_packages,
				tag=tag,
				useCache=use_cache,
				waitForFinish=wait_for_finish,
			)

			response = self.http_client.call(
				url=self._url('builds'),
				method='POST',
				params=request_params,
			)

			return parse_date_fields(_pluck_data(response.json()))
=end

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

=begin
	from apify_shared.utils import filter_out_none_values_recursively, ignore_docs
	from .actor import _get_actor_representation
=end


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
=begin
		def create(
			self,
			*,
			name: str,
			title: Optional[str] = None,
			description: Optional[str] = None,
			seo_title: Optional[str] = None,
			seo_description: Optional[str] = None,
			versions: Optional[List[Dict]] = None,
			restart_on_error: Optional[bool] = None,
			is_public: Optional[bool] = None,
			is_deprecated: Optional[bool] = None,
			is_anonymously_runnable: Optional[bool] = None,
			categories: Optional[List[str]] = None,
			default_run_build: Optional[str] = None,
			default_run_max_items: Optional[int] = None,
			default_run_memory_mbytes: Optional[int] = None,
			default_run_timeout_secs: Optional[int] = None,
			example_run_input_body: Optional[Any] = None,
			example_run_input_content_type: Optional[str] = None,
		) -> Dict:
			actor_representation = _get_actor_representation(
				name=name,
				title=title,
				description=description,
				seo_title=seo_title,
				seo_description=seo_description,
				versions=versions,
				restart_on_error=restart_on_error,
				is_public=is_public,
				is_deprecated=is_deprecated,
				is_anonymously_runnable=is_anonymously_runnable,
				categories=categories,
				default_run_build=default_run_build,
				default_run_max_items=default_run_max_items,
				default_run_memory_mbytes=default_run_memory_mbytes,
				default_run_timeout_secs=default_run_timeout_secs,
				example_run_input_body=example_run_input_body,
				example_run_input_content_type=example_run_input_content_type,
			)

			return self._create(filter_out_none_values_recursively(actor_representation))
=end

	end

end