module FoodsoftDateUtil
  # find next occurence given a recurring ical string and time
  def self.next_occurrence(start=Time.now, from=start, options={})
    occ = nil
    if options && options[:recurr]
      schedule = IceCube::Schedule.new(start)
      schedule.add_recurrence_rule rule_from(options[:recurr])
      # @todo handle ical parse errors
      occ = (schedule.next_occurrence(from).to_time rescue nil)
    else
      occ = start
    end
    if options && options[:time] && occ
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

  # return time from today in words, supporting multiple dates
  def self.distance_of_time_in_words(from_times, to_time=Time.now, options={})
    from_times = [from_times] unless from_times.is_a? Array
    from_times = from_times.minmax.map do |time|
      if time == to_time
        I18n.t('lib.date_util.time_now')
      elsif time > to_time
        I18n.t('lib.date_util.time_until', delta: DateHelper.new.distance_of_time_in_words(time, to_time, options))
      else
        I18n.t('lib.date_util.time_ago', delta: DateHelper.new.distance_of_time_in_words(time, to_time, options))
      end
    end
    # if equal, return just one
    return from_times[0] if from_times[0] == from_times[1]
    # TODO return common prefix&suffix, e.g. "about 2 minutes ago to about 3 minutes ago" -> "about 2 to 3 minutes ago"
    return I18n.t('lib.date_util.times_join', from: from_times[0], to: from_times[1])
  end

  private

  # to be able to call distance_of_time_in_words
  class DateHelper
    include ActionView::Helpers::DateHelper
  end

end
