require "lzstring"
require "json"

module Fpuzzles
  # f-puzzles JSON ⇄ SudokuPad `puzzleid` payload. The payload is the f-puzzles
  # JSON lz-string-compressed to base64 with an `fpuzzles` prefix — byte-identical
  # to what the JS lz-string lib produces (verified), so SudokuPad imports it
  # natively. `decompress` is the inverse, available now for a future import path.
  module Compressor
    PREFIX = "fpuzzles".freeze

    module_function

    def compress(data)
      PREFIX + LZString.compress_to_base64(JSON.generate(data))
    end

    def decompress(payload)
      JSON.parse(LZString.decompress_from_base64(payload.delete_prefix(PREFIX)))
    end
  end
end
