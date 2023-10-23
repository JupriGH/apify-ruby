def _get_task_representation(
    actor_id: nil,
    name: nil,
    task_input: nil,
    build: nil,
    max_items: nil,
    memory_mbytes: nil,
    timeout_secs: nil,
    title: nil
) = ({
	actId: actor_id,
	name: name,
	options: {
		build: build,
		maxItems: max_items,
		memoryMbytes: memory_mbytes,
		timeoutSecs: timeout_secs,
	},
	input: task_input,
	title: title
})

module Apify 

	"""Sub-client for manipulating a single task."""
	class TaskClient < ResourceClient

		"""Initialize the TaskClient."""
		def initialize(**kwargs) = super(resource_path: 'actor-tasks', **kwargs)

		"""Retrieve the task.

		https://docs.apify.com/api/v2#/reference/actor-tasks/task-object/get-task

		Returns:
			dict, optional: The retrieved task
		"""	
		def get = _get

		"""Update the task with specified fields.

		https://docs.apify.com/api/v2#/reference/actor-tasks/task-object/update-task

		Args:
			name (str, optional): Name of the task
			build (str, optional): Actor build to run. It can be either a build tag or build number.
								   By default, the run uses the build specified in the task settings (typically latest).
			max_items (int, optional): Maximum number of results that will be returned by this run.
									   If the Actor is charged per result, you will not be charged for more results than the given limit.
			memory_mbytes (int, optional): Memory limit for the run, in megabytes.
										   By default, the run uses a memory limit specified in the task settings.
			timeout_secs (int, optional): Optional timeout for the run, in seconds. By default, the run uses timeout specified in the task settings.
			task_input (dict, optional): Task input dictionary
			title (str, optional): A human-friendly equivalent of the name

		Returns:
			dict: The updated task
		"""
		def update(
			name: nil,
			task_input: nil,
			build: nil,
			max_items: nil,
			memory_mbytes: nil,
			timeout_secs: nil,
			title: nil
		)
			task_representation = Utils::filter_out_none_values_recursively _get_task_representation(
				name: name,
				task_input: task_input,
				build: build,
				max_items: max_items,
				memory_mbytes: memory_mbytes,
				timeout_secs: timeout_secs,
				title: title
			)
			_update task_representation
		end

		"""Delete the task.

		https://docs.apify.com/api/v2#/reference/actor-tasks/task-object/delete-task
		"""
		def delete = _delete

		"""Start the task and immediately return the Run object.

		https://docs.apify.com/api/v2#/reference/actor-tasks/run-collection/run-task

		Args:
			task_input (dict, optional): Task input dictionary
			build (str, optional): Specifies the actor build to run. It can be either a build tag or build number.
								   By default, the run uses the build specified in the task settings (typically latest).
			max_items (int, optional): Maximum number of results that will be returned by this run.
									   If the Actor is charged per result, you will not be charged for more results than the given limit.
			memory_mbytes (int, optional): Memory limit for the run, in megabytes.
										   By default, the run uses a memory limit specified in the task settings.
			timeout_secs (int, optional): Optional timeout for the run, in seconds. By default, the run uses timeout specified in the task settings.
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
			task_input = nil,
			build: nil,
			max_items: nil,
			memory_mbytes: nil,
			timeout_secs: nil,
			wait_for_finish: nil,
			webhooks: nil
		)
			raise "TODO: webhooks" if webhooks
			request_params = _params(
				build: build,
				maxItems: max_items,
				memory: memory_mbytes,
				timeout: timeout_secs,
				waitForFinish: wait_for_finish,
				webhooks: nil #_encode_webhook_list_to_base64(webhooks) if webhooks is not None else None,
			)

			res = @http_client.call(
				url: _url('runs'),
				method: 'POST',
				headers: {'content-type' => 'application/json; charset=utf-8'},
				json: task_input,
				params: request_params,
			)
			res.dig(:parsed, "data")
			#return parse_date_fields(_pluck_data(response.json()))
		end

		"""Start a task and wait for it to finish before returning the Run object.

		It waits indefinitely, unless the wait_secs argument is provided.

		https://docs.apify.com/api/v2#/reference/actor-tasks/run-collection/run-task

		Args:
			task_input (dict, optional): Task input dictionary
			build (str, optional): Specifies the actor build to run. It can be either a build tag or build number.
								   By default, the run uses the build specified in the task settings (typically latest).
			max_items (int, optional): Maximum number of results that will be returned by this run.
									   If the Actor is charged per result, you will not be charged for more results than the given limit.
			memory_mbytes (int, optional): Memory limit for the run, in megabytes.
										   By default, the run uses a memory limit specified in the task settings.
			timeout_secs (int, optional): Optional timeout for the run, in seconds. By default, the run uses timeout specified in the task settings.
			webhooks (list, optional): Specifies optional webhooks associated with the actor run, which can be used to receive a notification
									   e.g. when the actor finished or failed. Note: if you already have a webhook set up for the actor or task,
									   you do not have to add it again here.
			wait_secs (int, optional): The maximum number of seconds the server waits for the task run to finish. If not provided, waits indefinitely.

		Returns:
			dict: The run object
		"""
		def call(
			task_input = nil,
			build: nil,
			max_items: nil,
			memory_mbytes: nil,
			timeout_secs: nil,
			webhooks: nil,
			wait_secs: nil
		)
			started_run = start(
				task_input,
				build: build,
				max_items: max_items,
				memory_mbytes: memory_mbytes,
				timeout_secs: timeout_secs,
				webhooks: webhooks
			)

			@root_client.run(started_run['id']).wait_for_finish wait_secs
		end
		
		"""Retrieve the default input for this task.

		https://docs.apify.com/api/v2#/reference/actor-tasks/task-input-object/get-task-input

		Returns:
			dict, optional: Retrieved task input
		"""
		def get_input
			res = @http_client.call url: _url('input'), method: 'GET', params: _params
			res && res[:parsed]
			#return cast(Dict, response.json())
			
		rescue ApifyApiError => exc
			Utils::_catch_not_found_or_throw
		end

		"""Update the default input for this task.

		https://docs.apify.com/api/v2#/reference/actor-tasks/task-input-object/update-task-input

		Returns:
			dict, Retrieved task input
		"""
		### notes: input merged with values already there
		def update_input task_input
			res = @http_client.call(
				url: _url('input'),
				method: 'PUT',
				params: _params,
				json: task_input
			)
			res && res[:parsed]
			#return cast(Dict, response.json())
		end
		
		"""Retrieve a client for the runs of this task."""
		def runs
			RunCollectionClient.new **_sub_resource_init_options(resource_path: 'runs')
		end

		"""Retrieve the client for the last run of this task.

		Last run is retrieved based on the start time of the runs.

		Args:
			status (ActorJobStatus, optional): Consider only runs with this status.
			origin (MetaOrigin, optional): Consider only runs started with this origin.

		Returns:
			RunClient: The resource client for the last run of this task.
		"""
		def last_run status: nil, origin: nil
			RunClient.new(**_sub_resource_init_options(
				resource_id: 'last',
				resource_path: 'runs',
				params: _params(
					status: status, #maybe_extract_enum_member_value(status),
					origin: origin, #maybe_extract_enum_member_value(origin),
				),
			))
		end
	
        """Retrieve a client for webhooks associated with this task."""
		def webhooks
			WebhookCollectionClient.new **_sub_resource_init_options
		end	
	end

	### TaskCollectionClient

	"""Sub-client for manipulating tasks."""
	class TaskCollectionClient < ResourceCollectionClient
		# TODO: RESOURCE_PATH = 'actor-tasks'
		
		"""Initialize the TaskCollectionClient."""
		def initialize **kwargs
			super resource_path: 'actor-tasks', **kwargs
		end
		
		"""List the available tasks.

		https://docs.apify.com/api/v2#/reference/actor-tasks/task-collection/get-list-of-tasks

		Args:
			limit (int, optional): How many tasks to list
			offset (int, optional): What task to include as first when retrieving the list
			desc (bool, optional): Whether to sort the tasks in descending order based on their creation date

		Returns:
			ListPage: The list of available tasks matching the specified filters.
		"""	
		def list limit: nil, offset: nil, desc: nil
			_list limit: limit, offset: offset, desc: desc
		end

		"""Create a new task.

		https://docs.apify.com/api/v2#/reference/actor-tasks/task-collection/create-task

		Args:
			actor_id (str): Id of the actor that should be run
			name (str): Name of the task
			build (str, optional): Actor build to run. It can be either a build tag or build number.
								   By default, the run uses the build specified in the task settings (typically latest).
			memory_mbytes (int, optional): Memory limit for the run, in megabytes.
										   By default, the run uses a memory limit specified in the task settings.
			max_items (int, optional): Maximum number of results that will be returned by runs of this task.
									   If the Actor of this task is charged per result, you will not be charged for more results than the given limit.
			timeout_secs (int, optional): Optional timeout for the run, in seconds. By default, the run uses timeout specified in the task settings.
			task_input (dict, optional): Task input object.
			title (str, optional): A human-friendly equivalent of the name

		Returns:
			dict: The created task.
		"""	
		def create(
			actor_id,
			name,
			build: nil,
			timeout_secs: nil,
			memory_mbytes: nil,
			max_items: nil,
			task_input: nil,
			title: nil
		)
			task_representation = Utils::filter_out_none_values_recursively _get_task_representation(
				actor_id: actor_id,
				name: name,
				task_input: task_input,
				build: build,
				max_items: max_items,
				memory_mbytes: memory_mbytes,
				timeout_secs: timeout_secs,
				title: title
			)

			_create task_representation
		end
	end

end