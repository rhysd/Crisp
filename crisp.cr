require "./src/crisp/interpreter"

if ARGV.empty?
  begin
    Crisp::Interpreter.new.run
  rescue e
    STDERR.puts e
    exit 1
  end
else
  Crisp::Interpreter.new(ARGV[1..-1]).run(ARGV.first)
end
