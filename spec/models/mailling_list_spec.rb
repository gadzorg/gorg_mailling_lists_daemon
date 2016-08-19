require 'spec_helper'

RSpec.describe MaillingList, type: :model do

  let (:ml)   {MaillingList.new(data)}
  let (:data) {complete_data}
  let (:complete_data) {
    {
        name:"Me 211",
        primary_email: "me211@gadz.org",
        description: "Liste de diffusion de la promotion me211",
        members:[
          "alexandre.narbonne@gadz.org",
          "dorian.becker@gadz.org"
        ],
        aliases:[
          "me.211@gadz.org"
          ],
        message_max_bytes_size: 3145728,
        object_tag:"[me211]",
        message_footer: "Pour se désinscrire : gorgmail.gadz.org",
        is_archived: true,
        distribution_policy:"open"
    }
  }

  it "returns a hash" do
    expected_hash={
        name:"Me 211",
        primary_email: "me211@gadz.org",
        description: "Liste de diffusion de la promotion me211",
        members:[
          "alexandre.narbonne@gadz.org",
          "dorian.becker@gadz.org"
        ],
        aliases:[
          "me.211@gadz.org"
          ],
        message_max_bytes_size: 3145728,
        object_tag:"[me211]",
        message_footer: "Pour se désinscrire : gorgmail.gadz.org",
        is_archived: true,
        distribution_policy:"open"
    }
    expect(ml.to_h).to eq(expected_hash)
  end

  describe "validate against its schema" do
    context "when valid" do
      let (:data) {complete_data.merge(message_max_bytes_size: nil)}

      it "returns true" do
        expect(ml.valid?).to be(true)
      end

      it "has no error" do
        ml.valid?
        expect(ml.errors).to match_array([])
      end
    end

    context "when invalid" do
      let (:data) {complete_data.merge(message_max_bytes_size: nil, primary_email: nil)}

      it "returns false" do
        expect(ml.valid?).to be(false)
      end

      it "set errors" do
        ml.valid?
        expect(ml.errors).to have(1).items
      end
    end
  end

  it "returns a google group object" do
    gg=ml.google_group
    expect(gg).to be_a_kind_of(GGroup)
    expect(gg.name).to eq("Me 211")
    expect(gg.email).to eq("me211@gadz.org")
    expect(gg.description).to eq("Liste de diffusion de la promotion me211")
  end
  describe "returns a google group settings" do
    let (:ggs) {ml.google_group_settings}

    it "returns a google group settings object" do
      expect(ggs).to be_a_kind_of(Google::Apis::GroupssettingsV1::Groups)
    end

    it "set default values" do
      expect(ggs.allow_google_communication).to eq(false)
      expect(ggs.who_can_add).to eq("NONE_CAN_ADD")
      expect(ggs.who_can_join).to eq("INVITED_CAN_JOIN")
      expect(ggs.who_can_view_membership).to eq("ALL_MANAGERS_CAN_VIEW")
      expect(ggs.who_can_view_group).to eq("ALL_MEMBERS_CAN_VIEW")
      expect(ggs.who_can_invite).to eq("NONE_CAN_INVITE")
      expect(ggs.allow_external_members).to eq(false)
      expect(ggs.allow_web_posting).to eq(true)
      expect(ggs.primary_language).to eq("fr")
      expect(ggs.archive_only).to eq(false)
      expect(ggs.spam_moderation_level).to eq("MODERATE")
      expect(ggs.members_can_post_as_the_group).to eq(false)
      expect(ggs.message_display_font).to eq("DEFAULT_FONT")
      expect(ggs.include_in_global_address_list).to eq(true)
      expect(ggs.who_can_leave_group).to eq("NONE_CAN_LEAVE")
      expect(ggs.who_can_contact_owner).to eq("ALL_MEMBERS_CAN_CONTACT")
    end

    it "set basic infos" do
      expect(ggs.max_message_bytes).to eq(3145728)
      expect(ggs.custom_footer_text).to eq("Pour se désinscrire : gorgmail.gadz.org")
      expect(ggs.include_custom_footer).to eq(true)
      expect(ggs.is_archived).to eq(true)
    end

    describe "set distribution infos" do
      context "is open" do
        let(:data) {complete_data.merge(distribution_policy: "open")}

        it "set distribution info for open" do
          expect(ggs.who_can_post_message).to eq("ANYONE_CAN_POST")
          expect(ggs.message_moderation_level).to eq("MODERATE_NONE")
          expect(ggs.reply_to).to eq("REPLY_TO_SENDER")
          expect(ggs.custom_reply_to).to be nil
          expect(ggs.send_message_deny_notification).to be nil
          expect(ggs.default_message_deny_notification_text).to be nil
          expect(ggs.show_in_group_directory).to be true
        end
      end
      context "is closed" do
        let(:data) {complete_data.merge(distribution_policy: "closed")}

        it "set distribution info for closed" do
          expect(ggs.who_can_post_message).to eq("ALL_MEMBERS_CAN_POST")
          expect(ggs.message_moderation_level).to eq("MODERATE_NONE")
          expect(ggs.reply_to).to eq("REPLY_TO_LIST")
          expect(ggs.custom_reply_to).to be nil
          expect(ggs.send_message_deny_notification).to be true
          expect(ggs.default_message_deny_notification_text).to eq("Seul les membres du groupes peuvent écrire")
          expect(ggs.show_in_group_directory).to be false
        end
      end
      context "is moderated" do
        let(:data) {complete_data.merge(distribution_policy: "moderated")}

        it "set distribution info for moderated" do
          expect(ggs.who_can_post_message).to eq("ANYONE_CAN_POST")
          expect(ggs.message_moderation_level).to eq("MODERATE_ALL_MESSAGES")
          expect(ggs.reply_to).to eq("REPLY_TO_SENDER")
          expect(ggs.custom_reply_to).to be nil
          expect(ggs.send_message_deny_notification).to be true
          expect(ggs.default_message_deny_notification_text).to eq("Votre message a été refusé par les modérateurs de la liste")
          expect(ggs.show_in_group_directory).to be true
        end
      end
    end
  end
end