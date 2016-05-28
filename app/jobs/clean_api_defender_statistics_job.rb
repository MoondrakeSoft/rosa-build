class CleanApiDefenderStatisticsJob
  include Sidekiq::Worker

  def perform
    deadline = Date.today - 1.month
    Redis.current.keys.select do |key|
      next if key !~ /^throttle:/
      # See: https://github.com/datagraph/rack-throttle/blob/master/lib/rack/throttle/daily.rb#L41
      # Formats:
      # 'throttle:uname:%Y-%m-%dT%H', 'throttle:uname:%Y-%m-%d'
      # example: "throttle:uname1:2014-01-25T20", "throttle:uname1:2014-01-25"
      date = key.gsub(/.*:/, '').gsub(/T.*/, '')
      Redis.current.del(key) if Date.parse(date) < deadline
    end
  end

end
