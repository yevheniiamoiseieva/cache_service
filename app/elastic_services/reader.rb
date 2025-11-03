module ElasticServices
  class Reader < BaseService

    def search
      query_body = build_search_query(params)

      result = client_pool.with do |connection|
        connection.search(
          index: INDEX_ALIAS,
          body: query_body,
          size: size,
          from: from
        )
      end

      logger.info("Search executed successfully for params: #{params}")
      result
    rescue StandardError => e
      log_error("Search error for params #{params}: #{e.inspect}.")
      { "hits" => { "total" => { "value" => 0 }, "hits" => [] } }
    end

    private

    def build_search_query(search_params)
      filters = search_params.map do |key, condition|
        if condition[:eq]
          { term: { key.to_sym => condition[:eq] } }
        end
      end.compact

      {
        query: {
          bool: {
            filter: filters
          }
        }
      }
    end
  end
end