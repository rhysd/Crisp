require "./types"

module Crisp
  class Printer
    def initialize(@print_readably = true)
    end

    def print(value)
        case value
        when Nil          then "nil"
        when Bool         then value.to_s
        when Int32        then value.to_s
        when Crisp::List    then "(#{value.map{|v| pr_str(v, @print_readably) as String}.join(" ")})"
        when Crisp::Vector  then "[#{value.map{|v| pr_str(v, @print_readably) as String}.join(" ")}]"
        when Crisp::Symbol  then value.str.to_s
        when Crisp::Func    then "<function>"
        when Crisp::Closure then "<closure>"
        when Crisp::HashMap
        # step1_read_print.cr requires specifying type
        "{#{value.map{|k, v| "#{pr_str(k, @print_readably)} #{pr_str(v, @print_readably)}" as String}.join(" ")}}"
        when String
        case
        when value.empty?()
            @print_readably ? value.inspect : value
        when value[0] == '\u029e'
            ":#{value[1..-1]}"
        else
            @print_readably ? value.inspect : value
        end
        when Crisp::Atom
        "(atom #{pr_str(value.val, @print_readably)})"
        else
        raise "invalid CrispType: #{value.to_s}"
        end
    end

    def print(t : Crisp::Type)
        print(t.unwrap, @print_readably) + (t.macro? ? " (macro)" : "")
    end
  end
end
