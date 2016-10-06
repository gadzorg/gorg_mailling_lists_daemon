class RateLimiterService

  def initialize(key=GorgMaillingListsDaemon.config['admin_user_id'],time_window=GorgMaillingListsDaemon.config['google_api_rate_time_window'].to_i,max=GorgMaillingListsDaemon.config['google_api_rate_limit'].to_i)
    @time_window=time_window.to_i
    @max=max.to_i
    @key="#{key}_#{@time_window}_#{@max}"
    @r=Redis.new(url:GorgMaillingListsDaemon.config['redis_url'])
  end

  def wait
    unless allowed_count
      time=time_to_wait
      GorgMaillingListsDaemon.logger.debug "Quota exceeded, waiting for #{time} seconds..."
      sleep(time) 
    end
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
    ret=@r.incrby(@key, n).to_i
    @r.expire(@key, @time_window) if @r.ttl(@key).to_i < 0
    ret
  end

end