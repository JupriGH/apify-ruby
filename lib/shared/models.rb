module Apify

	module Models

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

end