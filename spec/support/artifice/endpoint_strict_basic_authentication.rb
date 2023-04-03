# frozen_string_literal: true

require_relative "helpers/endpoint"

class EndpointStrictBasicAuthentication < Endpoint
  before do
    halt 401, "Authentication info not supplied" unless env["HTTP_AUTHORIZATION"]

    # Only accepts password == "password"
    halt 403, "Authentication failed" unless env["HTTP_AUTHORIZATION"] == "Basic dXNlcjpwYXNz"
  end
end

require_relative "helpers/artifice"

Artifice.activate_with(EndpointStrictBasicAuthentication)
