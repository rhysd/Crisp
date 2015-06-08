require "../helper"

describe "Crisp::Interpreter" do
  describe "#initialize" do
    it "takes arguments as string value" do
      i = Crisp::Interpreter.new %w(foo bar baz)
      result = i.eval_string("*ARGV*")
      result.should be_a(Crisp::Type)
      unwrapped = result.unwrap
      unwrapped.should be_a(Crisp::List)
      if unwrapped.is_a? Crisp::List
        unwrapped.size.should eq(3)
        a0 = unwrapped[0].unwrap
        a1 = unwrapped[1].unwrap
        a2 = unwrapped[2].unwrap
        a0.should be_a(String)
        a1.should be_a(String)
        a2.should be_a(String)
        a0.should eq("foo")
        a1.should eq("bar")
        a2.should eq("baz")
      end
    end
  end

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
      i = Crisp::Interpreter.new
      expect_raises Crisp::EvalException do
        i.run "/non/existent/file"
      end
    end
  end
end
