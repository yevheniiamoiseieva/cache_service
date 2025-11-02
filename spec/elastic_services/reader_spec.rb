require_relative '../spec_helper'

RSpec.describe ElasticServices::Reader do
  let(:mock_logger) { instance_double(Logger, info: true, error: true) }
  let(:mock_client) { double('elasticsearch_client') }
  let(:mock_pool) { instance_double(ConnectionPool) }

  let(:search_params) do
    {
      user_id: { eq: 42 },
      created_at: { eq: '2023-01-01' }
    }
  end

  let(:reader_instance) do
    described_class.new(
      client_pool: mock_pool,
      logger: mock_logger,
      params: search_params,
      size: 50,
      from: 100
    )
  end

  before do
    # Stub class-level attributes
    allow(ElasticServices::BaseService).to receive(:client_pool).and_return(mock_pool)
    allow(ElasticServices::BaseService).to receive(:elastic_logger).and_return(mock_logger)
  end

  describe '#build_search_query' do
    subject { reader_instance.send(:build_search_query, search_params) }

    context 'when given valid :eq search parameters' do
      let(:search_params) { { status: { eq: 'active' }, type: { eq: 'post' } } }

      it 'constructs the correct Elasticsearch query body with bool filter' do
        expected_query = {
          query: {
            bool: {
              filter: [
                { term: { status: 'active' } },
                { term: { type: 'post' } }
              ]
            }
          }
        }
        expect(subject).to eq(expected_query)
      end
    end

    context 'when given parameters without :eq condition (which are ignored)' do
      let(:search_params) { { status: { not_eq: 'active' }, type: { eq: 'post' } } }

      it 'only includes the filters with the :eq condition' do
        expected_query = {
          query: {
            bool: {
              filter: [
                { term: { type: 'post' } }
              ]
            }
          }
        }
        expect(subject).to eq(expected_query)
      end
    end

    context 'when given empty search parameters' do
      let(:search_params) { {} }

      it 'returns a query with an empty filter array' do
        expected_query = {
          query: {
            bool: {
              filter: []
            }
          }
        }
        expect(subject).to eq(expected_query)
      end
    end
  end

  describe '#search' do
    let(:expected_query_body) do
      {
        query: {
          bool: {
            filter: [
              { term: { user_id: 42 } },
              { term: { created_at: '2023-01-01' } }
            ]
          }
        }
      }
    end

    let(:elastic_response) do
      {
        "hits" => {
          "total" => { "value" => 500, "relation" => "eq" },
          "hits" => [{ "_source" => { "id" => 1, "data" => "A" } }]
        }
      }
    end

    before do
      allow(reader_instance).to receive(:build_search_query).and_return(expected_query_body)
    end

    context 'when search is successful' do
      before do
        allow(mock_pool).to receive(:with).and_yield(mock_client)
      end

      it 'calls connection.search with correct parameters' do
        allow(mock_client).to receive(:search).with(
          index: Constants::Elasticsearch::INDEX_ALIAS,
          body: expected_query_body,
          size: 50,
          from: 100
        ).and_return(elastic_response)

        expect(mock_logger).to receive(:info).with(/Search executed successfully/)

        result = reader_instance.search
        expect(result).to eq(elastic_response)

        expect(mock_client).to have_received(:search).with(
          index: Constants::Elasticsearch::INDEX_ALIAS,
          body: expected_query_body,
          size: 50,
          from: 100
        )
      end
    end

    context 'when an error occurs during search' do
      let(:error_message) { 'Elasticsearch connection error' }

      before do
        allow(mock_pool).to receive(:with).and_raise(StandardError.new(error_message))
      end

      it 'logs the error' do
        expect(mock_logger).to receive(:error).with(/Search error for params.*#{error_message}/)
        reader_instance.search
      end

      it 'returns an empty hits structure' do
        expected_empty_result = { "hits" => { "total" => { "value" => 0 }, "hits" => [] } }
        expect(reader_instance.search).to eq(expected_empty_result)
      end
    end
  end
end
