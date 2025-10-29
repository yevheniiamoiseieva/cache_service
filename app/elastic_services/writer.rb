class ElasticServices::Writer < ElasticServices::BaseService

  def bulk_insert
    data_to_insert = params

    body = data_to_insert.flat_map do |document|
      [
        { index: { _index: INDEX_NAME, _id: document[:event_id] } },
        document
      ]
    end

    result = client_pool.with do |connection|
      connection.bulk(body: body, refresh: true)
    end

    logger.info("Bulk insert finished. Errors: #{result['errors']}")
    result
  rescue StandardError => e
    log_error("Bulk insert error: #{e.inspect}.")
    { 'errors' => true, 'message' => e.message }
  end
end