# frozen_string_literal: true

module Llms
  # Base API client
  class Base
    class ResultError < StandardError; end

    attr_reader :prompt, :result_format

    RESULT_FORMATS = %i[numbered_list json].freeze

    def initialize(prompt, result_format: :json)
      @prompt = prompt

      raise ArgumentError, "Invalid result format: #{result_format}" unless RESULT_FORMATS.include?(result_format)

      @result_format = result_format
    end

    def self.configured?
      raise NotImplementedError
    end

    def self.extract_numbered_list(text)
      pattern = /^(?<number>\d+)\.\s.*?\*\*(?<title>.*?)\*\*\s*:\s*(?<value>.*)$/
      matches = text.scan(pattern)

      matches.map do |match|
        detected_separator = ["/", ","].detect { match[2].include? it } || ","

        {
          number: Integer(match[0]),
          label: match[1],
          value: match[2].split(/\s*#{detected_separator}\s*/)
        }
      end.sort_by { it.fetch(:number) } # rubocop:disable Style/MultilineBlockChain
    end

    def self.extract_json(text)
      text[/(\{.+\})/im, 1]
    end

    def self.extract_jsx(text)
      text[/(\{.+\})/im, 1] if text&.match?(/```jsx\n/i)
    end

    def chat_completion(text)
      raise NotImplementedError
    end

    # rubocop:disable Metrics/AbcSize
    def extract_result(content) # rubocop:disable Metrics/MethodLength
      case result_format
      when :numbered_list
        @read_attributes = self.class.extract_numbered_list(content).to_h { [it.fetch(:label), it.fetch(:value)] }
      else # :json
        content_jsx_result = self.class.extract_jsx(content)
        if content_jsx_result
          @read_attributes = eval(content_jsx_result.gsub(/: +null/i, ": nil")) # rubocop:disable Security/Eval
        else
          content_json_result = self.class.extract_json(content)
          @read_attributes = begin
            JSON.parse(content_json_result, symbolize_names: true)
          rescue JSON::ParserError
            raise ResultError, "Parsing JSON inside content: #{content_json_result}"
          end
        end
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
