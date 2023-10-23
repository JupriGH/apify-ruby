def _get_actor_version_representation(
    version_number: nil,
    build_tag: nil,
    env_vars: nil,
    apply_env_vars_to_build: nil,
    source_type: nil,
    source_files: nil,
    git_repo_url: nil,
    tarball_url: nil,
    github_gist_url: nil
) = ({
	versionNumber: version_number,
	buildTag: build_tag,
	envVars: env_vars,
	applyEnvVarsToBuild: apply_env_vars_to_build,
	sourceType: source_type, ### maybe_extract_enum_member_value(source_type), ### TODO
	sourceFiles: source_files,
	gitRepoUrl: git_repo_url,
	tarballUrl: tarball_url,
	gitHubGistUrl: github_gist_url
})

module Apify

	"""Sub-client for manipulating a single actor version."""
	class ActorVersionClient < ResourceClient

		"""Initialize the ActorVersionClient."""
		def initialize(**kwargs) = super(resource_path:'versions', **kwargs)

		"""Return information about the actor version.

		https://docs.apify.com/api/v2#/reference/actors/version-object/get-version

		Returns:
			dict, optional: The retrieved actor version data
		"""
		def get = _get

		"""Update the actor version with specified fields.

		https://docs.apify.com/api/v2#/reference/actors/version-object/update-version

		Args:
			build_tag (str, optional): Tag that is automatically set to the latest successful build of the current version.
			env_vars (list of dict, optional): Environment variables that will be available to the actor run process,
				and optionally also to the build process. See the API docs for their exact structure.
			apply_env_vars_to_build (bool, optional): Whether the environment variables specified for the actor run
				will also be set to the actor build process.
			source_type (ActorSourceType, optional): What source type is the actor version using.
			source_files (list of dict, optional): Source code comprised of multiple files, each an item of the array.
				Required when ``source_type`` is ``ActorSourceType.SOURCE_FILES``. See the API docs for the exact structure.
			git_repo_url (str, optional): The URL of a Git repository from which the source code will be cloned.
				Required when ``source_type`` is ``ActorSourceType.GIT_REPO``.
			tarball_url (str, optional): The URL of a tarball or a zip archive from which the source code will be downloaded.
				Required when ``source_type`` is ``ActorSourceType.TARBALL``.
			github_gist_url (str, optional): The URL of a GitHub Gist from which the source will be downloaded.
				Required when ``source_type`` is ``ActorSourceType.GITHUB_GIST``.

		Returns:
			dict: The updated actor version
		"""
		def update(
			build_tag: nil,
			env_vars: nil,
			apply_env_vars_to_build: nil,
			source_type: nil,
			source_files: nil,
			git_repo_url: nil,
			tarball_url: nil,
			github_gist_url: nil
		)
			actor_version_representation = Utils::filter_out_none_values_recursively( 
				_get_actor_version_representation(
					build_tag: build_tag,
					env_vars: env_vars,
					apply_env_vars_to_build: apply_env_vars_to_build,
					source_type: source_type,
					source_files: source_files,
					git_repo_url: git_repo_url,
					tarball_url: tarball_url,
					github_gist_url: github_gist_url
				)
			)

			_update actor_version_representation
		end
		
	   """Delete the actor version.

		https://docs.apify.com/api/v2#/reference/actors/version-object/delete-version
		"""
		def delete = _delete

		"""Retrieve the client for the specified environment variable of this actor version.

		Args:
			env_var_name (str): The name of the environment variable for which to retrieve the resource client.

		Returns:
			ActorEnvVarClient: The resource client for the specified actor environment variable.
		"""
		def env_var(env_var_name) = ActorEnvVarClient.new(**_sub_resource_init_options(resource_id: env_var_name))

		"""Retrieve a client for the environment variables of this actor version."""		
		def env_vars = ActorEnvVarCollectionClient.new(**_sub_resource_init_options)
	end

	### ActorVersionCollectionClient

	"""Sub-client for manipulating actor versions."""
	class ActorVersionCollectionClient < ResourceCollectionClient

		"""Initialize the ActorVersionCollectionClient with the passed arguments."""
		def initialize(**kwargs) = super(resource_path: 'versions', **kwargs)

		"""List the available actor versions.

		https://docs.apify.com/api/v2#/reference/actors/version-collection/get-list-of-versions

		Returns:
			ListPage: The list of available actor versions.
		"""
		def list = _list

		"""Create a new actor version.

		https://docs.apify.com/api/v2#/reference/actors/version-collection/create-version

		Args:
			version_number (str): Major and minor version of the actor (e.g. ``1.0``)
			build_tag (str, optional): Tag that is automatically set to the latest successful build of the current version.
			env_vars (list of dict, optional): Environment variables that will be available to the actor run process,
				and optionally also to the build process. See the API docs for their exact structure.
			apply_env_vars_to_build (bool, optional): Whether the environment variables specified for the actor run
				will also be set to the actor build process.
			source_type (ActorSourceType): What source type is the actor version using.
			source_files (list of dict, optional): Source code comprised of multiple files, each an item of the array.
				Required when ``source_type`` is ``ActorSourceType.SOURCE_FILES``. See the API docs for the exact structure.
			git_repo_url (str, optional): The URL of a Git repository from which the source code will be cloned.
				Required when ``source_type`` is ``ActorSourceType.GIT_REPO``.
			tarball_url (str, optional): The URL of a tarball or a zip archive from which the source code will be downloaded.
				Required when ``source_type`` is ``ActorSourceType.TARBALL``.
			github_gist_url (str, optional): The URL of a GitHub Gist from which the source will be downloaded.
				Required when ``source_type`` is ``ActorSourceType.GITHUB_GIST``.

		Returns:
			dict: The created actor version
		"""
=begin
		def create(
			self,
			*,
			version_number: str,
			build_tag: Optional[str] = None,
			env_vars: Optional[List[Dict]] = None,
			apply_env_vars_to_build: Optional[bool] = None,
			source_type: ActorSourceType,
			source_files: Optional[List[Dict]] = None,
			git_repo_url: Optional[str] = None,
			tarball_url: Optional[str] = None,
			github_gist_url: Optional[str] = None,
		) -> Dict:
			actor_version_representation = _get_actor_version_representation(
				version_number=version_number,
				build_tag=build_tag,
				env_vars=env_vars,
				apply_env_vars_to_build=apply_env_vars_to_build,
				source_type=source_type,
				source_files=source_files,
				git_repo_url=git_repo_url,
				tarball_url=tarball_url,
				github_gist_url=github_gist_url,
			)

			return self._create(filter_out_none_values_recursively(actor_version_representation))
=end

	end

end