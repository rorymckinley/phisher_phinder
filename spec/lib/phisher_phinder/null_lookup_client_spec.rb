# frozen_string_literal: true
require 'spec_helper'

RSpec.describe PhisherPhinder::NullLookupClient do
  describe 'lookup' do
    let(:output) { subject.lookup('does.not.matter') }

    it 'returns a reponse that responds with nil to any method that is not defined' do
      expect(output.country_iso_code).to be_nil
      expect(output.organisation).to be_nil
      expect(output.something_made_up).to be_nil
    end
  end
end
