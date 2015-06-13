require "../../helper"
require "./mal_spec_runner.cr"

describe "'Make a Lisp' tests" do
  it "tests step2 of mal" do
    runner = MalTestRunner.new(__DIR__ + "/tests/step2_eval.mal")
    i = Crisp::Interpreter.new

    runner.each_test do |input, output, result|
      if result
        r = i.print i.eval_string(input)
      else
        output.empty?.should be_false
        begin
          i.eval_string(input)
        rescue e
          e.message.should match(/#{output.last.chomp}/)
        end
      end
    end
  end
end
