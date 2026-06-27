require "erb"

module Sudokupad
  # Turns a Puzler definition (+ optional solution) into SudokuPad links:
  # encode → compress → shorten via createlink. Single backend path used by both
  # the editor export and the cached publish-time links.
  module LinkBuilder
    BASE = "https://sudokupad.app/".freeze

    module_function

    # Returns { short_url:, long_url:, payload:, warnings: }, or nil for puzzles
    # that can't be exported (e.g. a non-square grid). The short link falls back
    # to the long ?puzzleid= URL when createlink fails, so it always resolves.
    def build(definition:, solution: nil, include_solution: true, fallback_author: nil)
      result = Fpuzzles::Encoder.call(
        definition: definition, solution: solution,
        include_solution: include_solution, fallback_author: fallback_author
      )
      payload = Fpuzzles::Compressor.compress(result.data)
      long_url = "#{BASE}?puzzleid=#{ERB::Util.url_encode(payload)}"
      short_url =
        begin
          SudokupadLinkShortener.call(payload)
        rescue SudokupadLinkShortener::Error
          long_url
        end
      { short_url: short_url, long_url: long_url, payload: payload, warnings: result.warnings }
    rescue Fpuzzles::UnsupportedGrid
      nil
    end
  end
end
