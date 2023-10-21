### APIFY_UTILS

=begin
import asyncio
import base64
import builtins
import contextlib
import functools
import hashlib
import inspect
import json
import mimetypes
import os
import re
import sys
import time
from collections import OrderedDict
from collections.abc import MutableMapping
from datetime import datetime, timezone
from importlib import metadata
from typing import Any, Callable, Dict, Generic, ItemsView, Iterator, List, NoReturn, Optional
from typing import OrderedDict as OrderedDictType
from typing import Tuple, Type, TypeVar, Union, ValuesView, cast, overload

import aioshutil
import psutil
from aiofiles import ospath
from aiofiles.os import remove, rename

from apify_shared.consts import (
    BOOL_ENV_VARS,
    BOOL_ENV_VARS_TYPE,
    DATETIME_ENV_VARS,
    DATETIME_ENV_VARS_TYPE,
    FLOAT_ENV_VARS,
    FLOAT_ENV_VARS_TYPE,
    INTEGER_ENV_VARS,
    INTEGER_ENV_VARS_TYPE,
    STRING_ENV_VARS_TYPE,
    ActorEnvVars,
    ApifyEnvVars,
)
from apify_shared.utils import ignore_docs, is_content_type_json, is_content_type_text, is_content_type_xml, maybe_extract_enum_member_value

from .consts import REQUEST_ID_LENGTH, _StorageTypes

T = TypeVar('T')
=end

module Apify

module Utils

=begin
def _get_system_info() -> Dict:
    python_version = '.'.join([str(x) for x in sys.version_info[:3]])

    system_info: Dict[str, Union[str, bool]] = {
        'apify_sdk_version': metadata.version('apify'),
        'apify_client_version': metadata.version('apify-client'),
        'python_version': python_version,
        'os': sys.platform,
    }

    if _is_running_in_ipython():
        system_info['is_running_in_ipython'] = True

    return system_info


DualPropertyType = TypeVar('DualPropertyType')
DualPropertyOwner = TypeVar('DualPropertyOwner')


@ignore_docs
class dualproperty(Generic[DualPropertyType]):  # noqa: N801
    """Descriptor combining `property` and `classproperty`.

    When accessing the decorated attribute on an instance, it calls the getter with the instance as the first argument,
    and when accessing it on a class, it calls the getter with the class as the first argument.
    """

    def __init__(self, getter: Callable[..., DualPropertyType]) -> None:
        """Initialize the dualproperty.

        Args:
            getter (Callable): The getter of the property.
            It should accept either an instance or a class as its first argument.
        """
        self.getter = getter

    def __get__(self, obj: Optional[DualPropertyOwner], owner: Type[DualPropertyOwner]) -> DualPropertyType:
        """Call the getter with the right object.

        Args:
            obj (Optional[T]): The instance of class T on which the getter will be called
            owner (Type[T]): The class object of class T on which the getter will be called, if obj is None

        Returns:
            The result of the getter.
        """
        return self.getter(obj or owner)


	@overload
	def _fetch_and_parse_env_var(env_var: BOOL_ENV_VARS_TYPE) -> Optional[bool]:
		...


	@overload
	def _fetch_and_parse_env_var(env_var: BOOL_ENV_VARS_TYPE, default: bool) -> bool:
		...


	@overload
	def _fetch_and_parse_env_var(env_var: DATETIME_ENV_VARS_TYPE) -> Optional[Union[datetime, str]]:
		...


	@overload
	def _fetch_and_parse_env_var(env_var: DATETIME_ENV_VARS_TYPE, default: datetime) -> Union[datetime, str]:
		...


	@overload
	def _fetch_and_parse_env_var(env_var: FLOAT_ENV_VARS_TYPE) -> Optional[float]:
		...


	@overload
	def _fetch_and_parse_env_var(env_var: FLOAT_ENV_VARS_TYPE, default: float) -> float:
		...


	@overload
	def _fetch_and_parse_env_var(env_var: INTEGER_ENV_VARS_TYPE) -> Optional[int]:
		...


	@overload
	def _fetch_and_parse_env_var(env_var: INTEGER_ENV_VARS_TYPE, default: int) -> int:
		...


	@overload
	def _fetch_and_parse_env_var(env_var: STRING_ENV_VARS_TYPE, default: str) -> str:
		...


	@overload
	def _fetch_and_parse_env_var(env_var: STRING_ENV_VARS_TYPE) -> Optional[str]:
		...


	@overload
	def _fetch_and_parse_env_var(env_var: Union[ActorEnvVars, ApifyEnvVars]) -> Optional[Any]:
		...
=end

	def self._fetch_and_parse_env_var(env_var, default=nil)
		## env_var_name = str(maybe_extract_enum_member_value(env_var))

		val = ENV[env_var] # ENV(env_var_name)
		return default if val.nil? || val.empty?
				
		return ['true', '1'].include?(val.downcase) if 
			BOOL_ENV_VARS.include?(env_var)
		
		return Float(val) if 
			FLOAT_ENV_VARS.include?(env_var)
		
		return Int(val) if 
			INTEGER_ENV_VARS.include?(env_var)

		#return DateTime.iso8601(val, '%Y-%m-%dT%H:%M:%S.%fZ').to_time.localtime if # Local time
		return DateTime.iso8601(val, '%Y-%m-%dT%H:%M:%S.%fZ').to_time if # UTC time
			DATETIME_ENV_VARS.include?(env_var)
		
		return val # String
	#rescue
	#	return default
	end
	
=begin
def _get_cpu_usage_percent() -> float:
    return psutil.cpu_percent()


def _get_memory_usage_bytes() -> int:
    current_process = psutil.Process(os.getpid())
    mem = int(current_process.memory_info().rss or 0)
    for child in current_process.children(recursive=True):
        with contextlib.suppress(psutil.NoSuchProcess):
            mem += int(child.memory_info().rss or 0)
    return mem
=end

=begin
async def _run_func_at_interval_async(func: Callable, interval_secs: float) -> None:
    started_at = time.perf_counter()
    sleep_until = started_at
    while True:
        now = time.perf_counter()
        sleep_until += interval_secs
        while sleep_until < now:
            sleep_until += interval_secs

        sleep_for_secs = sleep_until - now
        await asyncio.sleep(sleep_for_secs)

        res = func()
        if inspect.isawaitable(res):
            await res


async def _force_remove(filename: str) -> None:
    """JS-like rm(filename, { force: true })."""
    with contextlib.suppress(FileNotFoundError):
        await remove(filename)


def _raise_on_non_existing_storage(client_type: _StorageTypes, id: str) -> NoReturn:
    client_type = maybe_extract_enum_member_value(client_type)
    raise ValueError(f'{client_type} with id "{id}" does not exist.')


def _raise_on_duplicate_storage(client_type: _StorageTypes, key_name: str, value: str) -> NoReturn:
    client_type = maybe_extract_enum_member_value(client_type)
    raise ValueError(f'{client_type} with {key_name} "{value}" already exists.')


def _guess_file_extension(content_type: str) -> Optional[str]:
    """Guess the file extension based on content type."""
    # e.g. mimetypes.guess_extension('application/json ') does not work...
    actual_content_type = content_type.split(';')[0].strip()

    # mimetypes.guess_extension returns 'xsl' in this case, because 'application/xxx' is "structured"
    # ('text/xml' would be "unstructured" and return 'xml')
    # we have to explicitly override it here
    if actual_content_type == 'application/xml':
        return 'xml'

    # Guess the extension from the mime type
    ext = mimetypes.guess_extension(actual_content_type)

    # Remove the leading dot if extension successfully parsed
    return ext[1:] if ext is not None else ext


def _maybe_parse_body(body: bytes, content_type: str) -> Any:
    if is_content_type_json(content_type):
        return json.loads(body.decode('utf-8'))  # Returns any
    elif is_content_type_xml(content_type) or is_content_type_text(content_type):
        return body.decode('utf-8')
    return body

=end

	"""Generate request ID based on unique key in a deterministic way."""
	def self._unique_key_to_request_id unique_key
		#id = re.sub(r'(\+|\/|=)', '', base64.b64encode(hashlib.sha256(unique_key.encode('utf-8')).digest()).decode('utf-8'))
		#return id[:REQUEST_ID_LENGTH] if len(id) > REQUEST_ID_LENGTH else id
		
		# https://stackoverflow.com/questions/2620975/strange-n-in-base64-encoded-string-in-ruby
		Base64.strict_encode64( Digest::SHA256.digest(unique_key) ).gsub(/\+|\/|\=/,"")[.. Consts::REQUEST_ID_LENGTH]
	end

=begin
async def _force_rename(src_dir: str, dst_dir: str) -> None:
    """Rename a directory. Checks for existence of soruce directory and removes destination directory if it exists."""
    # Make sure source directory exists
    if await ospath.exists(src_dir):
        # Remove destination directory if it exists
        if await ospath.exists(dst_dir):
            await aioshutil.rmtree(dst_dir, ignore_errors=True)
        await rename(src_dir, dst_dir)

ImplementationType = TypeVar('ImplementationType', bound=Callable)
MetadataType = TypeVar('MetadataType', bound=Callable)


def _wrap_internal(implementation: ImplementationType, metadata_source: MetadataType) -> MetadataType:
    @functools.wraps(metadata_source)
    def wrapper(*args: Any, **kwargs: Any) -> Any:
        return implementation(*args, **kwargs)

    return cast(MetadataType, wrapper)
=end

	### Starting with Ruby 1.9, the Hash class maintains the order of key-value pairs based on the order of insertion.
	
    """Attempt to reimplement LRUCache from `@apify/datastructures` using `OrderedDict`."""
	class LRUCache < Hash # (MutableMapping, Generic[T]):

		#_cache: OrderedDictType[str, T]
		#_max_length: int
		
		"""Create a LRUCache with a specific max_length."""
		def initialize max_length
			super
			@_max_length = max_length
		end

		"""Get an item from the cache. Move it to the end if present."""
		def __getitem__ key
			val = delete key
			self[key] = val if val
			return val
		end

		# Sadly TS impl returns bool indicating whether the key was already present or not
		"""Add an item to the cache. Remove least used item if max_length exceeded."""
		def __setitem__ key, value
			#self._cache[key] = value
			#if len(self._cache) > self._max_length:
			#	self._cache.popitem(last=False)

			# mutate ?
			# delete key
			
			self[key] = value
			shift if length > @_max_length
		end

		"""Remove an item from the cache."""		
		#def __delitem__(self, key: str) -> None:
		#	del self._cache[key]
		#end
		
		"""Iterate over the keys of the cache in order of insertion."""
		#def __iter__(self) -> Iterator[str]:
		#	return self._cache.__iter__()
		#end

		"""Get the number of items in the cache."""		
		#def __len__(self) -> int:
		#	return len(self._cache)
		#end
		
		"""Iterate over the values in the cache in order of insertion."""
		#def values(self) -> ValuesView[T]:  # Needed so we don't mutate the cache by __getitem__
		#	return self._cache.values()
		#end

		"""Iterate over the pairs of (key, value) in the cache in order of insertion."""
		#def items(self) -> ItemsView[str, T]:  # Needed so we don't mutate the cache by __getitem__
		#	return self._cache.items()
		#end
	end

=begin
def _is_running_in_ipython() -> bool:
    return getattr(builtins, '__IPYTHON__', False)


@overload
def _budget_ow(value: Union[str, int, float, bool], predicate: Tuple[Type, bool], value_name: str) -> None:
    ...
@overload
def _budget_ow(value: Dict, predicate: Dict[str, Tuple[Type, bool]]) -> None:
    ...
=end


	"""Budget version of ow."""
	def self.__validate_single field_value, expected_type, required, name
		if field_value.nil? && required
			# ValueError
			raise "\"#{name}\" is required!"
		end
		if (!field_value.nil? || required) && (field_value.class != expected_type)
			# ValueError
			raise "\"#{name}\" must be of type \"#{expected_type.name}\" but it is \"#{field_value.class.name}\"!"
		end
	end
	
	def self._budget_ow value, predicate, value_name=nil
				
		# Validate object
		if (value.class == Hash) && (predicate.class == Hash)			
			predicate.each do |key, p|
				field_type, required = p
				__validate_single value[key], field_type, required, key
			end
			
		# Validate "primitive"
		#elsif isinstance(value, (int, str, float, bool)) && 
		elsif (predicate.class == Array) && value_name
			field_type, required = predicate
			__validate_single value, field_type, required, value_name
		
		else
			raise 'Wrong input!' # ValueError
		end
	end

=begin
PARSE_DATE_FIELDS_MAX_DEPTH = 3
PARSE_DATE_FIELDS_KEY_SUFFIX = 'At'
ListOrDictOrAny = TypeVar('ListOrDictOrAny', List, Dict, Any)
=end 

end

end