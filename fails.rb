require 'bundler/setup'
require 'redis'
require 'yaml'
require 'time'

r = Redis.new

keys = r.keys 'resque-failures:*:failures:*'
histogram = Hash.new { |h,k| h[k] = 0 }

def ts(timestamp)
  Time.parse(timestamp).strftime('%H:%M')
end

failures = keys.inject([]) do |failures,key|
  begin
    queue, klass, timestamp, exception, backtrace, worker, payload = *r.hvals(key)
    histogram[ts(timestamp)] = histogram[ts(timestamp)] + 1
    failures << {
      queue: queue,
      klass: klass,
      timestamp: timestamp,
      exception: exception,
      backtrace: backtrace,
      worker: worker,
      payload: payload
    }
  rescue
  end
end
puts histogram

h = histogram.sort_by { |k,v| k }
h.each do |time,count|
  puts "#{time}: #{count}"
end