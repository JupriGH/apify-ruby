require 'logger'
require 'colorize'

=begin
	_LOG_NAME_COLOR = Fore.LIGHTBLACK_EX
=end

LOG_LEVEL_COLOR = {
	'DEBUG' => :blue,
	'INFO' => :green,
	'WARN' => :yellow,
	'ERROR' => :light_red,
	'FATAL' => :red, #logging.CRITICAL: Fore.RED,
}

LOG_LEVEL_SHORT_ALIAS = {
	'DEBUG' 	=> 'DEBUG ',
	'INFO' 		=> ' INFO ',
	'WARN' 		=> ' WARN ',
	'ERROR' 	=> 'ERROR ',
	'FATAL' 	=> 'FATAL ',
}
	
=begin
	# So that all the log messages have the same alignment
	_LOG_MESSAGE_INDENT = ' ' * 6
=end

### process extra info's
class LoggerExtra < Logger
	def __extra *msg, extra: nil, exc_info: nil, **kwargs
		if extra
			msg << "(#{extra.to_json})".light_black
		end
		if exc_info
			#p exc_info.backtrace
			
			#p "TODO: Log Traceback"
			#p exc_info
			msg << "#{exc_info.message} (#{exc_info.class.name.underline})".red 
			#msg << "\n" << exc_info.backtrace.join("\n\t")
			msg.push *exc_info.backtrace.map {|x| x.light_black.italic}
		end
		msg.join "\n#{" "*4}| "
	end
	
	def info(*args, **kwargs) = super(__extra(*args, **kwargs))
	def warn(*args, **kwargs) = super(__extra(*args, **kwargs))
	def error(*args, **kwargs) = super(__extra(*args, **kwargs))
	def debug(*args, **kwargs) = super(__extra(*args, **kwargs))
	def fatal(*args, **kwargs) = super(__extra(*args, **kwargs))
end

module Apify

	# Name of the logger used throughout the library (resolves to 'apify')
	# logger_name = __name__.split('.')[0]

	# Logger used throughout the library
	# logger = logging.getLogger(logger_name)
	Log = LoggerExtra.new STDOUT, progname: 'apify', level: Logger::UNKNOWN

	#Log.level = Logger::DEBUG
	#Log.formatter= ActorLogFormatter.new

	"""Log formatter that prints out the log message nicely formatted, with colored level and stringified extra fields.

	It formats the log records so that they:
	- start with the level (colorized, and padded to 5 chars so that it is nicely aligned)
	- then have the actual log message, if it's multiline then it's nicely indented
	- then have the stringified extra log fields
	- then, if an exception is a part of the log record, prints the formatted exception.
	"""
	class ActorLogFormatter < Logger::Formatter

=begin
		# The fields that are added to the log record with `logger.log(..., extra={...})`
		# are just merged in the log record with the other log record properties, and you can't get them in some nice, isolated way.
		# So, to get the extra fields, we just compare all the properties present in the log record
		# with properties present in an empty log record,
		# and extract all the extra ones not present in the empty log record
		empty_record = logging.LogRecord('dummy', 0, 'dummy', 0, 'dummy', None, None)
=end
		"""Create an instance of the ActorLogFormatter.

		Args:
			include_logger_name: Include logger name at the beginning of the log line. Defaults to False.
		"""
		def initialize *args, include_logger_name: nil, **kwargs
			super *args, **kwargs
			@include_logger_name = include_logger_name
		end
=begin
		def _get_extra_fields(self, record: logging.LogRecord) -> Dict[str, Any]:
			extra_fields: Dict[str, Any] = {}
			for key, value in record.__dict__.items():
				if key not in self.empty_record.__dict__:
					extra_fields[key] = value

			return extra_fields
=end
		"""Format the log record nicely.

		This formats the log record so that it:
		- starts with the level (colorized, and padded to 5 chars so that it is nicely aligned)
		- then has the actual log message, if it's multiline then it's nicely indented
		- then has the stringified extra log fields
		- then, if an exception is a part of the log record, prints the formatted exception.
		"""
		#def format(self, record: logging.LogRecord) -> str:
		def call severity, timestamp, progname, msg
		
			# logger_name_string = f'{_LOG_NAME_COLOR}[{record.name}]{Style.RESET_ALL} '

			# Colorize the log level, and shorten it to 6 chars tops
			"""
			level_color_code = _LOG_LEVEL_COLOR.get(record.levelno, '')
			level_short_alias = _LOG_LEVEL_SHORT_ALIAS.get(record.levelno, record.levelname)
			level_string = f'{level_color_code}{level_short_alias}{Style.RESET_ALL} '
			"""
			level_string = (LOG_LEVEL_SHORT_ALIAS[severity]||severity).colorize(LOG_LEVEL_COLOR[severity])
			# Format the exception, if there is some
			# Basically just print the traceback and indent it a bit
			
			exception_string = ''
			"""
			if record.exc_info:
				exc_info = record.exc_info
				record.exc_info = None
				exception_string = ''.join(traceback.format_exception(*exc_info)).rstrip()
				exception_string = '\n' + textwrap.indent(exception_string, _LOG_MESSAGE_INDENT)
			"""
			# Format the extra log record fields, if there were some
			# Just stringify them to JSON and color them gray
			extra_string = ''
			"""
			extra = self._get_extra_fields(record)
			if extra:
				extra_string = f' {Fore.LIGHTBLACK_EX}({json.dumps(extra, ensure_ascii=False, default=str)}){Style.RESET_ALL}'
			"""
			# Format the actual log message, and indent everything but the first line
			"""
			log_string = super().format(record)
			log_string = textwrap.indent(log_string, _LOG_MESSAGE_INDENT).lstrip()

			if self.include_logger_name:
				# Include logger name at the beginning of the log line
				return f'{logger_name_string}{level_string}{log_string}{extra_string}{exception_string}'
			else:
				return f'{level_string}{log_string}{extra_string}{exception_string}'
			"""
			
			log_string = msg
			
			[level_string, log_string, extra_string, exception_string, "\n"].join
		end
	end
end