require_relative '../elastic_services/reader'
require_relative '../elastic_services/writer'
require_relative '../elastic_services/updater'

class UpdateOrCreateService

  def self.call(input)
    new(input).call
  end

  def initialize(input)
    @input = input
  end

  def call
    event_id = @input[:event_id]

    data_in_elastic = find_data_by_id(event_id)

    if data_in_elastic.nil?
      create_document
      action = :created
    else
      update_document(data_in_elastic)
      action = :updated
    end

    { status: action }
  end

  private

  def find_data_by_id(event_id)
    params = { event_id: { eq: event_id } }
    data = ElasticServices::Reader.call(params:, action: :search)

    if data.dig("hits", "total", "value").to_i.zero?
      nil
    else
      { id: data.dig("hits", "hits").first["_id"], data: data.dig("hits", "hits").first.dig("_source") }
    end
  end

  def create_document
    ElasticServices::Writer.call(params: [@input], action: :bulk_insert)
  end

  def update_document(data_in_elastic)
    updated_document = data_in_elastic[:data].merge(@input)
    params = { document_id: data_in_elastic[:id], document: updated_document }
    ElasticServices::Updater.call(params:, action: :update)
  end
end