# frozen_string_literal: true

module FPuzzle
  class Base64
    class << self # rubocop:disable Metrics/ClassLength
      BASE_64_DICTIONARY = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/\\'

      def decode(base64_data)
        json = decode_base64(base64_data)
        return if json.blank?

        JSON.parse(
          json
        ).deep_transform_keys { |k| k.underscore.to_sym }
      end

      def encode(puzzle_data)
        json = puzzle_data.compact_blank.to_json

        result = encode_base64(json)
        result += '=' while result.length % 4 != 0

        result
      end

      private

      ENCODE_BITS_PER_CHAR = 5

      def check_data_reset(data)
        return data[:position] += 1 unless data[:position] == ENCODE_BITS_PER_CHAR

        data[:position] = 0
        data[:output].push BASE_64_DICTIONARY[data[:numeric]]
        data[:numeric] = 0
      end

      def increment_data_loop(data, num_times)
        num_times.times do
          data[:numeric] = (data[:numeric] << 1) | (data[:value] & 1)
          check_data_reset(data)
          data[:value] >>= 1
        end
      end

      def increment_bits(bits)
        bits[:enlarge_in] -= 1
        return unless bits[:enlarge_in].zero?

        bits[:enlarge_in] = 2**bits[:num]
        bits[:num] += 1
      end

      def char_loop(bits, lt256, data, first_pass)
        bits[:num].times do
          data[:numeric] <<= 1
          data[:numeric] |= data[:value] if lt256
          check_data_reset(data)
          if lt256
            data[:value] = 0
          elsif first_pass
            data[:value] >>= 1
          end
        end
        data[:value] = chars[0].ord
      end

      def process_chars(dictionary, chars, data, bits, first_pass)
        if dictionary[:to_create][chars]
          lt256 = chars[0].ord < 256
          data[:value] = 1 if lt256
          char_loop(bits, lt256, data, first_pass)
          increment_data_loop(data, lt256 ? 16 : 8)
          increment_bits(bits)
          dictionary[:to_create].delete(chars)
        else
          data[:value] = dictionary[:values][chars]
          increment_data_loop(data, bits[:num])
        end
        increment_bits(bits)
      end

      def encode_base64(json_data) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        dictionary = { values: {}, to_create: {} }
        bits = { num: 2, enlarge_in: 2 }
        data = { output: [], position: 0, numeric: 0, value: nil }
        w = ''
        wc = ''

        json_data.each_char do |char|
          if dictionary[:values][char].nil?
            dictionary[:values][char] = dictionary[:values].length + 3
            dictionary[:to_create][char] = true
          end

          wc = "#{w}#{char}"
          if dictionary[:values][wc]
            w = wc
          else
            process_chars(dictionary, w, data, bits, true)
            dictionary[:values][wc] = dictionary[:values].length + 3
            w = char
          end
        end

        process_chars(dictionary, w, data, bits, false) if w != ''

        data[:value] = 2
        bits[:num].times do
          data[:numeric] = (data[:numeric] << 1) | (data[:value] & 1)
          check_data_reset(data)
          data[:value] >>= 1
        end

        while data[:position] <= ENCODE_BITS_PER_CHAR
          data[:numeric] <<= 1
          data[:output].push BASE_64_DICTIONARY[data[:numeric]] if data[:position] == ENCODE_BITS_PER_CHAR
          data[:position] += 1
        end

        data[:output].join
      end

      def decode_base64(base64_data) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        length = base64_data.length
        data = get_decode_data(base64_data, 0)
        bits = decode_loop(2, base64_data:, data:)
        return '' if bits == 2

        c = decode_loop(8 << bits, base64_data:, data:).chr
        dictionary = [0, 1, 2, c]
        result = [c]

        num_bits = 3
        enlarge_in = 4
        entry = c

        while data[:index] <= length
          bits = decode_loop(num_bits, base64_data:, data:)
          return result.join if bits == 2

          w = entry
          c = bits
          if bits.in?([0, 1])
            dictionary.push decode_loop(8 << bits, base64_data:, data:).chr
            c = dictionary.size - 1
            enlarge_in -= 1
          end

          if enlarge_in.zero?
            enlarge_in = 2**num_bits
            num_bits += 1
          end

          if dictionary[c].is_a? String
            entry = dictionary[c]
          elsif c == dictionary.length
            entry = w + w[0]
          else
            return
          end
          result.push(entry)

          dictionary.push(w + entry[0])
          enlarge_in -= 1

          if enlarge_in.zero?
            enlarge_in = 2**num_bits
            num_bits += 1
          end
        end

        ''
      end

      def get_decode_data(base64_data, index)
        {
          val: BASE_64_DICTIONARY.index(base64_data[index]),
          position: 32,
          index: index + 1
        }
      end

      def decode_loop(times, data:, base64_data:)
        bits = 0
        times.times do |i|
          resb = data[:val] & data[:position]
          data[:position] >>= 1
          if data[:position].zero?
            data.merge!(
              get_decode_data(
                base64_data,
                data[:index]
              )
            )
          end
          bits |= 2**i if resb.positive?
        end
        bits
      end
    end
  end
end
