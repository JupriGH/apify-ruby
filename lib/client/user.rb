require_relative 'base/resource_client'

module Apify

class UserClient < ResourceClient
    """Sub-client for querying user data."""

    def initialize **kwargs
        """Initialize the UserClient."""
		kwargs[:resource_id] ||= 'me'
		super resource_path: 'users', **kwargs 
		
    end
	
	def get
        """Return information about user account.

        You receive all or only public info based on your token permissions.

        https://docs.apify.com/api/v2#/reference/users

        Returns:
            dict, optional: The retrieved user data, or None if the user does not exist.
        """
        _get
	end
end

end