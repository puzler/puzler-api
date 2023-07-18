# frozen_string_literal: true

class ApplicationController < ActionController::API
  def root
    render json: { message: 'Hello There' }, status: :ok
  end
end
