class MalTestRunner
  def initialize(@test_file : String)
  end

  macro check_EOF
    return if l.is_a? Iterator::Stop
  end

  def each_test
    lines = File.open(@test_file).each_line

    until (l = lines.next).is_a? Iterator::Stop
      while l =~ /^\s*(;|$)/
        l = lines.next
        check_EOF
      end

      check_EOF
      input = l

      output = [] of String
      loop do
        l = lines.next
        check_EOF

        if l =~ /^; /
          output << l[2..-1]
        else
          break
        end
      end

      if l =~ /^;=>/
        yield input, output, l[3..-1]
      else
        yield input, output, nil
      end
    end
  end
end
