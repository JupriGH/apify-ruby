require_relative 'http_client'
require_relative 'clients/dataset'
require_relative 'clients/key_value_store'
require_relative 'clients/user'

module Apify

DEFAULT_API_URL = 'https://api.apify.com'
API_VERSION = 'v2'

class BaseApifyClient
    @http_client

    def initialize token: nil, api_url: nil, max_retries: 8, min_delay_between_retries_millis: 500, timeout_secs: 360
        """Initialize the Apify API Client.

        Args:
            token (str, optional): The Apify API token
            api_url (str, optional): The URL of the Apify API server to which to connect to. Defaults to https://api.apify.com
            max_retries (int, optional): How many times to retry a failed request at most
            min_delay_between_retries_millis (int, optional): How long will the client wait between retrying requests
                (increases exponentially from this value)
            timeout_secs (int, optional): The socket timeout of the HTTP requests sent to the Apify API
        """
        
		# TODO: ruby 0 == true
		
		@token = token
        @api_url = (api_url or DEFAULT_API_URL).sub(/\/+$/, '') # .rstrip('/')
        @base_url = "#{api_url}/#{API_VERSION}"
        @max_retries = max_retries or 8
        @min_delay_between_retries_millis = min_delay_between_retries_millis or 500
        @timeout_secs = timeout_secs or 360
	end
	
    def _options
        { root_client: self, base_url: @base_url, http_client: @http_client }
	end

end

class ApifyClient < BaseApifyClient
    """The Apify API client."""

    @http_client # _HTTPClient

    def initialize token: nil, api_url: nil, max_retries: 8, min_delay_between_retries_millis: 500, timeout_secs: 360
        """Initialize the ApifyClient.

        Args:
            token (str, optional): The Apify API token
            api_url (str, optional): The URL of the Apify API server to which to connect to. Defaults to https://api.apify.com
            max_retries (int, optional): How many times to retry a failed request at most
            min_delay_between_retries_millis (int, optional): How long will the client wait between retrying requests
                (increases exponentially from this value)
            timeout_secs (int, optional): The socket timeout of the HTTP requests sent to the Apify API
        """
        super \
            token: token, api_url: api_url, max_retries: max_retries, min_delay_between_retries_millis: min_delay_between_retries_millis, timeout_secs: timeout_secs
      
        @http_client = HTTPClient.new \
            token: token, max_retries: @max_retries, min_delay_between_retries_millis: @min_delay_between_retries_millis, timeout_secs: @timeout_secs
	end
	
=begin
    def actor(self, actor_id: str) -> ActorClient:
        """Retrieve the sub-client for manipulating a single actor.

        Args:
            actor_id (str): ID of the actor to be manipulated
        """
        return ActorClient(resource_id=actor_id, **self._options())

    def actors(self) -> ActorCollectionClient:
        """Retrieve the sub-client for manipulating actors."""
        return ActorCollectionClient(**self._options())

    def build(self, build_id: str) -> BuildClient:
        """Retrieve the sub-client for manipulating a single actor build.

        Args:
            build_id (str): ID of the actor build to be manipulated
        """
        return BuildClient(resource_id=build_id, **self._options())

    def builds(self) -> BuildCollectionClient:
        """Retrieve the sub-client for querying multiple builds of a user."""
        return BuildCollectionClient(**self._options())

    def run(self, run_id: str) -> RunClient:
        """Retrieve the sub-client for manipulating a single actor run.

        Args:
            run_id (str): ID of the actor run to be manipulated
        """
        return RunClient(resource_id=run_id, **self._options())

    def runs(self) -> RunCollectionClient:
        """Retrieve the sub-client for querying multiple actor runs of a user."""
        return RunCollectionClient(**self._options())
=end
    def dataset dataset_id
        """Retrieve the sub-client for manipulating a single dataset.

        Args:
            dataset_id (str): ID of the dataset to be manipulated
        """
        DatasetClient.new resource_id: dataset_id, **_options
	end
	
    def datasets
        """Retrieve the sub-client for manipulating datasets."""
        DatasetCollectionClient.new **_options
	end
	
    def key_value_store key_value_store_id
        """Retrieve the sub-client for manipulating a single key-value store.

        Args:
            key_value_store_id (str): ID of the key-value store to be manipulated
        """
        KeyValueStoreClient.new resource_id: key_value_store_id, **_options
	end
=begin
    def key_value_stores(self) -> KeyValueStoreCollectionClient:
        """Retrieve the sub-client for manipulating key-value stores."""
        return KeyValueStoreCollectionClient(**self._options())

    def request_queue(self, request_queue_id: str, *, client_key: Optional[str] = None) -> RequestQueueClient:
        """Retrieve the sub-client for manipulating a single request queue.

        Args:
            request_queue_id (str): ID of the request queue to be manipulated
            client_key (str): A unique identifier of the client accessing the request queue
        """
        return RequestQueueClient(resource_id=request_queue_id, client_key=client_key, **self._options())

    def request_queues(self) -> RequestQueueCollectionClient:
        """Retrieve the sub-client for manipulating request queues."""
        return RequestQueueCollectionClient(**self._options())

    def webhook(self, webhook_id: str) -> WebhookClient:
        """Retrieve the sub-client for manipulating a single webhook.

        Args:
            webhook_id (str): ID of the webhook to be manipulated
        """
        return WebhookClient(resource_id=webhook_id, **self._options())

    def webhooks(self) -> WebhookCollectionClient:
        """Retrieve the sub-client for querying multiple webhooks of a user."""
        return WebhookCollectionClient(**self._options())

    def webhook_dispatch(self, webhook_dispatch_id: str) -> WebhookDispatchClient:
        """Retrieve the sub-client for accessing a single webhook dispatch.

        Args:
            webhook_dispatch_id (str): ID of the webhook dispatch to access
        """
        return WebhookDispatchClient(resource_id=webhook_dispatch_id, **self._options())

    def webhook_dispatches(self) -> WebhookDispatchCollectionClient:
        """Retrieve the sub-client for querying multiple webhook dispatches of a user."""
        return WebhookDispatchCollectionClient(**self._options())

    def schedule(self, schedule_id: str) -> ScheduleClient:
        """Retrieve the sub-client for manipulating a single schedule.

        Args:
            schedule_id (str): ID of the schedule to be manipulated
        """
        return ScheduleClient(resource_id=schedule_id, **self._options())

    def schedules(self) -> ScheduleCollectionClient:
        """Retrieve the sub-client for manipulating schedules."""
        return ScheduleCollectionClient(**self._options())

    def log(self, build_or_run_id: str) -> LogClient:
        """Retrieve the sub-client for retrieving logs.

        Args:
            build_or_run_id (str): ID of the actor build or run for which to access the log
        """
        return LogClient(resource_id=build_or_run_id, **self._options())

    def task(self, task_id: str) -> TaskClient:
        """Retrieve the sub-client for manipulating a single task.

        Args:
            task_id (str): ID of the task to be manipulated
        """
        return TaskClient(resource_id=task_id, **self._options())

    def tasks(self) -> TaskCollectionClient:
        """Retrieve the sub-client for manipulating tasks."""
        return TaskCollectionClient(**self._options())
=end

    def user user_id: nil
        """Retrieve the sub-client for querying users.

        Args:
            user_id (str, optional): ID of user to be queried. If None, queries the user belonging to the token supplied to the client
        """
        UserClient.new resource_id: user_id, **_options
	end

=begin
    def store(self) -> StoreCollectionClient:
        """Retrieve the sub-client for Apify store."""
        return StoreCollectionClient(**self._options())
	end
=end

end

end