#!/usr/bin/env ruby
# encoding: utf-8
require "json-schema"

class DeleteMaillingListMessageHandler < BaseMessageHandler
  # Respond to routing key: request.maillinglist.delete

  def validate_payload
    key=msg.data[:mailling_list_key]
    if key&&key!=""
      GorgMaillingListsDaemon.logger.error "Data validation error : #{key} key not found"
      raise_hardfail("Data validation error", error: "#{key} key not found")
    end
    GorgMaillingListsDaemon.logger.debug "Message data validated"
  end

  def process
    gg=GGroup.find(msg.data[:mailling_list_key])
    if gg
      gg.delete
      GorgMaillingListsDaemon.logger.info("Successfully deleted maillinglist #{gg.email}")
    else
      GorgMaillingListsDaemon.logger.error "Mailling list not found"
      raise_hardfail("Mailling list not found", error: "key : #{msg.data[:mailling_list_key]}")
    end
  end
end
