#!/usr/bin/env ruby
# encoding: utf-8
require "json-schema"

class CreateMaillingListMessageHandler < BaseMessageHandler
  # Respond to routing key: request.maillinglist.create

  def validate_payload
    schema={
      "$schema"=>"http://json-schema.org/draft-04/schema#",
      "title"=> "Create Google Account message schema",
      "type"=>"object",
      "properties"=>{
        "gram_account_uuid"=>{
          "type"=>"string",
          "description"=>"The unique identifier of linked GrAM Account",
          "pattern"=>"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
        },
        "primary_email"=>{
          "type"=>"string",
          "description"=>"Primary email address used to create google account"
        },
        "aliases"=>{
          "type"=>"array",
          "description"=>"Google account email aliases",
          "items"=>{
            "type"=>"string"
            }
          }
      },
      "additionalProperties"=>true,
      "required"=>["gram_account_uuid", "primary_email"]
    }

    errors=JSON::Validator.fully_validate(schema, msg.data, :insert_defaults => true)
    if errors.any?
      GoogleDirectoryDaemon.logger.error "Data validation error : #{errors.inspect}"
      raise_hardfail("Data validation error", error: errors.inspect)
    end

    GoogleDirectoryDaemon.logger.debug "Message data validated"
  end

end