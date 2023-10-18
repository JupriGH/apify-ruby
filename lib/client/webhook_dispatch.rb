module Apify

class WebhookDispatchClient < ResourceClient
    """Sub-client for querying information about a webhook dispatch."""

    def initialize **kwargs
        """Initialize the WebhookDispatchClient."""
        super resource_path: 'webhook-dispatches', **kwargs
	end
	
    def get
        """Retrieve the webhook dispatch.

        https://docs.apify.com/api/v2#/reference/webhook-dispatches/webhook-dispatch-object/get-webhook-dispatch

        Returns:
            dict, optional: The retrieved webhook dispatch, or None if it does not exist
        """
        _get
	end
end

class WebhookDispatchCollectionClient < ResourceCollectionClient
    """Sub-client for listing webhook dispatches."""

    def initialize **kwargs
        """Initialize the WebhookDispatchCollectionClient."""
        super resource_path: 'webhook-dispatches', **kwargs
	end

    def list limit: nil, offset: nil, desc: nil
        """List all webhook dispatches of a user.

        https://docs.apify.com/api/v2#/reference/webhook-dispatches/webhook-dispatches-collection/get-list-of-webhook-dispatches

        Args:
            limit (int, optional): How many webhook dispatches to retrieve
            offset (int, optional): What webhook dispatch to include as first when retrieving the list
            desc (bool, optional): Whether to sort the webhook dispatches in descending order based on the date of their creation

        Returns:
            ListPage: The retrieved webhook dispatches of a user
        """
        _list limit: limit, offset: offset, desc: desc
	end
end

end