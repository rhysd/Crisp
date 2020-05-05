require "time"
require "readline"

require "./expr"
require "./error"
require "./printer"
require "./reader"

module Crisp
  extend self

  macro calc_op(op)
    -> (args : Array(Crisp::Expr)) {
      x, y = args[0].unwrap, args[1].unwrap
      Crisp.eval_error "invalid arguments for binary operator {{op.id}}" unless x.is_a?(Int32) && y.is_a?(Int32)
      Crisp::Expr.new(x {{op.id}} y)
    }
  end

  def list(args)
    args.to_crisp_value
  end

  def list?(args)
    args.first.unwrap.is_a? Crisp::List
  end

  def empty?(args)
    a = args.first.unwrap
    a.is_a?(Array) ? a.empty? : false
  end

  def count(args)
    a = args.first.unwrap
    case a
    when Array
      a.size.as Int32
    when Nil
      0
    else
      Crisp.eval_error "invalid argument for function 'count'"
    end
  end

  def pr_str(args)
    args.map { |a| Printer.new.print(a) }.join(" ")
  end

  def str(args)
    args.map { |a| Printer.new(false).print(a) }.join
  end

  def prn(args)
    puts self.pr_str(args)
    nil
  end

  def println(args)
    puts args.map { |a| Printer.new(false).print(a) }.join(" ")
    nil
  end

  def read_string(args)
    head = args.first.unwrap
    Crisp.eval_error "argument of read-str must be string" unless head.is_a? String
    read_str head
  end

  def slurp(args)
    head = args.first.unwrap
    Crisp.eval_error "argument of slurp must be string" unless head.is_a? String
    begin
      File.read head
    rescue e : File::NotFoundError
      Crisp.eval_error "no such file: #{head}"
    end
  end

  def cons(args)
    head, tail = args[0].as Crisp::Expr, args[1].unwrap
    Crisp.eval_error "2nd arg of cons must be list" unless tail.is_a? Array
    ([head] + tail).to_crisp_value
  end

  def concat(args)
    args.each_with_object(Crisp::List.new) do |arg, list|
      a = arg.unwrap
      Crisp.eval_error "arguments of concat must be list" unless a.is_a?(Array)
      a.each { |e| list << e }
    end
  end

  def nth(args)
    a0, a1 = args[0].unwrap, args[1].unwrap
    Crisp.eval_error "1st argument of nth must be list or vector" unless a0.is_a? Array
    Crisp.eval_error "2nd argument of nth must be integer" unless a1.is_a? Int32
    a0[a1]
  end

  def first(args)
    a0 = args[0].unwrap

    return nil if a0.nil?
    Crisp.eval_error "1st argument of first must be list or vector or nil" unless a0.is_a? Array
    a0.empty? ? nil : a0.first
  end

  def rest(args)
    a0 = args[0].unwrap

    return Crisp::List.new if a0.nil?
    Crisp.eval_error "1st argument of first must be list or vector or nil" unless a0.is_a? Array
    return Crisp::List.new if a0.empty?
    a0[1..-1].to_crisp_value
  end

  def apply(args)
    Crisp.eval_error "apply must take at least 2 arguments" unless args.size >= 2

    head = args.first.unwrap
    last = args.last.unwrap

    Crisp.eval_error "last argument of apply must be list or vector" unless last.is_a? Array

    case head
    when Crisp::Closure
      head.fn.call(args[1..-2] + last)
    when Crisp::Func
      head.call(args[1..-2] + last)
    else
      Crisp.eval_error "1st argument of apply must be function or closure"
    end
  end

  def map(args)
    func = args.first.unwrap
    list = args[1].unwrap

    Crisp.eval_error "2nd argument of map must be list or vector" unless list.is_a? Array

    f = case func
        when Crisp::Closure then func.fn
        when Crisp::Func    then func
        else                     Crisp.eval_error "1st argument of map must be function"
        end

    list.each_with_object(Crisp::List.new) do |elem, mapped|
      mapped << f.call([elem])
    end
  end

  def nil_value?(args)
    args.first.unwrap.nil?
  end

  def true?(args)
    a = args.first.unwrap
    a.is_a?(Bool) && a
  end

  def false?(args)
    a = args.first.unwrap
    a.is_a?(Bool) && !a
  end

  def symbol?(args)
    args.first.unwrap.is_a?(Crisp::Symbol)
  end

  def symbol(args)
    head = args.first.unwrap
    Crisp.eval_error "1st argument of symbol function must be string" unless head.is_a? String
    Crisp::Symbol.new head
  end

  def keyword(args)
    head = args.first.unwrap
    Crisp.eval_error "1st argument of symbol function must be string" unless head.is_a? String
    "\u029e" + head
  end

  def keyword?(args)
    head = args.first.unwrap
    head.is_a?(String) && !head.empty? && head[0] == '\u029e'
  end

  def vector(args)
    args.to_crisp_value(Crisp::Vector)
  end

  def vector?(args)
    args.first.unwrap.is_a? Crisp::Vector
  end

  def hash_map(args)
    Crisp.eval_error "hash-map must take even number of arguments" unless args.size.even?
    map = Crisp::HashMap.new
    args.each_slice(2) do |kv|
      k = kv[0].unwrap
      Crisp.eval_error "key must be string" unless k.is_a? String
      map[k] = kv[1]
    end
    map
  end

  def map?(args)
    args.first.unwrap.is_a? Crisp::HashMap
  end

  def assoc(args)
    head = args.first.unwrap
    Crisp.eval_error "1st argument of assoc must be hashmap" unless head.is_a? Crisp::HashMap
    Crisp.eval_error "assoc must take a list and even number of arguments" unless (args.size - 1).even?

    map = Crisp::HashMap.new
    head.each { |k, v| map[k] = v }

    args[1..-1].each_slice(2) do |kv|
      k = kv[0].unwrap
      Crisp.eval_error "key must be string" unless k.is_a? String
      map[k] = kv[1]
    end

    map
  end

  def dissoc(args)
    head = args.first.unwrap
    Crisp.eval_error "1st argument of assoc must be hashmap" unless head.is_a? Crisp::HashMap

    map = Crisp::HashMap.new
    head.each { |k, v| map[k] = v }

    args[1..-1].each do |arg|
      key = arg.unwrap
      Crisp.eval_error "key must be string" unless key.is_a? String
      map.delete key
    end

    map
  end

  def get(args)
    a0, a1 = args[0].unwrap, args[1].unwrap
    return nil unless a0.is_a? Crisp::HashMap
    Crisp.eval_error "2nd argument of get must be string" unless a1.is_a? String

    # a0[a1]? isn't available because type of a0[a1] is inferred NoReturn
    a0.has_key?(a1) ? a0[a1] : nil
  end

  def contains?(args)
    a0, a1 = args[0].unwrap, args[1].unwrap
    Crisp.eval_error "1st argument of get must be hashmap" unless a0.is_a? Crisp::HashMap
    Crisp.eval_error "2nd argument of get must be string" unless a1.is_a? String
    a0.has_key? a1
  end

  def keys(args)
    head = args.first.unwrap
    Crisp.eval_error "1st argument of assoc must be hashmap" unless head.is_a? Crisp::HashMap
    head.keys.each_with_object(Crisp::List.new) { |e, l| l << Crisp::Expr.new(e) }
  end

  def vals(args)
    head = args.first.unwrap
    Crisp.eval_error "1st argument of assoc must be hashmap" unless head.is_a? Crisp::HashMap
    head.values.to_crisp_value
  end

  def sequential?(args)
    args.first.unwrap.is_a? Array
  end

  def readline(args)
    head = args.first.unwrap
    Crisp.eval_error "1st argument of readline must be string" unless head.is_a? String
    Readline.readline head
  end

  def meta(args)
    m = args.first.meta
    m.nil? ? nil : m
  end

  def with_meta(args)
    t = args.first.dup
    t.meta = args[1]
    t
  end

  def atom(args)
    Crisp::Atom.new args.first
  end

  def atom?(args)
    args.first.unwrap.is_a? Crisp::Atom
  end

  def deref(args)
    head = args.first.unwrap
    Crisp.eval_error "1st argument of deref must be atom" unless head.is_a? Crisp::Atom
    head.val
  end

  def reset!(args)
    head = args.first.unwrap
    Crisp.eval_error "1st argument of reset! must be atom" unless head.is_a? Crisp::Atom
    head.val = args[1]
  end

  def swap!(args)
    atom = args.first.unwrap
    Crisp.eval_error "1st argument of swap! must be atom" unless atom.is_a? Crisp::Atom

    a = [atom.val] + args[2..-1]

    func = args[1].unwrap
    case func
    when Crisp::Func
      atom.val = func.call a
    when Crisp::Closure
      atom.val = func.fn.call a
    else
      Crisp.eval_error "2nd argumetn of swap! must be function"
    end
  end

  def conj(args)
    seq = args.first.unwrap
    case seq
    when Crisp::List
      (args[1..-1].reverse + seq).to_crisp_value
    when Crisp::Vector
      (seq + args[1..-1]).to_crisp_value(Crisp::Vector)
    else
      Crisp.eval_error "1st argument of conj must be list or vector"
    end
  end

  def time_ms(args)
    Time.utc.to_unix_ms.to_i32
  end

  # Note:
  # Simply using ->self.some_func doesn't work
  macro func(name)
    -> (args : Array(Crisp::Expr)) { Crisp::Expr.new self.{{name.id}}(args) }
  end

  macro rel_op(op)
  -> (args : Array(Crisp::Expr)) { Crisp::Expr.new (args[0] {{op.id}} args[1]) }
  end

  NameSpace = {
    "+"           => calc_op(:+),
    "-"           => calc_op(:-),
    "*"           => calc_op(:*),
    "/"           => calc_op(://),
    "list"        => func(:list),
    "list?"       => func(:list?),
    "empty?"      => func(:empty?),
    "count"       => func(:count),
    "="           => rel_op(:==),
    "<"           => rel_op(:<),
    ">"           => rel_op(:>),
    "<="          => rel_op(:<=),
    ">="          => rel_op(:>=),
    "pr-str"      => func(:pr_str),
    "str"         => func(:str),
    "prn"         => func(:prn),
    "println"     => func(:println),
    "read-string" => func(:read_string),
    "slurp"       => func(:slurp),
    "cons"        => func(:cons),
    "concat"      => func(:concat),
    "nth"         => func(:nth),
    "first"       => func(:first),
    "rest"        => func(:rest),
    "throw"       => ->(args : Array(Crisp::Expr)) { raise Crisp::RuntimeException.new args[0] },
    "apply"       => func(:apply),
    "map"         => func(:map),
    "nil?"        => func(:nil_value?),
    "true?"       => func(:true?),
    "false?"      => func(:false?),
    "symbol?"     => func(:symbol?),
    "symbol"      => func(:symbol),
    "keyword"     => func(:keyword),
    "keyword?"    => func(:keyword?),
    "vector"      => func(:vector),
    "vector?"     => func(:vector?),
    "hash-map"    => func(:hash_map),
    "map?"        => func(:map?),
    "assoc"       => func(:assoc),
    "dissoc"      => func(:dissoc),
    "get"         => func(:get),
    "contains?"   => func(:contains?),
    "keys"        => func(:keys),
    "vals"        => func(:vals),
    "sequential?" => func(:sequential?),
    "readline"    => func(:readline),
    "meta"        => func(:meta),
    "with-meta"   => func(:with_meta),
    "atom"        => func(:atom),
    "atom?"       => func(:atom?),
    "deref"       => func(:deref),
    "deref"       => func(:deref),
    "reset!"      => func(:reset!),
    "swap!"       => func(:swap!),
    "conj"        => func(:conj),
    "time-ms"     => func(:time_ms),
  } of String => Crisp::Func
end
