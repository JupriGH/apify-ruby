module Apify

    """Base class for sub-clients manipulating a single resource."""
	class ResourceClient < BaseClient

		def _get		
			res = @http_client.call url: @url, method: 'GET', params: _params
			return res && res.dig(:parsed, "data")
			#return parse_date_fields(_pluck_data(response.json()))
		rescue ApifyApiError => exc
			Utils::_catch_not_found_or_throw exc
		end
		
		def _update updated_fields
			# TODO: Utils::_filter_none....
		
			res = @http_client.call url: _url, method: 'PUT', params: _params, json: updated_fields
			res && res.dig(:parsed, "data")
			#return parse_date_fields(_pluck_data(response.json()))
		end
		
		def _delete
			@http_client.call url: _url, method: 'DELETE', params: _params
		except ApifyApiError => exc
			@utils::_catch_not_found_or_throw exc
		end

	end

    """Base class for sub-clients manipulating a resource collection."""
	class ResourceCollectionClient < BaseClient


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