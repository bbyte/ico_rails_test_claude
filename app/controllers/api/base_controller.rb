module Api
  class BaseController < ApplicationController
    protect_from_forgery with: :null_session
    before_action :authenticate_user!

    private

    def authenticate_user!
      if user_signed_in?
        super
      else
        render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end

    def current_user_jwt
      cookies[:rss_jwt]
    end
  end
end
