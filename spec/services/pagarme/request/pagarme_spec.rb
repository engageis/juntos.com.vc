require 'rails_helper'

RSpec.describe Pagarme::Request::Pagarme do
  let(:response_body) do
    "{
      \"body\":
      {
        \"id\": 10,
        \"parameter_name\": \"some parameter name\",
        \"message\": \"some message\"
      }
    }"
  end
  let(:response) do
    "#{response_body}\n\u0000"
  end

  describe ".response_formatter" do
    subject { Pagarme::Request::Pagarme.response_formatter(response) }

    context "when the formatter handles the response" do
      it { is_expected.not_to be_empty }
      it { expect(subject.first).to be_a(Hash) }
      it { expect(subject.first[:message]).to be_present }
      it { expect(subject.first[:parameter_name]).to eq("some parameter name") }
    end

    context "when the formatter cannot handle the response" do
      context "and the response does not need to be formatted" do
        let(:response) { response_body }

        it { is_expected.to be_empty }

        it "should log the error" do
          expect(Rails.logger).to receive(:error).with("Failure to parse the Pagarme response #{response}")

          subject
        end
      end

      context "and response is not even a json" do
        let(:response) { "any non-json formattable" }

        it { is_expected.to be_empty }

        it "should log the error" do
          expect(Rails.logger).to receive(:error).with("Failure to parse the Pagarme response #{response}")

          subject
        end
      end
    end

    context "when the response comes with errors" do
      let(:response_body) do
        "{
          \"body\":
          {
            \"errors\":
            {
              \"type\": \"any type of error\"
            }
          }
        }"
      end

      it { is_expected.to be_empty }
    end
  end
end
