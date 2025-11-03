require_relative '../spec_helper'
RSpec.describe ElasticServices::Updater do
  let(:mock_logger) { instance_double(Logger, info: true, error: true) }
  let(:mock_client) { double('elasticsearch_client') }
  let(:mock_pool) { instance_double(ConnectionPool) }

  let(:document_id) { 'product_123' }
  let(:document_data) { { price: 99.99, status: 'sold' } }

  let(:updater_params) do
    {
      document_id: document_id,
      document: document_data
    }
  end

  let(:updater_instance) do
    described_class.new(
      client_pool: mock_pool,
      logger: mock_logger,
      params: updater_params
    )
  end

  before do
    allow(ElasticServices::BaseService).to receive(:client_pool).and_return(mock_pool)
    allow(ElasticServices::BaseService).to receive(:elastic_logger).and_return(mock_logger)
  end

  describe '#update' do
    let(:elastic_response) do
      {
        '_index' => 'test_alias',
        '_id' => document_id,
        'result' => 'updated',
        '_version' => 2
      }
    end
    let(:expected_update_body) { { doc: document_data } }

    context 'when update is successful' do
      before do
        allow(mock_pool).to receive(:with).and_yield(mock_client)
      end

      it 'calls connection.update with correct parameters and logs success' do
        allow(mock_client).to receive(:update).with(
          index: Constants::Elasticsearch::INDEX_ALIAS,
          id: document_id,
          body: expected_update_body
        ).and_return(elastic_response)

        expect(mock_logger).to receive(:info).with("Document ID #{document_id} updated successfully.")

        result = updater_instance.update
        expect(result).to eq(elastic_response)

        expect(mock_client).to have_received(:update).with(
          index: Constants::Elasticsearch::INDEX_ALIAS,
          id: document_id,
          body: expected_update_body
        )
      end
    end

    context 'when an error occurs during update' do
      let(:error_message) { '404 Document Not Found' }
      let(:error) { StandardError.new(error_message) }

      before do
        allow(mock_pool).to receive(:with).and_raise(error)
      end

      it 'logs the error and returns a structured error hash' do
        expect(mock_logger).to receive(:error).with(/Update error for ID #{document_id}: #<StandardError: #{error_message}>./)

        expected_error_result = { 'error' => true, 'message' => error_message }
        expect(updater_instance.update).to eq(expected_error_result)
      end
    end

    context 'when document_id is nil (e.g., missing from params)' do
      let(:document_id) { nil }
      let(:updater_params_nil_id) do
        { document_id: nil, document: document_data }
      end

      let(:updater_instance_nil_id) do
        described_class.new(
          client_pool: mock_pool,
          logger: mock_logger,
          params: updater_params_nil_id
        )
      end

      it 'handles the error when the client fails due to missing ID' do
        error_message_for_nil_id = '400 Bad Request: ID missing'
        allow(mock_pool).to receive(:with).and_raise(StandardError.new(error_message_for_nil_id))

        expect(mock_logger).to receive(:error).with(/Update error for ID : #<StandardError: #{error_message_for_nil_id}>./)

        expected_error_result = { 'error' => true, 'message' => error_message_for_nil_id }
        expect(updater_instance_nil_id.update).to eq(expected_error_result)
      end
    end
  end
end