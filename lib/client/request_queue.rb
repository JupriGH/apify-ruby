from typing import Any, Dict, List, Optional

from apify_shared.utils import filter_out_none_values_recursively, ignore_docs, parse_date_fields

from ..._errors import ApifyApiError
from ..._utils import _catch_not_found_or_throw, _pluck_data
from ..base import ResourceClient, ResourceClientAsync

module Apify

=begin

class RequestQueueClient(ResourceClient):
    """Sub-client for manipulating a single request queue."""

    @ignore_docs
    def __init__(self, *args: Any, client_key: Optional[str] = None, **kwargs: Any) -> None:
        """Initialize the RequestQueueClient.

        Args:
            client_key (str, optional): A unique identifier of the client accessing the request queue
        """
        resource_path = kwargs.pop('resource_path', 'request-queues')
        super().__init__(*args, resource_path=resource_path, **kwargs)
        self.client_key = client_key

    def get(self) -> Optional[Dict]:
        """Retrieve the request queue.

        https://docs.apify.com/api/v2#/reference/request-queues/queue/get-request-queue

        Returns:
            dict, optional: The retrieved request queue, or None, if it does not exist
        """
        return self._get()

    def update(self, *, name: Optional[str] = None) -> Dict:
        """Update the request queue with specified fields.

        https://docs.apify.com/api/v2#/reference/request-queues/queue/update-request-queue

        Args:
            name (str, optional): The new name for the request queue

        Returns:
            dict: The updated request queue
        """
        updated_fields = {
            'name': name,
        }

        return self._update(filter_out_none_values_recursively(updated_fields))

    def delete(self) -> None:
        """Delete the request queue.

        https://docs.apify.com/api/v2#/reference/request-queues/queue/delete-request-queue
        """
        return self._delete()

    def list_head(self, *, limit: Optional[int] = None) -> Dict:
        """Retrieve a given number of requests from the beginning of the queue.

        https://docs.apify.com/api/v2#/reference/request-queues/queue-head/get-head

        Args:
            limit (int, optional): How many requests to retrieve

        Returns:
            dict: The desired number of requests from the beginning of the queue.
        """
        request_params = self._params(limit=limit, clientKey=self.client_key)

        response = self.http_client.call(
            url=self._url('head'),
            method='GET',
            params=request_params,
        )

        return parse_date_fields(_pluck_data(response.json()))

    def list_and_lock_head(self, *, lock_secs: int, limit: Optional[int] = None) -> Dict:
        """Retrieve a given number of unlocked requests from the beginning of the queue and lock them for a given time.

        https://docs.apify.com/api/v2#/reference/request-queues/queue-head-with-locks/get-head-and-lock

        Args:
            lock_secs (int): How long the requests will be locked for, in seconds
            limit (int, optional): How many requests to retrieve


        Returns:
            dict: The desired number of locked requests from the beginning of the queue.
        """
        request_params = self._params(lockSecs=lock_secs, limit=limit, clientKey=self.client_key)

        response = self.http_client.call(
            url=self._url('head/lock'),
            method='POST',
            params=request_params,
        )

        return parse_date_fields(_pluck_data(response.json()))

    def add_request(self, request: Dict, *, forefront: Optional[bool] = None) -> Dict:
        """Add a request to the queue.

        https://docs.apify.com/api/v2#/reference/request-queues/request-collection/add-request

        Args:
            request (dict): The request to add to the queue
            forefront (bool, optional): Whether to add the request to the head or the end of the queue

        Returns:
            dict: The added request.
        """
        request_params = self._params(
            forefront=forefront,
            clientKey=self.client_key,
        )

        response = self.http_client.call(
            url=self._url('requests'),
            method='POST',
            json=request,
            params=request_params,
        )

        return parse_date_fields(_pluck_data(response.json()))

    def get_request(self, request_id: str) -> Optional[Dict]:
        """Retrieve a request from the queue.

        https://docs.apify.com/api/v2#/reference/request-queues/request/get-request

        Args:
            request_id (str): ID of the request to retrieve

        Returns:
            dict, optional: The retrieved request, or None, if it did not exist.
        """
        try:
            response = self.http_client.call(
                url=self._url(f'requests/{request_id}'),
                method='GET',
                params=self._params(),
            )
            return parse_date_fields(_pluck_data(response.json()))

        except ApifyApiError as exc:
            _catch_not_found_or_throw(exc)

        return None

    def update_request(self, request: Dict, *, forefront: Optional[bool] = None) -> Dict:
        """Update a request in the queue.

        https://docs.apify.com/api/v2#/reference/request-queues/request/update-request

        Args:
            request (dict): The updated request
            forefront (bool, optional): Whether to put the updated request in the beginning or the end of the queue

        Returns:
            dict: The updated request
        """
        request_id = request['id']

        request_params = self._params(
            forefront=forefront,
            clientKey=self.client_key,
        )

        response = self.http_client.call(
            url=self._url(f'requests/{request_id}'),
            method='PUT',
            json=request,
            params=request_params,
        )

        return parse_date_fields(_pluck_data(response.json()))

    def delete_request(self, request_id: str) -> None:
        """Delete a request from the queue.

        https://docs.apify.com/api/v2#/reference/request-queues/request/delete-request

        Args:
            request_id (str): ID of the request to delete.
        """
        request_params = self._params(
            clientKey=self.client_key,
        )

        self.http_client.call(
            url=self._url(f'requests/{request_id}'),
            method='DELETE',
            params=request_params,
        )

    def prolong_request_lock(self, request_id: str, *, forefront: Optional[bool] = None, lock_secs: int) -> Dict:
        """Prolong the lock on a request.

        https://docs.apify.com/api/v2#/reference/request-queues/request-lock/prolong-request-lock

        Args:
            request_id (str): ID of the request to prolong the lock
            forefront (bool, optional): Whether to put the request in the beginning or the end of the queue after lock expires
            lock_secs (int): By how much to prolong the lock, in seconds
        """
        request_params = self._params(
            clientKey=self.client_key,
            forefront=forefront,
            lockSecs=lock_secs,
        )

        response = self.http_client.call(
            url=self._url(f'requests/{request_id}/lock'),
            method='PUT',
            params=request_params,
        )

        return parse_date_fields(_pluck_data(response.json()))

    def delete_request_lock(self, request_id: str, *, forefront: Optional[bool] = None) -> None:
        """Delete the lock on a request.

        https://docs.apify.com/api/v2#/reference/request-queues/request-lock/delete-request-lock

        Args:
            request_id (str): ID of the request to delete the lock
            forefront (bool, optional): Whether to put the request in the beginning or the end of the queue after the lock is deleted
        """
        request_params = self._params(
            clientKey=self.client_key,
            forefront=forefront,
        )

        self.http_client.call(
            url=self._url(f'requests/{request_id}/lock'),
            method='DELETE',
            params=request_params,
        )

    def batch_add_requests(self, requests: List[Dict[str, Any]], *, forefront: Optional[bool] = None) -> Dict:
        """Add requests to the queue.

        https://docs.apify.com/api/v2#/reference/request-queues/batch-request-operations/add-requests

        Args:
            requests (List[Dict[str, Any]]): List of the requests to add
            forefront (bool, optional): Whether to add the requests to the head or the end of the queue
        """
        request_params = self._params(
            clientKey=self.client_key,
            forefront=forefront,
        )

        response = self.http_client.call(
            url=self._url('requests/batch'),
            method='POST',
            params=request_params,
            json=requests,
        )
        return parse_date_fields(_pluck_data(response.json()))

    def batch_delete_requests(self, requests: List[Dict[str, Any]]) -> Dict:
        """Delete given requests from the queue.

        https://docs.apify.com/api/v2#/reference/request-queues/batch-request-operations/delete-requests

        Args:
            requests (List[Dict[str, Any]]): List of the requests to delete
        """
        request_params = self._params(
            clientKey=self.client_key,
        )

        response = self.http_client.call(
            url=self._url('requests/batch'),
            method='DELETE',
            params=request_params,
            json=requests,
        )

        return parse_date_fields(_pluck_data(response.json()))

    def list_requests(self, *, limit: Optional[int] = None, exclusive_start_id: Optional[str] = None) -> Dict:
        """List requests in the queue.

        https://docs.apify.com/api/v2#/reference/request-queues/request-collection/list-requests

        Args:
            limit (int, optional): How many requests to retrieve
            exclusive_start_id (str, optional): All requests up to this one (including) are skipped from the result
        """
        request_params = self._params(limit=limit, exclusive_start_id=exclusive_start_id, clientKey=self.client_key)

        response = self.http_client.call(
            url=self._url('requests'),
            method='GET',
            params=request_params,
        )

        return parse_date_fields(_pluck_data(response.json()))

from typing import Any, Dict, Optional

from apify_shared.models import ListPage
from apify_shared.utils import ignore_docs

from ..base import ResourceCollectionClient, ResourceCollectionClientAsync


class RequestQueueCollectionClient(ResourceCollectionClient):
    """Sub-client for manipulating request queues."""

    @ignore_docs
    def __init__(self, *args: Any, **kwargs: Any) -> None:
        """Initialize the RequestQueueCollectionClient with the passed arguments."""
        resource_path = kwargs.pop('resource_path', 'request-queues')
        super().__init__(*args, resource_path=resource_path, **kwargs)

    def list(
        self,
        *,
        unnamed: Optional[bool] = None,
        limit: Optional[int] = None,
        offset: Optional[int] = None,
        desc: Optional[bool] = None,
    ) -> ListPage[Dict]:
        """List the available request queues.

        https://docs.apify.com/api/v2#/reference/request-queues/queue-collection/get-list-of-request-queues

        Args:
            unnamed (bool, optional): Whether to include unnamed request queues in the list
            limit (int, optional): How many request queues to retrieve
            offset (int, optional): What request queue to include as first when retrieving the list
            desc (bool, optional): Whether to sort therequest queues in descending order based on their modification date

        Returns:
            ListPage: The list of available request queues matching the specified filters.
        """
        return self._list(unnamed=unnamed, limit=limit, offset=offset, desc=desc)

    def get_or_create(self, *, name: Optional[str] = None) -> Dict:
        """Retrieve a named request queue, or create a new one when it doesn't exist.

        https://docs.apify.com/api/v2#/reference/request-queues/queue-collection/create-request-queue

        Args:
            name (str, optional): The name of the request queue to retrieve or create.

        Returns:
            dict: The retrieved or newly-created request queue.
        """
        return self._get_or_create(name=name)

=end

end