require "colorize"
require "readline"

require "./reader"
require "./printer"
require "./types"
require "./env"
require "./core"
require "./error"
require "./evaluator"

module Crisp

  class Interpreter
    def initialize(args = nil)
      @printer = Printer.new
      @evaluator = Evaluator.new
      @env = Crisp::Env.new

      Crisp::NameSpace.each{|k,v| @env.set(k, Crisp::Expr.new(v))}
      @env.set("eval", Crisp::Expr.new -> (args: Array(Crisp::Expr)){ @evaluator.eval(args[0], @env) })

      eval_string "(def! not (fn* (a) (if a false true)))"
      eval_string "(def! load-file (fn* (f) (eval (read-string (str \"(do \" (slurp f) \")\")))))"
      eval_string "(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list 'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw \"odd number of forms to cond\")) (cons 'cond (rest (rest xs)))))))"
      eval_string "(defmacro! or (fn* (& xs) (if (empty? xs) nil (if (= 1 (count xs)) (first xs) `(let* (or_FIXME ~(first xs)) (if or_FIXME or_FIXME (or ~@(rest xs))))))))"
      eval_string "(def! *host-language* \"crystal\")"

      argv = Crisp::List.new

      if args
        args.each do |a|
          argv << Crisp::Expr.new a
        end
      end

      @env.set("*ARGV*", Crisp::Expr.new argv)
    end

    def read(str)
      Crisp.read_str str
    end

    def print(result)
      @printer.print(result)
    end

    def eval_string(str)
      @evaluator.eval(read(str), @env)
    end

    def eval(t : Crisp::Expr)
      @evaluator.eval(t, @env)
    end

    def eval(val)
      @evaluator.eval(Crisp::Expr.new val, @env)
    end

    def run(filename = nil)
      if filename
        eval_string "(load-file \"#{filename}\")"
        return
      end

      while line = Readline.readline("Crisp> ", true)
        begin
          puts self.print(eval_string(line))
        rescue e
          puts e.message
        end
      end
    end
  end
end

