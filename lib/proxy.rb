require 'net/http'
require 'json'

module Apify

=begin
import inspect
import ipaddress
import re
from typing import Any, Awaitable, Callable, Dict, List, Optional, Pattern, TypedDict, Union
from urllib.parse import urljoin, urlparse

import httpx
from typing_extensions import NotRequired

from apify_client import ApifyClientAsync
from apify_shared.consts import ApifyEnvVars
from apify_shared.utils import ignore_docs

from .config import Configuration
from .log import logger
=end




=begin
class ProxyInfo(TypedDict):
    """Provides information about a proxy connection that is used for requests."""

    url: str
    """The URL of the proxy."""

    hostname: str
    """The hostname of the proxy."""

    port: int
    """The proxy port."""

    username: NotRequired[str]
    """The username for the proxy."""

    password: str
    """The password for the proxy."""

    groups: NotRequired[List[str]]
    """An array of proxy groups to be used by the [Apify Proxy](https://docs.apify.com/proxy).
    If not provided, the proxy will select the groups automatically.
    """

    country_code: NotRequired[str]
    """If set and relevant proxies are available in your Apify account, all proxied requests will
    use IP addresses that are geolocated to the specified country. For example `GB` for IPs
    from Great Britain. Note that online services often have their own rules for handling
    geolocation and thus the country selection is a best attempt at geolocation, rather than
    a guaranteed hit. This parameter is optional, by default, each proxied request is assigned
    an IP address from a random country. The country code needs to be a two letter ISO country code.
    See the [full list of available country codes](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Officially_assigned_code_elements).
    This parameter is optional, by default, the proxy uses all available proxy servers from all countries.
    """

    session_id: NotRequired[str]
    """The identifier of the used proxy session, if used. Using the same session ID guarantees getting the same proxy URL."""
=end

class ProxyConfiguration

	APIFY_PROXY_VALUE_REGEX = /^[\w._~]+$/
	COUNTRY_CODE_REGEX 		= /^[A-Z]{2}$/
	SESSION_ID_MAX_LENGTH 	= 50
	
    """Configures a connection to a proxy server with the provided options.

    Proxy servers are used to prevent target websites from blocking your crawlers based on IP address rate limits or blacklists.
    The default servers used by this class are managed by [Apify Proxy](https://docs.apify.com/proxy).
    To be able to use Apify Proxy, you need an Apify account and access to the selected proxies. If you provide no configuration option,
    the proxies will be managed automatically using a smart algorithm.

    If you want to use your own proxies, use the `proxy_urls` or `new_url_function` constructor options.
    Your list of proxy URLs will be rotated by the configuration, if this option is provided.
    """

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

    def initialize(
        password: nil,
        groups: nil,
        country_code: nil,
        proxy_urls: nil,
        new_url_function: nil, # Optional[Union[Callable[[Optional[str]], str], Callable[[Optional[str]], Awaitable[str]]]] = None,
        _actor_config: nil,
        _apify_client: nil
	)
        """Create a ProxyConfiguration instance. It is highly recommended to use `Actor.create_proxy_configuration()` instead of this.

        Args:
            password (str, optional): Password for the Apify Proxy. If not provided, will use os.environ['APIFY_PROXY_PASSWORD'], if available.
            groups (list of str, optional): Proxy groups which the Apify Proxy should use, if provided.
            country_code (str, optional): Country which the Apify Proxy should use, if provided.
            proxy_urls (list of str, optional): Custom proxy server URLs which should be rotated through.
            new_url_function (Callable, optional): Function which returns a custom proxy URL to be used.
        """
		@_next_custom_url_index = 0
		
        if groups
			raise "groups is not array" if groups.class != Array
            groups.each do |group|
				raise "group is not string" if group.class != String
				_check group, label: 'groups', pattern: APIFY_PROXY_VALUE_REGEX
			end
        end
		
		if country_code
            raise "country_code is not string" if country_code.class != String
            _check country_code, label: 'country_code', pattern: COUNTRY_CODE_REGEX
        end
		
		if proxy_urls
            raise "proxy_urls is not array" if proxy_urls.class != Array
			proxy_urls.each_with_index do |url, i|
				# ValueError
				raise "proxy_urls[#{i}] (\"#{url}\") is not a valid URL" unless _is_url(url)
			end
		end
		
        # Validation
        if proxy_urls and new_url_function
			# ValueError
            raise 'Cannot combine custom proxies in "proxy_urls" with custom generating function in "new_url_function".' 
		end
		
        if (proxy_urls or new_url_function) and (groups or country_code)
            # ValueError
			raise 	'Cannot combine custom proxies with Apify Proxy! ' \
					'It is not allowed to set "proxy_urls" or "new_url_function" combined with ' \
					'"groups" or "country_code".'				
		end
		
        # mypy has a bug with narrowing types for filter (https://github.com/python/mypy/issues/12682)
        # if proxy_urls and next(filter(lambda url: 'apify.com' in url, proxy_urls), None):  # type: ignore
        #    Log.warning('Some Apify proxy features may work incorrectly. Please consider setting up Apify properties instead of `proxy_urls`.\n'
        #                   'See https://sdk.apify.com/docs/guides/proxy-management#apify-proxy-configuration')
		# end
		
        @_actor_config = _actor_config or Configuration._get_default_instance
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
	
    def __initialize
        """Load the Apify Proxy password if the API token is provided and check access to Apify Proxy and provided proxy groups.

        Only called if Apify Proxy configuration is used.
        Also checks if country has access to Apify Proxy groups if the country code is provided.

        You should use the Actor.create_proxy_configuration function
        to create a pre-initialized `ProxyConfiguration` instance instead of calling this manually.
        """
        if @_uses_apify_proxy
            _maybe_fetch_password
            _check_access
		end
	end

    def new_url session_id: nil # Optional[Union[int, str]]
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
        if session_id
			session_id = session_id.to_s
            _check session_id, label: 'session_id', max_length: SESSION_ID_MAX_LENGTH, pattern: APIFY_PROXY_VALUE_REGEX
		end
		
        if @_new_url_function
            raise 
=begin			
			try:
                res = self._new_url_function(session_id)
                if inspect.isawaitable(res):
                    res = await res
                return str(res)
            except Exception as e:
                raise ValueError('The provided "new_url_function" did not return a valid URL') from e
=end
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

        p "http://#{username}:#{@_password}@#{@_hostname}:#{@_port}"
	end
=begin
    async def new_proxy_info(self, session_id: Optional[Union[int, str]] = None) -> ProxyInfo:
        """Create a new ProxyInfo object.

        Use it if you want to work with a rich representation of a proxy URL.
        If you need the URL string only, use `ProxyConfiguration.new_url`.

        Args:
            session_id (int or str, optional): Represents the identifier of a proxy session (https://docs.apify.com/proxy#sessions).
            All the HTTP requests going through the proxy with the same session identifier
            will use the same target proxy server (i.e. the same IP address).
            The identifier must not be longer than 50 characters and include only the following: `0-9`, `a-z`, `A-Z`, `"."`, `"_"` and `"~"`.

        Returns:
            ProxyInfo: Dictionary that represents information about the proxy and its configuration.
        """
        if session_id is not None:
            session_id = f'{session_id}'
            _check(session_id, label='session_id', max_length=SESSION_ID_MAX_LENGTH, pattern=APIFY_PROXY_VALUE_REGEX)

        url = await self.new_url(session_id)
        res: ProxyInfo
        if self._uses_apify_proxy:
            res = {
                'url': url,
                'hostname': self._hostname,
                'port': self._port,
                'username': self._get_username(session_id),
                'password': self._password or '',
                'groups': self._groups,
            }
            if self._country_code:
                res['country_code'] = self._country_code
            if session_id is not None:
                res['session_id'] = session_id
            return res
        else:
            parsed_url = urlparse(url)
            assert parsed_url.hostname is not None
            assert parsed_url.port is not None
            res = {
                'url': url,
                'hostname': parsed_url.hostname,
                'port': parsed_url.port,
                'password': parsed_url.password or '',
            }
            if parsed_url.username:
                res['username'] = parsed_url.username
        return res
=end
    def _maybe_fetch_password
        token = @_actor_config.token

        if token and @_apify_client
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
			raise  	"Apify Proxy password must be provided using the \"password\" constructor argument " \
					"or the \"#{ApifyEnvVars::PROXY_PASSWORD}\" environment variable. " \
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

		p :PROXY, status

        if status
			# ConnectionError
            raise status['connectionError'] if !status['connected']
            @is_man_in_the_middle = status['isManInTheMiddle']
        else 
            Log.warn \
				"Apify Proxy access check timed out. Watch out for errors with status code 407. " \
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
end

end

###################################################################### UTILS

# Regular expression pattern to match an IPv4 or IPv6 address
IP_PATTERN = /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$|^
              (?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|^
              ::(?:[0-9a-fA-F]{1,4}:){0,6}[0-9a-fA-F]{1,4}$|^
              (?:[0-9a-fA-F]{1,4}:){1,6}:$|^
              (?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}$/
			  
def _is_url url
	parsed_url 		= URI(url)
	host 			= parsed_url.host
	
	has_all_parts 	= parsed_url.scheme && host && parsed_url.path
	is_domain 		= host.include?('.')
	is_localhost 	= host == 'localhost'
	is_ip_address 	= IP_PATTERN.match?(host)

	has_all_parts && ( is_domain || is_localhost || is_ip_address )
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
        raise "#{error_str} does not match pattern #{pattern.pattern}"
	end
end