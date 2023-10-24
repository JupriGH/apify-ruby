# Required critical Libraries
require 'json'
require 'csv'
require 'net/http'

# Apify Internal Modules
require_relative 'consts'
require_relative 'shared/consts'
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

require_relative 'memory/memory'

require_relative 'client/apify_client'

# emulate python with context manager
def with(cls)
	yield cls.__enter__
	exc = nil
rescue Exception => e
 	exc = e
ensure
	cls.__exit__ exc
end