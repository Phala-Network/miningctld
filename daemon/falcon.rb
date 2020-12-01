#!/usr/bin/env -S falcon host
# frozen_string_literal: true

load :rack, :supervisor, :self_signed_tls

hostname = File.basename(__dir__)
rack hostname, :self_signed_tls do
	endpoint Async::HTTP::Endpoint.parse('http://0.0.0.0:9292')
	protocol {Async::HTTP::Protocol::HTTP1}
	scheme 'http'
	cache true
end
