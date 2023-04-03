# frozen_string_literal: true

require_relative "helpers/endpoint"

class EndpointBasicAuthentication < Endpoint
  before do
    halt 401, "Authentication info not supplied" unless env["HTTP_AUTHORIZATION"]
  end
end

require_relative "helpers/artifice"

Artifice.activate_with(EndpointBasicAuthentication)
