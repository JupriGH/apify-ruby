module Apify

	module MemoryStorage

	"""Sub-client for manipulating a single request queue."""
	class RequestQueueClient < BaseResourceClient

		STORAGE_TYPE = StorageTypes::REQUEST_QUEUE
		
		attr_accessor :_requests, :_handled_request_count, :_pending_request_count, :_last_used_timestamp
	
		"""Initialize the RequestQueueClient."""
		def initialize memory_storage_client, id: nil, name: nil
			super memory_storage_client, id: id, name: name
			@_requests = {} ### ValueSortedDict(lambda req: req.get('orderNo') or -float('inf'))
			@_handled_request_count = 0
			@_pending_request_count = 0
			@_last_used_timestamp = 0.0
		end

		"""Retrieve the request queue.

		Returns:
			dict, optional: The retrieved request queue, or None, if it does not exist
		"""
		# def get = super
	
		"""Update the request queue with specified fields.

		Args:
			name (str, optional): The new name for the request queue

		Returns:
			dict: The updated request queue
		"""
=begin
		async def update(self, *, name: Optional[str] = None) -> Dict:
			# Check by id
			existing_queue_by_id = self._find_or_create_client_by_id_or_name(
				memory_storage_client=self._memory_storage_client, id=self._id, name=self._name)

			if existing_queue_by_id is None:
				_raise_on_non_existing_storage(_StorageTypes.REQUEST_QUEUE, self._id)

			# Skip if no changes
			if name is None:
				return existing_queue_by_id._to_resource_info()

			async with existing_queue_by_id._file_operation_lock:
				# Check that name is not in use already
				existing_queue_by_name = next(
					(queue for queue in self._memory_storage_client._request_queues_handled if queue._name and queue._name.lower() == name.lower()), None)

				if existing_queue_by_name is not None:
					_raise_on_duplicate_storage(_StorageTypes.REQUEST_QUEUE, 'name', name)

				existing_queue_by_id._name = name

				previous_dir = existing_queue_by_id._resource_directory

				existing_queue_by_id._resource_directory = os.path.join(self._memory_storage_client._request_queues_directory, name)

				await _force_rename(previous_dir, existing_queue_by_id._resource_directory)

				# Update timestamps
				await existing_queue_by_id._update_timestamps(True)

				return existing_queue_by_id._to_resource_info()
=end

		"""Delete the request queue."""
		def delete
			store = @_memory_storage_client._pop_client self.class, id: @_id
			return unless store
			
			# async with store._file_operation_lock:
				store._pending_request_count = 0
				store._handled_request_count = 0
				store._requests.clear

				FileUtils.rm_rf store._resource_directory
		end
		
		"""Retrieve a given number of requests from the beginning of the queue.

		Args:
			limit (int, optional): How many requests to retrieve

		Returns:
			dict: The desired number of requests from the beginning of the queue.
		"""	
		def list_head limit: nil
			store = _check_id

			#async with store._file_operation_lock:
				store._update_timestamps false

				items = []

				# Iterate all requests in the queue which have sorted key larger than infinity, which means `orderNo` is not `None`
				# This will iterate them in order of `orderNo`
				
				### TODO
				
				#for request_key in store._requests.irange_key(min_key=-float('inf'), inclusive=(False, True)):
				store._requests.each_key do |request_key|
				
					break if items.length >= limit

					request = store._requests[request_key]

					# Check that the request still exists and was not handled,
					# in case something deleted it or marked it as handled concurrenctly
					if request && request[:orderNo]
						items << request
					end
				end

				{
					'limit' => limit,
					'hadMultipleClients' => false,
					'queueModifiedAt' => store._modified_at.utc.iso8601,
					'items' => items.map {|item| _json_to_request(item[:json])},
				}
		end
		
		"""Add a request to the queue.

		Args:
			request (dict): The request to add to the queue
			forefront (bool, optional): Whether to add the request to the head or the end of the queue

		Returns:
			dict: The added request.
		"""
		def add_request request, forefront: nil
			store = _check_id

			request_model = _create_internal_request(request, forefront)

			#async with store._file_operation_lock:
				existing_request_with_id = store._requests[request_model[:id]]

				# We already have the request present, so we return information about it
				if existing_request_with_id
					store._update_timestamps false
					return {
						'requestId' => existing_request_with_id['id'],
						'wasAlreadyHandled' => existing_request_with_id['orderNo'].nil?,
						'wasAlreadyPresent' => true,
					}
				end
				
				store._requests[request_model[:id]] = request_model
				if request_model[:orderNo].nil?
					store._handled_request_count += 1
				else
					store._pending_request_count += 1
				end
				
				store._update_timestamps true
				Utils::_update_request_queue_item(
					request: request_model,
					request_id: request_model[:id],
					entity_directory: store._resource_directory,
					persist_storage: @_memory_storage_client._persist_storage,
				)

				{
					'requestId' => request_model[:id],
					# We return wasAlreadyHandled: false even though the request may
					# have been added as handled, because that's how API behaves.
					'wasAlreadyHandled' => false,
					'wasAlreadyPresent' => false,
				}
		end
	
		"""Retrieve a request from the queue.

		Args:
			request_id (str): ID of the request to retrieve

		Returns:
			dict, optional: The retrieved request, or None, if it did not exist.
		"""
		def get_request request_id
			store = _check_id

			#async with store._file_operation_lock:
				store._update_timestamps false

				request_model = store._requests[request_id]
				_json_to_request (request_model ? request_model[:json] : nil)
		end

		"""Update a request in the queue.

		Args:
			request (dict): The updated request
			forefront (bool, optional): Whether to put the updated request in the beginning or the end of the queue

		Returns:
			dict: The updated request
		"""
		def update_request request, forefront: nil
			store = _check_id

			request_model = _create_internal_request(request, forefront)

			# First we need to check the existing request to be
			# able to return information about its handled state.

			existing_request = store._requests[request_model[:id]]

			# Undefined means that the request is not present in the queue.
			# We need to insert it, to behave the same as API.
			
			return add_request(request, forefront: forefront) if !existing_request
		
			# async with store._file_operation_lock:
				# When updating the request, we need to make sure that
				# the handled counts are updated correctly in all cases.
				store._requests[request_model[:id]] = request_model

				is_request_handled_state_changing = existing_request[:orderNo] != request_model[:orderNo] # TODO: type(existing_request[:orderNo]) != type(request_model[:orderNo])  # noqa
				request_was_handled_before_update = existing_request[:orderNo].nil?

				# We add 1 pending request if previous state was handled
				if is_request_handled_state_changing
					pending_count_adjustment = request_was_handled_before_update ? 1 : -1
					store._pending_request_count += pending_count_adjustment
					store._handled_request_count -= pending_count_adjustment				
				end

				store._update_timestamps true
				Utils::_update_request_queue_item(
					request: request_model,
					request_id: request_model[:id],
					entity_directory: store._resource_directory,
					persist_storage: @_memory_storage_client._persist_storage
				)

				{
					'requestId' => request_model[:id],
					'wasAlreadyHandled' => request_was_handled_before_update,
					'wasAlreadyPresent' => true,
				}
		end

        """Delete a request from the queue.

        Args:
            request_id (str): ID of the request to delete.
        """
=begin
		async def delete_request(self, request_id: str) -> None:
			existing_queue_by_id = self._find_or_create_client_by_id_or_name(
				memory_storage_client=self._memory_storage_client, id=self._id, name=self._name)

			if existing_queue_by_id is None:
				_raise_on_non_existing_storage(_StorageTypes.REQUEST_QUEUE, self._id)

			async with existing_queue_by_id._file_operation_lock:
				request = existing_queue_by_id._requests.get(request_id)

						if request:
							del existing_queue_by_id._requests[request_id]
							if request['orderNo'] is None:
								existing_queue_by_id._handled_request_count -= 1
							else:
								existing_queue_by_id._pending_request_count -= 1
							await existing_queue_by_id._update_timestamps(True)
							await _delete_request(entity_directory=existing_queue_by_id._resource_directory, request_id=request_id)
=end

		"""Retrieve the request queue store info."""
		def _to_resource_info 
			{
				'id' => @_id,
				'name' => @_name,
				'accessedAt' => @_accessed_at,
				'createdAt'=> @_created_at,
				'modifiedAt' => @_modified_at,
				'hadMultipleClients' => false,
				'handledRequestCount'=> @_handled_request_count,
				'pendingRequestCount' => @_pending_request_count,
				'stats' => {},
				'totalRequestCount' => @_requests.length,
				'userId' => '1',
			}
		end
	
		def _json_to_request request_json
			return unless request_json
			request = JSON.parse request_json
			Apify::Utils::filter_out_none_values_recursively(request)
		end

		def _create_internal_request request, forefront
			order_no = _calculate_order_no(request, forefront)
			id = Apify::Utils::_unique_key_to_request_id(request['uniqueKey'])

			raise 'Request ID does not match its unique_key.' if # ValueError
				request['id'] && request['id'] != id
				
			json_request = {**request, 'id' => id}.to_json
			
			{
				id: id,
				json: json_request,
				method: request['method'],
				orderNo: order_no,
				retryCount: request['retryCount']||0,
				uniqueKey: request['uniqueKey'],
				url: request['url'],
			}
		end
	
		def _calculate_order_no request, forefront
			return if request['handledAt']

			# Get the current timestamp in milliseconds
			timestamp = (Time.now.to_f * 1000).round(6)

			# Make sure that this timestamp was not used yet, so that we have unique orderNos
			if timestamp <= @_last_used_timestamp
				timestamp = @_last_used_timestamp + 0.000001
			end
			
			@_last_used_timestamp = timestamp
			forefront ? -timestamp : timestamp
		end
	
		def self._create_from_directory storage_directory, memory_storage_client, id, name=nil		
			created_at = accessed_at = modified_at = Time.now.utc
			handled_request_count = 0
			pending_request_count = 0
			
			entries = []

			# Access the request queue folder
			Dir.foreach(storage_directory) do |entry_name|
				entry_path = File.join(storage_directory, entry_name)
				next unless File.file?(entry_path)
				
				content = JSON.parse File.read(entry_path, encoding: 'utf-8'), symbolize_names: true

				if entry_name == '__metadata__.json'
					# We have found the queue's metadata file, build out information based on it
									
					id = content[:id]
					name = content[:name]
					created_at = Time.parse content[:createdAt]
					accessed_at = Time.parse content[:accessedAt]
					modified_at = Time.parse content[:modifiedAt]
					handled_request_count = content[:handledRequestCount]
					pending_request_count = content[:pendingRequestCount]

					next
				end

				content[:orderNo] = content[:orderNo].to_f if content[:orderNo]
				entries << content
			end
			
			new_client = new memory_storage_client, id: id, name: name

			# Overwrite properties
			new_client._accessed_at = accessed_at
			new_client._created_at = created_at
			new_client._modified_at = modified_at
			new_client._handled_request_count = handled_request_count
			new_client._pending_request_count = pending_request_count
			new_client._requests = entries.map {|request| [request[:id], request]}.to_h

			return new_client
		end
	end

	"""Sub-client for manipulating request queues."""
	class RequestQueueCollectionClient < BaseResourceCollectionClient

		CLIENT_CLASS = RequestQueueClient

		"""List the available request queues.

		Returns:
			ListPage: The list of available request queues matching the specified filters.
		"""
		# def list = super

		"""Retrieve a named request queue, or create a new one when it doesn't exist.

		Args:
			name (str, optional): The name of the request queue to retrieve or create.
			schema (Dict, optional): The schema of the request queue

		Returns:
			dict: The retrieved or newly-created request queue.
		"""
		# def get_or_create(name: nil, schema: nil, _id: nil) = super name: name, schema: schema, _id: _id
	end

	end
end