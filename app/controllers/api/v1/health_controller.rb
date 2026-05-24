module Api
  module V1
    class HealthController < ApplicationController
      protect_from_forgery with: :null_session

      def show
        render json: { status: "ok", mode: ModeDetector.current }
      end
    end
  end
end
