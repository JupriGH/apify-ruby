module Apify

	module Models # apify-shared

		class ListPage
			"""A single page of items returned from a list() method."""

			attr_accessor :items, :count, :offset, :limit, :total, :desc

			def initialize data
				"""Initialize a ListPage instance from the API response data."""
				@items 	= data['items'] || []
				@offset	= data['offset'] || 0
				@limit 	= data['limit'] || 0
				@count 	= data['count'] || @items.length
				@total 	= data['total'] || (@offset + @count)
				@desc 	= data['desc'] || false
			end
		end
	end

	"""Sub-client for manipulating a single dataset."""
	class DatasetClient < ResourceClient

		"""Initialize the DatasetClient."""		
		def initialize **kwargs
			super resource_path: 'datasets', **kwargs 
		end

		"""Retrieve the dataset.

		https://docs.apify.com/api/v2#/reference/datasets/dataset/get-dataset

		Returns:
			dict, optional: The retrieved dataset, or None, if it does not exist
		"""
		def get =_get

		"""Update the dataset with specified fields.

		https://docs.apify.com/api/v2#/reference/datasets/dataset/update-dataset

		Args:
			name (str, optional): The new name for the dataset

		Returns:
			dict: The updated dataset
		"""
		def update name: nil, title: nil
			updated_fields = Utils::filter_out_none_values_recursively({ 'name': name, 'title': title })
			
			# if updated_fields.length > 0
			_update updated_fields
		end

		"""Delete the dataset.

		https://docs.apify.com/api/v2#/reference/datasets/dataset/delete-dataset
		"""		
		def delete = _delete

		"""List the items of the dataset.

		https://docs.apify.com/api/v2#/reference/datasets/item-collection/get-items

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
		def list_items offset: nil, limit: nil, clean: nil, desc: nil, fields: nil, omit: nil, unwind: nil, skip_empty: nil, skip_hidden: nil, flatten: nil, view: nil
			request_params = _params(
				offset: offset,
				limit: limit,
				desc: desc,
				clean: clean,
				fields: fields,
				omit: omit,
				unwind: unwind,
				skipEmpty: skip_empty,
				skipHidden: skip_hidden,
				flatten: flatten,
				view: view
			)

			res = @http_client.call url: _url('items'), method: 'GET', params: request_params
			
			response = res[:response]		
			data = res[:parsed]

			Models::ListPage.new({
				'items' 	=> data, # data,
				'total'		=> response['x-apify-pagination-total'].to_i,  # int
				'offset' 	=> response['x-apify-pagination-offset'].to_i, # int
				'count'		=> (data ? data.length : 0),  # because x-apify-pagination-count returns invalid values when hidden/empty items are skipped
				'limit' 	=> response['x-apify-pagination-limit'].to_i, # int  # API returns 999999999999 when no limit is used
				'desc' 		=> response['x-apify-pagination-desc'] == 'true'
			})
		end

		"""Iterate over the items in the dataset.

		https://docs.apify.com/api/v2#/reference/datasets/item-collection/get-items

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
			cache_size = 1000
			read_items = 0

			# We can't rely on ListPage.total because that is updated with a delay,
			# so if you try to read the dataset items right after a run finishes, you could miss some.
			# Instead, we just read and read until we reach the limit, or until there are no more items to read.

			while true #!should_finish
				
				effective_limit = cache_size
				if limit 
					break if read_items >= limit
					effective_limit = [cache_size, limit-read_items].min
				end
				
				## p "PAGE: #{offset + read_items} #{effective_limit}"
				
				items_page = list_items(
					offset: 		offset + read_items,
					limit: 			effective_limit,
					clean: 			clean,
					desc: 			desc,
					fields: 		fields,
					omit: 			omit,
					unwind: 		unwind,
					skip_empty: 	skip_empty,
					skip_hidden: 	skip_hidden
				) 

				items = items_page.items 
				
				items.each { |item| yield item }

				size = items.length
				read_items += size

				break if size < cache_size
			end
		end

		"""Get the items in the dataset as raw bytes.

		Deprecated: this function is a deprecated alias of `get_items_as_bytes`. It will be removed in a future version.

		https://docs.apify.com/api/v2#/reference/datasets/item-collection/get-items

		Args:
			item_format (str): Format of the results, possible values are: json, jsonl, csv, html, xlsx, xml and rss. The default value is json.
			offset (int, optional): Number of items that should be skipped at the start. The default value is 0
			limit (int, optional): Maximum number of items to return. By default there is no limit.
			desc (bool, optional): By default, results are returned in the same order as they were stored.
				To reverse the order, set this parameter to True.
			clean (bool, optional): If True, returns only non-empty items and skips hidden fields (i.e. fields starting with the # character).
				The clean parameter is just a shortcut for skip_hidden=True and skip_empty=True parameters.
				Note that since some objects might be skipped from the output, that the result might contain less items than the limit value.
			bom (bool, optional): All text responses are encoded in UTF-8 encoding.
				By default, csv files are prefixed with the UTF-8 Byte Order Mark (BOM),
				while json, jsonl, xml, html and rss files are not. If you want to override this default behavior,
				specify bom=True query parameter to include the BOM or bom=False to skip it.
			delimiter (str, optional): A delimiter character for CSV files. The default delimiter is a simple comma (,).
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
			skip_header_row (bool, optional): If True, then header row in the csv format is skipped.
			skip_hidden (bool, optional): If True, then hidden fields are skipped from the output, i.e. fields starting with the # character.
			xml_root (str, optional): Overrides default root element name of xml output. By default the root element is items.
			xml_row (str, optional): Overrides default element name that wraps each page or page function result object in xml output.
				By default the element name is item.
			flatten (list of str, optional): A list of fields that should be flattened

		Returns:
			bytes: The dataset items as raw bytes
		"""
=begin
		def download_items(
			self,
			*,
			item_format: str = 'json',
			offset: Optional[int] = None,
			limit: Optional[int] = None,
			desc: Optional[bool] = None,
			clean: Optional[bool] = None,
			bom: Optional[bool] = None,
			delimiter: Optional[str] = None,
			fields: Optional[List[str]] = None,
			omit: Optional[List[str]] = None,
			unwind: Optional[str] = None,
			skip_empty: Optional[bool] = None,
			skip_header_row: Optional[bool] = None,
			skip_hidden: Optional[bool] = None,
			xml_root: Optional[str] = None,
			xml_row: Optional[str] = None,
			flatten: Optional[List[str]] = None,
		) -> bytes:
			warnings.warn(
				'`DatasetClient.download_items()` is deprecated, use `DatasetClient.get_items_as_bytes()` instead.',
				DeprecationWarning,
				stacklevel=2,
			)

			return self.get_items_as_bytes(
				item_format=item_format,
				offset=offset,
				limit=limit,
				desc=desc,
				clean=clean,
				bom=bom,
				delimiter=delimiter,
				fields=fields,
				omit=omit,
				unwind=unwind,
				skip_empty=skip_empty,
				skip_header_row=skip_header_row,
				skip_hidden=skip_hidden,
				xml_root=xml_root,
				xml_row=xml_row,
				flatten=flatten,
			)
=end
		"""Get the items in the dataset as raw bytes.

		https://docs.apify.com/api/v2#/reference/datasets/item-collection/get-items

		Args:
			item_format (str): Format of the results, possible values are: json, jsonl, csv, html, xlsx, xml and rss. The default value is json.
			offset (int, optional): Number of items that should be skipped at the start. The default value is 0
			limit (int, optional): Maximum number of items to return. By default there is no limit.
			desc (bool, optional): By default, results are returned in the same order as they were stored.
				To reverse the order, set this parameter to True.
			clean (bool, optional): If True, returns only non-empty items and skips hidden fields (i.e. fields starting with the # character).
				The clean parameter is just a shortcut for skip_hidden=True and skip_empty=True parameters.
				Note that since some objects might be skipped from the output, that the result might contain less items than the limit value.
			bom (bool, optional): All text responses are encoded in UTF-8 encoding.
				By default, csv files are prefixed with the UTF-8 Byte Order Mark (BOM),
				while json, jsonl, xml, html and rss files are not. If you want to override this default behavior,
				specify bom=True query parameter to include the BOM or bom=False to skip it.
			delimiter (str, optional): A delimiter character for CSV files. The default delimiter is a simple comma (,).
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
			skip_header_row (bool, optional): If True, then header row in the csv format is skipped.
			skip_hidden (bool, optional): If True, then hidden fields are skipped from the output, i.e. fields starting with the # character.
			xml_root (str, optional): Overrides default root element name of xml output. By default the root element is items.
			xml_row (str, optional): Overrides default element name that wraps each page or page function result object in xml output.
				By default the element name is item.
			flatten (list of str, optional): A list of fields that should be flattened

		Returns:
			bytes: The dataset items as raw bytes
		"""
		def get_items_as_bytes(
			item_format: 'json',
			offset: nil,
			limit: nil,
			desc: nil,
			clean: nil,
			bom: nil,
			delimiter: nil,
			fields: nil,
			omit: nil,
			unwind: nil,
			skip_empty: nil,
			skip_header_row: nil,
			skip_hidden: nil,
			xml_root: nil,
			xml_row: nil,
			flatten: nil
		)
			request_params = _params(
				format: 		item_format,
				offset: 		offset,
				limit: 			limit,
				desc: 			desc,
				clean: 			clean,
				bom: 			bom,
				delimiter: 		delimiter,
				fields: 		fields,
				omit: 			omit,
				unwind: 		unwind,
				skipEmpty: 		skip_empty,
				skipHeaderRow: 	skip_header_row,
				skipHidden: 	skip_hidden,
				xmlRoot: 		xml_root,
				xmlRow: 		xml_row,
				flatten: 		flatten
			)

			res = @http_client.call url: _url('items'), method: 'GET', params: request_params, parse_response: false		
			res[:response].body
		end

		"""Retrieve the items in the dataset as a stream.

		https://docs.apify.com/api/v2#/reference/datasets/item-collection/get-items

		Args:
			item_format (str): Format of the results, possible values are: json, jsonl, csv, html, xlsx, xml and rss. The default value is json.
			offset (int, optional): Number of items that should be skipped at the start. The default value is 0
			limit (int, optional): Maximum number of items to return. By default there is no limit.
			desc (bool, optional): By default, results are returned in the same order as they were stored.
				To reverse the order, set this parameter to True.
			clean (bool, optional): If True, returns only non-empty items and skips hidden fields (i.e. fields starting with the # character).
				The clean parameter is just a shortcut for skip_hidden=True and skip_empty=True parameters.
				Note that since some objects might be skipped from the output, that the result might contain less items than the limit value.
			bom (bool, optional): All text responses are encoded in UTF-8 encoding.
				By default, csv files are prefixed with the UTF-8 Byte Order Mark (BOM),
				while json, jsonl, xml, html and rss files are not. If you want to override this default behavior,
				specify bom=True query parameter to include the BOM or bom=False to skip it.
			delimiter (str, optional): A delimiter character for CSV files. The default delimiter is a simple comma (,).
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
			skip_header_row (bool, optional): If True, then header row in the csv format is skipped.
			skip_hidden (bool, optional): If True, then hidden fields are skipped from the output, i.e. fields starting with the # character.
			xml_root (str, optional): Overrides default root element name of xml output. By default the root element is items.
			xml_row (str, optional): Overrides default element name that wraps each page or page function result object in xml output.
				By default the element name is item.

		Returns:
			httpx.Response: The dataset items as a context-managed streaming Response
		"""		
=begin
		@contextmanager
		def stream_items(
			self,
			*,
			item_format: str = 'json',
			offset: Optional[int] = None,
			limit: Optional[int] = None,
			desc: Optional[bool] = None,
			clean: Optional[bool] = None,
			bom: Optional[bool] = None,
			delimiter: Optional[str] = None,
			fields: Optional[List[str]] = None,
			omit: Optional[List[str]] = None,
			unwind: Optional[str] = None,
			skip_empty: Optional[bool] = None,
			skip_header_row: Optional[bool] = None,
			skip_hidden: Optional[bool] = None,
			xml_root: Optional[str] = None,
			xml_row: Optional[str] = None,
		) -> Iterator[httpx.Response]:
			response = None
			try:
				request_params = self._params(
					format=item_format,
					offset=offset,
					limit=limit,
					desc=desc,
					clean=clean,
					bom=bom,
					delimiter=delimiter,
					fields=fields,
					omit=omit,
					unwind=unwind,
					skipEmpty=skip_empty,
					skipHeaderRow=skip_header_row,
					skipHidden=skip_hidden,
					xmlRoot=xml_root,
					xmlRow=xml_row,
				)

				response = self.http_client.call(
					url=self._url('items'),
					method='GET',
					params=request_params,
					stream=True,
					parse_response=False,
				)
				yield response
			finally:
				if response:
					response.close()
=end

		"""Push items to the dataset.

		https://docs.apify.com/api/v2#/reference/datasets/item-collection/put-items

		Args:
			items: The items which to push in the dataset. Either a stringified JSON, a dictionary, or a list of strings or dictionaries.
		"""
		def push_items items			
			data = nil
			json = nil

			if items.class == String
				data = items
			else # Hash/dict
				json = items
			end
			
			@http_client.call(
				url: _url('items'),
				method: 'POST',
				headers: {'content-type': 'application/json; charset=utf-8'},
				params: _params,
				data: data,
				json: json
			)[:parsed]
		end
		
	end

	### DatasetCollectionClient

	"""Sub-client for manipulating datasets."""
	class DatasetCollectionClient < ResourceCollectionClient

		"""Initialize the DatasetCollectionClient with the passed arguments."""
		def initialize **kwargs
			super resource_path: 'datasets', **kwargs
		end 

		"""List the available datasets.

		https://docs.apify.com/api/v2#/reference/datasets/dataset-collection/get-list-of-datasets

		Args:
			unnamed (bool, optional): Whether to include unnamed datasets in the list
			limit (int, optional): How many datasets to retrieve
			offset (int, optional): What dataset to include as first when retrieving the list
			desc (bool, optional): Whether to sort the datasets in descending order based on their modification date

		Returns:
			ListPage: The list of available datasets matching the specified filters.
		"""
		def list unnamed: nil, limit: nil, offset: nil, desc: nil
			_list unnamed: unnamed, limit: limit, offset: offset, desc: desc
		end

		"""Retrieve a named dataset, or create a new one when it doesn't exist.

		https://docs.apify.com/api/v2#/reference/datasets/dataset-collection/create-dataset

		Args:
			name (str, optional): The name of the dataset to retrieve or create.
			schema (Dict, optional): The schema of the dataset

		Returns:
			dict: The retrieved or newly-created dataset.
		"""		
		def get_or_create name: nil, schema: nil
			resource = Utils::filter_out_none_values_recursively({'schema': schema})			
			_get_or_create name: name, resource: resource
		end

	end

end