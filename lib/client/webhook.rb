
"""Prepare webhook dictionary representation for clients."""
def _get_webhook_representation(
    event_types: nil,
    request_url: nil,
    payload_template: nil,
    actor_id: nil,
    actor_task_id: nil,
    actor_run_id: nil,
    ignore_ssl_errors: nil,
    do_not_retry: nil,
    idempotency_key: nil,
    is_ad_hoc: nil
)
    webhook = {
        requestUrl: request_url,
        payloadTemplate: payload_template,
        ignoreSslErrors: ignore_ssl_errors,
        doNotRetry: do_not_retry,
        idempotencyKey: idempotency_key,
        isAdHoc: is_ad_hoc,
        condition: {
            actorRunId: actor_run_id,
            actorTaskId: actor_task_id,
            actorId: actor_id,
        },
    }

    webhook[:isAdHoc] = true if actor_run_id

	### TODO:
	
    #if event_types
    #    webhook[:eventTypes] = [maybe_extract_enum_member_value(event_type) for event_type in event_types]
	#end
	
    webhook
end

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
		def update(
			event_types: nil,
			request_url: nil,
			payload_template: nil,
			actor_id: nil,
			actor_task_id: nil,
			actor_run_id: nil,
			ignore_ssl_errors: nil,
			do_not_retry: nil,
			is_ad_hoc: nil
		)
			webhook_representation = Utils::filter_out_none_values_recursively _get_webhook_representation(
				event_types: event_types,
				request_url: request_url,
				payload_template: payload_template,
				actor_id: actor_id,
				actor_task_id: actor_task_id,
				actor_run_id: actor_run_id,
				ignore_ssl_errors: ignore_ssl_errors,
				do_not_retry: do_not_retry,
				is_ad_hoc: is_ad_hoc
			)

			_update webhook_representation
		end


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
		def test
			res = @http_client.call url: _url('test'), method: 'POST', params: _params
			res && res.dig(:parsed, 'data')
			#return parse_date_fields(_pluck_data(response.json()))

		rescue ApifyApiError => exc
			Utils::_catch_not_found_or_throw exc
		end
		
		"""Get dispatches of the webhook.

		https://docs.apify.com/api/v2#/reference/webhooks/dispatches-collection/get-collection

		Returns:
			WebhookDispatchCollectionClient: A client allowing access to dispatches of this webhook using its list method
		"""
		def dispatches = WebhookDispatchCollectionClient(**_sub_resource_init_options(resource_path: 'dispatches'))

	end

	### WebhookCollectionClient
	
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
		def create(
			event_types,
			request_url,
			payload_template: nil,
			actor_id: nil,
			actor_task_id: nil,
			actor_run_id: nil,
			ignore_ssl_errors: nil,
			do_not_retry: nil,
			idempotency_key: nil,
			is_ad_hoc: nil
		)
			webhook_representation = Utils::filter_out_none_values_recursively _get_webhook_representation(
				event_types: event_types,
				request_url: request_url,
				payload_template: payload_template,
				actor_id: actor_id,
				actor_task_id: actor_task_id,
				actor_run_id: actor_run_id,
				ignore_ssl_errors: ignore_ssl_errors,
				do_not_retry: do_not_retry,
				idempotency_key: idempotency_key,
				is_ad_hoc: is_ad_hoc,
			)

			_create webhook_representation
		end
	end
end