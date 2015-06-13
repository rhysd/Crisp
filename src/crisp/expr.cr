require "./printer"

module Crisp
  extend self

  class Symbol
    property :str
    def initialize(@str)
    end

    def ==(other : Symbol)
      @str == other.str
    end
  end

  class List < Array(Expr)
  end

  class Vector < Array(Expr)
  end

  class HashMap < Hash(String, Expr)
  end

  class Atom
    property :val
    def initialize(@val)
    end

    def ==(rhs : Atom)
      @val == rhs.val
    end
  end

  class Closure
    property :ast, :params, :env, :fn
    def initialize(@ast, @params, @env, @fn)
    end
  end

  class Expr
    alias Func = (Array(Expr) -> Expr)
    alias Type = Nil | Bool | Int32 | String | Symbol | List | Vector | HashMap | Func | Closure | Atom

    is_macro :: Bool
    meta :: Expr

    property :is_macro, :meta

    def initialize(@val : Type)
      @is_macro = false
      @meta = nil
    end

    def initialize(other : Expr)
      @val = other.unwrap
      @is_macro = other.is_macro
      @meta = other.meta
    end

    def unwrap
      @val
    end

    def macro?
      @is_macro
    end

    def to_s
      Printer.new.print(self)
    end

    def dup
      Expr.new(@val).tap do |t|
        t.is_macro = @is_macro
        t.meta = @meta
      end
    end

    def ==(other : Expr)
      @val == other.unwrap
    end

    macro rel_op(*ops)
      {% for op in ops %}
        def {{op.id}}(other : Crisp::Expr)
          l, r = @val, other.unwrap
            {% for t in [Int32, String] %}
              if l.is_a?({{t}}) && r.is_a?({{t}})
                return (l) {{op.id}} (r)
              end
            {% end %}
            if l.is_a?(Symbol) && r.is_a?(Symbol)
              return l.str {{op.id}} r.str
            end
          false
        end
      {% end %}
    end

    rel_op :<, :>, :<=, :>=
  end

  alias Func = Expr::Func
end

macro gen_type(t, *args)
  Crisp::Expr.new {{t.id}}.new({{*args}})
end

class Array
  def to_crisp_value(t = Crisp::List)
    each_with_object(t.new){|e, l| l << e}
  end
end

