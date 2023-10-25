=begin
import asyncio
import json
import os
from datetime import datetime, timezone
from typing import TYPE_CHECKING, Any, AsyncIterator, Dict, List, Optional, Tuple

import aioshutil

from ..._utils import _force_rename, _raise_on_duplicate_storage, _raise_on_non_existing_storage
from ...consts import _StorageTypes
from ..file_storage_utils import _update_dataset_items, _update_metadata
from .base_resource_client import BaseResourceClient

if TYPE_CHECKING:
    from ..memory_storage_client import MemoryStorageClient
=end

module Apify

	module MemoryStorage

	"""Sub-client for manipulating a single dataset."""
	class DatasetClient < BaseResourceClient

		# This is what API returns in the x-apify-pagination-limit
		# header when no limit query parameter is used.
		LIST_ITEMS_LIMIT = 999_999_999_999

		# Number of characters of the dataset item file names.
		# E.g.: 000000019.json - 9 digits
		LOCAL_ENTRY_NAME_DIGITS = 9

		attr_accessor :_created_at, :_accessed_at, :_modified_at, :_item_count, :_dataset_entries
		
		"""Initialize the DatasetClient."""
		def initialize memory_storage_client, id: nil, name: nil
			super
			@_dataset_entries = {}		
			@_item_count = 0
		end
		
		"""Retrieve the dataset.

		Returns:
			dict, optional: The retrieved dataset, or None, if it does not exist
		"""
		# def get = super

		"""Update the dataset with specified fields.

		Args:
			name (str, optional): The new name for the dataset

		Returns:
			dict: The updated dataset
		"""
=begin
		async def update(self, *, name: Optional[str] = None) -> Dict:

			# Check by id
			existing_dataset_by_id = self._find_or_create_client_by_id_or_name(
				memory_storage_client=self._memory_storage_client,
				id=self._id,
				name=self._name,
			)

			if existing_dataset_by_id is None:
				_raise_on_non_existing_storage(_StorageTypes.DATASET, self._id)

			# Skip if no changes
			if name is None:
				return existing_dataset_by_id._to_resource_info()

			async with existing_dataset_by_id._file_operation_lock:
				# Check that name is not in use already
				existing_dataset_by_name = next(
					(dataset for dataset in self._memory_storage_client._datasets_handled if dataset._name and dataset._name.lower() == name.lower()),
					None,
				)

				if existing_dataset_by_name is not None:
					_raise_on_duplicate_storage(_StorageTypes.DATASET, 'name', name)

				existing_dataset_by_id._name = name

				previous_dir = existing_dataset_by_id._resource_directory

				existing_dataset_by_id._resource_directory = os.path.join(self._memory_storage_client._datasets_directory, name)

				await _force_rename(previous_dir, existing_dataset_by_id._resource_directory)

				# Update timestamps
				await existing_dataset_by_id._update_timestamps(True)

			return existing_dataset_by_id._to_resource_info()
=end

		"""Delete the dataset."""
=begin
		def delete
			dataset = next((dataset for dataset in self._memory_storage_client._datasets_handled if dataset._id == self._id), None)
			return unless dataset

			# async with dataset._file_operation_lock:

				self._memory_storage_client._datasets_handled.remove(dataset)
				dataset._item_count = 0
				dataset._dataset_entries.clear()

				if os.path.exists(dataset._resource_directory):
					await aioshutil.rmtree(dataset._resource_directory)
		end
=end
		"""List the items of the dataset.

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
=begin
		async def list_items(
			self,
			*,
			offset: Optional[int] = 0,
			limit: Optional[int] = LIST_ITEMS_LIMIT,
			clean: Optional[bool] = None,  # noqa: U100
			desc: Optional[bool] = None,
			fields: Optional[List[str]] = None,  # noqa: U100
			omit: Optional[List[str]] = None,  # noqa: U100
			unwind: Optional[str] = None,  # noqa: U100
			skip_empty: Optional[bool] = None,  # noqa: U100
			skip_hidden: Optional[bool] = None,  # noqa: U100
			flatten: Optional[List[str]] = None,  # noqa: U100
			view: Optional[str] = None,  # noqa: U100
		) -> ListPage:
			# Check by id
			existing_dataset_by_id = self._find_or_create_client_by_id_or_name(
				memory_storage_client=self._memory_storage_client,
				id=self._id,
				name=self._name,
			)

			if existing_dataset_by_id is None:
				_raise_on_non_existing_storage(_StorageTypes.DATASET, self._id)

			async with existing_dataset_by_id._file_operation_lock:
				start, end = existing_dataset_by_id._get_start_and_end_indexes(
					max(existing_dataset_by_id._item_count - (offset or 0) - (limit or LIST_ITEMS_LIMIT), 0) if desc else offset or 0,
					limit,
				)

				items = []

				for idx in range(start, end):
					entry_number = self._generate_local_entry_name(idx)
					items.append(existing_dataset_by_id._dataset_entries[entry_number])

				await existing_dataset_by_id._update_timestamps(False)

				if desc:
					items.reverse()

				return ListPage({
					'count': len(items),
					'desc': desc or False,
					'items': items,
					'limit': limit or LIST_ITEMS_LIMIT,
					'offset': offset or 0,
					'total': existing_dataset_by_id._item_count,
				})
=end
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
=begin
		async def iterate_items(
			self,
			*,
			offset: int = 0,
			limit: Optional[int] = None,
			clean: Optional[bool] = None,  # noqa: U100
			desc: Optional[bool] = None,
			fields: Optional[List[str]] = None,  # noqa: U100
			omit: Optional[List[str]] = None,  # noqa: U100
			unwind: Optional[str] = None,  # noqa: U100
			skip_empty: Optional[bool] = None,  # noqa: U100
			skip_hidden: Optional[bool] = None,  # noqa: U100
		) -> AsyncIterator[Dict]:
			cache_size = 1000
			first_item = offset

			# If there is no limit, set last_item to None until we get the total from the first API response
			if limit is None:
				last_item = None
			else:
				last_item = offset + limit

			current_offset = first_item
			while last_item is None or current_offset < last_item:
				if last_item is None:
					current_limit = cache_size
				else:
					current_limit = min(cache_size, last_item - current_offset)

				current_items_page = await self.list_items(
					offset=current_offset,
					limit=current_limit,
					desc=desc,
				)

				current_offset += current_items_page.count
				if last_item is None or current_items_page.total < last_item:
					last_item = current_items_page.total

				for item in current_items_page.items:
					yield item
=end
		
		#async def get_items_as_bytes(self, *_args: Any, **_kwargs: Any) -> bytes:  # noqa: D102
		#	raise NotImplementedError('This method is not supported in local memory storage.')

		#async def stream_items(self, *_args: Any, **_kwargs: Any) -> AsyncIterator:  # noqa: D102
		#	raise NotImplementedError('This method is not supported in local memory storage.')

		"""Push items to the dataset.

		Args:
			items: The items which to push in the dataset. Either a stringified JSON, a dictionary, or a list of strings or dictionaries.
		"""
		def push_items items
			# Check by id 
			#existing_dataset_by_id = self.class::_find_or_create_client_by_id_or_name @_memory_storage_client, id: @_id, name: @_name

			existing_dataset_by_id = @_memory_storage_client._find_or_create_client self.class, id: @_id, name: @_name

			_raise_on_non_existing_storage(StorageTypes.DATASET, @_id) if !existing_dataset_by_id

			normalized = _normalize_items items

			added_ids = []
			normalized.each { |entry|
				existing_dataset_by_id._item_count += 1
				idx = _generate_local_entry_name existing_dataset_by_id._item_count

				existing_dataset_by_id._dataset_entries[idx] = entry
				added_ids << idx
			}
			
			data_entries = []
			added_ids.each { |id| data_entries << [id, existing_dataset_by_id._dataset_entries[id]] }

			#existing_dataset_by_id._file_operation_lock.acquire
			existing_dataset_by_id._update_timestamps true
			Utils::_update_dataset_items(
				data: data_entries,
				entity_directory: existing_dataset_by_id._resource_directory,
				persist_storage: @_memory_storage_client._persist_storage
			)
			#existing_dataset_by_id._file_operation_lock.release
		end 
		
		"""Retrieve the dataset info."""
		def _to_resource_info
			{
				'id' => @_id,
				'name' => @_name,
				'itemCount' => @_item_count,
				'accessedAt' => @_accessed_at,
				'createdAt' => @_created_at,
				'modifiedAt' => @_modified_at,
			}
		end

		"""Update the timestamps of the dataset."""	
		def _update_timestamps has_been_modified=nil
			now = Time.now
			@_accessed_at = now
			@_modified_at = now if has_been_modified
				
			dataset_info = _to_resource_info
			Utils::_update_metadata(
				data: dataset_info,
				entity_directory: @_resource_directory,
				write_metadata: @_memory_storage_client._write_metadata,
			)
		end
=begin
		def _get_start_and_end_indexes(self, offset: int, limit: Optional[int] = None) -> Tuple[int, int]:
			actual_limit = limit or self._item_count
			start = offset + 1
			end = min(offset + actual_limit, self._item_count) + 1
			return (start, end)
=end

		def _generate_local_entry_name(idx) = idx.to_s.rjust(LOCAL_ENTRY_NAME_DIGITS, '0')

		def _normalize_items items
			def _normalize_item item
				item = JSON.parse(item) if item.class == String 
				if item.class == Array
					received = item.join(',\n')
					raise "Each dataset item can only be a single JSON object, not an array. Received: [#{received}]" #ValueError
				end
				if ![Hash, NilClass].include?(item.class)
					raise "Each dataset item must be a JSON object. Received: #{item}" # ValueError
				end
				return item
			end

			items = JSON.parse(items) if items.class == String		
			items = [items] if items.class != Array
			items = items.map { |item| _normalize_item item }
			
			# filter(None, ..) returns items that are True
			#return list(filter(None, result))
			items.filter {|item| !item.nil?}
		end

		def self._create_from_directory storage_directory, memory_storage_client, id, name	
			item_count = 0
			created_at = accessed_at = modified_at = Time.now
			entries = {}

			has_seen_metadata_file = false

			# Access the dataset folder
			Dir.foreach(storage_directory) do |entry_name|
				entry_path = File.join(storage_directory, entry_name)
				next unless File.file?(entry_path)
				
				if entry_name == '__metadata__.json'
					has_seen_metadata_file = true

					# We have found the dataset's metadata file, build out information based on it
					metadata = JSON.parse(File.read(entry_path, encoding: 'utf-8'))
					
					id = metadata['id']
					name = metadata['name']
					item_count = metadata['itemCount']||0
					created_at = Time.parse(metadata['createdAt'])
					accessed_at = Time.parse(metadata['accessedAt'])
					modified_at = Time.parse(metadata['modifiedAt'])
					
					next
				end
				
				entry_content = JSON.parse(File.read(entry_path, encoding: 'utf-8'))
				entry_name = entry_name.split('.')[0]

				entries[entry_name] = entry_content
				item_count += 1 if !has_seen_metadata_file
			end

			new_client = new memory_storage_client, id: id, name: name

			# Overwrite properties
			new_client._accessed_at = accessed_at
			new_client._created_at = created_at
			new_client._modified_at = modified_at
			new_client._item_count = item_count

			entries.each { |entry_id, content| new_client._dataset_entries[entry_id] = content }
			return new_client
		end
	end

	### DatasetCollectionClient
	
	class DatasetCollectionClient < BaseResourceCollectionClient
		"""Sub-client for manipulating datasets."""
		
		CLIENT_CLASS = DatasetClient
		
		"""List the available datasets.

		Returns:
			ListPage: The list of available datasets matching the specified filters.
		"""
		# def list = super

		"""Retrieve a named dataset, or create a new one when it doesn't exist.

		Args:
			name (str, optional): The name of the dataset to retrieve or create.
			schema (Dict, optional): The schema of the dataset

		Returns:
			dict: The retrieved or newly-created dataset.
		"""
		# def get_or_create (name: nil, schema: nil, _id: nil) = super name: name, schema: schema, _id: _id		
	end
	
end
end
