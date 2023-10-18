=begin
from apify_shared.utils import filter_out_none_values_recursively, ignore_docs
from ..._errors import ApifyApiError
from ..._utils import _catch_not_found_or_throw, _pluck_data_as_list
=end

module Apify

=begin

def _get_schedule_representation(
    cron_expression: Optional[str] = None,
    is_enabled: Optional[bool] = None,
    is_exclusive: Optional[bool] = None,
    name: Optional[str] = None,
    actions: Optional[List[Dict]] = None,
    description: Optional[str] = None,
    timezone: Optional[str] = None,
    title: Optional[str] = None,
) -> Dict:
    return {
        'cronExpression': cron_expression,
        'isEnabled': is_enabled,
        'isExclusive': is_exclusive,
        'name': name,
        'actions': actions,
        'description': description,
        'timezone': timezone,
        'title': title,
    }

=end

class ScheduleClient < ResourceClient
    """Sub-client for manipulating a single schedule."""

    def initialize **kwargs
        """Initialize the ScheduleClient."""
        super resource_path: 'schedules', **kwargs
	end
		
    def get
        """Return information about the schedule.

        https://docs.apify.com/api/v2#/reference/schedules/schedule-object/get-schedule

        Returns:
            dict, optional: The retrieved schedule
        """
        _get
	end

=begin
    def update(
        self,
        *,
        cron_expression: Optional[str] = None,
        is_enabled: Optional[bool] = None,
        is_exclusive: Optional[bool] = None,
        name: Optional[str] = None,
        actions: Optional[List[Dict]] = None,
        description: Optional[str] = None,
        timezone: Optional[str] = None,
        title: Optional[str] = None,
    ) -> Dict:
        """Update the schedule with specified fields.

        https://docs.apify.com/api/v2#/reference/schedules/schedule-object/update-schedule

        Args:
            cron_expression (str, optional): The cron expression used by this schedule
            is_enabled (bool, optional): True if the schedule should be enabled
            is_exclusive (bool, optional): When set to true, don't start actor or actor task if it's still running from the previous schedule.
            name (str, optional): The name of the schedule to create.
            actions (list of dict, optional): Actors or tasks that should be run on this schedule. See the API documentation for exact structure.
            description (str, optional): Description of this schedule
            timezone (str, optional): Timezone in which your cron expression runs
                                      (TZ database name from https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
            title (str, optional): A human-friendly equivalent of the name

        Returns:
            dict: The updated schedule
        """
        schedule_representation = _get_schedule_representation(
            cron_expression=cron_expression,
            is_enabled=is_enabled,
            is_exclusive=is_exclusive,
            name=name,
            actions=actions,
            description=description,
            timezone=timezone,
            title=title,
        )

        return self._update(filter_out_none_values_recursively(schedule_representation))

    def delete(self) -> None:
        """Delete the schedule.

        https://docs.apify.com/api/v2#/reference/schedules/schedule-object/delete-schedule
        """
        self._delete()
=end

    def get_log
        """Return log for the given schedule.

        https://docs.apify.com/api/v2#/reference/schedules/schedule-log/get-schedule-log

        Returns:
            list, optional: Retrieved log of the given schedule
        """
        #try:
            res = @http_client.call url: _url('log'), method: 'GET', params: _params
            res && res.dig(:parsed, "data")
			#return _pluck_data_as_list(response.json())
        
		#except ApifyApiError as exc:
        #    _catch_not_found_or_throw(exc)

        #return None
	end
end

=begin
from apify_shared.utils import filter_out_none_values_recursively, ignore_docs
=end

class ScheduleCollectionClient < ResourceCollectionClient
    """Sub-client for manipulating schedules."""

    def initialize **kwargs
        """Initialize the ScheduleCollectionClient with the passed arguments."""
        super resource_path: 'schedules', **kwargs
	end
	
    def list limit: nil, offset: nil, desc: nil
        """List the available schedules.

        https://docs.apify.com/api/v2#/reference/schedules/schedules-collection/get-list-of-schedules

        Args:
            limit (int, optional): How many schedules to retrieve
            offset (int, optional): What schedules to include as first when retrieving the list
            desc (bool, optional): Whether to sort the schedules in descending order based on their modification date

        Returns:
            ListPage: The list of available schedules matching the specified filters.
        """
        _list limit: limit, offset: offset, desc: desc
	end
=begin
    def create(
        self,
        *,
        cron_expression: str,
        is_enabled: bool,
        is_exclusive: bool,
        name: Optional[str] = None,
        actions: Optional[List[Dict]] = None,
        description: Optional[str] = None,
        timezone: Optional[str] = None,
        title: Optional[str] = None,
    ) -> Dict:
        """Create a new schedule.

        https://docs.apify.com/api/v2#/reference/schedules/schedules-collection/create-schedule

        Args:
            cron_expression (str): The cron expression used by this schedule
            is_enabled (bool): True if the schedule should be enabled
            is_exclusive (bool): When set to true, don't start actor or actor task if it's still running from the previous schedule.
            name (str, optional): The name of the schedule to create.
            actions (list of dict, optional): Actors or tasks that should be run on this schedule. See the API documentation for exact structure.
            description (str, optional): Description of this schedule
            timezone (str, optional): Timezone in which your cron expression runs
                (TZ database name from https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

        Returns:
            dict: The created schedule.
        """
        if not actions:
            actions = []

        schedule_representation = _get_schedule_representation(
            cron_expression=cron_expression,
            is_enabled=is_enabled,
            is_exclusive=is_exclusive,
            name=name,
            actions=actions,
            description=description,
            timezone=timezone,
            title=title,
        )

        return self._create(filter_out_none_values_recursively(schedule_representation))
=end

end

end