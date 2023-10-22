module Apify

	"""Sub-client for manipulating logs."""
	class LogClient < ResourceClient

		"""Initialize the LogClient."""
		def initialize(**kwargs) = super(resource_path: 'logs', **kwargs)

		"""Retrieve the log as text.

		https://docs.apify.com/api/v2#/reference/logs/log/get-log

		Returns:
			str, optional: The retrieved log, or None, if it does not exist.
		"""		
		def get
			res = @http_client.call url: @url, method: 'GET', params: _params
			res && res[:response].body.force_encoding('UTF-8')

		rescue ApifyApiError => exc
			Utils::_catch_not_found_or_throw(exc)
		end
		
		"""Retrieve the log as raw bytes.

		https://docs.apify.com/api/v2#/reference/logs/log/get-log

		Returns:
			bytes, optional: The retrieved log as raw bytes, or None, if it does not exist.
		"""		
		def get_as_bytes
			res = @http_client.call url: @url, method: 'GET', params: _params, parse_response: false
			res && res[:response].body

		rescue ApifyApiError => exc
			Utils::_catch_not_found_or_throw(exc)
		end
		
		"""Retrieve the log as a stream.

		https://docs.apify.com/api/v2#/reference/logs/log/get-log

		Returns:
			httpx.Response, optional: The retrieved log as a context-managed streaming Response, or None, if it does not exist.
		"""
		#@contextmanager
		def stream # Iterator[Optional[httpx.Response]]:			
			@http_client.call(
				url: @url,
				method: 'GET',
				params: _params(stream: true),
				stream: true,
				parse_response: false
			) do |data|
				yield data
			end

		rescue ApifyApiError => exc
			#res[:response].close
			Utils::_catch_not_found_or_throw exc
		end
	end

end