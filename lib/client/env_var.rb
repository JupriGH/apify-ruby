
def _get_actor_env_var_representation(
    is_secret: nil,
    name: nil,
    value: nil
)
    {
        'isSecret' => is_secret,
        'name' => name,
        'value' => value,
    }
end

module Apify

	"""Sub-client for manipulating a single actor environment variable."""
	class ActorEnvVarClient < ResourceClient
		
		"""Initialize the ActorEnvVarClient."""
		def initialize(**kwargs) = super(resource_path: 'env-vars', **kwargs)

		"""Return information about the actor environment variable.

		https://docs.apify.com/api/v2#/reference/actors/environment-variable-object/get-environment-variable

		Returns:
			dict, optional: The retrieved actor environment variable data
		"""		
		def get = _get

		"""Update the actor environment variable with specified fields.

		https://docs.apify.com/api/v2#/reference/actors/environment-variable-object/update-environment-variable

		Args:
			is_secret (bool, optional): Whether the environment variable is secret or not
			name (str): The name of the environment variable
			value (str): The value of the environment variable

		Returns:
			dict: The updated actor environment variable
		"""
		def update name, value, is_secret=nil 
			actor_env_var_representation = Utils:: filter_out_none_values_recursively(
				_get_actor_env_var_representation(
					is_secret: is_secret,
					name: name,
					value: value
				)
			)
			_update actor_env_var_representation
		end
		
		"""Delete the actor environment variable.

		https://docs.apify.com/api/v2#/reference/actors/environment-variable-object/delete-environment-variable
		"""
		def delete = _delete
	end

	"""Sub-client for manipulating actor env vars."""
	class ActorEnvVarCollectionClient < ResourceCollectionClient

		"""Initialize the ActorEnvVarCollectionClient with the passed arguments."""
		def initialize(**kwargs) = super(resource_path: 'env-vars', **kwargs)

		"""List the available actor environment variables.

		https://docs.apify.com/api/v2#/reference/actors/environment-variable-collection/get-list-of-environment-variables

		Returns:
			ListPage: The list of available actor environment variables.
		"""		
		def list = _list

		"""Create a new actor environment variable.

		https://docs.apify.com/api/v2#/reference/actors/environment-variable-collection/create-environment-variable

		Args:
			is_secret (bool, optional): Whether the environment variable is secret or not
			name (str): The name of the environment variable
			value (str): The value of the environment variable

		Returns:
			dict: The created actor environment variable
		"""
		def create name, value, is_secret=nil  
			actor_env_var_representation = Utils::filter_out_none_values_recursively(
				_get_actor_env_var_representation(
					is_secret: is_secret,
					name: name,
					value: value
				)
			)
			_create actor_env_var_representation
		end
	end
end