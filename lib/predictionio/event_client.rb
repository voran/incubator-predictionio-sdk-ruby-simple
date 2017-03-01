# Ruby SDK for convenient access of PredictionIO Output API.
#
# Author::    PredictionIO Team (support@prediction.io)
# Copyright:: Copyright (c) 2014 TappingStone, Inc.
# Copyright:: Copyright (c) 2016 Perpetto BG Ltd.
# License::   Apache License, Version 2.0

require 'date'

module PredictionIO
  # This class contains methods that interface with the PredictionIO Event
  # Server via the PredictionIO Event API using REST requests.
  #
  # Many REST request methods support optional arguments. They can be supplied
  # to these methods as Hash'es. For a complete reference, please visit
  # http://prediction.io.
  #
  # == High-performance Asynchronous Backend
  #
  # All REST request methods come in both synchronous and asynchronous flavors.
  # Both flavors accept the same set of arguments. In addition, all synchronous
  # request methods can instead accept a PredictionIO::AsyncResponse object
  # generated from asynchronous request methods as its first argument. In this
  # case, the method will block until a response is received from it.
  #
  # Any network reconnection and request retry is automatically handled in the
  # background. Exceptions will be thrown after a request times out to avoid
  # infinite blocking.
  #
  # == Installation
  # The easiest way is to use RubyGems:
  #     gem install predictionio
  #
  # == Synopsis
  # In most cases, using synchronous methods. If you have a special performance
  # requirement, you may want to take a look at asynchronous methods.
  #
  # === Instantiate an EventClient
  #     # Include the PredictionIO SDK
  #     require 'predictionio'
  #
  #     client = PredictionIO::EventClient.new(<access_key>)
  #
  # === Import a User Record from Your App (with asynchronous/non-blocking
  #     requests)
  #
  #     #
  #     # (your user registration logic)
  #     #
  #
  #     uid = get_user_from_your_db()
  #
  #     # PredictionIO call to create user
  #     response = client.aset_user(uid)
  #
  #     #
  #     # (other work to do for the rest of the page)
  #     #
  #
  #     begin
  #       # PredictionIO call to retrieve results from an asynchronous response
  #       result = client.set_user(response)
  #     rescue PredictionIO::EventClient::NotCreatedError => e
  #       log_and_email_error(...)
  #     end
  #
  # === Import a User Action (Rate) from Your App (with synchronous/blocking
  #     requests)
  #     # PredictionIO call to record the view action
  #     begin
  #       result = client.record_user_action_on_item('rate', 'foouser',
  #                                                  'baritem',
  #                                                  'rating' => 4)
  #     rescue PredictionIO::EventClient::NotCreatedError => e
  #       ...
  #     end
  class EventClient
    # Raised when an event is not created after a synchronous API call.
    class NotCreatedError < StandardError; end

    # Create a new PredictionIO Event Client with defaults:
    # - 1 concurrent HTTP(S) connections (threads)
    # - API entry point at http://localhost:7070 (apiurl)
    # - a 60-second timeout for each HTTP(S) connection (thread_timeout)
    def initialize(access_key, apiurl = 'http://localhost:7070')
      @access_key = access_key
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

    # Request to create an event and return the response.
    #
    # Corresponding REST API method: POST /events.json
    def create_event(event, entity_type, entity_id, optional = {})
      h = optional
      h.key?('eventTime') || h['eventTime'] = DateTime.now.to_s
      h['event'] = event
      h['entityType'] = entity_type
      h['entityId'] = entity_id
      @http.post(PredictionIO::Request.new(
        "/events.json?accessKey=#{@access_key}", h.to_json
      ))
    end

    # Request to delete an event and return the response.
    #
    # Corresponding REST API method: DELETE events/<your_eventId>.json
    def delete_event(event_id)
      @http.delete(PredictionIO::Request.new(
        "/events/#{event_id}.json?accessKey=#{@access_key}", {}.to_json
      ))
    end

    # Corresponding REST API method: GET events.json
    def find_events(params = {})
      @http.get(PredictionIO::Request.new(
        '/events.json', params.merge('accessKey' => @access_key)
      ))
    end

    # Request to set properties of a user and return the response.
    #
    # Corresponding REST API method: POST /events.json
    def set_user(uid, optional = {})
      create_event('$set', 'user', uid, optional)
    end

    # Request to unset properties of a user and return the response.
    #
    # properties must be a non-empty Hash.
    #
    # Corresponding REST API method: POST /events.json
    def unset_user(uid, optional)
      check_unset_properties(optional)
      create_event('$unset', 'user', uid, optional)
    end

    # Request to delete a user and return the response.
    #
    # Corresponding REST API method: POST /events.json
    def delete_user(uid)
      create_event('$delete', 'user', uid)
    end

    # Request to set properties of an item and return the response.
    #
    # Corresponding REST API method: POST /events.json
    def set_item(iid, optional = {})
      create_event('$set', 'item', iid, optional)
    end

    # Request to unset properties of an item and return the response.
    #
    # properties must be a non-empty Hash.
    #
    # Corresponding REST API method: POST /events.json
    def unset_item(iid, optional)
      check_unset_properties(optional)
      create_event('$unset', 'item', iid, optional)
    end

    # Request to delete an item and return the response.
    #
    # Corresponding REST API method: POST /events.json
    def delete_item(uid)
      create_event('$delete', 'item', uid)
    end

    # Request to record an action on an item and return the response.
    #
    # Corresponding REST API method: POST /events.json
    def record_user_action_on_item(action, uid, iid, optional = {})
      optional['targetEntityType'] = 'item'
      optional['targetEntityId'] = iid
      create_event(action, 'user', uid, optional)
    end

    private
    def check_unset_properties(optional)
      optional.key?('properties') ||
        fail(ArgumentError, 'properties must be present when event is $unset')
      optional['properties'].empty? &&
        fail(ArgumentError, 'properties cannot be empty when event is $unset')
    end
  end
end
