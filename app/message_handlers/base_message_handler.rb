#!/usr/bin/env ruby
# encoding: utf-8


##Abstract class for payload validation and handling connectivity process
# Children classes should implement :
#  - process() : process the message stored in msg
#  - validate_payload() : method used to validate message's payload format
#                         Returns a boolean (true = valid, false = invalid)
#                         If not implemented, returns true

class GorgService::Consumer::MessageHandler::Base

    handle_error Faraday::ConnectionFailed do |error,message|
        Application.logger.error("Unable to connect to Google API")
        raise_softfail("GoogleAPIConnectionError", error: error, message: message)
    end

    handle_error Google::Apis::ClientError do |error, message|
      if error.message.start_with? "dailyLimitExceeded"
        GoogleDirectoryDaemon.logger.error e.message
        raise_softfail("Google API Quota exceeded", error: e.message, message: message)
      elsif error.message.start_with? "quotaExceeded"
        Application.logger.error e.message
        raise_softfail("Google API 100 seconds Quota exceeded", error: error.message, message: message)
      else
        Application.logger.error("Unknown Google API Client Error")
        raise_hardfail("UnknownGoogleAPIClientError", error: error, message: message)
      end
    end
end