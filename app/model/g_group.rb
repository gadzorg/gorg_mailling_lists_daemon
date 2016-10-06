#!/usr/bin/env ruby
# encoding: utf-8

require 'google/apis/admin_directory_v1'
GGroup=Google::Apis::AdminDirectoryV1::Group
class GGroup
  #
  # Add methods to Google::Apis::AdminDirectoryV1::User to have a pseudo
  # ActiveModel behaviour
  #

  # @return [Boolean]
  #  Used to cache existence of this user in Google Apps Directory
  attr_accessor :persisted


  # Save user data in Google Apps Directory either by patching existing
  # account or creating a new one
  #
  # @return [Google::Apis::AdminDirectoryV1::User]
  #  Google::Apis::AdminDirectoryV1::User updated with Google Directory data
  def save
    if persisted?
      self.update_from_group_obj!(self.class.service.patch_group(self.id, self))
      rate_limiter_service.incr
    else
      self.update_from_group_obj!(self.class.service.insert_group(self))
      rate_limiter_service.incr
    end
    self
  end


  # Delete User from Google Apps Directory
  #
  # @return [Nil]
  def delete
    response=self.class.service.delete_group self.id
    rate_limiter_service.incr
    self.persisted=false
    response
  end

  # Test if user already exist in Google Apps Directory
  # Use cache if available
  #
  # @param [Boolean] force
  #  Force API querying and reset persistance caching
  #
  # @return [Boolean]
  def persisted? force: false
    if self.id&& !force
      return true
    else
      self.persisted = false
      if gg=self.class.find(self.id||self.email)
        rate_limiter_service.incr
        self.id=gg.id
        self.persisted = true
        return true
      else
        return false
      end
    end
  end


  # Refresh current User with Google Directory data
  # Return nil if not persisted yet
  def refresh
    if persisted?
      self.update_from_group_obj!(self.class.find self.id)
      rate_limiter_service.incr
    end
  end

  def members
    if persisted?
      self.class.service.list_members self.id
      rate_limiter_service.incr
    end
  end

  def delete_member email
    self.class.service.delete_member self.id, email
    rate_limiter_service.incr
  end

  def add_member email, role: "MEMBER"
    member=Google::Apis::AdminDirectoryV1::Member.new(email: email, role: role)
    self.class.service.insert_member self.id, member
    rate_limiter_service.incr
  end

  # Lookup requested email in Google Directory
  # @return [Google::Apis::AdminDirectoryV1::User]
  #  or nil if not found
  def self.find group_key
    begin
      user=service.get_group group_key
      rate_limiter_service.incr
      user.persisted=true
      user
    rescue Google::Apis::ClientError => e
      if JSON.parse(e.body)['error']['code'] == 404
        return nil
      else
        raise e
      end
    end
  end

  # @return [DirectoryService]
  #  Service used to perform API calls
  def self.service
    @service||=DirectoryService.new
  end

  # Copy provided user data in current user data
  def update_from_group_obj! g_obj
    self.update!(g_obj.to_h)
  end


  private

  def rate_limiter_service
    self.class.rate_limiter_service
  end

  def self.rate_limiter_service
    RateLimiterService.new
  end



end