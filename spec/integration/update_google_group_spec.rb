require 'spec_helper'
require 'support/integrations_tools'


RSpec.describe "Request an ggroup update", type: :integration do

  let(:before_start_proc) {Proc.new{LogMessageHandler.listen_to 'reply.mailinglist.delete'}}

  let(:message) {GorgService::Message.new(event:'request.mailinglist.update',
                                          data: payload,
                                          reply_to: Application.config['rabbitmq_event_exchange_name'],
                                          soa_version: "2.0"
  )}

  let(:ggroup_name) {Faker::Company.name}
  let(:ggroup_email) {"#{Faker::Internet.username(specifier: ggroup_name)}@poubs.org"}
  let(:ggroup_description) {Faker::Company.bs}

  let(:guser_1_attributes) {{
        specifier: {
            given_specifier: "User 1",
            family_specifier: Faker::Company.name,
        },
        password: '96dcd4c1f74f7a2eed974365c0bf9ec434ff31f6',
        hash_function: "SHA-1",
        primary_email: "#{Faker::Internet.username(specifier: Faker::Name.name)}_#{Faker::Internet.username(specifier: ggroup_name)}@poubs.org"
    }}
  let(:guser_2_attributes) {{
      specifier: {
          given_specifier: "User 2",
          family_specifier: Faker::Company.name,
      },
      password: '96dcd4c1f74f7a2eed974365c0bf9ec434ff31f6',
      hash_function: "SHA-1",
      primary_email: "#{Faker::Internet.username(specifier: Faker::Name.name)}_#{Faker::Internet.username(specifier: ggroup_name)}@poubs.org"
  }}
  let(:guser_3_attributes) {{
      specifier: {
          given_specifier: "User 3",
          family_specifier: Faker::Company.name,
      },
      password: '96dcd4c1f74f7a2eed974365c0bf9ec434ff31f6',
      hash_function: "SHA-1",
      primary_email: "#{Faker::Internet.username(specifier: Faker::Name.name)}_#{Faker::Internet.username(specifier: ggroup_name)}@poubs.org"
  }}
  let(:guser_4_attributes) {{
      specifier: {
          given_specifier: "User 4",
          family_specifier: Faker::Company.name,
      },
      password: '96dcd4c1f74f7a2eed974365c0bf9ec434ff31f6',
      hash_function: "SHA-1",
      primary_email: "#{Faker::Internet.username(specifier: Faker::Name.name)}_#{Faker::Internet.username(specifier: ggroup_name)}@poubs.org"
  }}
  let(:guser_1){GUser.new(guser_1_attributes).save}
  let(:guser_2){GUser.new(guser_2_attributes).save}
  let(:guser_3){GUser.new(guser_3_attributes).save}
  let(:guser_4){GUser.new(guser_4_attributes).save}

  let(:payload){
    {
        "name"=>ggroup_name,
        "primary_email"=>ggroup_email,
        "description"=>ggroup_description,
        "aliases"=>["#{Faker::Internet.username(specifier: ggroup_name)}_2@poubs.org","#{Faker::Internet.username(specifier: ggroup_name)}_3@poubs.org"],
        "owners"=>[guser_1.primary_email],
        "managers"=> [guser_2.primary_email],
        "members"=> [guser_3.primary_email],
        "message_max_bytes_size"=> 3000,
        "is_archived"=> true,
        "distribution_policy"=> ["open", "closed", "moderated"].sample
    }
  }

  before(:each) do
    GorgService::Producer.new.publish_message(message)
    sleep(30)
  end

  context "Not existing GGroup" do

    it "creates group" do
      expect(GGroup.find(ggroup_email)).to be_a_kind_of(GGroup)
    end

  end

  context "Existing google Group" do

    before(:each) do
      @gg=GGroup.new({
                         email: ggroup_email,
                         specifier:  ggroup_name,
                         description: ggroup_description
                     }).save
    end


  end
end
