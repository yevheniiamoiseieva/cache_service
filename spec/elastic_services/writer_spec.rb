require_relative '../spec_helper'

RSpec.describe ElasticServices::Writer do
  let(:mock_logger) { instance_double(Logger, info: true, error: true) }
  let(:mock_client) { double('elasticsearch_client') }
  let(:mock_pool) { instance_double(ConnectionPool) }

  let(:data_to_insert) do
    [
      { event_id: 'a1b2', user_id: 101, action: 'view' },
      { event_id: 'c3d4', user_id: 102, action: 'click' }
    ]
  end

  let(:writer_instance) do
    described_class.new(
      client_pool: mock_pool,
      logger: mock_logger,
      params: data_to_insert
    )
  end

  before do
    allow(ElasticServices::BaseService).to receive(:client_pool).and_return(mock_pool)
    allow(ElasticServices::BaseService).to receive(:elastic_logger).and_return(mock_logger)
  end

  describe '#bulk_insert' do
    let(:expected_bulk_body) do
      [
        { index: { _index: Constants::Elasticsearch::INDEX_NAME, _id: 'a1b2' } },
        { event_id: 'a1b2', user_id: 101, action: 'view' },
        { index: { _index: Constants::Elasticsearch::INDEX_NAME, _id: 'c3d4' } },
        { event_id: 'c3d4', user_id: 102, action: 'click' }
      ]
    end

    let(:elastic_response) do
      {
        'took' => 50,
        'errors' => false,
        'items' => [
          { 'index' => { 'status' => 201, '_id' => 'a1b2' } },
          { 'index' => { 'status' => 201, '_id' => 'c3d4' } }
        ]
      }
    end

    context 'when bulk insert is successful' do
      before do
        allow(mock_pool).to receive(:with).and_yield(mock_client)
      end

      it 'calls connection.bulk with the correct body and refresh: true' do
        allow(mock_client).to receive(:bulk).with(
          body: expected_bulk_body,
          refresh: true
        ).and_return(elastic_response)

        expect(mock_logger).to receive(:info).with("Bulk insert finished. Errors: false")

        result = writer_instance.bulk_insert
        expect(result).to eq(elastic_response)

        expect(mock_client).to have_received(:bulk).with(
          body: expected_bulk_body,
          refresh: true
        )
      end
    end

    context 'when an error occurs during connection or execution' do
      let(:error_message) { 'Connection refused' }
      let(:error) { StandardError.new(error_message) }

      before do
        allow(mock_pool).to receive(:with).and_raise(error)
      end

      it 'logs the error and returns a structured error hash' do
        expect(mock_logger).to receive(:error).with(/Bulk insert error: #<StandardError: #{error_message}>./)

        expected_error_result = { 'errors' => true, 'message' => error_message }
        expect(writer_instance.bulk_insert).to eq(expected_error_result)
      end
    end

    context 'when input data is empty' do
      let(:data_to_insert) { [] }
      let(:empty_bulk_body) { [] }
      let(:empty_response) { elastic_response.merge('errors' => false, 'items' => []) }

      before do
        allow(mock_pool).to receive(:with).and_yield(mock_client)
      end

      it 'calls connection.bulk with an empty body and returns the result' do
        allow(mock_client).to receive(:bulk).with(
          body: empty_bulk_body,
          refresh: true
        ).and_return(empty_response)

        expect(mock_logger).to receive(:info).with("Bulk insert finished. Errors: false")

        result = writer_instance.bulk_insert
        expect(result).to eq(empty_response)

        expect(mock_client).to have_received(:bulk).with(
          body: empty_bulk_body,
          refresh: true
        )
      end
    end
  end
end