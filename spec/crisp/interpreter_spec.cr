require "../helper"
require_crisp "interpreter"

describe "Crisp::Interpreter"
  describe "#eval_string"
    it "evaluates string of Crisp expression"
      i = Crisp::Interpreter.new
      result = i.eval_string "(+ 1 2)"
      result.should be_a(Crisp::Type)
      unwrapped = result.unwrap
      result.should be_a(Int32)
      result.should eq(unwrapped, 3)
    end
  end
end
