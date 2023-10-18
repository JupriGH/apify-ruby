=begin
from contextlib import asynccontextmanager, contextmanager
from typing import Any, AsyncIterator, Iterator, Optional

import httpx

from apify_shared.utils import ignore_docs

from ..._errors import ApifyApiError
from ..._utils import _catch_not_found_or_throw
from ..base import ResourceClient, ResourceClientAsync
=end

module Apify

class LogClient < ResourceClient
    """Sub-client for manipulating logs."""

    def initialize **kwargs
        """Initialize the LogClient."""
        super resource_path: 'logs', **kwargs
	end
	
    def get
        """Retrieve the log as text.

        https://docs.apify.com/api/v2#/reference/logs/log/get-log

        Returns:
            str, optional: The retrieved log, or None, if it does not exist.
        """
        #try:
            res = @http_client.call url: @url, method: 'GET', params: _params
            res && res[:response].body.force_encoding('UTF-8')

        #except ApifyApiError as exc:
        #    _catch_not_found_or_throw(exc)

        #return None
	end
	
    def get_as_bytes
        """Retrieve the log as raw bytes.

        https://docs.apify.com/api/v2#/reference/logs/log/get-log

        Returns:
            bytes, optional: The retrieved log as raw bytes, or None, if it does not exist.
        """
        #try:
            res = @http_client.call url: @url, method: 'GET', params: _params, parse_response: false
            res && res[:response].body

        #except ApifyApiError as exc:
        #    _catch_not_found_or_throw(exc)

        #return None
	end
	
=begin
    @contextmanager
    def stream(self) -> Iterator[Optional[httpx.Response]]:
        """Retrieve the log as a stream.

        https://docs.apify.com/api/v2#/reference/logs/log/get-log

        Returns:
            httpx.Response, optional: The retrieved log as a context-managed streaming Response, or None, if it does not exist.
        """
        response = None
        try:
            response = self.http_client.call(
                url=self.url,
                method='GET',
                params=self._params(stream=True),
                stream=True,
                parse_response=False,
            )

            yield response
        except ApifyApiError as exc:
            _catch_not_found_or_throw(exc)
            yield None
        finally:
            if response:
                response.close()

=end
end

end