class MaillingList

  JSON_SCHEMA={"$schema"=>"http://json-schema.org/draft-04/schema#",
                "title"=>"Mailling list creation message",
                "type"=>"object",
                "properties"=>{
                  "name"=>{
                    "type"=>"string",
                    "description"=>"Name of the mailling list"
                  },
                "primary_email"=>{
                  "type"=>"string",
                  "description"=>"Primary email address used to create the mailling list"
                },
                "description"=>{
                  "type"=>"string",
                  "description"=>"Description of the mailling list"
                },
                "aliases"=>{
                  "type"=>"array",
                  "description"=>"Mailling list email aliases",
                  "items"=>{
                   "type"=>"string"
                  }
                },
                "members"=>{
                  "type"=>"array",
                  "description"=>"List of members email address",
                  "items"=>{
                    "type"=>"string"
                  }
                },
                "message_max_bytes_size"=>{
                  "type"=>"integer",
                  "description"=>"Message maximum size in bytes. Default to 3MB",
                  "default"=>3145728
                },
                "object_tag"=>{
                  "type"=>"string",
                  "description"=>"Tag in front of object. ex: [me211]"
                },
                "message_footer"=>{
                  "type"=>"string",
                  "description"=>"Message appended to the bottom of each message"
                },
                "is_archived"=>{
                  "type"=>"boolean",
                  "description"=>"Defines if messages archive is activated for this mailling list",
                  "default"=>false
                },
                "distribution_policy"=>{
                  "enum"=>["open", "closed", "moderated"],
                  "default"=>"closed",
                  "description"=>"open: Anyone can post to the list;closed: Only members can post to the list; moderated: All message shave to be approved by a moderator"}
                },
                "additionalProperties"=>true,
                "required"=>[
                  "name",
                  "primary_email"
                  ]
                }

  attr_accessor   :name,
                  :primary_email,
                  :description,
                  :aliases,
                  :members,
                  :message_max_bytes_size,
                  :object_tag,
                  :message_footer,
                  :is_archived,
                  :distribution_policy

  def initialize(hsh)
    set_values_from_hash hsh
  end

  def errors
    @errors||=[]
  end

  def to_h
    {
      :name => @name,
      :primary_email => @primary_email,
      :description => @description,
      :aliases => @aliases,
      :members => @members,
      :message_max_bytes_size => @message_max_bytes_size,
      :object_tag => @object_tag,
      :message_footer => @message_footer,
      :is_archived => @is_archived,
      :distribution_policy => @distribution_policy,
    }.delete_if { |k, v| v.nil? }
  end

  def set_default
    hsh=self.to_h
    JSON::Validator.fully_validate(JSON_SCHEMA, hsh, :insert_defaults => true)
    set_values_from_hash hsh
  end

  def valid?
    hsh=self.to_h
    @errors=JSON::Validator.fully_validate(JSON_SCHEMA, hsh)
    if errors.any?
      return false
    else
      hsh = hsh.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo} #convert string keys in symbols
      set_values_from_hash hsh
      return true
    end
  end

  def google_group
    hsh={
          email: @primary_email,
          name:  @name,
          description: @description
        }.delete_if { |k, v| v.nil? }
    gg=GGroup.new(hsh)
  end

  def google_group_settings

    ggs_base_data={
      max_message_bytes: @message_max_bytes_size,
      custom_footer_text: @message_footer,
      include_custom_footer: @message_footer&&(@message_footer=="" ? false : true),
      is_archived: @is_archived,
    }.delete_if { |k, v| v.nil? }

    ggs_distribution_data= case @distribution_policy
    when "open"
      {
        who_can_post_message: "ANYONE_CAN_POST",
        message_moderation_level: "MODERATE_NONE",
        reply_to: "REPLY_TO_SENDER",
        show_in_group_directory: true,
      }
    when "closed"
      {
        who_can_post_message: "ALL_MEMBERS_CAN_POST",
        message_moderation_level: "MODERATE_NONE",
        reply_to: "REPLY_TO_LIST",
        send_message_deny_notification: true,
        default_message_deny_notification_text: "Seul les membres du groupes peuvent écrire",
        show_in_group_directory: false,
      }

    when "moderated"
      {
        who_can_post_message: "ANYONE_CAN_POST",
        message_moderation_level: "MODERATE_ALL_MESSAGES",
        reply_to: "REPLY_TO_SENDER",
        send_message_deny_notification: true,
        default_message_deny_notification_text: "Votre message a été refusé par les modérateurs de la liste",
        show_in_group_directory: true,
      }
    end

    Google::Apis::GroupssettingsV1::Groups.new(
      google_group_settings_default_values.merge(ggs_base_data).merge(ggs_distribution_data)
      )
  end


  private

    def set_values_from_hash hsh
      @name = hsh[:name]
      @primary_email = hsh[:primary_email]
      @description = hsh[:description]
      @aliases = hsh[:aliases]
      @members = hsh[:members]
      @message_max_bytes_size = hsh[:message_max_bytes_size]
      @object_tag = hsh[:object_tag]
      @message_footer = hsh[:message_footer]
      @is_archived = hsh[:is_archived]
      @distribution_policy = hsh[:distribution_policy]
    end

    def google_group_settings_default_values
      {
        :allow_google_communication =>false,
        :who_can_add =>"NONE_CAN_ADD",
        :who_can_join =>"INVITED_CAN_JOIN",
        :who_can_view_membership =>"ALL_MANAGERS_CAN_VIEW",
        :who_can_view_group =>"ALL_MEMBERS_CAN_VIEW",
        :who_can_invite =>"NONE_CAN_INVITE",
        :allow_external_members =>false,
        :allow_web_posting =>true,
        :primary_language =>"fr",
        :archive_only =>false,
        :spam_moderation_level =>"MODERATE",
        :members_can_post_as_the_group =>false,
        :message_display_font => "DEFAULT_FONT",
        :include_in_global_address_list =>true,
        :who_can_leave_group =>"NONE_CAN_LEAVE",
        :who_can_contact_owner =>"ALL_MEMBERS_CAN_CONTACT",
      }
    end

end