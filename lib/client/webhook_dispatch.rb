module Apify

	"""Sub-client for querying information about a webhook dispatch."""
	class WebhookDispatchClient < ResourceClient

		"""Initialize the WebhookDispatchClient."""
		def initialize(**kwargs) = super(resource_path: 'webhook-dispatches', **kwargs)

		"""Retrieve the webhook dispatch.

		https://docs.apify.com/api/v2#/reference/webhook-dispatches/webhook-dispatch-object/get-webhook-dispatch

		Returns:
			dict, optional: The retrieved webhook dispatch, or None if it does not exist
		"""		
		def get = _get
	end

	### WebhookDispatchCollectionClient

	"""Sub-client for listing webhook dispatches."""
	class WebhookDispatchCollectionClient < ResourceCollectionClient

		"""Initialize the WebhookDispatchCollectionClient."""
		def initialize(**kwargs) = super resource_path: 'webhook-dispatches', **kwargs

		"""List all webhook dispatches of a user.

		https://docs.apify.com/api/v2#/reference/webhook-dispatches/webhook-dispatches-collection/get-list-of-webhook-dispatches

		Args:
			limit (int, optional): How many webhook dispatches to retrieve
			offset (int, optional): What webhook dispatch to include as first when retrieving the list
			desc (bool, optional): Whether to sort the webhook dispatches in descending order based on the date of their creation

		Returns:
			ListPage: The retrieved webhook dispatches of a user
		"""
		def list limit: nil, offset: nil, desc: nil
			_list limit: limit, offset: offset, desc: desc
		end
	end

end