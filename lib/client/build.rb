module Apify

	"""Sub-client for manipulating a single actor build."""
	class BuildClient < ActorJobBaseClient

		"""Initialize the BuildClient."""
		def initialize(**kwargs) = super resource_path: 'actor-builds', **kwargs

		"""Return information about the actor build.

		https://docs.apify.com/api/v2#/reference/actor-builds/build-object/get-build

		Returns:
			dict, optional: The retrieved actor build data
		"""		
		def get = _get


		"""Delete the build.

		https://docs.apify.com/api/v2#/reference/actor-builds/delete-build/delete-build
		"""
		def delete = _delete

		"""Abort the actor build which is starting or currently running and return its details.

		https://docs.apify.com/api/v2#/reference/actor-builds/abort-build/abort-build

		Returns:
			dict: The data of the aborted actor build
		"""
		def abort = _abort

		"""Wait synchronously until the build finishes or the server times out.

		Args:
			wait_secs (int, optional): how long does the client wait for build to finish. None for indefinite.

		Returns:
			dict, optional: The actor build data. If the status on the object is not one of the terminal statuses
				(SUCEEDED, FAILED, TIMED_OUT, ABORTED), then the build has not yet finished.
		"""
		def wait_for_finish(wait_secs=nil) = _wait_for_finish wait_secs
	end

	### BuildCollectionClient

	"""Sub-client for listing actor builds."""
	class BuildCollectionClient < ResourceCollectionClient

		"""Initialize the BuildCollectionClient."""
		def initialize(**kwargs) = super resource_path: 'actor-builds', **kwargs

		"""List all actor builds (either of a single actor, or all user's actors, depending on where this client was initialized from).

		https://docs.apify.com/api/v2#/reference/actors/build-collection/get-list-of-builds
		https://docs.apify.com/api/v2#/reference/actor-builds/build-collection/get-user-builds-list

		Args:
			limit (int, optional): How many builds to retrieve
			offset (int, optional): What build to include as first when retrieving the list
			desc (bool, optional): Whether to sort the builds in descending order based on their start date

		Returns:
			ListPage: The retrieved actor builds
		"""	
		def list(limit: nil, offset: nil, desc: nil) = _list limit: limit, offset: offset, desc: desc
	end

end