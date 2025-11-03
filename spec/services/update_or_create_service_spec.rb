require_relative '../spec_helper'

RSpec.describe UpdateOrCreateService do
  let(:event_id) { 42 }
  let(:input_data) { { event_id: event_id, title: 'New Title', description: 'Updated data' } }

  before do
    allow(ElasticServices::Reader).to receive(:call)
    allow(ElasticServices::Writer).to receive(:call)
    allow(ElasticServices::Updater).to receive(:call)
  end

  context 'when event is NOT found in cache (Cache MISS)' do
    before do
      allow(ElasticServices::Reader).to receive(:call).and_return(
        { "hits" => { "total" => { "value" => 0 }, "hits" => [] } }
      )
    end

    it 'calls Writer for creation and returns :created status' do
      expect(ElasticServices::Writer).to receive(:call).with(
        params: [input_data],
        action: :bulk_insert
      )
      expect(ElasticServices::Updater).not_to receive(:call)

      result = described_class.call(input_data)
      expect(result[:status]).to eq(:created)
    end
  end

  context 'when event IS found in cache (Cache HIT)' do
    let(:elastic_document_id) { 'elastic_doc_abc' }
    let(:old_data) { { event_id: event_id, title: 'Old Title', created_at: '2025-01-01' } }

    let(:elastic_hit) do
      {
        'hits' => {
          'total' => { 'value' => 1 },
          'hits' => [{ '_id' => elastic_document_id, '_source' => old_data }]
        }
      }
    end

    before do
      allow(ElasticServices::Reader).to receive(:call).and_return(elastic_hit)
    end

    it 'calls Updater with the merged document and returns :updated status' do
      expected_merged_document = old_data.merge(input_data)

      expect(ElasticServices::Writer).not_to receive(:call)

      expect(ElasticServices::Updater).to receive(:call).with(
        params: {
          document_id: elastic_document_id,
          document: expected_merged_document
        },
        action: :update
      )

      result = described_class.call(input_data)
      expect(result[:status]).to eq(:updated)
    end
  end

  describe '#find_data_by_id logic' do
    it 'calls Reader with correct term query structure' do
      expected_params = { event_id: { eq: event_id } }
      expect(ElasticServices::Reader).to receive(:call).with(
        params: expected_params,
        action: :search
      ).and_return({ "hits" => { "total" => { "value" => 0 }, "hits" => [] } })

      described_class.new(event_id: event_id).send(:find_data_by_id, event_id)
    end
  end
end