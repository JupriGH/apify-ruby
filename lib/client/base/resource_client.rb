module Apify

class ResourceClient < BaseClient
    """Base class for sub-clients manipulating a single resource."""

    def _get		
		#try:
			res = @http_client.call url: @url, method: 'GET', params: _params
			res && res.dig(:parsed, "data")
			#return parse_date_fields(_pluck_data(response.json()))
        #except ApifyApiError as exc:
        #    _catch_not_found_or_throw(exc)
	end
	
    def _update updated_fields
        res = @http_client.call url: _url, method: 'PUT', params: _params, json: updated_fields
        res && res.dig(:parsed, "data")
		#return parse_date_fields(_pluck_data(response.json()))
	end
	
    def _delete
        #try:
            @http_client.call url: _url, method: 'DELETE', params: _params
        #except ApifyApiError as exc:
        #    _catch_not_found_or_throw(exc)
		nil
	end

end

################################################################################################################################
class ResourceCollectionClient < BaseClient
    """Base class for sub-clients manipulating a resource collection."""

    def _list **kwargs
        res = @http_client.call url: _url, method:	'GET', params:	_params(**kwargs)		
		data = res && res.dig(:parsed, "data")
		# data = Utils::parse_date_fields(data)

		Models::ListPage.new data
        # return ListPage(parse_date_fields(_pluck_data(response.json())))
	end
	
    def _create resource
        res = @http_client.call url: _url, method: 'POST', params: _params, json: resource
		res && res.dig(:parsed, "data")
        # return parse_date_fields(_pluck_data(response.json()))
	end
    
	def _get_or_create name:, resource: nil
        res = @http_client.call url: _url, method: 'POST', params: _params(name: name), json: resource		
		res && res.dig(:parsed, "data")
        # return parse_date_fields(_pluck_data(response.json()))
	end
end
		
end