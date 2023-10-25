### APIFY_SHARED_UTILS

=begin
import contextlib
import io
import json
import re
from datetime import datetime, timezone
from enum import Enum
from typing import Any, Dict, List, Optional, TypeVar, cast

PARSE_DATE_FIELDS_MAX_DEPTH = 3
PARSE_DATE_FIELDS_KEY_SUFFIX = 'At'

ListOrDict = TypeVar('ListOrDict', List, Dict)
T = TypeVar('T')


=end

module Apify

module Utils

    """Return copy of the dictionary, recursively omitting all keys for which values are None."""	
	def self.filter_out_none_values_recursively dictionary
		# return cast(dict, _filter_out_none_values_recursively_internal(dictionary))
		_filter_out_none_values_recursively_internal dictionary
	end

    """Recursively filters out None values from a dictionary.

    Unfortunately, it's necessary to have an internal function for the correct result typing,
    without having to create complicated overloads
    """
	def self._filter_out_none_values_recursively_internal dictionary, remove_empty_dicts=false
		result = {}

		dictionary.each { |k,v|
			if v.class == Hash
				v = _filter_out_none_values_recursively_internal(v, remove_empty_dicts != false)
			end
			result[k] = v if v
		}
		
		return nil if (result.length == 0) && remove_empty_dicts
		return result
	end

	"""Check if the given content type is JSON."""
	def self.is_content_type_json(content_type) = content_type&.match?(/^(application|text)\/json/i)

	"""Check if the given content type is XML."""
	def self.is_content_type_xml(content_type) = content_type&.match?(/^application\/.*xml$/i)
	
	"""Check if the given content type is text."""
	def self.is_content_type_text(content_type) = content_type&.match?(/^text\//i)
	
	"""Check if the input value is a file-like object or bytes.

	The check for IOBase is not ideal, it would be better to use duck typing,
	but then the check would be super complex, judging from how the 'requests' library does it.
	This way should be good enough for the vast majority of use cases, if it causes issues, we can improve it later.
	"""
	def self.is_file_or_bytes value
		### TODO
		#return isinstance(value, (bytes, bytearray, io.IOBase))
		false
	end

=begin

@ignore_docs
def json_dumps(obj: Any) -> str:
    """Dump JSON to a string with the correct settings and serializer."""
    return json.dumps(obj, ensure_ascii=False, indent=2, default=str)
=end

	"""Extract the value of an enumeration member if it is an Enum, otherwise return the original value."""	
=begin
	def maybe_extract_enum_member_value maybe_enum_member
		if isinstance(maybe_enum_member, Enum):
			return maybe_enum_member.value
		return maybe_enum_member
	end
=end

=begin
	def parse_date_fields data, max_depth: PARSE_DATE_FIELDS_MAX_DEPTH
		"""Recursively parse date fields in a list or dictionary up to the specified depth."""
		if max_depth < 0:
			return data

		if isinstance(data, list):
			return [parse_date_fields(item, max_depth - 1) for item in data]

		if isinstance(data, dict):
			def parse(key: str, value: object) -> object:
				parsed_value = value
				if key.endswith(PARSE_DATE_FIELDS_KEY_SUFFIX) and isinstance(value, str):
					with contextlib.suppress(ValueError):
						parsed_value = datetime.strptime(value, '%Y-%m-%dT%H:%M:%S.%fZ').replace(tzinfo=timezone.utc)
				elif isinstance(value, dict):
					parsed_value = parse_date_fields(value, max_depth - 1)
				elif isinstance(value, list):
					parsed_value = parse_date_fields(value, max_depth)  # type: ignore # mypy doesn't work with decorators and recursive calls well
				return parsed_value

			return {key: parse(key, value) for (key, value) in data.items()}

		return data
	end

=end
	
end

end