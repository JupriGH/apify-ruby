require_relative 'base_client'

module Apify

class ResourceClient < BaseClient
    """Base class for sub-clients manipulating a single resource."""

    def _get
        #try:
            #response = @http_client.call( url: @url, method: 'GET', params: @_params )
			#return parse_date_fields(_pluck_data(response.json()))
			
			tmp = @http_client.call( url: @url, method: 'GET', params: @_params )
			
			if tmp
				return tmp.dig(:parsed, "data")
			end

        #except ApifyApiError as exc:
        #    _catch_not_found_or_throw(exc)

        return nil
	end
	
=begin
    def _update(self, updated_fields: Dict) -> Dict:
        response = self.http_client.call(
            url=self._url(),
            method='PUT',
            params=self._params(),
            json=updated_fields,
        )

        return parse_date_fields(_pluck_data(response.json()))

    def _delete(self) -> None:
        try:
            self.http_client.call(
                url=self._url(),
                method='DELETE',
                params=self._params(),
            )

        except ApifyApiError as exc:
            _catch_not_found_or_throw(exc)

=end
end

end