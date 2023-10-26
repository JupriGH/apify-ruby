module Apify

	"""The `Dataset` class represents a store for structured data where each object stored has the same attributes.

	You can imagine it as a table, where each object is a row and its attributes are columns.
	Dataset is an append-only storage - you can only add new records to it but you cannot modify or remove existing records.
	Typically it is used to store crawling results.

	Do not instantiate this class directly, use the `Actor.open_dataset()` function instead.

	`Dataset` stores its data either on local disk or in the Apify cloud,
	depending on whether the `APIFY_LOCAL_STORAGE_DIR` or `APIFY_TOKEN` environment variables are set.

	If the `APIFY_LOCAL_STORAGE_DIR` environment variable is set, the data is stored in
	the local directory in the following files:
	```
	{APIFY_LOCAL_STORAGE_DIR}/datasets/{DATASET_ID}/{INDEX}.json
	```
	Note that `{DATASET_ID}` is the name or ID of the dataset. The default dataset has ID: `default`,
	unless you override it by setting the `APIFY_DEFAULT_DATASET_ID` environment variable.
	Each dataset item is stored as a separate JSON file, where `{INDEX}` is a zero-based index of the item in the dataset.

	If the `APIFY_TOKEN` environment variable is set but `APIFY_LOCAL_STORAGE_DIR` is not, the data is stored in the
	[Apify Dataset](https://docs.apify.com/storage/dataset) cloud storage.
	"""

	class Dataset < BaseStorage
		
		HUMAN_FRIENDLY_LABEL = StorageTypes::DATASET
		
		"""Create a `Dataset` instance.

		Do not use the constructor directly, use the `Actor.open_dataset()` function instead.

		Args:
			id (str): ID of the dataset.
			name (str, optional): Name of the dataset.
			client (ApifyClientAsync or MemoryStorageClient): The storage client which should be used.
			config (Configuration): The configuration which should be used.
		"""
		def initialize id=nil, name: nil, client: nil, config: nil
			super id, name: name, client: client, config: config
			@_dataset_client = client.dataset @_id
		end
		
		    
		# def _get_human_friendly_label(cls) -> str:
		#    'Dataset'
		# end

		def self._get_default_id config
			config.default_dataset_id
		end

		def self._get_single_storage_client id, client
			client.dataset id
		end

		def self._get_storage_collection_client client
			client.datasets
		end

		"""Store an object or an array of objects to the dataset.

		The size of the data is limited by the receiving API and therefore `push_data()` will only
		allow objects whose JSON representation is smaller than 9MB. When an array is passed,
		none of the included objects may be larger than 9MB, but the array itself may be of any size.

		Args:
			data (JSONSerializable): dict or array of dicts containing data to be stored in the default dataset.
				The JSON representation of each item must be smaller than 9MB.
		"""
		def self.push_data data
			open.push_data data
		end

		def push_data data
			# Handle singular items
			if data.class != Array
				payload = _check_and_serialize(item: data)
				return @_dataset_client.push_items(payload)
			end
			
			# Handle lists
			"""
			payloads_generator = (_check_and_serialize(item, index) for index, item in enumerate(data))

			# Invoke client in series to preserve the order of data
			for chunk in _chunk_by_size(payloads_generator):
				await self._dataset_client.push_items(chunk)
			"""

			part, size = "[", 2		
			
			data.each_with_index do |item, index|
				item = _check_and_serialize(item: item, index: index)
				
				if (size + 1 + item.length) > EFFECTIVE_LIMIT_BYTES			
					# SEND
					part << "]"
					@_dataset_client.push_items(part)
					
					# RESET
					part, size = "[", 2
				end

				if size > 2
					part << ","
				end	
				
				part << item
				size += 1 + item.length
			end
			# LAST
			if size > 2
				part << "]"
				@_dataset_client.push_items(part)
			end		
		end

		"""Get items from the dataset.

		Args:
			offset (int, optional): Number of items that should be skipped at the start. The default value is 0
			limit (int, optional): Maximum number of items to return. By default there is no limit.
			desc (bool, optional): By default, results are returned in the same order as they were stored.
				To reverse the order, set this parameter to True.
			clean (bool, optional): If True, returns only non-empty items and skips hidden fields (i.e. fields starting with the # character).
				The clean parameter is just a shortcut for skip_hidden=True and skip_empty=True parameters.
				Note that since some objects might be skipped from the output, that the result might contain less items than the limit value.
			fields (list of str, optional): A list of fields which should be picked from the items,
				only these fields will remain in the resulting record objects.
				Note that the fields in the outputted items are sorted the same way as they are specified in the fields parameter.
				You can use this feature to effectively fix the output format.
			omit (list of str, optional): A list of fields which should be omitted from the items.
			unwind (str, optional): Name of a field which should be unwound.
				If the field is an array then every element of the array will become a separate record and merged with parent object.
				If the unwound field is an object then it is merged with the parent object.
				If the unwound field is missing or its value is neither an array nor an object and therefore cannot be merged with a parent object,
				then the item gets preserved as it is. Note that the unwound items ignore the desc parameter.
			skip_empty (bool, optional): If True, then empty items are skipped from the output.
				Note that if used, the results might contain less items than the limit value.
			skip_hidden (bool, optional): If True, then hidden fields are skipped from the output, i.e. fields starting with the # character.
			flatten (list of str, optional): A list of fields that should be flattened
			view (str, optional): Name of the dataset view to be used

		Returns:
			ListPage: A page of the list of dataset items according to the specified filters.
		"""		
		def self.get_data(
			offset: nil, limit: nil, clean: nil, desc: nil, fields: nil, omit: nil, unwind: nil, skip_empty: nil, skip_hidden: nil, flatten: nil, view: nil
		)
			open.get_data(
				offset: offset,
				limit: limit,
				desc: desc,
				clean: clean,
				fields: fields,
				omit: omit,
				unwind: unwind,
				skip_empty: skip_empty,
				skip_hidden: skip_hidden,
				flatten: flatten,
				view: view
			)
		end

		def get_data offset: nil, limit: nil, clean: nil, desc: nil, fields: nil, omit: nil, unwind: nil, skip_empty: nil, skip_hidden: nil, flatten: nil, view: nil
		
			# try {
			#     return await this.client.listItems(options);
			# } catch (e) {
			#     const error = e as Error;
			#     if (error.message.includes('Cannot create a string longer than')) {
			#         throw new Error('dataset.getData(): The response is too large for parsing. You can fix this by lowering the "limit" option.');
			#     }
			#     throw e;
			# }
			# TODO: Simulate the above error in Python and handle accordingly...
			
			@_dataset_client.list_items(
				offset: offset,
				limit: limit,
				desc: desc,
				clean: clean,
				fields: fields,
				omit: omit,
				unwind: unwind,
				skip_empty: skip_empty,
				skip_hidden: skip_hidden,
				flatten: flatten,
				view: view
			)
		end

		"""Save the entirety of the dataset's contents into one file within a key-value store.

		Args:
			key (str): The key to save the data under.
			to_key_value_store_id (str, optional): The id of the key-value store in which the result will be saved.
			to_key_value_store_name (str, optional): The name of the key-value store in which the result will be saved.
				You must specify only one of `to_key_value_store_id` and `to_key_value_store_name` arguments.
				If you omit both, it uses the default key-value store.
			content_type (str, optional): Either 'text/csv' or 'application/json'. Defaults to JSON.
		"""		
		def export_to( 
			key, 
			to_key_value_store_id: nil, 
			to_key_value_store_name: nil, 
			content_type: nil,
			force_cloud: nil ### NEW
		)

			key_value_store = KeyValueStore.open to_key_value_store_id, name: to_key_value_store_name, force_cloud: force_cloud

			items, offset, limit = [], 0, 1000

			while true
				list_items = @_dataset_client.list_items limit: limit, offset: offset

				items.push *list_items.items
				
				o = offset + list_items.count
				break if list_items.total <= o				
				offset = o
			end
			
			raise 'Cannot export an empty dataset' if items.empty? # ValueError

			if ['csv','text/csv'].include?(content_type) 
				## "TODO: csv check columns orders!"				
				csv_string = CSV.generate do |csv|
					csv << items[0].keys
					items.each { |row| csv << row.values }
				end
				return key_value_store.set_value key, csv_string, 'text/csv'
			end
			
			if ['json','text/json','application/json'].include?(content_type) 
				return key_value_store.set_value key, items, 'application/json'
			end
			
			raise "Unsupported content type: #{content_type}" # ValueError
		end

		"""Save the entirety of the dataset's contents into one JSON file within a key-value store.

		Args:
			key (str): The key to save the data under.
			from_dataset_id (str, optional): The ID of the dataset in case of calling the class method. Uses default dataset if omitted.
			from_dataset_name (str, optional): The name of the dataset in case of calling the class method. Uses default dataset if omitted.
				You must specify only one of `from_dataset_id` and `from_dataset_name` arguments.
				If you omit both, it uses the default dataset.
			to_key_value_store_id (str, optional): The id of the key-value store in which the result will be saved.
			to_key_value_store_name (str, optional): The name of the key-value store in which the result will be saved.
				You must specify only one of `to_key_value_store_id` and `to_key_value_store_name` arguments.
				If you omit both, it uses the default key-value store.
		"""
		def self.export_to_json(
			key,
			from_dataset_id: nil,
			from_dataset_name: nil,
			to_key_value_store_id: nil,
			to_key_value_store_name: nil,
			force_cloud: nil  ### NEW
		)
			dataset = open id: from_dataset_id, name: from_dataset_name, force_cloud: force_cloud
			dataset.export_to_json(
				key, 
				to_key_value_store_id: to_key_value_store_id, 
				to_key_value_store_name: to_key_value_store_name,
				force_cloud: force_cloud
			)
		end
		
		def export_to_json(
			key,
			to_key_value_store_id: nil,
			to_key_value_store_name: nil,
			force_cloud: nil ### NEW
		)
			export_to(
				key, 
				to_key_value_store_id: to_key_value_store_id, 
				to_key_value_store_name: to_key_value_store_name,
				force_cloud: force_cloud,
				content_type: 'application/json'
			)
		end
		
		"""Save the entirety of the dataset's contents into one CSV file within a key-value store.

		Args:
			key (str): The key to save the data under.
			from_dataset_id (str, optional): The ID of the dataset in case of calling the class method. Uses default dataset if omitted.
			from_dataset_name (str, optional): The name of the dataset in case of calling the class method. Uses default dataset if omitted.
				You must specify only one of `from_dataset_id` and `from_dataset_name` arguments.
				If you omit both, it uses the default dataset.
			to_key_value_store_id (str, optional): The id of the key-value store in which the result will be saved.
			to_key_value_store_name (str, optional): The name of the key-value store in which the result will be saved.
				You must specify only one of `to_key_value_store_id` and `to_key_value_store_name` arguments.
				If you omit both, it uses the default key-value store.
		"""
		def self.export_to_csv(
			key,
			from_dataset_id: nil,
			from_dataset_name: nil,
			to_key_value_store_id: nil,
			to_key_value_store_name: nil,
			force_cloud: nil  ### NEW
		)
			dataset = open id: from_dataset_id, name: from_dataset_name, force_cloud: force_cloud
			dataset.export_to_csv(
				key, 
				to_key_value_store_id: to_key_value_store_id, 
				to_key_value_store_name: to_key_value_store_name,
				force_cloud: force_cloud
			)
		end
		
		def export_to_csv(
			key,
			to_key_value_store_id: nil,
			to_key_value_store_name: nil,
			force_cloud: nil ### NEW
		)
			export_to(
				key, 
				to_key_value_store_id: to_key_value_store_id, 
				to_key_value_store_name: to_key_value_store_name, 
				force_cloud: force_cloud,
				content_type: 'text/csv'
			)
		end

		"""Get an object containing general information about the dataset.

		Returns:
			dict: Object returned by calling the GET dataset API endpoint.
		"""		
		def get_info
			@_dataset_client.get
		end

		"""Iterate over the items in the dataset.

		Args:
			offset (int, optional): Number of items that should be skipped at the start. The default value is 0
			limit (int, optional): Maximum number of items to return. By default there is no limit.
			desc (bool, optional): By default, results are returned in the same order as they were stored.
				To reverse the order, set this parameter to True.
			clean (bool, optional): If True, returns only non-empty items and skips hidden fields (i.e. fields starting with the # character).
				The clean parameter is just a shortcut for skip_hidden=True and skip_empty=True parameters.
				Note that since some objects might be skipped from the output, that the result might contain less items than the limit value.
			fields (list of str, optional): A list of fields which should be picked from the items,
				only these fields will remain in the resulting record objects.
				Note that the fields in the outputted items are sorted the same way as they are specified in the fields parameter.
				You can use this feature to effectively fix the output format.
			omit (list of str, optional): A list of fields which should be omitted from the items.
			unwind (str, optional): Name of a field which should be unwound.
				If the field is an array then every element of the array will become a separate record and merged with parent object.
				If the unwound field is an object then it is merged with the parent object.
				If the unwound field is missing or its value is neither an array nor an object and therefore cannot be merged with a parent object,
				then the item gets preserved as it is. Note that the unwound items ignore the desc parameter.
			skip_empty (bool, optional): If True, then empty items are skipped from the output.
				Note that if used, the results might contain less items than the limit value.
			skip_hidden (bool, optional): If True, then hidden fields are skipped from the output, i.e. fields starting with the # character.

		Yields:
			dict: An item from the dataset
		"""		
		def iterate_items(
			offset: 0,
			limit: nil,
			clean: nil,
			desc: nil,
			fields: nil,
			omit: nil,
			unwind: nil,
			skip_empty: nil,
			skip_hidden: nil
		)
			@_dataset_client.iterate_items(
				offset: offset,
				limit: limit,
				clean: clean,
				desc: desc,
				fields: fields,
				omit: omit,
				unwind: unwind,
				skip_empty: skip_empty,
				skip_hidden: skip_hidden
			) do |item|
				yield item
			end
		end
		

		"""Remove the dataset either from the Apify cloud storage or from the local directory."""
		def drop
			@_dataset_client.delete
			#_remove_from_cache
		end

		"""Open a dataset.

		Datasets are used to store structured data where each object stored has the same attributes,
		such as online store products or real estate offers.
		The actual data is stored either on the local filesystem or in the Apify cloud.

		Args:
			id (str, optional): ID of the dataset to be opened.
				If neither `id` nor `name` are provided, the method returns the default dataset associated with the actor run.
				If the dataset with the given ID does not exist, it raises an error.
			name (str, optional): Name of the dataset to be opened.
				If neither `id` nor `name` are provided, the method returns the default dataset associated with the actor run.
				If the dataset with the given name does not exist, it is created.
			force_cloud (bool, optional): If set to True, it will open a dataset on the Apify Platform even when running the actor locally.
				Defaults to False.
			config (Configuration, optional): A `Configuration` instance, uses global configuration if omitted.

		Returns:
			Dataset: An instance of the `Dataset` class for the given ID or name.
		"""
		def self.open id=nil, name: nil, force_cloud: nil, config: nil
			_open_internal id, name: name, force_cloud: force_cloud, config: config
		end
	end

end


### Helpers

MAX_PAYLOAD_SIZE_BYTES = Apify::MAX_PAYLOAD_SIZE_BYTES
SAFETY_BUFFER_PERCENT = 0.01 / 100
EFFECTIVE_LIMIT_BYTES = MAX_PAYLOAD_SIZE_BYTES - (MAX_PAYLOAD_SIZE_BYTES * SAFETY_BUFFER_PERCENT).ceil

"""Accept a JSON serializable object as an input, validate its serializability and its serialized size against `EFFECTIVE_LIMIT_BYTES`."""
def _check_and_serialize item: nil, index: nil
    s = index ? " at index #{index} " : " "

    #try:
        payload = item.to_json
    #except Exception as e:
    #    raise ValueError(f'Data item{s}is not serializable to JSON.') from e

    length_bytes = payload.length # len(payload.encode('utf-8'))
    if length_bytes > EFFECTIVE_LIMIT_BYTES
        raise "Data item#{s}is too large (size: #{length_bytes} bytes, limit: #{EFFECTIVE_LIMIT_BYTES} bytes)" # ValueError
	end
	
    return payload
end

"""Take an array of JSONs, produce iterator of chunked JSON arrays respecting `EFFECTIVE_LIMIT_BYTES`.

Takes an array of JSONs (payloads) as input and produces an iterator of JSON strings
where each string is a JSON array of payloads with a maximum size of `EFFECTIVE_LIMIT_BYTES` per one
JSON array. Fits as many payloads as possible into a single JSON array and then moves
on to the next, preserving item order.

The function assumes that none of the items is larger than `EFFECTIVE_LIMIT_BYTES` and does not validate.
"""
=begin
def _chunk_by_size items
	"""
    last_chunk_bytes = 2  # Add 2 bytes for [] wrapper.
    current_chunk = []

    for payload in items:
        length_bytes = len(payload.encode('utf-8'))

        if last_chunk_bytes + length_bytes <= EFFECTIVE_LIMIT_BYTES:
            current_chunk.append(payload)
            last_chunk_bytes += length_bytes + 1  # Add 1 byte for ',' separator.
        else:
            yield f'[{",".join(current_chunk)}]'
            current_chunk = [payload]
            last_chunk_bytes = length_bytes + 2  # Add 2 bytes for [] wrapper.

    yield f'[{",".join(current_chunk)}]'
	"""
end
=end