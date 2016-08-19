#!/usr/bin/env ruby
# encoding: utf-8

require 'google/apis/groupssettings_v1'

class GroupsSettingsService < Google::Apis::GroupssettingsV1::GroupssettingsService

  def initialize
    super
    self.client_options.application_name = GorgMaillingListsDaemon.config["application_name"]
    authorizer = DefaultAuthorizer
    self.authorization = authorizer.authorize

    self
  end
end