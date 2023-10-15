require 'net/http'
require 'json'
require 'rbconfig'

module Apify

class BaseHTTPClient

    def initialize token: nil, max_retries: 8, min_delay_between_retries_millis: 500, timeout_secs: 360

        @max_retries = max_retries
        @min_delay_between_retries_millis = min_delay_between_retries_millis
        @timeout_secs = timeout_secs

        @headers = {'Accept': 'application/json, */*'}

        workflow_key = ENV['APIFY_WORKFLOW_KEY']
        if workflow_key
			@headers['X-Apify-Workflow-Key'] = workflow_key
		end
		
        is_at_home 		= ENV.include? 'APIFY_IS_AT_HOME'
        python_version 	= RUBY_VERSION  # '3.11.5' # '.'.join([str(x) for x in sys.version_info[:3]])
        client_version 	= "1.1.5" # metadata.version('apify-client')
		platform 		= RbConfig::CONFIG['host_os'] # 'linux' # sys.platform
        
		@headers['User-Agent'] = "ApifyClient/#{client_version} (#{platform}; Ruby/#{python_version}); isAtHome/#{is_at_home}"
		
        if token
            @headers['Authorization'] = "Bearer #{token}"
		end
        
		# self.httpx_client = httpx.Client(headers=headers, follow_redirects=True, timeout=timeout_secs)
        # self.httpx_async_client = httpx.AsyncClient(headers=headers, follow_redirects=True, timeout=timeout_secs)
	end

    def _maybe_parse_response response # Net::HTTPResponse
		# 204 NO_CONTENT
		if response.body.nil? || response.code == 204 # NO_CONTENT
			return 
		end

		# COMPRESSION
		case response['content-encoding']
		when "gzip"
			sio 	= StringIO.new response.body
			gz 		= Zlib::GzipReader.new sio
			
			response.body = gz.read
		when "br"
			raise "TODO: brotli"
		end

		content_type = nil		
		t = response["Content-Type"]
		if t
			content_type = t.split(";")[0]
		end

        #try:
            
			#if is_content_type_json(content_type)
			if content_type =~ /^.*?\/json$/
                return JSON.parse(response.body)            
			#elsif is_content_type_xml(content_type) or is_content_type_text(content_type)
            #    return response.body
            else
                # return response.body
			end
			
		#except ValueError as err:
        #    raise InvalidResponseBodyError(response) from err
		return nil
	end

    def _parse_params params
        if not params
            return
		end
		
        parsed_params = {}

		# Our API needs to have boolean parameters passed as 0 or 1, therefore we have to replace them
		
		"""
		for key, value in params.items():
            if isinstance(value, bool):
                parsed_params[key] = int(value)
            elif value is not None:
                parsed_params[key] = value

        return parsed_params
		"""

		def is_empty val
			val == false || val == 0 || val == "" || val.nil? || val.empty? 
		end

		params.each do |key, val|
			if val.is_a?(TrueClass) || val.is_a?(FalseClass)
				parsed_params[key] = val ? "1" : "0"
			elsif !is_empty val
				parsed_params[key] = val
			end
			
			#puts "Key: #{key}, Value: #{val}"
		end
		parsed_params

	end
	
    def _prepare_request_call headers, params, data, json
        
		if json and data
            raise 'Cannot pass both "json" and "data" parameters at the same time!' # ValueError
		end
		
        if not headers
            headers = {}
		end
		
		headers['Accept-Encoding'] = "br, gzip, deflate"
		
        # dump JSON data to string, so they can be gzipped
        if json
            #data = jsonlib.dumps(json, ensure_ascii=False, allow_nan=False, default=str).encode('utf-8')
			data = json.to_json
			headers['Content-Type'] = 'application/json'
		end
		
        #if isinstance(data, (str, bytes, bytearray)):
        #    if isinstance(data, str):
        #        data = data.encode('utf-8')
        #    end
		#	data = gzip.compress(data)
        #    headers['Content-Encoding'] = 'gzip'
		#end
		
        [ headers, _parse_params(params), data ]
	end

end

class HTTPClient < BaseHTTPClient

    def call(
        method: nil,
        url: nil,
        headers: nil,
        params: nil,
        data: nil,
        json: nil,
        stream: nil,
        parse_response: true
    )
        # log_context.method.set(method)
        # log_context.url.set(url)

        if stream and parse_response
            raise 'Cannot stream response and parse it at the same time!' # ValueError
		end

        headers, params, content = _prepare_request_call(headers, params, data, json)

		###################################################################################
		headers = {**@headers, **headers}

		p method
		p url
		p headers
		p params
		p stream
		p parse_response
		
		uri = URI.parse(url)

		# start session
		Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|

			if params && params.length > 0
				raise "TODO: params"
			end
			
			if stream
				raise "TODO: stream"
			end	
			
			#post 	= { query: { site: 'stackoverflow', page: 1 } }
		
			# Create the request
			if method == 'POST'
				raise "TODO: POST"
				req = Net::HTTP::Post.new uri
				if content
					req.body = content
				end
			else
				req = Net::HTTP::Get.new uri
			end

			# headers
			headers.each do |key, val|
				req[key] = val
			end

			# Perform the request
			res = http.request(req)

			# Handle the response
			if res.is_a?(Net::HTTPSuccess)

				res.each do |key, val|
					p "#{key}: #{val}"
				end
								
				_maybe_parsed_body = nil
				if not stream
					if parse_response
						_maybe_parsed_body = _maybe_parse_response res
					else
						#_maybe_parsed_body = res.body # response.content
					end
					# setattr(response, '_maybe_parsed_body', _maybe_parsed_body)  # noqa: B010
					
					
				end
				
				return { response: res, parsed: _maybe_parsed_body }
			
			else
				# TODO: handle errors
				p "HTTP Error: #{res.code}"
				raise
				return nil
			end
		end

=begin
        httpx_client = self.httpx_client

        def _make_request(stop_retrying: Callable, attempt: int) -> httpx.Response:
            log_context.attempt.set(attempt)
            logger.debug('Sending request')
            try:
                request = httpx_client.build_request(
                    method=method,
                    url=url,
                    headers=headers,
                    params=params,
                    content=content,
                )
                response = httpx_client.send(
                    request=request,
                    stream=stream or False,
                )

                # If response status is < 300, the request was successful, and we can return the result
                if response.status_code < 300:
                    logger.debug('Request successful', extra={'status_code': response.status_code})
                    if not stream:
                        if parse_response:
                            _maybe_parsed_body = self._maybe_parse_response(response)
                        else:
                            _maybe_parsed_body = response.content
                        setattr(response, '_maybe_parsed_body', _maybe_parsed_body)  # noqa: B010

                    return response

            except Exception as e:
                logger.debug('Request threw exception', exc_info=e)
                if not _is_retryable_error(e):
                    logger.debug('Exception is not retryable', exc_info=e)
                    stop_retrying()
                raise e

            # We want to retry only requests which are server errors (status >= 500) and could resolve on their own,
            # and also retry rate limited requests that throw 429 Too Many Requests errors
            logger.debug('Request unsuccessful', extra={'status_code': response.status_code})
            if response.status_code < 500 and response.status_code != HTTPStatus.TOO_MANY_REQUESTS:
                logger.debug('Status code is not retryable', extra={'status_code': response.status_code})
                stop_retrying()
            raise ApifyApiError(response, attempt)

        return _retry_with_exp_backoff(
            _make_request,
            max_retries=self.max_retries,
            backoff_base_millis=self.min_delay_between_retries_millis,
            backoff_factor=DEFAULT_BACKOFF_EXPONENTIAL_FACTOR,
            random_factor=DEFAULT_BACKOFF_RANDOM_FACTOR,
        )
=end

	end
end

end