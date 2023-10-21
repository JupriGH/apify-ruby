module Apify

	"""Sub-client for querying user data."""
	class UserClient < ResourceClient

		"""Initialize the UserClient."""
		def initialize **kwargs
			kwargs[:resource_id] ||= 'me'
			super resource_path: 'users', **kwargs 
		end

		"""Return information about user account.

		You receive all or only public info based on your token permissions.

		https://docs.apify.com/api/v2#/reference/users

		Returns:
			dict, optional: The retrieved user data, or None if the user does not exist.
		"""
		def get = _get
	end

end