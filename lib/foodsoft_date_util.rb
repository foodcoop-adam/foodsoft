module FoodsoftDateUtil
  # find next occurence given a recurring ical string and time
  def self.next_occurrence(start=Time.now, from=start, options={})
    if options[:recurr]
      schedule = IceCube::Schedule.new(start)
      schedule.add_recurrence_rule get_rule(options[:recurr])
      # TODO handle ical parse errors
      occ = (Time.parse(schedule.next_occurrence(from)) rescue nil)
    else
      occ = start
    end
    if occ and options[:time]
      occ = occ.beginning_of_day.advance(seconds: Time.parse(options[:time]).seconds_since_midnight)
    end
    occ
  end

  # @param p [String, Symbol, Hash, IceCube::Rule] What to return a rule from.
  # @return [IceCube::Rule] Recurring rule
  def self.rule_from(p)
    if p.is_a? String
      IceCube::Rule.from_ical(p)
    elsif p.is_a? Hash
      IceCube::Rule.from_hash(p)
    else
      p
    end
  end
end
