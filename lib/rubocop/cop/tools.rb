$sug_c = 0

module RuboCopTools
  def r_corrected_lines(corrector)
    corrector.rewrite.lines
  end

  def r_original_lines
    processed_source.lines
  end

  def r_diff_lines(corrector)
    r_corrected_lines(corrector).each_with_index.filter { |line, index| line != r_original_lines[index] }
  end

  def r_differing_lines_count(corrector)
    r_diff_lines(corrector).count
  end

  def correct(*args, **params)
    result = super(*args, **params)
    return result if $sug_c > 20
    begin
      range = args.first
      @current_offenses = @current_offenses.map do |offense|
        break if $sug_c > 20
        corrector = offense.corrector

        if corrector && r_differing_lines_count(corrector) == 1 && !offense.message['SUG']
          cor = r_diff_lines(corrector).first.first
          if cor
            offense = offense.dup
            offense.instance_exec { @message = @message + "SUG #\{cor\}" }
            $sug_c  += 1
            offense.freeze
          end
        end

        offense
      end
    rescue => e
      STDOUT.puts "auto-correction failed"
    end

    result
  end
end

if defined?(RuboCop::Cop::Base)
  ObjectSpace
  .each_object(Class)
  .select { |klass| klass < RuboCop::Cop::Base }
  .each do |klass|
    klass.prepend(RuboCopTools)
  end
end