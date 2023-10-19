=begin
import asyncio
import math
import time
from datetime import datetime, timezone
from typing import Dict, Optional

from apify_shared.consts import ActorJobStatus
from apify_shared.utils import ignore_docs, parse_date_fields

from ..._errors import ApifyApiError
from ..._utils import _catch_not_found_or_throw, _pluck_data
from .resource_client import ResourceClient, ResourceClientAsync



# After how many seconds we give up trying in case job doesn't exist

=end

module Apify

class ActorJobBaseClient < ResourceClient
    """Base sub-client class for actor runs and actor builds."""
	
	DEFAULT_WAIT_FOR_FINISH_SEC = 999999
	DEFAULT_WAIT_WHEN_JOB_NOT_EXIST_SEC = 3

    def _wait_for_finish wait_secs=nil
		raise "TODO: #{__method__}"
=begin
        started_at = datetime.now(timezone.utc)
        should_repeat = true
        job = nil
        seconds_elapsed = 0

        while should_repeat
            wait_for_finish = DEFAULT_WAIT_FOR_FINISH_SEC
            if wait_secs is not None:
                wait_for_finish = wait_secs - seconds_elapsed

            try:
                response = self.http_client.call(
                    url=self._url(),
                    method='GET',
                    params=self._params(waitForFinish=wait_for_finish),
                )
                job = parse_date_fields(_pluck_data(response.json()))

                seconds_elapsed = math.floor(((datetime.now(timezone.utc) - started_at).total_seconds()))
                if (
                    ActorJobStatus(job['status'])._is_terminal or (wait_secs is not None and seconds_elapsed >= wait_secs)
                ):
                    should_repeat = False

                if not should_repeat:
                    # Early return here so that we avoid the sleep below if not needed
                    return job

            except ApifyApiError as exc:
                _catch_not_found_or_throw(exc)

                # If there are still not found errors after DEFAULT_WAIT_WHEN_JOB_NOT_EXIST_SEC, we give up and return None
                # In such case, the requested record probably really doesn't exist.
                if (seconds_elapsed > DEFAULT_WAIT_WHEN_JOB_NOT_EXIST_SEC):
                    return None

            # It might take some time for database replicas to get up-to-date so sleep a bit before retrying
            time.sleep(0.25)
		end
        return job
=end
	end

    def _abort gracefully=false
        res = @http_client.call url: _url('abort'), method: 'POST', params: _params(gracefully: gracefully)
		res && res.dig(:parsed, "data")
        #return parse_date_fields(_pluck_data(response.json()))
	end
end

end