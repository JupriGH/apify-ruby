def _get_schedule_representation(
	cron_expression: nil,
	is_enabled: nil,
	is_exclusive: nil,
	name: nil,
	actions: nil,
	description: nil,
	timezone: nil,
	title: nil
) = ({
	cronExpression: cron_expression,
	isEnabled: 		is_enabled,
	isExclusive:	is_exclusive,
	name:			name,
	actions:		actions,
	description:	description,
	timezone:		timezone,
	title:			title
})
		
module Apify

	"""Sub-client for manipulating a single schedule."""
	class ScheduleClient < ResourceClient

		"""Initialize the ScheduleClient."""
		def initialize(**kwargs) = super resource_path: 'schedules', **kwargs

		"""Return information about the schedule.

		https://docs.apify.com/api/v2#/reference/schedules/schedule-object/get-schedule

		Returns:
			dict, optional: The retrieved schedule
		"""			
		def get = _get

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
		def update(
			cron_expression: nil,
			is_enabled: nil,
			is_exclusive: nil,
			name: nil,
			actions: nil,
			description: nil,
			timezone: nil,
			title: nil
		)
			_update _get_schedule_representation(
				cron_expression: cron_expression,
				is_enabled: is_enabled,
				is_exclusive: is_exclusive,
				name: name,
				actions: actions,
				description: description,
				timezone: timezone,
				title: title
			)
		end

		"""Delete the schedule.

		https://docs.apify.com/api/v2#/reference/schedules/schedule-object/delete-schedule
		"""		
		def delete = _delete

		"""Return log for the given schedule.

		https://docs.apify.com/api/v2#/reference/schedules/schedule-log/get-schedule-log

		Returns:
			list, optional: Retrieved log of the given schedule
		"""		
		def get_log
			_http_get 'log', params: _params, pluck_data: true # _pluck_data_as_list			
		rescue ApifyApiError => exc
			Utils::_catch_not_found_or_throw(exc)
		end
	end

	### ScheduleCollectionClient
	
	"""Sub-client for manipulating schedules."""
	class ScheduleCollectionClient < ResourceCollectionClient

		"""Initialize the ScheduleCollectionClient with the passed arguments."""
		def initialize(**kwargs) = super resource_path: 'schedules', **kwargs

		"""List the available schedules.

		https://docs.apify.com/api/v2#/reference/schedules/schedules-collection/get-list-of-schedules

		Args:
			limit (int, optional): How many schedules to retrieve
			offset (int, optional): What schedules to include as first when retrieving the list
			desc (bool, optional): Whether to sort the schedules in descending order based on their modification date

		Returns:
			ListPage: The list of available schedules matching the specified filters.
		"""		
		def list(limit: nil, offset: nil, desc: nil) = _list limit: limit, offset: offset, desc: desc

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
		def create(
			cron_expression,
			is_enabled,
			is_exclusive,
			name: nil,
			actions: nil,
			description: nil,
			timezone: nil,
			title: nil
		)
			actions ||= []

			_create _get_schedule_representation(
				cron_expression: cron_expression,
				is_enabled: is_enabled,
				is_exclusive: is_exclusive,
				name: name,
				actions: actions,
				description: description,
				timezone: timezone,
				title: title
			)
		end
	end
end
