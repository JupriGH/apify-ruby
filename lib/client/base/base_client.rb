module Apify

	class BaseBaseClient # (metaclass=_WithLogDetailsClient):

		@resource_id
		@url
		@params
		@http_client
		@root_client

		def _url(path=nil) = path ? "#{@url}/#{path}" : @url
		
		def _params(**kwargs) = @param ? {**@params,  **kwargs} : {**kwargs}

		def _sub_resource_init_options **kwargs
			{ base_url: @url, http_client: @http_client, params: @params, root_client: @root_client, **kwargs }
		end

	end 

    """Base class for sub-clients."""
	class BaseClient < BaseBaseClient

		"""Initialize the sub-client.

		Args:
			base_url (str): Base URL of the API server
			root_client (ApifyClient): The ApifyClient instance under which this resource client exists
			http_client (_HTTPClient): The _HTTPClient instance to be used in this client
			resource_id (str): ID of the manipulated resource, in case of a single-resource client
			resource_path (str): Path to the resource's endpoint on the API server
			params (dict): Parameters to include in all requests from this client
		"""
		def initialize (
			base_url: nil,
			root_client: nil,
			http_client: nil,
			resource_id: nil,
			resource_path: nil,
			params: nil
		)
			# if resource_path.endswith('/'):
			#    raise ValueError('resource_path must not end with "/"')

			@base_url 		= base_url
			@root_client 	= root_client # ApifyClient
			@http_client 	= http_client # _HTTPClient
			@params 		= params || {}
			@resource_path	= resource_path
			@resource_id 	= resource_id
			
			@url = "#{@base_url}/#{@resource_path}"
			
			if resource_id
				@url << '/' << Utils::_to_safe_id(resource_id)
			end
		end
		
		### NEW
		def _request(
			method,
			path=nil, 
			headers: nil,
			params: nil, 
			filter_null: nil, 
			pluck_data: nil, 
			data: nil, 
			json: nil
		)
			json = Utils::filter_out_none_values_recursively(json) if json && filter_null

			res = @http_client.call url: _url(path), method: method, headers: headers, params: params, data: data, json: json
			
			# assume results is JSON
			return if !res
			return res.dig(:parsed, 'data') if pluck_data			
			return res
		end
		
		def _http_get(*args, **kargs) = _request('GET', *args, **kargs)
		def _http_put(*args, **kargs) = _request('PUT', *args, **kargs)
		def _http_post(*args, **kargs) = _request('POST', *args, **kargs)			
		def _http_del(*args, **kargs) = _request('DELETE', *args, **kargs)			
	end
end