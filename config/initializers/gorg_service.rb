#!/usr/bin/env ruby
# encoding: utf-8

require 'gorg_service'

# For default values see : https://github.com/Zooip/gorg_service
GorgService.configure do |c|
  # application name for display usage
  c.application_name= GorgMaillingListsDaemon.config["application_name"]
  # application id used to find message from this producer
  c.application_id=GorgMaillingListsDaemon.config["application_id"]

  ## RabbitMQ configuration
  # 
  ### Authentification
  # If your RabbitMQ server is password protected put it here
  #
  c.rabbitmq_user=GorgMaillingListsDaemon.config['rabbitmq_user']
  c.rabbitmq_password=GorgMaillingListsDaemon.config['rabbitmq_password']
  #  
  ### Network configuration :
  #
  c.rabbitmq_host=GorgMaillingListsDaemon.config['rabbitmq_host']
  c.rabbitmq_port=GorgMaillingListsDaemon.config['rabbitmq_port']
  c.rabbitmq_vhost=GorgMaillingListsDaemon.config['rabbitmq_vhost']

  c.rabbitmq_queue_name=GorgMaillingListsDaemon.config['rabbitmq_queue_name']
  #
  #
  # c.rabbitmq_queue_name = c.application_name
  c.rabbitmq_exchange_name=GorgMaillingListsDaemon.config['rabbitmq_exchange_name']
  #
  # time before trying again on softfail in milliseconds (temporary error)
  c.rabbitmq_deferred_time=GorgMaillingListsDaemon.config['rabbitmq_deferred_time']
  # 
  # maximum number of try before discard a message
  c.rabbitmq_max_attempts=GorgMaillingListsDaemon.config['rabbitmq_max_attempts']
  #
  # The routing key used when sending a message to the central log system (Hardfail or Warning)
  # Central logging is disable if nil
  c.log_routing_key=GorgMaillingListsDaemon.config['log_routing_key']
  #
  # Routing hash
  #  map routing_key of received message with MessageHandler 
  #  exemple:
  # c.message_handler_map={
  #   "some.routing.key" => MyMessageHandler,
  #   "Another.routing.key" => OtherMessageHandler,
  #   "third.routing.key" => MyMessageHandler,
  # }

  c.logger=GorgMaillingListsDaemon.logger

  c.message_handler_map={
    'request.maillinglist.update' => UpdateMaillingListMessageHandler,
    'request.maillinglist.delete' => DeleteMaillingListMessageHandler,
  }
end

sender=GorgMessageSender.new(host: "rabbitmq.gorgu.net", port: 5672, user: "rat-ldapd", pass: "ldapdPasswd", exchange_name: "agoram_event_exchange", vhost: "dev-rat", app_id: "bar", durable_exchange: true)