# Required critical Libraries
require 'json'
require 'csv'
require 'net/http'

# Apify Internal Modules
require_relative 'shared/consts'
require_relative 'shared/models'
require_relative 'consts'
require_relative 'log'
require_relative 'utils'
require_relative 'config'
require_relative 'event'
require_relative 'crypto'
require_relative 'proxy'
require_relative 'actor'
require_relative 'storages/base'
require_relative 'storages/dataset'
require_relative 'storages/key_value_store'
require_relative 'storages/request_queue'

# emulate python with context manager
def with(cls)
	yield cls.__enter__
	exc = nil
rescue Exception => e
 	exc = e
ensure
	cls.__exit__ exc
end

# Apify main module

module Apify
	Log = LoggerExtra.new STDOUT, progname: 'apify', level: Logger::WARN # Logger::UNKNOWN
	#Log.level = Logger::DEBUG
	Log.formatter= ActorLogFormatter.new	

	# plug-n-play
	autoload :MemoryStorage, 	File.expand_path('memory/memory', __dir__)
	autoload :ApifyClient, 		File.expand_path('client/apify_client', __dir__)
	
	# ... TODO: more extensions
end
