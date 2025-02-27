module ForestLiana
  class SmartActionsController < ForestLiana::ApplicationController
    if Rails::VERSION::MAJOR < 4
      before_filter :check_permission_for_smart_route
    else
      before_action :check_permission_for_smart_route
    end

    private

    def get_smart_action_request
      begin
        params[:data][:attributes]
      rescue => error
        FOREST_LOGGER.error "Smart Action execution error: #{error}"
        {}
      end
    end

    def check_permission_for_smart_route
      begin
        
        smart_action_request = get_smart_action_request
        if !smart_action_request.nil? && smart_action_request.has_key?(:smart_action_id)
          checker = ForestLiana::PermissionsChecker.new(
            find_resource(smart_action_request[:collection_name]),
            'actions',
            @rendering_id,
            get_smart_action_permission_info(forest_user, smart_action_request)
          )
          return head :forbidden unless checker.is_authorized?
        else
          FOREST_LOGGER.error 'Smart action execution error: Unable to retrieve the smart action id.'
          render serializer: nil, json: { status: 400 }, status: :bad_request
        end
      rescue => error
        FOREST_LOGGER.error "Smart Action execution error: #{error}"
        render serializer: nil, json: { status: 400 }, status: :bad_request
      end
    end

    def find_resource(collection_name)
      begin
          resource = SchemaUtils.find_model_from_collection_name(collection_name)

          if resource.nil? || !SchemaUtils.model_included?(resource) ||
            !resource.ancestors.include?(ActiveRecord::Base)
            render serializer: nil, json: { status: 404 }, status: :not_found
          end
          resource
      rescue => error
        FOREST_LOGGER.error "Find Collection error: #{error}\n#{format_stacktrace(error)}"
        render serializer: nil, json: { status: 404 }, status: :not_found
      end
    end

    def get_smart_action_permission_info(user, smart_action_request)
      {
        user_id: user['id'],
        action_id: smart_action_request[:smart_action_id],
      }
    end
  end
end
