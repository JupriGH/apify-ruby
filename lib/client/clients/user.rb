require_relative '../base/resource_client'

module Apify

class UserClient < ResourceClient
    """Sub-client for querying user data."""

    def initialize **kwargs
        """Initialize the UserClient."""

        #resource_id = kwargs.pop('resource_id', None)
        #if resource_id is None:
        #    resource_id = 'me'
        #resource_path = kwargs.pop('resource_path', 'users')
        #super().__init__(*args, resource_id=resource_id, resource_path=resource_path, **kwargs)

		kwargs[:resource_id] 	||= 'me'
		kwargs[:resource_path] 	||= 'users'
		super **kwargs
		
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