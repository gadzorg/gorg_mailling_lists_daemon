#!/usr/bin/env ruby
# encoding: utf-8
require "json-schema"

class DeleteMailingListMessageHandler < GorgService::Consumer::MessageHandler::RequestHandler

  listen_to 'request.mailinglist.delete'

  SCHEMA={
      "$schema"=>"http://json-schema.org/draft-04/schema#",
      "title"=> "DeleteMailingList",
      "type"=>"object",
      "properties"=>{
          "mailling_list_key"=>{
              "type"=>"string",
              "description"=>"Primary email address used to create google account"
          }
      },
      "additionalProperties"=>true,
      "required"=>["mailling_list_key"]
  }

  def validate
    message.validate_data_with(SCHEMA)
    Application.logger.debug "Message data validated"
  end

  def process
    gg=GGroup.find(message.data[:mailling_list_key])
    if gg
      gg.delete
      Application.logger.info("Successfully deleted maillinglist #{gg.email}")
    else
      Application.logger.error "Mailling list not found"
      raise_hardfail("Mailling list not found", error: "key : #{message.data[:mailling_list_key]}")
    end
  end
end
