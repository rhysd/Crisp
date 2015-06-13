require "./expr"

module Crisp
  class Printer
    def initialize(@print_readably = true)
    end

    def print(value)
      case value
      when Nil          then "nil"
      when Bool         then value.to_s
      when Int32        then value.to_s
      when Crisp::List    then "(#{value.map{|v| print(v) as String}.join(" ")})"
      when Crisp::Vector  then "[#{value.map{|v| print(v) as String}.join(" ")}]"
      when Crisp::Symbol  then value.str.to_s
      when Crisp::Func    then "<function>"
      when Crisp::Closure then "<closure>"
      when Crisp::HashMap
        "{#{value.map{|k, v| "#{print(k)} #{print(v)}"}.join(" ")}}"
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
        "(atom #{print(value.val)})"
      else
        raise "invalid CrispExpr: #{value.to_s}"
      end
    end

    def print(e : Crisp::Expr)
      print(e.unwrap) + (e.macro? ? " (macro)" : "")
    end
  end
end
