require_relative '../utils'

module Apify

class BaseBaseClient # (metaclass=_WithLogDetailsClient):
    @resource_id
    @url
    @params
    @http_client
    @root_client

	@safe_id # added by Jupri

    def _url path: nil
        path ? "#{@url}/#{path}" : @url
	end
	
    def _params **kwargs
        { **(@params||{}) ,  **(kwargs||{}) }
	end

    def _sub_resource_init_options **kwargs
        { base_url: @url, http_client: @http_client, params: @params, root_client: @root_client, **kwargs }
	end

end 

class BaseClient < BaseBaseClient
    """Base class for sub-clients."""

    @http_client # _HTTPClient
    @root_client # ApifyClient

    def initialize (
        base_url: nil,
        root_client: nil,
        http_client: nil,
        resource_id: nil,
        resource_path: nil,
        params: nil
    )
        """Initialize the sub-client.

        Args:
            base_url (str): Base URL of the API server
            root_client (ApifyClient): The ApifyClient instance under which this resource client exists
            http_client (_HTTPClient): The _HTTPClient instance to be used in this client
            resource_id (str): ID of the manipulated resource, in case of a single-resource client
            resource_path (str): Path to the resource's endpoint on the API server
            params (dict): Parameters to include in all requests from this client
        """
        # if resource_path.endswith('/'):
        #    raise ValueError('resource_path must not end with "/"')

        @base_url 		= base_url
        @root_client 	= root_client
        @http_client 	= http_client
        @params 		= params or {}
        @resource_path	= resource_path
        @resource_id 	= resource_id
        
		@url = "#{@base_url}/#{@resource_path}"
        
		if resource_id
            safe_id = Utils._to_safe_id(resource_id)
            @url = "#{@url}/#{safe_id}"
		end
	end
end

end