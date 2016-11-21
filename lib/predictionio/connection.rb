require 'faraday'
module PredictionIO

  # This class handles Connections
  class Connection


    # Creates a connection to the given URI.
    def initialize(uri)
      @connection = Faraday.new(:url => uri) do |faraday|
        faraday.request  :url_encoded             # form-encode POST params
        faraday.response :logger                  # log requests to STDOUT
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end
      @connection.headers['Content-Type'] = 'application/json; charset=utf-8'
    end

    # Create a GET request and return the response.
    def get(request)
      @connection.get request.qpath
    end

    # Create a POST and return the response.
    def post(request)
      if request.params.is_a?(Hash)
        @connection.post request.path, request.params
      else
        @connection.post request.path do |req|
          req.body = request.params
        end
      end
    end

    # Create a DELETE and return the response.
    def delete(request)
      @connection.delete request.path do |req|
        req.body = request.params
      end
    end
  end
end
