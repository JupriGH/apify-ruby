require 'net/http'

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
		
        #is_at_home = ('APIFY_IS_AT_HOME' in os.environ)
        #python_version = '.'.join([str(x) for x in sys.version_info[:3]])
        #client_version = metadata.version('apify-client')
        #@headers['User-Agent'] = f'ApifyClient/{client_version} ({sys.platform}; Python/{python_version}); isAtHome/{is_at_home}'
		
        if token
            @headers['Authorization'] = "Bearer #{token}"
		end
        
		# self.httpx_client = httpx.Client(headers=headers, follow_redirects=True, timeout=timeout_secs)
        # self.httpx_async_client = httpx.AsyncClient(headers=headers, follow_redirects=True, timeout=timeout_secs)
	end
=begin
	"""
    @staticmethod
    def _maybe_parse_response(response: httpx.Response) -> Any:
        if response.status_code == HTTPStatus.NO_CONTENT:
            return None

        content_type = ''
        if 'content-type' in response.headers:
            content_type = response.headers['content-type'].split(';')[0].strip()

        try:
            if is_content_type_json(content_type):
                return response.json()
            elif is_content_type_xml(content_type) or is_content_type_text(content_type):
                return response.text
            else:
                return response.content
        except ValueError as err:
            raise InvalidResponseBodyError(response) from err
	end
	"""
=end
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
			
			puts "Key: #{key}, Value: #{value}"
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
		
        # dump JSON data to string, so they can be gzipped
		
        if json
            #data = jsonlib.dumps(json, ensure_ascii=False, allow_nan=False, default=str).encode('utf-8')
			data = data.to_json
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
        parse_response: nil
    )
        # log_context.method.set(method)
        # log_context.url.set(url)

        if stream and parse_response
            raise 'Cannot stream response and parse it at the same time!' # ValueError
		end

        headers, params, content = _prepare_request_call(headers, params, data, json)

		headers = {**@headers, **headers}

		p method
		p url
		p headers
		p params
		p content # data
		p json
		p stream
		p parse_response
		
		raise "TODO"
		
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

=begin
class HTTPClientAsync < BaseHTTPClient

    # async 
	def call method: nil, url: nil, headers: nil, params: nil, data: nil, json: nil, stream: nil, parse_response: true

        # log_context.method.set(method)
        # log_context.url.set(url)

        # if stream and parse_response:
        #    raise ValueError('Cannot stream response and parse it at the same time!')

        headers, params, content = _prepare_request_call(headers, params, data, json)


        httpx_async_client = self.httpx_async_client

        async def _make_request(stop_retrying: Callable, attempt: int) -> httpx.Response:
            log_context.attempt.set(attempt)
            logger.debug('Sending request')
            try:
                request = httpx_async_client.build_request(
                    method=method,
                    url=url,
                    headers=headers,
                    params=params,
                    content=content,
                )
                response = await httpx_async_client.send(
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

        return await _retry_with_exp_backoff_async(
            _make_request,
            max_retries=self.max_retries,
            backoff_base_millis=self.min_delay_between_retries_millis,
            backoff_factor=DEFAULT_BACKOFF_EXPONENTIAL_FACTOR,
            random_factor=DEFAULT_BACKOFF_RANDOM_FACTOR,
        )

	end

end
=end

end