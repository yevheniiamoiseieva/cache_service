class ElasticServices::Updater < ElasticServices::BaseService

  def update
    document_id = params[:document_id]
    document = params[:document]

    result = client_pool.with do |connection|
      connection.update(
        index: INDEX_ALIAS,
        id: document_id,
        body: { doc: document }
      )
    end

    logger.info("Document ID #{document_id} updated successfully.")
    result
  rescue StandardError => e
    log_error("Update error for ID #{document_id}: #{e.inspect}.")
    { 'error' => true, 'message' => e.message }
  end
end