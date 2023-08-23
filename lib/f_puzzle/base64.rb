# frozen_string_literal: true

module FPuzzle
  class Base64
    class << self
      BASE_64_DICTIONARY = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/\\'

      def decode(base64_data)
        json = decode_base64(base64_data)
        return if json.blank?

        JSON.parse(
          json
        ).deep_transform_keys { |k| k.underscore.to_sym }
      end

      private

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
