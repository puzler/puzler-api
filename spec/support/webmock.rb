require "webmock/rspec"

# No real external HTTP in specs. localhost stays open for the test server /
# ActiveStorage disk service; everything else must be stubbed explicitly.
WebMock.disable_net_connect!(allow_localhost: true)
