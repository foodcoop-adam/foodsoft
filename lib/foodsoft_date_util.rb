module FoodsoftDateUtil
  # find next occurence given a recurring ical string and time
  def self.next_occurrence(start=Time.now, from=start, options={})
    if options[:recurr]
      schedule = IceCube::Schedule.new(start)
      schedule.add_recurrence_rule IceCube::Rule.from_ical(options[:recurr])
      # TODO handle ical parse errors
      occ = (schedule.next_occurrence(from).to_time rescue nil)
    else
      occ = start
    end
    if occ and options[:time]
      occ = occ.beginning_of_day.advance(seconds: options[:time].to_time.seconds_since_midnight)
    end
    occ
  end
end
