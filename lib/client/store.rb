module Apify

class StoreCollectionClient < ResourceCollectionClient
    """Sub-client for Apify store."""

    def initialize **kwargs
        """Initialize the StoreCollectionClient."""
        super resource_path: 'store', **kwargs
	end
	
    def list(
        limit: nil,
        offset: nil,
        search: nil,
        sort_by: nil,
        category: nil,
        username: nil,
        pricing_model: nil
    )
        """List Actors in Apify store.

        https://docs.apify.com/api/v2/#/reference/store/store-actors-collection/get-list-of-actors-in-store

        Args:
            limit (int, optional): How many Actors to list
            offset (int, optional): What Actor to include as first when retrieving the list
            search (str, optional): String to search by. The search runs on the following fields: title, name, description, username, readme.
            sort_by (str, optional): Specifies the field by which to sort the results.
            category (str, optional): Filter by this category
            username (str, optional): Filter by this username
            pricing_model (str, optional): Filter by this pricing model

        Returns:
            ListPage: The list of available tasks matching the specified filters.
        """
        _list(
            limit: limit,
            offset: offset,
            search: search,
            sortBy: sort_by,
            category: category,
            username: username,
            pricingModel: pricing_model
        )
	end
end

end
