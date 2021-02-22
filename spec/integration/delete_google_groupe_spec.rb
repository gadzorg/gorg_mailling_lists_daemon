require 'spec_helper'
require 'support/integrations_tools'


RSpec.describe "Request a ggroup delete", type: :integration do

  let(:before_start_proc) {Proc.new{LogMessageHandler.listen_to 'reply.mailinglist.delete'}}

  let(:message) {GorgService::Message.new(event:'request.mailinglist.delete',
                                          data: payload,
                                          reply_to: Application.config['rabbitmq_event_exchange_name'],
                                          soa_version: "2.0"
  )}

  let(:ggroup_name) {Faker::Company.name}
  let(:ggroup_email) {"#{Faker::Internet.username(specifier: ggroup_name)}@poubs.org"}
  let(:ggroup_description) {Faker::Company.bs}

  context "Existing google Group" do

    before(:each) do
      @gg=GGroup.new({
                        email: ggroup_email,
                        name:  ggroup_name,
                        description: ggroup_description
                    }).save
    end

    let(:payload){
      {
          "mailling_list_key" => ggroup_email
      }
    }

    it "delete group" do
      GorgService::Producer.new.publish_message(message)
      sleep(15)
      expect(GGroup.find(@gg.email)).to be_nil
    end

  end
end
