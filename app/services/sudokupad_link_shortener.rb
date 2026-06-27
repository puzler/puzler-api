require "net/http"
require "json"

# Turns an f-puzzles puzzleid payload into a short SudokuPad link via SudokuPad's
# createlink API. Short links are nicer to share and, for solution-embedded
# payloads, carry no decodable data (the solution stays out of any URL we hand
# out). Runs server-side to avoid browser CORS to sudokupad.app and to keep
# solution payloads off the client. Raises Error on any failure so callers can
# fall back to the long ?puzzleid= URL.
class SudokupadLinkShortener
  class Error < StandardError; end

  # POST { puzzle: <payload> } -> { "result": "success", "shortid": "0jct63gsc3" }
  ENDPOINT = "https://sudokupad.app/admin/createlink".freeze
  SHORT_LINK_BASE = "https://sudokupad.app".freeze
  TIMEOUT = 5 # seconds — third party; don't hang a request on it.

  def self.call(payload)
    new(payload).call
  end

  def initialize(payload)
    @payload = payload.to_s
  end

  def call
    raise Error, "Empty payload" if @payload.empty?

    response = post
    raise Error, "createlink returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    body = JSON.parse(response.body)
    shortid = body["shortid"].to_s
    raise Error, "createlink failed (#{body['result']})" unless body["result"] == "success" && shortid.present?

    "#{SHORT_LINK_BASE}/#{shortid}"
  rescue JSON::ParserError, Net::OpenTimeout, Net::ReadTimeout, SocketError, IOError, SystemCallError => e
    raise Error, "createlink request failed: #{e.message}"
  end

  private

  def post
    uri = URI(ENDPOINT)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = TIMEOUT
    http.read_timeout = TIMEOUT

    # createlink expects a JSON body; a form-encoded body is rejected as
    # "Invalid request data". `{ puzzle }` alone is enough (it generates the id).
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(puzzle: @payload)
    http.request(request)
  end
end
