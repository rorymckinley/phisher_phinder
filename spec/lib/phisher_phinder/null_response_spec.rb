# frozen_string_literal: true
require 'spec_helper'

RSpec.describe PhisherPhinder::NullResponse do
  it 'returns nil when any undefined method is called' do
    expect(subject.foo).to be_nil
    expect(subject.bar).to be_nil
  end

  it 'always equals another instance of the class' do
    expect(described_class.new).to eq described_class.new
    expect(described_class.new).to_not eq ''
  end
end
