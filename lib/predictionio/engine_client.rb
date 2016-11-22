# Ruby SDK for convenient access of PredictionIO Output API.
#
# Author::    PredictionIO Team (support@prediction.io)
# Copyright:: Copyright (c) 2014 TappingStone, Inc.
# Copyright:: Copyright (c) 2016 Perpetto BG Ltd.
# License::   Apache License, Version 2.0

module PredictionIO
  # This class contains methods that interface with PredictionIO Engine
  # Instances that are trained from PredictionIO built-in Engines.
  #
  # Many REST request methods support optional arguments. They can be supplied
  # to these methods as Hash'es. For a complete reference, please visit
  # http://prediction.io.
  #
  # == Synopsis
  # In most cases, using synchronous methods. If you have a special performance
  # requirement, you may want to take a look at asynchronous methods.
  #
  # === Instantiate an EngineClient
  #     # Include the PredictionIO SDK
  #     require 'predictionio'
  #
  #     client = PredictionIO::EngineClient.new
  #
  # === Send a Query to Retrieve Predictions
  #     # PredictionIO call to record the view action
  #     begin
  #       result = client.query('uid' => 'foobar')
  #     rescue NotFoundError => e
  #       ...
  #     rescue BadRequestError => e
  #       ...
  #     rescue ServerError => e
  #       ...
  #     end
  class EngineClient
    # Raised when an event is not created after a synchronous API call.
    class NotFoundError < StandardError; end

    # Raised when the query is malformed.
    class BadRequestError < StandardError; end

    # Raised when the Engine Instance returns a server error.
    class ServerError < StandardError; end

    # Create a new PredictionIO Event Client with defaults:
    # - 1 concurrent HTTP(S) connections (threads)
    # - API entry point at http://localhost:8000 (apiurl)
    # - a 60-second timeout for each HTTP(S) connection (thread_timeout)
    def initialize(apiurl = 'http://localhost:8000')
      @http = PredictionIO::Connection.new(URI(apiurl)) do |faraday|
        yield faraday if block_given?
      end
    end


    # Returns PredictionIO's status in string.
    def get_status
      status = @http.get(PredictionIO::Request.new('/'))
      begin
        status.body
      rescue
        status
      end
    end

    # Sends a query and returns the response.
    # The query should be a Ruby data structure that can be
    # converted to a JSON object.
    #
    # Corresponding REST API method: POST /
    def send_query(query)
      response = @http.post(PredictionIO::Request.new('/queries.json', query.to_json))
      return JSON.parse(response.body) if response.success?
      begin
        msg = response.body
      rescue
        raise response
      end
      case response.status
      when 400
        fail BadRequestError, msg
      when 404
        fail NotFoundError, msg
      when 500
        fail ServerError, msg
      else
        fail msg
      end
    end
  end
end
