# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Overphishing::Mail do
  let(:base_headers) do
    {
      original_email: '',
      original_headers: '',
      original_body: '',
      headers: {},
      tracing_headers: []
    }
  end

  it 'exposes all the email addresses that appear in the Reply-To headers' do
    mail = described_class.new(
      **base_headers.merge({
        headers: {
          reply_to: [
            "a@b.com",
            "c@d.com, <d@e.com >",
            "d@e.com, e@F.com",
            "G <g@h.com>, H <h@i.com>"
          ]
        }
      })
    )

    expect(mail.reply_to_addresses.sort).to eql([
      'a@b.com', 'c@d.com', 'd@e.com', 'e@f.com', 'g@h.com', 'h@i.com'
    ])
  end
end
