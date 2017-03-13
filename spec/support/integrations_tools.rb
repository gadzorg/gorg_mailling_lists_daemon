require 'gorg_service/rspec/bunny_cleaner'
require 'gorg_service/rspec/log_message_handler'

RSpec.configure do |c|
  c.before(:context, type: :integration) {GorgService.configuration.rabbitmq_client_class=BunnyCleaner}
  c.around(:example,type: :integration) do |example|
    BunnyCleaner.cleaning do
      begin
        LogMessageHandler.reset_listen_to!
        LogMessageHandler.listen_to Application.config['log_routing_key']
        LogMessageHandler.reset

        defined?(before_start_proc) && before_start_proc.call

        @app=Application.new
        @app.start
        begin
          example.run
        ensure
          @app.stop
        end
      ensure
        Application.logger.info "#### CLEANING UP GSuite"

        if defined?(ggroup_email)&&ggroup_email
          Application.logger.info "## Delete Group #{ggroup_email}"
          temp=GGroup.find(ggroup_email)
          temp&&temp.delete
        end

        if defined?(guser_1_attributes)&&guser_1_attributes
          Application.logger.info "## Delete User #{guser_1_attributes[:primary_email]}"
          temp=GUser.find(guser_1_attributes[:primary_email])
          temp&&temp.delete
        end

        if defined?(guser_2_attributes)&&guser_2_attributes
          Application.logger.info "## Delete User #{guser_2_attributes[:primary_email]}"
          temp=GUser.find(guser_2_attributes[:primary_email])
          temp&&temp.delete
        end

        if defined?(guser_3_attributes)&&guser_3_attributes
          Application.logger.info "## Delete User #{guser_3_attributes[:primary_email]}"
          temp=GUser.find(guser_3_attributes[:primary_email])
          temp&&temp.delete
        end

        if defined?(guser_4_attributes)&&guser_4_attributes
          Application.logger.info "## Delete User #{guser_4_attributes[:primary_email]}"
          temp=GUser.find(guser_4_attributes[:primary_email])
          temp&&temp.delete
        end
      end

    end
  end
end