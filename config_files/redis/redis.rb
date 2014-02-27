$redis = Redis.new(:host => 'localhost', :port => 6379)

begin
  $redis.info
rescue
  $redis = nil
end