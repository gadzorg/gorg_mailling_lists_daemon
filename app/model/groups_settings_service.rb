#!/usr/bin/env ruby
# encoding: utf-8

require 'google/apis/groupssettings_v1'

class GroupsSettingsService < Google::Apis::GroupssettingsV1::GroupssettingsService

  def initialize
    super
    self.client_options.application_name = Application.config["application_name"]
    authorizer = ServiceAccountAuthorizer
    self.authorization = authorizer.authorize

    self
  end
end