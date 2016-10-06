#!/usr/bin/env ruby
# encoding: utf-8
require "json-schema"

class UpdateMaillingListMessageHandler < BaseMessageHandler
  # Respond to routing key: request.maillinglist.create

  def validate_payload   
    unless mailling_list.valid?
      GorgMaillingListsDaemon.logger.error "Data validation error : #{mailling_list.errors.inspect}"
      raise_hardfail("Data validation error", error: mailling_list.errors.inspect)
    end
    GorgMaillingListsDaemon.logger.debug "Message data validated"
  end

  def process
   update_group
   update_group_settings
   update_group_aliases if mailling_list.aliases
   update_group_members if mailling_list.members
  end

  def update_group
    @gg=mailling_list.google_group
    @gg.save
  end

  def update_group_settings
    ggsservice=GroupsSettingsService.new
    ggs=mailling_list.google_group_settings

    begin
      ggs=ggsservice.update_group mailling_list.primary_email, ggs
      GorgMaillingListsDaemon.logger.info "Google Group #{mailling_list.primary_email} configuration successfully updated"
    rescue Google::Apis::ClientError => e
      case e.message
      when ""
      else
        raise
      end
    end
  end

  def update_group_members

    

    current=@gg.members.members
    current_mails=current ? current.map{|m| m.email} : []
    target_mails=mailling_list.members

    to_create= target_mails - current_mails 
    to_delete= current_mails - target_mails
    GorgMaillingListsDaemon.logger.debug "Members to add  : #{to_create}"
    GorgMaillingListsDaemon.logger.debug "Members to del  : #{to_delete}"

    #Slice actions in batch of 1000 (max acceptable value for Google APIs)
    actions=[]
    actions+= to_delete.map{|email| {action: :delete, value: email}}
    actions+= to_create.map{|email| {action: :create, value: email}}

    rl=RateLimiterService.new
    while actions.any?
      GorgMaillingListsDaemon.logger.debug "Il reste #{actions.count} actions a effectuer"
      rl.wait
      count=[rl.allowed_count,75].min
      b=actions.shift(count)
      GorgMaillingListsDaemon.logger.debug "Batch size : #{b.count}"

      GGroup.service.batch do
        b.each do |a|
          case a[:action]
          when :create
            @gg.add_member a[:value]
          when :delete
            @gg.delete_member a[:value]
          end
        end
      end
    end

    GorgMaillingListsDaemon.logger.info "Successfully update members of #{mailling_list.primary_email} : add #{to_create.count}, del #{to_delete.count}"
  end

  def update_group_aliases
    GorgMaillingListsDaemon.logger.warn "update_group_aliases not implemented"
  end

  def mailling_list
    @mailling_list||=MaillingList.new(msg.data)
  end

end
