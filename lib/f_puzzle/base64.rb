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

      def encode(puzzle_data)
        json = puzzle_data.compact_blank.to_json

        result = encode_base64(json)
        result += '=' while result.length % 4 != 0

        result
      end

      private

      def encode_base64(json_data)
        bits_per_char = 6
        context_dictionary = {}
        context_dict_size = 3
        context_dictionary_to_create = {}
        context_w = ''
        context_wc = ''
        context_num_bits = 2
        context_data_val = 0
        context_data_position = 0
        context_enlarge_in = 2
        context_data = []

        json_data.each_char do |char|
          if context_dictionary[char].nil?
            context_dictionary[char] = context_dict_size
            context_dict_size += 1
            context_dictionary_to_create[char] = true
          end

          context_wc = "#{context_w}#{char}"
          if context_dictionary[context_wc]
            context_w = context_wc
          else
            if context_dictionary_to_create[context_w]
              if context_w[0].ord < 256
                context_num_bits.times do
                  context_data_val <<= 1
                  if context_data_position == bits_per_char - 1
                    context_data_position = 0
                    context_data.push BASE_64_DICTIONARY[context_data_val]
                    context_data_val = 0
                  else
                    context_data_position += 1
                  end
                end
                value = context_w[0].ord
                8.times do
                  context_data_val = (context_data_val << 1) | (value & 1)
                  if context_data_position == bits_per_char - 1
                    context_data_position = 0
                    context_data.push BASE_64_DICTIONARY[context_data_val]
                    context_data_val = 0
                  else
                    context_data_position += 1
                  end
                  value >>= 1
                end
              else
                value = 1
                context_num_bits.times do
                  context_data_val = (context_data_val << 1) | value
                  if context_data_position == bits_per_char - 1
                    context_data_position = 0
                    context_data.push BASE_64_DICTIONARY[context_data_val]
                    context_data_val = 0
                  else
                    context_data_position += 1
                  end
                  value = 0
                end
                value = context_w[0].ord
                16.times do
                  context_data_val = (context_data_val << 1) | (value & 1)
                  if context_data_position == bits_per_char - 1
                    context_data_position = 0
                    context_data.push BASE_64_DICTIONARY[context_data_val]
                    context_data_val = 0
                  else
                    context_data_position += 1
                  end
                  value = value >> 1
                end
              end
              context_enlarge_in -= 1
              if context_enlarge_in.zero?
                context_enlarge_in = 2**context_num_bits
                context_num_bits += 1
              end
              context_dictionary_to_create.delete(context_w)
            else
              value = context_dictionary[context_w]
              context_num_bits.times do
                context_data_val = (context_data_val << 1) | (value & 1)
                if context_data_position == bits_per_char - 1
                  context_data_position = 0
                  context_data.push BASE_64_DICTIONARY[context_data_val]
                  context_data_val = 0
                else
                  context_data_position += 1
                end
                value >>= 1
              end
            end
            context_enlarge_in -= 1
            if context_enlarge_in.zero?
              context_enlarge_in = 2**context_num_bits
              context_num_bits += 1
            end
            context_dictionary[context_wc] = context_dict_size
            context_dict_size += 1
            context_w = char
          end
        end

        if context_w != ''
          if context_dictionary_to_create[context_w]
            if context_w[0].ord < 256
              context_num_bits.times do
                context_data_val <<= 1
                if context_data_position == bits_per_char - 1
                  context_data_position = 0
                  context_data.push BASE_64_DICTIONARY[context_data_val]
                  context_data_val = 0
                else
                  context_data_position += 1
                end
              end
              value = context_w[0].ord
              8.times do
                context_data_val = (context_data_val << 1) | (value & 1)
                context_data_position = 0
                if context_data_position == bits_per_char - 1
                  context_data.push BASE_64_DICTIONARY[context_data_val]
                  context_data_val = 0
                end
                value >>= 1
              end
            else
              value = 1
              context_num_bits.times do
                context_data_val = (context_data_val << 1) | value
                if context_data_position == bits_per_char - 1
                  context_data_position = 0
                  context_data.push BASE_64_DICTIONARY[context_data_val]
                  context_data_val = 0
                else
                  context_data_position += 1
                end
                value = 0
              end
              value = context_w[0].ord
              16.times do
                context_data_val = (context_data_val << 1) | (value & 1)
                if context_data_position == bits_per_char - 1
                  context_data_position = 0
                  context_data.push BASE_64_DICTIONARY[context_data_val]
                  context_data_val = 0
                else
                  context_data_position += 1
                end
                value >>= 1
              end
            end
            context_enlarge_in -= 1
            if context_enlarge_in.zero?
              context_enlarge_in = 2**context_num_bits
              context_num_bits += 1
            end
            context_dictionary_to_create.delete(context_w)
          else
            value = context_dictionary[context_w]
            context_num_bits.times do
              context_data_val = (context_data_val << 1) | (value & 1)
              if context_data_position == bits_per_char - 1
                context_data_position = 0
                context_data.push BASE_64_DICTIONARY[context_data_val]
                context_data_val = 0
              else
                context_data_position += 1
              end
              value >>= 1
            end
          end
          context_enlarge_in -= 1
          if context_enlarge_in.zero?
            context_enlarge_in = 2**context_num_bits
            context_num_bits += 1
          end
        end

        value = 2
        context_num_bits.times do
          context_data_val = (context_data_val << 1) | (value & 1)
          if context_data_position == bits_per_char - 1
            context_data_position = 0
            context_data.push BASE_64_DICTIONARY[context_data_val]
            context_data_val = 0
          else
            context_data_position += 1
          end
          value >>= 1
        end

        loop do
          context_data_val <<= 1
          if context_data_position == bits_per_char - 1
            context_data.push BASE_64_DICTIONARY[context_data_val]
            break
          else
            context_data_position += 1
          end
        end

        context_data.join
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
