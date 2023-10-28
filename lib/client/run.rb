module Apify

	"""Sub-client for manipulating a single actor run."""
	class RunClient < ActorJobBaseClient

		"""Initialize the RunClient."""
		def initialize(**kwargs) = super resource_path: 'actor-runs', **kwargs

		"""Return information about the actor run.

		https://docs.apify.com/api/v2#/reference/actor-runs/run-object/get-run

		Returns:
			dict: The retrieved actor run data
		"""		
		def get = _get

		"""Update the run with the specified fields.

		https://docs.apify.com/api/v2#/reference/actor-runs/run-object/update-run

		Args:
			status_message (str, optional): The new status message for the run
			is_status_message_terminal (bool, optional): Set this flag to True if this is the final status message of the Actor run.

		Returns:
			dict: The updated run
		"""
		def update status_message: nil, is_status_message_terminal: nil
			_update ({statusMessage: status_message, isStatusMessageTerminal: is_status_message_terminal})
		end

		"""Delete the run.

		https://docs.apify.com/api/v2#/reference/actor-runs/delete-run/delete-run
		"""		
		def delete = _delete

		"""Abort the actor run which is starting or currently running and return its details.

		https://docs.apify.com/api/v2#/reference/actor-runs/abort-run/abort-run

		Args:
			gracefully (bool, optional): If True, the actor run will abort gracefully.
				It will send ``aborting`` and ``persistStates`` events into the run and force-stop the run after 30 seconds.
				It is helpful in cases where you plan to resurrect the run later.

		Returns:
			dict: The data of the aborted actor run
		"""		
		def abort(gracefully=false) = _abort gracefully

		"""Wait synchronously until the run finishes or the server times out.

		Args:
			wait_secs (int, optional): how long does the client wait for run to finish. None for indefinite.

		Returns:
			dict, optional: The actor run data. If the status on the object is not one of the terminal statuses
				(SUCEEDED, FAILED, TIMED_OUT, ABORTED), then the run has not yet finished.
		"""		
		def wait_for_finish(wait_secs=nil) = _wait_for_finish wait_secs

		"""Transform an actor run into a run of another actor with a new input.

		https://docs.apify.com/api/v2#/reference/actor-runs/metamorph-run/metamorph-run

		Args:
			target_actor_id (str): ID of the target actor that the run should be transformed into
			target_actor_build (str, optional): The build of the target actor. It can be either a build tag or build number.
				By default, the run uses the build specified in the default run configuration for the target actor (typically the latest build).
			run_input (Any, optional): The input to pass to the new run.
			content_type (str, optional): The content type of the input.

		Returns:
			dict: The actor run data.
		"""
=begin
		def metamorph(
			self,
			*,
			target_actor_id: str,
			target_actor_build: Optional[str] = None,
			run_input: Optional[Any] = None,
			content_type: Optional[str] = None,
		) -> Dict:
			run_input, content_type = _encode_key_value_store_record_value(run_input, content_type)

			safe_target_actor_id = _to_safe_id(target_actor_id)

			request_params = self._params(
				targetActorId=safe_target_actor_id,
				build=target_actor_build,
			)

			response = self.http_client.call(
				url=self._url('metamorph'),
				method='POST',
				headers={'content-type': content_type},
				data=run_input,
				params=request_params,
			)

			return parse_date_fields(_pluck_data(response.json()))
=end

		"""Resurrect a finished actor run.

		Only finished runs, i.e. runs with status FINISHED, FAILED, ABORTED and TIMED-OUT can be resurrected.
		Run status will be updated to RUNNING and its container will be restarted with the same default storages.

		https://docs.apify.com/api/v2#/reference/actor-runs/resurrect-run/resurrect-run

		Args:
			build (str, optional): Which actor build the resurrected run should use. It can be either a build tag or build number.
								   By default, the resurrected run uses the same build as before.
			memory_mbytes (int, optional): New memory limit for the resurrected run, in megabytes.
										   By default, the resurrected run uses the same memory limit as before.
			timeout_secs (int, optional): New timeout for the resurrected run, in seconds.
										   By default, the resurrected run uses the same timeout as before.

		Returns:
			dict: The actor run data.
		"""
		def resurrect build: nil, memory_mbytes: nil, timeout_secs: nil
			_http_post 'resurrect', params: _params(build: build, memory: memory_mbytes, timeout: timeout_secs), pluck_data: true
		end

		"""Reboot an Actor run. Only runs that are running, i.e. runs with status RUNNING can be rebooted.

		https://docs.apify.com/api/v2#/reference/actor-runs/reboot-run/reboot-run

		Returns:
			dict: The Actor run data.
		"""
		def reboot = _http_post 'reboot', pluck_data: true

		"""Get the client for the default dataset of the actor run.

		https://docs.apify.com/api/v2#/reference/actors/last-run-object-and-its-storages

		Returns:
			DatasetClient: A client allowing access to the default dataset of this actor run.
		"""
		def dataset
			DatasetClient.new **_sub_resource_init_options(resource_path: 'dataset')
		end

		"""Get the client for the default key-value store of the actor run.

		https://docs.apify.com/api/v2#/reference/actors/last-run-object-and-its-storages

		Returns:
			KeyValueStoreClient: A client allowing access to the default key-value store of this actor run.
		"""
		def key_value_store
			KeyValueStoreClient.new  **_sub_resource_init_options(resource_path: 'key-value-store')
		end

		"""Get the client for the default request queue of the actor run.

		https://docs.apify.com/api/v2#/reference/actors/last-run-object-and-its-storages

		Returns:
			RequestQueueClient: A client allowing access to the default request_queue of this actor run.
		"""		
		def request_queue
			RequestQueueClient.new **_sub_resource_init_options(resource_path: 'request-queue')
		end

		"""Get the client for the log of the actor run.

		https://docs.apify.com/api/v2#/reference/actors/last-run-object-and-its-storages

		Returns:
			LogClient: A client allowing access to the log of this actor run.
		"""		
		def log
			LogClient.new **_sub_resource_init_options(resource_path: 'log')
		end
	end

	### RunCollectionClient

	"""Sub-client for listing actor runs."""
	class RunCollectionClient < ResourceCollectionClient

		"""Initialize the RunCollectionClient."""
		def initialize(**kwargs) = super resource_path: 'actor-runs', **kwargs

		"""List all actor runs (either of a single actor, or all user's actors, depending on where this client was initialized from).

		https://docs.apify.com/api/v2#/reference/actors/run-collection/get-list-of-runs

		https://docs.apify.com/api/v2#/reference/actor-runs/run-collection/get-user-runs-list

		Args:
			limit (int, optional): How many runs to retrieve
			offset (int, optional): What run to include as first when retrieving the list
			desc (bool, optional): Whether to sort the runs in descending order based on their start date
			status (ActorJobStatus, optional): Retrieve only runs with the provided status

		Returns:
			ListPage: The retrieved actor runs
		"""		
		def list limit: nil, offset: nil, desc: nil, status: nil
			_list limit: limit, offset: offset, desc: desc, status: status # Utils::maybe_extract_enum_member_value(status)
		end
	end
end