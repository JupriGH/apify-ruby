=begin

import aiofiles
from aiofiles.os import makedirs

from apify_shared.utils import json_dumps

from .._utils import _force_remove
=end

module Apify

module MemoryStorage::Utils ### FileUtils

	def self._update_metadata data:, entity_directory:, write_metadata: nil
		# Skip writing the actual metadata file. This is done after ensuring the directory exists so we have the directory present
		return if !write_metadata

		# Ensure the directory for the entity exists
		FileUtils.mkdir_p(entity_directory)

		# Write the metadata to the file
		file_path = File.join(entity_directory, '__metadata__.json')
		File.write file_path, data.to_json, encoding: 'utf-8'
	end
	
	def self._update_dataset_items data:, entity_directory:, persist_storage: nil
		# Skip writing files to the disk if the client has the option set to false
		return if !persist_storage

		# Ensure the directory for the entity exists
		FileUtils.mkdir_p(entity_directory)

		# Save all the new items to the disk
		data.each { |idx, item|
			file_path = File.join(entity_directory, "#{idx}.json")	
			File.open(file_path, 'wb') { |f| f.write JSON.dump(item).encode('utf-8') }
		}			
	end
	
=begin
	async def _update_request_queue_item(
		*,
		request_id: str,
		request: Dict,
		entity_directory: str,
		persist_storage: bool,
	) -> None:
		# Skip writing files to the disk if the client has the option set to false
		if not persist_storage:
			return

		# Ensure the directory for the entity exists
		await makedirs(entity_directory, exist_ok=True)

		# Write the request to the file
		file_path = os.path.join(entity_directory, f'{request_id}.json')
		async with aiofiles.open(file_path, mode='wb') as f:
			await f.write(json_dumps(request).encode('utf-8'))


	async def _delete_request(*, request_id: str, entity_directory: str) -> None:
		# Ensure the directory for the entity exists
		await makedirs(entity_directory, exist_ok=True)

		file_path = os.path.join(entity_directory, f'{request_id}.json')
		await _force_remove(file_path)
=end

end
end