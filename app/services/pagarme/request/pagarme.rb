class Pagarme::Request::Pagarme
  PAGARME_URI = ENV.fetch("PAGARME_API_URI")
  PAGARME_API_KEY = ENV.fetch("PAGARME_API_KEY")

  class << self
    def post_pagarme_request(request)
      params =
        {
          requests: request,
          api_key:  PAGARME_API_KEY
        }.to_json

      headers =
        {
          'content-type' => "application/json",
          'Accept'       => "application/json"
        }

      HTTParty.post(PAGARME_URI, body: params, headers: headers)
    end

    def response_formatter(json_objects)
      formated_json = "[#{json_objects.gsub("\n\u0000", ',')[0..-2]}]"

      JSON.parse(formated_json).map do |subscription|
        subscription['body'].symbolize_keys unless subscription['body']['errors'].present?
      end.compact
    rescue JSON::ParserError
      Rails.logger.error("Failure to parse the Pagarme response #{json_objects}")
      return []
    end

    def request_params_for_get(collection, slug)
      collection.map do |id|
        {
          method: "get",
          path: "/#{slug}/#{id}"
        }
      end
    end

    def request_params_for_cancel(collection, slug)
      collection.map do |id|
        {
          method: "post",
          path: "/#{slug}/#{id}/cancel"
        }
      end
    end
  end
end
