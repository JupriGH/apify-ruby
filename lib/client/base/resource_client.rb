module Apify

    """Base class for sub-clients manipulating a single resource."""
	class ResourceClient < BaseClient

		def _get			
			_http_get params: _params, pluck_data: true # parse_date			
		rescue ApifyApiError => exc
			Utils::_catch_not_found_or_throw exc
		end
		
		def _update updated_fields
			_http_put params: _params, json: updated_fields, filter_null: true, pluck_data: true # parse_date
		end
		
		def _delete
			_http_del params: _params
		except ApifyApiError => exc
			@utils::_catch_not_found_or_throw exc
		end
	end

    """Base class for sub-clients manipulating a resource collection."""
	class ResourceCollectionClient < BaseClient

		def _list **kwargs		
			data = _http_get params: _params(**kwargs), pluck_data: true # parse_date 
			Models::ListPage.new data
		end
		
		def _create resource		
			_http_post params: _params, json: resource, filter_null: true, pluck_data: true # parse_date
		end
		
		def _get_or_create name:, resource: nil
			#raise "### _get_or_create name #{name}"
		
			_http_post params: _params(name: name), json: resource, filter_null: true, pluck_data: true # parse_date
		end
	end
		
end