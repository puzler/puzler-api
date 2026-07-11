require "lzstring"
require "json"

module Scl
  # SCL JSON ⇄ SudokuPad `puzzleid` payload. The payload is the SCL JSON
  # lz-string-compressed to base64 with an `scl` prefix. We deliberately emit
  # PLAIN JSON (no PuzzleZipper key-aliasing): SudokuPad's decoder tries
  # JSON.parse before PuzzleZipper.unzip, and skipping the zipper avoids its
  # numeric-string coercion (a `"solution: 0123..."` meta-cage would lose its
  # leading zero). `decompress` is the inverse, used by specs and available
  # for a future import path.
  module Compressor
    PREFIX = "scl".freeze

    module_function

    def compress(data)
      PREFIX + LZString.compress_to_base64(JSON.generate(data))
    end

    def decompress(payload)
      JSON.parse(LZString.decompress_from_base64(payload.delete_prefix(PREFIX)))
    end
  end
end
