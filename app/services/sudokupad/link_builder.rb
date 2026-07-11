require "erb"

module Sudokupad
  # Turns a Puzler definition (+ optional solution) into SudokuPad links:
  # encode (native SCL) → compress → shorten via createlink. Single backend
  # path used by both the editor export and the cached publish-time links.
  module LinkBuilder
    BASE = "https://sudokupad.app/".freeze

    module_function

    # Returns { short_url:, long_url:, payload:, warnings: }, or nil for
    # puzzles that can't be exported (malformed grid). The short link falls
    # back to the long ?puzzleid= URL when createlink fails, so it always
    # resolves. Player settings (e.g. turning the conflict checker off for
    # non-standard-sudoku puzzles) can only travel as `setting-*` URL params —
    # SudokuPad ignores settings inside the payload — so they are appended to
    # both URL forms.
    def build(definition:, solution: nil, include_solution: true, fallback_author: nil)
      result = Scl::Encoder.call(
        definition: definition, solution: solution,
        include_solution: include_solution, fallback_author: fallback_author
      )
      payload = Scl::Compressor.compress(result.data)
      long_url = append_params("#{BASE}?puzzleid=#{ERB::Util.url_encode(payload)}", result.url_params)
      short_url =
        begin
          append_params(SudokupadLinkShortener.call(payload), result.url_params)
        rescue SudokupadLinkShortener::Error
          long_url
        end
      { short_url: short_url, long_url: long_url, payload: payload, warnings: result.warnings }
    rescue Scl::UnsupportedGrid
      nil
    end

    def append_params(url, params)
      return url if params.nil? || params.empty?

      query = params.map { |key, value| "#{ERB::Util.url_encode(key)}=#{ERB::Util.url_encode(value)}" }.join("&")
      url + (url.include?("?") ? "&" : "?") + query
    end
  end
end
