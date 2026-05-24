module Api
  module V1
    class SessionsController < Devise::SessionsController
      respond_to :json
      protect_from_forgery with: :null_session

      def create
        super do |user|
          if user.persisted?
            jwt = ENV.fetch("RSS_SERVICE_JWT", "")
            cookies[:rss_jwt] = {
              value: jwt,
              httponly: true,
              same_site: :strict,
              secure: Rails.env.production?
            }
          end
        end
      end

      def destroy
        super
        cookies.delete(:rss_jwt)
      end

      private

      def respond_with(resource, _opts = {})
        if resource.persisted?
          render json: { message: "Signed in successfully", email: resource.email }
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      def respond_to_on_destroy(*)
        render json: { message: "Signed out successfully" }
      end
    end
  end
end
