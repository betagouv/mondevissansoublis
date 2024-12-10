# frozen_string_literal: true

require "rails_helper"

RSpec.describe Llms::Mistral, type: :service do
  let(:prompt) { Rails.root.join("lib/quote_reader/prompt_qa.txt").read }
  let(:mistral) { described_class.new(prompt) }

  describe "#chat_completion" do
    let(:text) do
      <<~TEXT
        1.1  dépose et enlèvement d'une chaudière gaz hors condensation                             1,00  U        0,00           0,00
          1.2  Pompe à chaleur AIR/EAU - moyenne température - Atlantic Alféa Extensa A.I. 8 R32 -    1,00  U    8 765,00       8 765,00

               6kW - classe énergétique chauffage A+++ - efficacité énergétique saisonnière chauffage
               avec sonde extérieure 179 % - SCOP 4.5 - niveau sonore intérieur / extérieur : 32/38 dB
      TEXT
    end

    # rubocop:disable RSpec/ExampleLength
    # rubocop:disable RSpec/MultipleExpectations
    it "returns a successful complete response", :vcr do
      read_attributes = mistral.chat_completion(text)

      expect(read_attributes.dig(:gestes, -1)).to include(
        type: "pac_air_eau",
        marque: "Atlantic",
        puissance: 6.0
      )
      expect(mistral.read_attributes).to be(read_attributes)
    end
    # rubocop:enable RSpec/MultipleExpectations
    # rubocop:enable RSpec/ExampleLength
  end
end
