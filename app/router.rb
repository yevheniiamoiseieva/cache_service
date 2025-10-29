require 'roda'
require 'json'
require_relative 'elastic_services/reader'
require_relative 'services/update_or_create_service'

class Router < Roda
  plugin :json
  plugin :default_headers, 'Content-Type' => 'application/json'

  route do |r|
    r.on "cache/events" do

      r.post do
        request_body = JSON.parse(r.body.read, symbolize_names: true)

        unless request_body[:event_id]
          response.status = 400
          next { error: "Missing event_id in payload" }
        end

        result = UpdateOrCreateService.call(request_body)

        response.status = 202
        { message: "Cache update accepted", status: result[:status] }
      rescue JSON::ParserError
        response.status = 400
        { error: "Invalid JSON format" }
      end

      r.get Integer do |event_id|
        params = { event_id: { eq: event_id } }
        data = ElasticServices::Reader.call(params:, action: :search)

        if data.dig("hits", "total", "value").to_i.zero?
          response.status = 404
          { error: "Data not found in cache" }
        else
          data.dig("hits", "hits").first.dig("_source")
        end
      end
    end
  end
end