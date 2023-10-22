module Apify

	"""Base sub-client class for actor runs and actor builds."""
	class ActorJobBaseClient < ResourceClient
		
		DEFAULT_WAIT_FOR_FINISH_SEC = 999999
		
		# After how many seconds we give up trying in case job doesn't exist
		DEFAULT_WAIT_WHEN_JOB_NOT_EXIST_SEC = 3

		def _wait_for_finish wait_secs=nil

			started_at = Time.now.utc # datetime.now(timezone.utc)
			job = nil
			seconds_elapsed = 0

			while true            
				wait_for_finish = wait_secs ? (wait_secs - seconds_elapsed) : DEFAULT_WAIT_FOR_FINISH_SEC
				
				begin
					res = @http_client.call url: _url, method: 'GET', params: _params(waitForFinish: wait_for_finish)
			 
					#job = parse_date_fields(_pluck_data(response.json()))
					job = res.dig(:parsed, "data")
		
					#seconds_elapsed = math.floor(((datetime.now(timezone.utc) - started_at).total_seconds()))
					seconds_elapsed = Time.now.utc - started_at

					# Early return here so that we avoid the sleep below if not needed
					return job if ActorJobStatus::_is_terminal(job['status']) || (wait_secs && (seconds_elapsed >= wait_secs))
					
				rescue ApifyApiError => exc
				
					Utils::_catch_not_found_or_throw exc

					# If there are still not found errors after DEFAULT_WAIT_WHEN_JOB_NOT_EXIST_SEC, we give up and return None
					# In such case, the requested record probably really doesn't exist.
					return if seconds_elapsed > DEFAULT_WAIT_WHEN_JOB_NOT_EXIST_SEC
				end
				
				# It might take some time for database replicas to get up-to-date so sleep a bit before retrying
				sleep 0.25
			end
			
			return job
		end

		def _abort gracefully=false
			res = @http_client.call url: _url('abort'), method: 'POST', params: _params(gracefully: gracefully)
			res && res.dig(:parsed, "data")
			#return parse_date_fields(_pluck_data(response.json()))
		end
	end

end