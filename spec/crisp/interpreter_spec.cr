require "../helper"

describe "Crisp::Interpreter" do
  describe "#eval_string" do
    it "evaluates string of Crisp expression" do
      i = Crisp::Interpreter.new
      result = i.eval_string "(+ 1 2)"
      result.should be_a(Crisp::Type)
      unwrapped = result.unwrap
      unwrapped.should be_a(Int32)
      unwrapped.should eq(3)
    end
  end

  describe "#run" do
    it "raises eval error with file which doesn't exist" do
      expect_raises Crisp::EvalException do
        Crisp::Interpreter.new "/non/existent/file"
      end
    end
  end
end
