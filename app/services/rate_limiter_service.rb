class RateLimiterService

  def initialize(key=GorgMaillingListsDaemon.config['admin_user_id'],time_window=GorgMaillingListsDaemon.config['google_api_rate_time_window'].to_i,max=GorgMaillingListsDaemon.config['google_api_rate_limit'].to_i)
    @time_window=time_window
    @max=max
    @key="#{key}_#{@time_window}_#{@max}"
    @r=Redis.new(url:GorgMaillingListsDaemon.config['redis_url'])
  end

  def wait
    sleep(time_to_wait) unless allowed_count
  end

  def time_to_wait
    [@r.ttl(@key).to_i,0].max
  end

  def allowed_count
    allowed=@max-current_count
    return allowed > 0 ? allowed : nil
  end

  def current_count
    @r.get(@key).to_i
  end

  def incr(n=1)
    ret=@r.incrby(@key, n)
    @r.expire(@key, @time_window) if @r.ttl(@key).to_i < 0
    ret
  end

end