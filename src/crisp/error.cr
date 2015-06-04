module Crisp
  extend self

  class ParseException < Exception
  end

  class EvalException < Exception
  end

  class RuntimeException < Exception
    getter :thrown
    def initialize(@thrown)
      super()
    end
  end

  def eval_error(msg)
    raise Crisp::EvalException.new msg
  end

  def parse_error(msg)
    raise Crisp::ParseException.new msg
  end
end
