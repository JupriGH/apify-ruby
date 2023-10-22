require 'async'
require 'async/io/stream'
require 'async/http/endpoint'
require 'async/websocket/client'

=begin
import asyncio
import contextlib
import inspect
import json
from collections import defaultdict
from typing import Any, Callable, Coroutine, Dict, List, Optional, Set, Union

import websockets.client
from pyee.asyncio import AsyncIOEventEmitter

from apify_shared.consts import ActorEventTypes
from apify_shared.utils import ignore_docs, maybe_extract_enum_member_value, parse_date_fields

ListenerType = Union[Callable[[], None], Callable[[Any], None], Callable[[], Coroutine[Any, Any, None]], Callable[[Any], Coroutine[Any, Any, None]]]
=end

class EventEmitter
	def initialize
		@subscribers = {}
	end

	# Subscribe a callback to an event	
	def add_listener event, callback
		@subscribers[event] ||= []
		@subscribers[event] << callback
	end
	
	# Remove a specific callback from an event
	def remove_listener event, callback
		@subscribers[event]&.delete(callback)
	end

	# Emit an event and trigger subscribed callbacks
	def emit event, *args
		if @subscribers[event]
			@subscribers[event].each { |callback| 
				Async { 
					callback.call(*args) 
				} 
			}
		end
	end

	# Remove all callbacks from an event
	def remove_all_listeners event=nil
		if event
			@subscribers[event].clear # = []
		else
			@subscribers.clear
		end
	end
end

module Apify

	"""A class for managing actor events.

	You shouldn't use this class directly,
	but instead use it via the `Actor.on()` and `Actor.off()` methods.
	"""
	class EventManager

=begin
		_platform_events_websocket: Optional[websockets.client.WebSocketClientProtocol] = None
		_process_platform_messages_task: Optional[asyncio.Task] = None
		_send_persist_state_interval_task: Optional[asyncio.Task] = None
		_send_system_info_interval_task: Optional[asyncio.Task] = None
		_listener_tasks: Set[asyncio.Task]
		_listeners_to_wrappers: Dict[ActorEventTypes, Dict[Callable, List[Callable]]]
		_connected_to_platform_websocket: Optional[asyncio.Future] = None
=end

		"""Create an instance of the EventManager.

		Args:
			config (Configuration): The actor configuration to be used in this event manager.
		"""
		def initialize config
			@_config = config
			@_event_emitter = EventEmitter.new  # AsyncIOEventEmitter()
			@_initialized = false
			#@_listener_tasks = set()
			@_listeners_to_wrappers = {} # defaultdict(lambda: defaultdict(list))

			##
			@_platform_events_websocket = nil
			@_connected_to_platform_websocket = false
		end

		"""Initialize the event manager.

		When running this on the Apify Platform, this will start processing events
		send by the platform to the events websocket and emitting them as events
		that can be listened to by the `Actor.on()` method.
		"""
		def init
			raise 'EventManager was already initialized!' if @_initialized # RuntimeError

			# Run tasks but don't await them
			if @_config.actor_events_ws_url
				#self._connected_to_platform_websocket = asyncio.Future()
				#self._process_platform_messages_task = asyncio.create_task(self._process_platform_messages())

				@_process_platform_messages_task = _process_platform_messages
				
				is_connected = @_connected_to_platform_websocket
				raise 'Error connecting to platform events websocket!' unless is_connected # RuntimeError
			else
				Log.debug 'APIFY_ACTOR_EVENTS_WS_URL env var not set, no events from Apify platform will be emitted.'
			end
			
			@_initialized = true
		end

		"""Initialize the event manager.

		This will stop listening for the platform events,
		and it will wait for all the event listeners to finish.

		Args:
			event_listeners_timeout_secs (float, optional): Optional timeout after which the pending event listeners are canceled.
		"""		
		def close event_listeners_timeout_secs: nil
			raise 'EventManager was not initialized!' if !@_initialized # RuntimeError

			if @_platform_events_websocket
				Log.debug "@_platform_events_websocket.close"
				@_platform_events_websocket.close
				#@_platform_events_websocket.wait
			end
			if @_process_platform_messages_task
				Log.debug "@_process_platform_messages_task.stop"
				@_process_platform_messages_task.stop
				#await self._process_platform_messages_task
			end
			
			wait_for_all_listeners_to_complete timeout_secs: event_listeners_timeout_secs

			@_event_emitter.remove_all_listeners

			@_initialized = false
		end

		"""Add an event listener to the event manager.

		Args:
			event_name (ActorEventTypes): The actor event for which to listen to.
			listener (Callable): The function which is to be called when the event is emitted (can be async).
				Must accept either zero or one arguments (the first argument will be the event data).
		"""
		def on event_name, listener
			raise 'EventManager was not initialized!' if !@_initialized # RuntimeError

			# Detect whether the listener will accept the event_data argument
=begin
			try:
				signature = inspect.signature(listener)
			except (ValueError, TypeError):
				# If we can't determine the listener argument count (e.g. for the built-in `print` function),
				# let's assume the listener will accept the argument
				listener_argument_count = 1
			else:
				try:
					dummy_event_data: Dict = {}
					signature.bind(dummy_event_data)
					listener_argument_count = 1
				except TypeError:
					try:
						signature.bind()
						listener_argument_count = 0
					except TypeError:
						raise ValueError('The "listener" argument must be a callable which accepts 0 or 1 arguments!')
=end
			
			#event_name = maybe_extract_enum_member_value(event_name)
=begin
			async def inner_wrapper(event_data: Any) -> None:
				if inspect.iscoroutinefunction(listener):
					if listener_argument_count == 0:
						await listener()
					else:
						await listener(event_data)
				else:
					if listener_argument_count == 0:
						listener()  # type: ignore[call-arg]
					else:
						listener(event_data)  # type: ignore[call-arg]

			async def outer_wrapper(event_data: Any) -> None:
				listener_task = asyncio.create_task(inner_wrapper(event_data))
				self._listener_tasks.add(listener_task)
				try:
					await listener_task
				except asyncio.CancelledError:
					raise
				except Exception:
					# We need to swallow the exception and just log it here, since it could break the event emitter otherwise
					logger.exception('Exception in event listener', extra={'event_name': event_name, 'listener_name': listener.__name__})
				finally:
					self._listener_tasks.remove(listener_task)

			self._listeners_to_wrappers[event_name][listener].append(outer_wrapper)
=end

			@_event_emitter.add_listener event_name, listener
			#return self._event_emitter.add_listener(event_name, outer_wrapper)
		end

		"""Remove a listener, or all listeners, from an actor event.

		Args:
			event_name (ActorEventTypes): The actor event for which to remove listeners.
			listener (Callable, optional): The listener which is supposed to be removed. If not passed, all listeners of this event are removed.
		"""
		def off event_name, listener			
			raise 'EventManager was not initialized!' if !@_initialized # RuntimeError

			#event_name = maybe_extract_enum_member_value(event_name)

			if listener
				#for listener_wrapper in self._listeners_to_wrappers[event_name][listener]:
				#	@_event_emitter.remove_listener event_name, listener_wrapper
				#self._listeners_to_wrappers[event_name][listener] = []
				
				@_event_emitter.remove_listener event_name, listener
			else
				self._listeners_to_wrappers[event_name] = defaultdict(list)
				@_event_emitter.remove_all_listeners event_name
			end
		end
		
		"""Emit an actor event manually.

		Args:
			event_name (ActorEventTypes): The actor event which should be emitted.
			data (Any): The data that should be emitted with the event.
		"""
		def emit event_name, data
			#event_name = maybe_extract_enum_member_value(event_name)
			@_event_emitter.emit event_name, data
		end
		
		"""Wait for all event listeners which are currently being executed to complete.

		Args:
			timeout_secs (float, optional): Timeout for the wait. If the event listeners don't finish until the timeout, they will be canceled.
		"""
		def wait_for_all_listeners_to_complete timeout_secs: nil
			Log.fatal "TODO: #{self.class}.#{__method__}", timeout_secs
=begin
			async def _wait_for_listeners() -> None:
				results = await asyncio.gather(*self._listener_tasks, return_exceptions=True)
				for result in results:
					if result is Exception:
						logger.exception('Event manager encountered an exception in one of the event listeners', exc_info=result)
=end
			if false # timeout_secs:
				#_, pending = await asyncio.wait([asyncio.create_task(_wait_for_listeners())], timeout=timeout_secs)
				#if pending:
				#	logger.warning('Timed out waiting for event listeners to complete, unfinished event listeners will be canceled')
				#	for pending_task in pending:
				#		pending_task.cancel()
				#		with contextlib.suppress(asyncio.CancelledError):
				#			await pending_task
			else
				#_wait_for_listeners
			end
		end
		
		def _process_platform_messages
			# This should be called only on the platform, where we have the ACTOR_EVENTS_WS_URL configured
			url = @_config.actor_events_ws_url

			raise unless url
			#assert self._connected_to_platform_websocket is not None

			begin
				endpoint = Async::HTTP::Endpoint.parse(url)
				Log.debug "!!WS URL!!".red, url
				
				@_platform_events_websocket = connection = Async::WebSocket::Client.connect(endpoint)
				@_connected_to_platform_websocket = true
				
				Log.debug "!!WS CONNECTED!!".red
				
				return Async {
					while message = connection.read							
						begin
							parsed_message = JSON.parse(message.buffer) # , symbolize_names: true)
							raise unless parsed_message.class == Hash
							#parsed_message = parse_date_fields(parsed_message)
							event_name = parsed_message['name']
							event_data = parsed_message['data']  # 'data' can be missing
							#Log.debug "WS:", event_name, extra: event_data
							
							@_event_emitter.emit(event_name, event_data)
						
						rescue JSON::ParserError => exc
							Log.fatal 'Cannot parse actor event', extra: {'message': message}
							raise exc
						end
					end
					#Log.debug "!!WS NO MORE DATA!!".red
					connection.close
					@_connected_to_platform_websocket = false					
				}
			rescue
				Log.fatal 'Error in websocket connection'
			end
			
			###################################################################################################
			return
		

			#Async do
				p "WEBSOCKET:"
				p @_config.actor_events_ws_url
				
				uri = URL(@_config.actor_events_ws_url)
				
				stream = Async::IO::Stream.open(uri.host, uri.port)
				client = Async::WebSocket::Client.new(stream)
				
				client.connect

				#client.write("Hello, WebSocket!")

				client.read do |message|
					parsed_message = JSON.parse(message.buffer, symbolize_names: true)
					assert isinstance(parsed_message, dict)
					
					#parsed_message = parse_date_fields(parsed_message)
					event_name = parsed_message[:name]
					event_data = parsed_message[:data]  # 'data' can be missing
					
					_event_emitter.emit(event_name, event_data)
					
					client.close
				end

				client.wait
			
				p "WEBSOCKET: DONE"
				
				raise
			#end

			#Async::Reactor.run
			
=begin
			try:
				async with websockets.client.connect(self._config.actor_events_ws_url) as websocket:
					self._platform_events_websocket = websocket
					self._connected_to_platform_websocket.set_result(True)
					async for message in websocket:
						try:
							parsed_message = json.loads(message)
							assert isinstance(parsed_message, dict)
							parsed_message = parse_date_fields(parsed_message)
							event_name = parsed_message['name']
							event_data = parsed_message.get('data')  # 'data' can be missing

							self._event_emitter.emit(event_name, event_data)

						except Exception:
							logger.exception('Cannot parse actor event', extra={'message': message})
			except Exception:
				logger.exception('Error in websocket connection')
	   
			 self._connected_to_platform_websocket.set_result(False)
=end
		end

	end
end