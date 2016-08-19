require 'gram_v2_client'

GramV2Client.configure do |c|
  c.site=GorgMaillingListsDaemon.config["gram_api_host"]
  c.user=GorgMaillingListsDaemon.config["gram_api_user"]
  c.password=GorgMaillingListsDaemon.config["gram_api_password"]
end