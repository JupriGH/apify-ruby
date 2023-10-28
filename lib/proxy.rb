module Apify

	"""Configures a connection to a proxy server with the provided options.

	Proxy servers are used to prevent target websites from blocking your crawlers based on IP address rate limits or blacklists.
	The default servers used by this class are managed by [Apify Proxy](https://docs.apify.com/proxy).
	To be able to use Apify Proxy, you need an Apify account and access to the selected proxies. If you provide no configuration option,
	the proxies will be managed automatically using a smart algorithm.

	If you want to use your own proxies, use the `proxy_urls` or `new_url_function` constructor options.
	Your list of proxy URLs will be rotated by the configuration, if this option is provided.
	"""
	class ProxyConfiguration

		# Regular expression pattern to match an IPv4 or IPv6 address
		IP_PATTERN = /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$|^
					  (?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|^
					  ::(?:[0-9a-fA-F]{1,4}:){0,6}[0-9a-fA-F]{1,4}$|^
					  (?:[0-9a-fA-F]{1,4}:){1,6}:$|^
					  (?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}$/


		APIFY_PROXY_VALUE_REGEX = /^[\w._~]+$/
		COUNTRY_CODE_REGEX = /^[A-Z]{2}$/
		SESSION_ID_MAX_LENGTH = 50

		@is_man_in_the_middle = false

		#@_next_custom_url_index = 0
		@_proxy_urls
		@_used_proxy_urls
		@_new_url_function
		@_groups
		@_country_code
		@_password
		@_hostname
		@_port
		@_uses_apify_proxy
		@_actor_config
		@_apify_client

		"""Create a ProxyConfiguration instance. It is highly recommended to use `Actor.create_proxy_configuration()` instead of this.

		Args:
			password (str, optional): Password for the Apify Proxy. If not provided, will use os.environ['APIFY_PROXY_PASSWORD'], if available.
			groups (list of str, optional): Proxy groups which the Apify Proxy should use, if provided.
			country_code (str, optional): Country which the Apify Proxy should use, if provided.
			proxy_urls (list of str, optional): Custom proxy server URLs which should be rotated through.
			new_url_function (Callable, optional): Function which returns a custom proxy URL to be used.
		"""
		def initialize(
			password: nil,
			groups: nil,
			country_code: nil,
			proxy_urls: nil,
			new_url_function: nil, # Optional[Union[Callable[[Optional[str]], str], Callable[[Optional[str]], Awaitable[str]]]] = None,
			_actor_config: nil,
			_apify_client: nil
		)
			@_next_custom_url_index = 0

			if groups
				raise "groups must be an array!" if groups.class != Array
				groups.each do |group|
					raise "group must be a string!" if group.class != String
					_check group, label: 'groups', pattern: APIFY_PROXY_VALUE_REGEX
				end
			end
			
			if country_code
				raise "country_code must be a string!" if country_code.class != String
				_check country_code, label: 'country_code', pattern: COUNTRY_CODE_REGEX
			end
			
			if proxy_urls
				raise "proxy_urls must be an array!" if proxy_urls.class != Array
				proxy_urls.each_with_index do |url, i|
					raise "proxy_urls[#{i}] (\"#{url}\") is not a valid URL" unless _is_url(url) # ValueError
				end
			end
			
			# Validation
			if proxy_urls && new_url_function
				# ValueError
				raise 'Cannot combine custom proxies in "proxy_urls" with custom generating function in "new_url_function".' 
			end
			
			if (proxy_urls || new_url_function) && (groups || country_code)
				# ValueError
				raise 	'Cannot combine custom proxies with Apify Proxy! ' \
						'It is not allowed to set "proxy_urls" or "new_url_function" combined with ' \
						'"groups" or "country_code".'				
			end
			
			# mypy has a bug with narrowing types for filter (https://github.com/python/mypy/issues/12682)
			if proxy_urls && proxy_urls.find {|url| url.include?('apify.com')}  # type: ignore
			    Log.warn 'Some Apify proxy features may work incorrectly. Please consider setting up Apify properties instead of `proxy_urls`.',
						 'See https://sdk.apify.com/docs/guides/proxy-management#apify-proxy-configuration'
			end
			
			@_actor_config = _actor_config || Configuration._get_default_instance
			@_apify_client = _apify_client

			@_hostname 		= @_actor_config.proxy_hostname
			@_port 			= @_actor_config.proxy_port
			@_password 		= password || @_actor_config.proxy_password

			@_proxy_urls 		= proxy_urls
			@_used_proxy_urls 	= {}
			@_new_url_function 	= new_url_function
			@_groups 			= groups
			@_country_code 		= country_code
			@_uses_apify_proxy 	= ! (proxy_urls || new_url_function)			
		end

		"""Load the Apify Proxy password if the API token is provided and check access to Apify Proxy and provided proxy groups.

		Only called if Apify Proxy configuration is used.
		Also checks if country has access to Apify Proxy groups if the country code is provided.

		You should use the Actor.create_proxy_configuration function
		to create a pre-initialized `ProxyConfiguration` instance instead of calling this manually.
		"""		
		def __initialize
			if @_uses_apify_proxy
				_maybe_fetch_password
				_check_access
			end
		end

		'''Return a new proxy URL based on provided configuration options and the `sessionId` parameter.

		Args:
			session_id (int or str, optional): Represents the identifier of a proxy session (https://docs.apify.com/proxy#sessions).
			All the HTTP requests going through the proxy with the same session identifier
			will use the same target proxy server (i.e. the same IP address).
			The identifier must not be longer than 50 characters and include only the following: `0-9`, `a-z`, `A-Z`, `"."`, `"_"` and `"~"`.

		Returns:
			str: A string with a proxy URL, including authentication credentials and port number.
				 For example, `http://bob:password123@proxy.example.com:8000`
		'''
		def new_url session_id=nil # Optional[Union[int, str]]
			if session_id
				session_id = session_id.to_s
				_check session_id, label: 'session_id', max_length: SESSION_ID_MAX_LENGTH, pattern: APIFY_PROXY_VALUE_REGEX
			end
			
			if @_new_url_function
				raise "`new_url_function` is not a function!" unless @_new_url_function.respond_to?(:call)			
				begin	
					res = @_new_url_function.call session_id
					#if inspect.isawaitable(res):
					#	res = await res
					return res.to_s
				rescue Exception => exc
					raise 'The provided "new_url_function" did not return a valid URL' # ValueError
				end
			end
			
			if @_proxy_urls
				if !session_id
					index = @_next_custom_url_index
					@_next_custom_url_index = (@_next_custom_url_index + 1) % @_proxy_urls.length
					return @_proxy_urls[index]
				else
					if !@_used_proxy_urls.has_key?(session_id)
						index = @_next_custom_url_index
						@_next_custom_url_index = (@_next_custom_url_index + 1) % @_proxy_urls.length
						@_used_proxy_urls[session_id] = @_proxy_urls[index]
					end
					return @_used_proxy_urls[session_id]
				end
			end
			
			username = _get_username session_id

			"http://#{username}:#{@_password}@#{@_hostname}:#{@_port}"
		end

		'''Create a new ProxyInfo object.

		Use it if you want to work with a rich representation of a proxy URL.
		If you need the URL string only, use `ProxyConfiguration.new_url`.

		Args:
			session_id (int or str, optional): Represents the identifier of a proxy session (https://docs.apify.com/proxy#sessions).
			All the HTTP requests going through the proxy with the same session identifier
			will use the same target proxy server (i.e. the same IP address).
			The identifier must not be longer than 50 characters and include only the following: `0-9`, `a-z`, `A-Z`, `"."`, `"_"` and `"~"`.

		Returns:
			ProxyInfo: Dictionary that represents information about the proxy and its configuration.
		'''
		def new_proxy_info session_id=nil
			#if session_id
			#	session_id = session_id.to_s
			#	_check session_id, label:'session_id', max_length: SESSION_ID_MAX_LENGTH, pattern: APIFY_PROXY_VALUE_REGEX
			#end
			
			url = new_url session_id
			
			#res: ProxyInfo
			if @_uses_apify_proxy
				res = {
					'url' 		=> url,
					'hostname' 	=> @_hostname,
					'port'		=> @_port,
					'username'	=> _get_username(session_id),
					'password'	=> @_password || '',
					'groups'	=> @_groups,
				}
				
				res['country_code'] = @_country_code if @_country_code
				res['session_id'] = session_id if session_id
			else
				parsed_url = URI(url)				
				raise unless (parsed_url.host && parsed_url.port)

				res = {
					'url'		=> url,
					'hostname'	=> parsed_url.host,
					'port'		=> parsed_url.port,
					'password'	=> parsed_url.password || '',
				}
				res['username'] = parsed_url.user if parsed_url.user
			end
			return res
		end
		
		def _maybe_fetch_password
			token = @_actor_config.token

			if token && @_apify_client
				user_info = @_apify_client.user.get
				if user_info
					password = user_info.dig("proxy", "password")
					if @_password
						if @_password != password
							
							Log.warn	'The Apify Proxy password you provided belongs to '\
										'a different user than the Apify token you are using. '\
										'Are you sure this is correct?'
						end
					else
						@_password = password
					end
				end
			end
			
			if not @_password
				# ValueError
				raise  	"Apify Proxy password must be provided using the \"password\" constructor argument "\
						"or the \"#{ApifyEnvVars::PROXY_PASSWORD}\" environment variable. "\
						"If you add the \"#{ApifyEnvVars::TOKEN}\" environment variable, the password will be automatically inferred."
			end
		end
		
		def _check_access
			proxy_status_url = "#{@_actor_config.proxy_status_url}/?format=json"
			
			status = nil

			'''
			async with httpx.AsyncClient(proxies=await self.new_url()) as client:
				for _ in range(2):
					try:
						response = await client.get(proxy_status_url)
						status = response.json()
						break
					except Exception:
						# retry on connection errors
						pass
			'''
			
			uri = URI(proxy_status_url)
			prx = URI(new_url)

			# start session
			Net::HTTP.new(uri.host, uri.port, prx.host, prx.port, prx.user, prx.password).start do |http|			
				req = Net::HTTP::Get.new uri
				res = http.request(req)
				
				if res.is_a?(Net::HTTPSuccess)
					status = JSON.parse(res.body)
				else
					## TODO
				end
			end

			# p :PROXY, status

			if status
				# ConnectionError
				raise status['connectionError'] if !status['connected']
				@is_man_in_the_middle = status['isManInTheMiddle']
			else 
				Log.warn	"Apify Proxy access check timed out. Watch out for errors with status code 407. "\
							"If you see some, it most likely means you don't have access to either all or some of the proxies you're trying to use."
			end
		end
		
		def _get_username session_id=nil
			session_id &&= session_id.to_s
			
			parts = []

			# if xx then parts << yy end
			
			@_groups 		&& parts << "groups-#{@_groups.join("+")}"     
			session_id 		&& parts << "session-#{session_id}"
			@_country_code 	&& parts << "country-#{@_country_code}"
			
			parts.empty? ? 'auto' : parts.join(",")
		end
		
		
		# UTILS
		def _is_url url
			parsed_url 		= URI(url)
			host 			= parsed_url.host
			
			return unless parsed_url.scheme && host && parsed_url.path # has_all_parts
			return true if host.include?('.') || host == 'localhost' || IP_PATTERN.match?(host) 
		end

		def _check value, label: nil, pattern: nil, min_length: nil, max_length: nil
			error_str = "Value #{value}"
			label && error_str << " of argument #{label}"

			if min_length && value.length < min_length
				raise "#{error_str} is shorter than minimum allowed length #{min_length}" # ValueError
			end
			
			if max_length && value.length > max_length
				raise "#{error_str} is longer than maximum allowed length #{max_length}" # ValueError
			end
			
			if pattern && !pattern.match?(value)
				raise "#{error_str} does not match pattern #{pattern.source}"
			end
		end	
		
	end
end



	