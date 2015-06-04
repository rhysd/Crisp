require "./crisp"

if ARGV.empty?
  Crisp::Interpreter.new.run
else
  Crisp::Interpreter.new(ARGV[1..-1]).run(ARGV.first)
end
