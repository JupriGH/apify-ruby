=begin
from apify_shared.consts import WebhookEventType
from apify_shared.utils import filter_out_none_values_recursively, ignore_docs, maybe_extract_enum_member_value, parse_date_fields

from ..._errors import ApifyApiError
from ..._utils import _catch_not_found_or_throw, _pluck_data
from .webhook_dispatch_collection import WebhookDispatchCollectionClient, WebhookDispatchCollectionClientAsync
=end

=begin
def _get_webhook_representation(
    *,
    event_types: Optional[List[WebhookEventType]] = None,
    request_url: Optional[str] = None,
    payload_template: Optional[str] = None,
    actor_id: Optional[str] = None,
    actor_task_id: Optional[str] = None,
    actor_run_id: Optional[str] = None,
    ignore_ssl_errors: Optional[bool] = None,
    do_not_retry: Optional[bool] = None,
    idempotency_key: Optional[str] = None,
    is_ad_hoc: Optional[bool] = None,
) -> Dict:
    """Prepare webhook dictionary representation for clients."""
    webhook: Dict[str, Any] = {
        'requestUrl': request_url,
        'payloadTemplate': payload_template,
        'ignoreSslErrors': ignore_ssl_errors,
        'doNotRetry': do_not_retry,
        'idempotencyKey': idempotency_key,
        'isAdHoc': is_ad_hoc,
        'condition': {
            'actorRunId': actor_run_id,
            'actorTaskId': actor_task_id,
            'actorId': actor_id,
        },
    }

    if actor_run_id is not None:
        webhook['isAdHoc'] = True

    if event_types is not None:
        webhook['eventTypes'] = [maybe_extract_enum_member_value(event_type) for event_type in event_types]

    return webhook
=end

module Apify

	"""Sub-client for manipulating a single webhook."""
	class WebhookClient < ResourceClient

		"""Initialize the WebhookClient."""
		def initialize **kwargs
			super resource_path: 'webhooks', **kwargs
		end

		"""Retrieve the webhook.

		https://docs.apify.com/api/v2#/reference/webhooks/webhook-object/get-webhook

		Returns:
			dict, optional: The retrieved webhook, or None if it does not exist
		"""		
		def get = _get
		
		"""Update the webhook.

		https://docs.apify.com/api/v2#/reference/webhooks/webhook-object/update-webhook

		Args:
			event_types (list of WebhookEventType, optional): List of event types that should trigger the webhook. At least one is required.
			request_url (str, optional): URL that will be invoked once the webhook is triggered.
			payload_template (str, optional): Specification of the payload that will be sent to request_url
			actor_id (str, optional): Id of the actor whose runs should trigger the webhook.
			actor_task_id (str, optional): Id of the actor task whose runs should trigger the webhook.
			actor_run_id (str, optional): Id of the actor run which should trigger the webhook.
			ignore_ssl_errors (bool, optional): Whether the webhook should ignore SSL errors returned by request_url
			do_not_retry (bool, optional): Whether the webhook should retry sending the payload to request_url upon
										   failure.
			is_ad_hoc (bool, optional): Set to True if you want the webhook to be triggered only the first time the
										condition is fulfilled. Only applicable when actor_run_id is filled.

		Returns:
			dict: The updated webhook
		"""
=begin
		def update(
			self,
			*,
			event_types: Optional[List[WebhookEventType]] = None,
			request_url: Optional[str] = None,
			payload_template: Optional[str] = None,
			actor_id: Optional[str] = None,
			actor_task_id: Optional[str] = None,
			actor_run_id: Optional[str] = None,
			ignore_ssl_errors: Optional[bool] = None,
			do_not_retry: Optional[bool] = None,
			is_ad_hoc: Optional[bool] = None,
		) -> Dict:
			webhook_representation = _get_webhook_representation(
				event_types=event_types,
				request_url=request_url,
				payload_template=payload_template,
				actor_id=actor_id,
				actor_task_id=actor_task_id,
				actor_run_id=actor_run_id,
				ignore_ssl_errors=ignore_ssl_errors,
				do_not_retry=do_not_retry,
				is_ad_hoc=is_ad_hoc,
			)

			return self._update(filter_out_none_values_recursively(webhook_representation))
=end


		"""Delete the webhook.

		https://docs.apify.com/api/v2#/reference/webhooks/webhook-object/delete-webhook
		"""
		def delete = _delete


		"""Test a webhook.

		Creates a webhook dispatch with a dummy payload.

		https://docs.apify.com/api/v2#/reference/webhooks/webhook-test/test-webhook

		Returns:
			dict, optional: The webhook dispatch created by the test
		"""
=begin
		def test(self) -> Optional[Dict]:
			try:
				response = self.http_client.call(
					url=self._url('test'),
					method='POST',
					params=self._params(),
				)

				return parse_date_fields(_pluck_data(response.json()))

			except ApifyApiError as exc:
				_catch_not_found_or_throw(exc)

			return None
=end

		"""Get dispatches of the webhook.

		https://docs.apify.com/api/v2#/reference/webhooks/dispatches-collection/get-collection

		Returns:
			WebhookDispatchCollectionClient: A client allowing access to dispatches of this webhook using its list method
		"""
=begin
		def dispatches(self) -> WebhookDispatchCollectionClient:
			return WebhookDispatchCollectionClient(
				**self._sub_resource_init_options(resource_path='dispatches'),
			)
=end
	end

	### WebhookCollectionClient
	
=begin
from apify_shared.consts import WebhookEventType
from apify_shared.models import ListPage
from apify_shared.utils import filter_out_none_values_recursively, ignore_docs

=end
	
	
	
	"""Sub-client for manipulating webhooks."""
	class WebhookCollectionClient < ResourceCollectionClient

		"""Initialize the WebhookCollectionClient."""
		def initialize **kwargs
			super resource_path: 'webhooks', **kwargs
		end

		"""List the available webhooks.

		https://docs.apify.com/api/v2#/reference/webhooks/webhook-collection/get-list-of-webhooks

		Args:
			limit (int, optional): How many webhooks to retrieve
			offset (int, optional): What webhook to include as first when retrieving the list
			desc (bool, optional): Whether to sort the webhooks in descending order based on their date of creation

		Returns:
			ListPage: The list of available webhooks matching the specified filters.
		"""
		def list limit: nil, offset: nil, desc: nil
			_list limit: limit, offset: offset, desc: desc
		end

		"""Create a new webhook.

		You have to specify exactly one out of actor_id, actor_task_id or actor_run_id.

		https://docs.apify.com/api/v2#/reference/webhooks/webhook-collection/create-webhook

		Args:
			event_types (list of WebhookEventType): List of event types that should trigger the webhook. At least one is required.
			request_url (str): URL that will be invoked once the webhook is triggered.
			payload_template (str, optional): Specification of the payload that will be sent to request_url
			actor_id (str, optional): Id of the actor whose runs should trigger the webhook.
			actor_task_id (str, optional): Id of the actor task whose runs should trigger the webhook.
			actor_run_id (str, optional): Id of the actor run which should trigger the webhook.
			ignore_ssl_errors (bool, optional): Whether the webhook should ignore SSL errors returned by request_url
			do_not_retry (bool, optional): Whether the webhook should retry sending the payload to request_url upon
										   failure.
			idempotency_key (str, optional): A unique identifier of a webhook. You can use it to ensure that you won't
											 create the same webhook multiple times.
			is_ad_hoc (bool, optional): Set to True if you want the webhook to be triggered only the first time the
										condition is fulfilled. Only applicable when actor_run_id is filled.

		Returns:
			dict: The created webhook
		"""
=begin
		def create(
			self,
			*,
			event_types: List[WebhookEventType],
			request_url: str,
			payload_template: Optional[str] = None,
			actor_id: Optional[str] = None,
			actor_task_id: Optional[str] = None,
			actor_run_id: Optional[str] = None,
			ignore_ssl_errors: Optional[bool] = None,
			do_not_retry: Optional[bool] = None,
			idempotency_key: Optional[str] = None,
			is_ad_hoc: Optional[bool] = None,
		) -> Dict:
			webhook_representation = _get_webhook_representation(
				event_types=event_types,
				request_url=request_url,
				payload_template=payload_template,
				actor_id=actor_id,
				actor_task_id=actor_task_id,
				actor_run_id=actor_run_id,
				ignore_ssl_errors=ignore_ssl_errors,
				do_not_retry=do_not_retry,
				idempotency_key=idempotency_key,
				is_ad_hoc=is_ad_hoc,
			)

			return self._create(filter_out_none_values_recursively(webhook_representation))
=end
	end
end