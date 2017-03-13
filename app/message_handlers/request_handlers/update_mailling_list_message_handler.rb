#!/usr/bin/env ruby
# encoding: utf-8
require "json-schema"

class UpdateMaillingListMessageHandler < GorgService::Consumer::MessageHandler::RequestHandler
  # Respond to routing key: request.maillinglist.create

  listen_to 'request.mailinglist.update'

  def validate
    mailling_list.validate!
  end

  def process
   GGroup.reload_service
   update_group
   update_group_settings
   update_group_aliases if mailling_list.aliases
   update_group_members if mailling_list.members.any?
   update_group_roles if (mailling_list.owners+mailling_list.managers).any?
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
      Application.logger.info "Google Group #{mailling_list.primary_email} configuration successfully updated"
    rescue Google::Apis::ClientError => e
      case e.message
      when ""
      else
        raise
      end
    end
  end

  def update_group_members
    current=@gg.members
    current_mails=current ? current.map{|m| m.email} : []
    target_mails=mailling_list.members

    to_create= target_mails - current_mails 
    to_delete= current_mails - target_mails
    Application.logger.debug "Members to add  : #{to_create}"
    Application.logger.debug "Members to del  : #{to_delete}"

    #Slice actions in batch of 1000 (max acceptable value for Google APIs)
    actions=[]
    actions+= to_delete.map{|email| {action: :delete, value: email}}
    actions+= to_create.map{|email| {action: :create, value: email}}

    dup_errors=[]
    rl=RateLimiterService.new
    while actions.any?
      Application.logger.debug "Il reste #{actions.count} actions a effectuer"
      rl.wait
      count=[rl.allowed_count,batch_size].min
      b=actions.shift(count)
      Application.logger.debug "Batch size : #{b.count}"
      Application.logger.debug "Batch : #{b.to_s}"

      begin
        GGroup.reload_service
        if b.count > 1
          GGroup.service.batch{process_action_batch b}
        else
          process_action_batch b
        end
      rescue Google::Apis::ClientError => e
        if e.message.start_with? "duplicate: Member already exists"
          log = (b.count==1 ? "#{e.message} : #{b.first}" : e.message)
          dup_errors<<log
        else
          raise
        end
      end
    end

    if dup_errors.any?
      Application.logger.error "Duplicated membres : #{dup_errors.to_s}"
      raise_hardfail("Duplicated membres : #{dup_errors.to_s}")
    end

    Application.logger.info "Successfully update members of #{mailling_list.primary_email} : add #{to_create.count}, del #{to_delete.count}"
  end

  def update_group_roles
    current_emails=@gg.privilegied_members.map(&:email)

    target_roles=Hash.new
    mailling_list.owners.each{|email| target_roles[email]="OWNER"}
    mailling_list.managers.each{|email| target_roles[email]="MANAGER"}
    (current_emails-target_roles.keys).each{|email| target_roles[email]="MEMBER"}

    actions=target_roles.map{|k,v| {action: :update_role, key: k,value: v}}
    
    rl=RateLimiterService.new
    while actions.any?
      Application.logger.debug "Il reste #{actions.count} actions de modification de role a effectuer"
      rl.wait
      count=[rl.allowed_count,batch_size].min
      b=actions.shift(count)
      Application.logger.debug "Batch size : #{b.count}"
      Application.logger.debug "Batch : #{b.to_s}"

      begin
        service=GGroup.reload_service
        if b.count > 1
          GGroup.service.batch{process_action_batch b}
        else
          process_action_batch b
        end        
      end
    end
    Application.logger.info "Successfully update members roles of #{mailling_list.primary_email} : #{target_roles.keys.count} changes"
  end

  def batch_size
    [Application.config['batch_size'].to_i,1].max
  end

  def process_action_batch batch
    batch.each do |a|
      case a[:action]
      when :create
        @gg.add_member a[:value]
      when :delete
        @gg.delete_member a[:value]
      when :update_role
        @gg.update_member_role(a[:key],a[:value])
      end
    end
  end

  def update_group_aliases
    Application.logger.warn "update_group_aliases not implemented"
  end

  def mailling_list
    @mailling_list||=MaillingList.new(message.data)
  end

end
