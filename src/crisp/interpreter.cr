require "colorize"
require "readline"

require "./reader"
require "./printer"
require "./types"
require "./env"
require "./core"
require "./error"

# Note:
# Employed downcase names because Crystal prohibits uppercase names for methods

module Crisp

  class Interpreter
    def initialize(args = nil)
      @env = Crisp::Env.new

      Crisp::NameSpace.each{|k,v| @curent_env.set(k, Crisp::Type.new(v))}
      @env.set("eval", Crisp::Type.new -> (args: Array(Crisp::Type)){ eval(args[0], @env) })

      eval_string "(def! not (fn* (a) (if a false true)))"
      eval_string "(def! load-file (fn* (f) (eval (read-string (str \"(do \" (slurp f) \")\")))))"
      eval_string "(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list 'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw \"odd number of forms to cond\")) (cons 'cond (rest (rest xs)))))))"
      eval_string "(defmacro! or (fn* (& xs) (if (empty? xs) nil (if (= 1 (count xs)) (first xs) `(let* (or_FIXME ~(first xs)) (if or_FIXME or_FIXME (or ~@(rest xs))))))))"
      eval_string "(def! *host-language* \"crystal\")"

      argv = Crisp::List.new

      if args
        args.each do |a|
          argv << Crisp::Type.new a
        end
      end

      @env.set("*ARGV*", Crisp::Type.new argv)

      @printer = Printer.new
    end

    def func_of(env, binds, body)
      -> (args : Array(Crisp::Type)) {
      new_env = Crisp::Env.new(env, binds, args)
      eval(body, new_env)
      } as Crisp::Func
    end

    def eval_ast(ast, env)
      return ast.map{|n| eval(n, env) as Crisp::Type} if ast.is_a? Array

      val = ast.unwrap

      Crisp::Type.new case val
      when Crisp::Symbol
        if e = env.get(val.str)
            e
        else
            Crisp.eval_error "'#{val.str}' not found"
        end
      when Crisp::List
        val.each_with_object(Crisp::List.new){|n, l| l << eval(n, env)}
      when Crisp::Vector
        val.each_with_object(Crisp::Vector.new){|n, l| l << eval(n, env)}
      when Crisp::HashMap
        new_map = Crisp::HashMap.new
        val.each{|k, v| new_map[k] = eval(v, env)}
        new_map
      else
        val
      end
    end

    def read(str)
      read_str str
    end

    macro pair?(list)
      {{list}}.is_a?(Array) && !{{list}}.empty?
    end

    def quasiquote(ast)
      list = ast.unwrap

      unless pair?(list)
      return Crisp::Type.new(
        Crisp::List.new << gen_type(Crisp::Symbol, "quote") << ast
      )
      end

      head = list.first.unwrap

      case
      # ("unquote" ...)
      when head.is_a?(Crisp::Symbol) && head.str == "unquote"
        list[1]
      # (("splice-unquote" ...) ...)
      when pair?(head) && (arg0 = head.first.unwrap).is_a?(Crisp::Symbol) && arg0.str == "splice-unquote"
        tail = Crisp::Type.new list[1..-1].to_crisp_value
        Crisp::Type.new(
          Crisp::List.new << gen_type(Crisp::Symbol, "concat") << head[1] << quasiquote(tail)
        )
      else
        tail = Crisp::Type.new list[1..-1].to_crisp_value
        Crisp::Type.new(
          Crisp::List.new << gen_type(Crisp::Symbol, "cons") << quasiquote(list.first) << quasiquote(tail)
        )
      end
    end

    def macro_call?(ast, env)
      list = ast.unwrap
      return false unless list.is_a? Crisp::List
      return false if list.empty?

      sym = list.first.unwrap
      return false unless sym.is_a? Crisp::Symbol

      func = env.find(sym.str).try(&.data[sym.str])
      return false unless func && func.macro?

      true
    end

    def macroexpand(ast, env)
      while macro_call?(ast, env)

        # Already checked in macro_call?
        list = ast.unwrap as Crisp::List
        func_sym = list[0].unwrap as Crisp::Symbol
        func = env.get(func_sym.str).unwrap

        case func
        when Crisp::Func
          ast = func.call(list[1..-1])
        when Crisp::Closure
          ast = func.fn.call(list[1..-1])
        else
          Crisp.eval_error "macro '#{func_sym.str}' must be function: #{ast}"
        end
      end

      ast
    end

    macro invoke_list(l, env)
      f = eval({{l}}.first, {{env}}).unwrap
      args = eval_ast({{l}}[1..-1], {{env}}) as Array

      case f
      when Crisp::Closure
        ast = f.ast
        {{env}} = Crisp::Env.new(f.env, f.params, args)
        next # TCO
      when Crisp::Func
        return f.call args
      else
        Crisp.eval_error "expected function as the first argument: #{f}"
      end
    end

    def debug(ast)
      puts print(ast).colorize.red
    end

    def eval(ast, env)
      # 'next' in 'do...end' has a bug in crystal 0.7.1
      # https://github.com/manastech/crystal/issues/659
      while true
        return eval_ast(ast, env) unless ast.unwrap.is_a? Crisp::List

        ast = macroexpand(ast, env)

        list = ast.unwrap

        return ast unless list.is_a? Crisp::List
        return ast if list.empty?

        head = list.first.unwrap

        return invoke_list(list, env) unless head.is_a? Crisp::Symbol

        return Crisp::Type.new case head.str
          when "def!"
            Crisp.eval_error "wrong number of argument for 'def!'" unless list.size == 3
            a1 = list[1].unwrap
            Crisp.eval_error "1st argument of 'def!' must be symbol: #{a1}" unless a1.is_a? Crisp::Symbol
            env.set(a1.str, eval(list[2], env))
          when "let*"
            Crisp.eval_error "wrong number of argument for 'def!'" unless list.size == 3

            bindings = list[1].unwrap
            Crisp.eval_error "1st argument of 'let*' must be list or vector" unless bindings.is_a? Array
            Crisp.eval_error "size of binding list must be even" unless bindings.size.even?

            new_env = Crisp::Env.new env
            bindings.each_slice(2) do |binding|
              key, value = binding
              name = key.unwrap
              Crisp.eval_error "name of binding must be specified as symbol #{name}" unless name.is_a? Crisp::Symbol
              new_env.set(name.str, eval(value, new_env))
            end

            ast, env = list[2], new_env
            next # TCO
          when "do"
            if list.empty?
              ast = Crisp::Type.new nil
              next
            end

            eval_ast(list[1..-2].to_crisp_value, env)
            ast = list.last
            next # TCO
          when "if"
            ast = unless eval(list[1], env).unwrap
              list.size >= 4 ? list[3] : Crisp::Type.new(nil)
            else
              list[2]
            end
            next # TCO
          when "fn*"
            params = list[1].unwrap
            unless params.is_a? Array
              Crisp.eval_error "'fn*' parameters must be list or vector: #{params}"
            end
            Crisp::Closure.new(list[2], params, env, func_of(env, params, list[2]))
          when "quote"
            list[1]
          when "quasiquote"
            ast = quasiquote list[1]
            next # TCO
          when "defmacro!"
            Crisp.eval_error "wrong number of argument for 'defmacro!'" unless list.size == 3
            a1 = list[1].unwrap
            Crisp.eval_error "1st argument of 'defmacro!' must be symbol: #{a1}" unless a1.is_a? Crisp::Symbol
            env.set(a1.str, eval(list[2], env).tap{|n| n.is_macro = true})
          when "macroexpand"
            macroexpand(list[1], env)
          when "try*"
            catch_list = list[2].unwrap
            return eval(list[1], env) unless catch_list.is_a? Crisp::List

            catch_head = catch_list.first.unwrap
            return eval(list[1], env) unless catch_head.is_a? Crisp::Symbol
            return eval(list[1], env) unless catch_head.str == "catch*"

            begin
              eval(list[1], env)
            rescue e : Crisp::RuntimeException
              new_env = Crisp::Env.new(env, [catch_list[1]], [e.thrown])
              eval(catch_list[2], new_env)
            rescue e
              new_env = Crisp::Env.new(env, [catch_list[1]], [Crisp::Type.new e.message])
              eval(catch_list[2], new_env)
            end
          else
            invoke_list(list, env)
          end
      end
    end

    def print(result)
      @printer.print(result)
    end

    def eval_string(str)
      print(eval(read(str), @env))
    end

    def run(filename = nil)
      if filename
        eval_string "(load-file \"#{filename}\")"
        return
      end

      while line = Readline.readline("Crisp> ", true)
        begin
          puts eval_string(line)
        rescue e
          STDERR.puts e
        end
      end
    end
  end
end

