# frozen_string_literal: true

module PhisherPhinder
  class NullResponse
    def method_missing(*_args)
    end

    def ==(other)
      other.instance_of? self.class
    end
  end
end
