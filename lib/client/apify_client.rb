require_relative 'base/base_client'
require_relative 'base/resource_client'
require_relative 'base/actor_job_base_client'

require_relative 'http_client'
require_relative 'actor'
require_relative 'build'
require_relative 'version'
require_relative 'env_var'
require_relative 'run'
require_relative 'dataset'
require_relative 'key_value_store'
require_relative 'request_queue'
require_relative 'webhook'
require_relative 'webhook_dispatch'
require_relative 'schedule'
require_relative 'log'
require_relative 'user'
require_relative 'task'
require_relative 'store'

require_relative 'errors'
require_relative '../shared/utils'
require_relative 'utils'

module Apify

DEFAULT_API_URL = 'https://api.apify.com'
API_VERSION = 'v2'

=begin
	class BaseApifyClient ### Base for Sync and Async client
		@http_client

		def initialize token=nil, api_url: nil, max_retries: 8, min_delay_between_retries_millis: 500, timeout_secs: 360
			"""Initialize the Apify API Client.

			Args:
				token (str, optional): The Apify API token
				api_url (str, optional): The URL of the Apify API server to which to connect to. Defaults to https://api.apify.com
				max_retries (int, optional): How many times to retry a failed request at most
				min_delay_between_retries_millis (int, optional): How long will the client wait between retrying requests
					(increases exponentially from this value)
				timeout_secs (int, optional): The socket timeout of the HTTP requests sent to the Apify API
			"""		
			@token = token
			api_url = (api_url || DEFAULT_API_URL).sub(/\/+$/, '') # .rstrip('/')
			@base_url = "#{api_url}/#{API_VERSION}"
			@max_retries = max_retries || 8
			@min_delay_between_retries_millis = min_delay_between_retries_millis || 500
			@timeout_secs = timeout_secs || 360
		end
		
		def _options
			{ root_client: self, base_url: @base_url, http_client: @http_client }
		end
	end
=end

	# The Apify API client.
	class ApifyClient # < BaseApifyClient
		
		@http_client # _HTTPClient

		# Initialize the ApifyClient.
		#
		# Args:
		#	token (str, optional): The Apify API token
		#	api_url (str, optional): The URL of the Apify API server to which to connect to. Defaults to https://api.apify.com
		#	max_retries (int, optional): How many times to retry a failed request at most
		#	min_delay_between_retries_millis (int, optional): How long will the client wait between retrying requests
		#		(increases exponentially from this value)
		#	timeout_secs (int, optional): The socket timeout of the HTTP requests sent to the Apify API
		
		def initialize token=nil, api_url: nil, max_retries: 8, min_delay_between_retries_millis: 500, timeout_secs: 360
=begin
			super(
				token, 
				api_url: api_url, 
				max_retries: max_retries, 
				min_delay_between_retries_millis: min_delay_between_retries_millis, 
				timeout_secs: timeout_secs
			)
=end
			@token = token
			api_url = (api_url || DEFAULT_API_URL).sub(/\/+$/, '') # .rstrip('/')
			@base_url = "#{api_url}/#{API_VERSION}"
			@max_retries = max_retries || 8
			@min_delay_between_retries_millis = min_delay_between_retries_millis || 500
			@timeout_secs = timeout_secs || 360
			
			@http_client = HTTPClient.new(
				token: token, 
				max_retries: @max_retries, 
				min_delay_between_retries_millis: @min_delay_between_retries_millis, 
				timeout_secs: @timeout_secs
			)
		end
		
		def _options = { root_client: self, base_url: @base_url, http_client: @http_client }
		
		# Retrieve the sub-client for manipulating a single actor.
		#
		# Args:
		#	actor_id (str): ID of the actor to be manipulated
		def actor(actor_id) = ActorClient.new(resource_id: actor_id, **_options)
		
		# Retrieve the sub-client for manipulating actors.
		def actors = ActorCollectionClient.new(**_options)
		
		# Retrieve the sub-client for manipulating a single actor build.
		#
		# Args:
		#	build_id (str): ID of the actor build to be manipulated	
		def build(build_id) = BuildClient.new(resource_id: build_id, **_options)
		
		# Retrieve the sub-client for querying multiple builds of a user.
		def builds = BuildCollectionClient.new(**_options)
		
		# Retrieve the sub-client for manipulating a single actor run.
		#
		# Args:
		#	run_id (str): ID of the actor run to be manipulated
		def run(run_id) = RunClient.new(resource_id: run_id, **_options)
		
		# Retrieve the sub-client for querying multiple actor runs of a user.
		def runs = RunCollectionClient.new(**_options)
		
		# Retrieve the sub-client for manipulating a single dataset.
		#
		# Args:
		#	dataset_id (str): ID of the dataset to be manipulated
		def dataset(dataset_id) = DatasetClient.new(resource_id: dataset_id, **_options)

		# Retrieve the sub-client for manipulating datasets.
		def datasets = DatasetCollectionClient.new(**_options)
		
		# Retrieve the sub-client for manipulating a single key-value store.
		#
		# Args:
		#	key_value_store_id (str): ID of the key-value store to be manipulated
		def key_value_store(key_value_store_id) =
			KeyValueStoreClient.new(resource_id: key_value_store_id, **_options)
		
		# Retrieve the sub-client for manipulating key-value stores.
		def key_value_stores = KeyValueStoreCollectionClient.new(**_options)
		
		# Retrieve the sub-client for manipulating a single request queue.
		#
		# Args:
		#	request_queue_id (str): ID of the request queue to be manipulated
		#	client_key (str): A unique identifier of the client accessing the request queue
		def request_queue(request_queue_id, client_key: nil) =
			RequestQueueClient.new(resource_id: request_queue_id, client_key: client_key, **_options)

		# Retrieve the sub-client for manipulating request queues.
		def request_queues = RequestQueueCollectionClient.new(**_options)
		
		# Retrieve the sub-client for manipulating a single webhook.
		#
		# Args:
		#	webhook_id (str): ID of the webhook to be manipulated
		def webhook(webhook_id) = WebhookClient.new(resource_id: webhook_id, **_options)
		
		# Retrieve the sub-client for querying multiple webhooks of a user.
		def webhooks = WebhookCollectionClient.new(**_options)
		
		# Retrieve the sub-client for accessing a single webhook dispatch.
		#
		# Args:
		#	webhook_dispatch_id (str): ID of the webhook dispatch to access
		def webhook_dispatch(webhook_dispatch_id) = WebhookDispatchClient.new(resource_id: webhook_dispatch_id, **_options)
		
		# Retrieve the sub-client for querying multiple webhook dispatches of a user.
		def webhook_dispatches = WebhookDispatchCollectionClient.new(**_options)
		
		# Retrieve the sub-client for manipulating a single schedule.
		#
		# Args:
		#	schedule_id (str): ID of the schedule to be manipulated
		def schedule(schedule_id) = ScheduleClient.new(resource_id: schedule_id, **_options)
		
		# Retrieve the sub-client for manipulating schedules.
		def schedules = ScheduleCollectionClient.new(**_options)
		
		# Retrieve the sub-client for retrieving logs.
		#
		# Args:
		#	build_or_run_id (str): ID of the actor build or run for which to access the log
		#
		def log(build_or_run_id) = LogClient.new(resource_id: build_or_run_id, **_options)
		
		# Retrieve the sub-client for manipulating a single task.
		#
		# Args:
		#	task_id (str): ID of the task to be manipulated
		def task(task_id) = TaskClient.new(resource_id: task_id, **_options)
		
		# Retrieve the sub-client for manipulating tasks.
		def tasks = TaskCollectionClient.new(**_options)

		# Retrieve the sub-client for querying users.
		#
		# Args:
		#	user_id (str, optional): ID of user to be queried. If None, queries the user belonging to the token supplied to the client	
		def user(user_id=nil) = UserClient.new(resource_id: user_id, **_options)

		# Retrieve the sub-client for Apify store.
		def store = StoreCollectionClient.new(**_options)
	end

end