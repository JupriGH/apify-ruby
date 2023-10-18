=begin
from typing import Any, Dict, Optional

from apify_shared.utils import filter_out_none_values_recursively, ignore_docs, parse_date_fields

from ..._utils import _encode_key_value_store_record_value, _pluck_data, _to_safe_id
from ..base import ActorJobBaseClient, ActorJobBaseClientAsync
from .dataset import DatasetClient, DatasetClientAsync
from .key_value_store import KeyValueStoreClient, KeyValueStoreClientAsync
from .log import LogClient, LogClientAsync
from .request_queue import RequestQueueClient, RequestQueueClientAsync
=end

module Apify

class RunClient < ActorJobBaseClient
    """Sub-client for manipulating a single actor run."""

    def initialize **kwargs
        """Initialize the RunClient."""
        super resource_path: 'actor-runs', **kwargs
	end
	
    def get
        """Return information about the actor run.

        https://docs.apify.com/api/v2#/reference/actor-runs/run-object/get-run

        Returns:
            dict: The retrieved actor run data
        """
        _get
	end
	
=begin
    def update(self, *, status_message: Optional[str] = None, is_status_message_terminal: Optional[bool] = None) -> Dict:
        """Update the run with the specified fields.

        https://docs.apify.com/api/v2#/reference/actor-runs/run-object/update-run

        Args:
            status_message (str, optional): The new status message for the run
            is_status_message_terminal (bool, optional): Set this flag to True if this is the final status message of the Actor run.

        Returns:
            dict: The updated run
        """
        updated_fields = {
            'statusMessage': status_message,
            'isStatusMessageTerminal': is_status_message_terminal,
        }

        return self._update(filter_out_none_values_recursively(updated_fields))

    def delete(self) -> None:
        """Delete the run.

        https://docs.apify.com/api/v2#/reference/actor-runs/delete-run/delete-run
        """
        return self._delete()

    def abort(self, *, gracefully: Optional[bool] = None) -> Dict:
        """Abort the actor run which is starting or currently running and return its details.

        https://docs.apify.com/api/v2#/reference/actor-runs/abort-run/abort-run

        Args:
            gracefully (bool, optional): If True, the actor run will abort gracefully.
                It will send ``aborting`` and ``persistStates`` events into the run and force-stop the run after 30 seconds.
                It is helpful in cases where you plan to resurrect the run later.

        Returns:
            dict: The data of the aborted actor run
        """
        return self._abort(gracefully=gracefully)

    def wait_for_finish(self, *, wait_secs: Optional[int] = None) -> Optional[Dict]:
        """Wait synchronously until the run finishes or the server times out.

        Args:
            wait_secs (int, optional): how long does the client wait for run to finish. None for indefinite.

        Returns:
            dict, optional: The actor run data. If the status on the object is not one of the terminal statuses
                (SUCEEDED, FAILED, TIMED_OUT, ABORTED), then the run has not yet finished.
        """
        return self._wait_for_finish(wait_secs=wait_secs)

    def metamorph(
        self,
        *,
        target_actor_id: str,
        target_actor_build: Optional[str] = None,
        run_input: Optional[Any] = None,
        content_type: Optional[str] = None,
    ) -> Dict:
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

    def resurrect(
        self,
        *,
        build: Optional[str] = None,
        memory_mbytes: Optional[int] = None,
        timeout_secs: Optional[int] = None,
    ) -> Dict:
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
        request_params = self._params(
            build=build,
            memory=memory_mbytes,
            timeout=timeout_secs,
        )

        response = self.http_client.call(
            url=self._url('resurrect'),
            method='POST',
            params=request_params,
        )

        return parse_date_fields(_pluck_data(response.json()))
	
    def reboot(self) -> Dict:
        """Reboot an Actor run. Only runs that are running, i.e. runs with status RUNNING can be rebooted.

        https://docs.apify.com/api/v2#/reference/actor-runs/reboot-run/reboot-run

        Returns:
            dict: The Actor run data.
        """
        response = self.http_client.call(
            url=self._url('reboot'),
            method='POST',
        )
        return parse_date_fields(_pluck_data(response.json()))
=end
    def dataset
        """Get the client for the default dataset of the actor run.

        https://docs.apify.com/api/v2#/reference/actors/last-run-object-and-its-storages

        Returns:
            DatasetClient: A client allowing access to the default dataset of this actor run.
        """
        DatasetClient.new **_sub_resource_init_options(resource_path: 'dataset')
	end

    def key_value_store
        """Get the client for the default key-value store of the actor run.

        https://docs.apify.com/api/v2#/reference/actors/last-run-object-and-its-storages

        Returns:
            KeyValueStoreClient: A client allowing access to the default key-value store of this actor run.
        """
        KeyValueStoreClient.new  **_sub_resource_init_options(resource_path: 'key-value-store')
	end
	
    def request_queue
        """Get the client for the default request queue of the actor run.

        https://docs.apify.com/api/v2#/reference/actors/last-run-object-and-its-storages

        Returns:
            RequestQueueClient: A client allowing access to the default request_queue of this actor run.
        """
        RequestQueueClient.new **_sub_resource_init_options(resource_path: 'request-queue')
	end
	
    def log
        """Get the client for the log of the actor run.

        https://docs.apify.com/api/v2#/reference/actors/last-run-object-and-its-storages

        Returns:
            LogClient: A client allowing access to the log of this actor run.
        """
        LogClient.new **_sub_resource_init_options(resource_path: 'log')
	end
end

=begin

from typing import Any, Dict, Optional

from apify_shared.consts import ActorJobStatus
from apify_shared.models import ListPage
from apify_shared.utils import ignore_docs, maybe_extract_enum_member_value

from ..base import ResourceCollectionClient, ResourceCollectionClientAsync
=end

class RunCollectionClient < ResourceCollectionClient
    """Sub-client for listing actor runs."""

    def initialize **kwargs
        """Initialize the RunCollectionClient."""
        super resource_path: 'actor-runs', **kwargs
	end
	
    def list(
        limit: nil,
        offset: nil,
        desc: nil,
        status: nil
    )
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
        _list limit: limit, offset: offset, desc: desc #, status: maybe_extract_enum_member_value(status)
	end
end

end