class Users::DataExportsController < ApplicationController
  include JwtAuthenticatable

  before_action :require_current_user!

  # GET /me/export — GDPR data portability: everything we store about the
  # user as a downloadable JSON file.
  def show
    send_data JSON.pretty_generate(UserDataExport.new(current_user).as_json),
      filename: "puzler-data-#{current_user.username}-#{Date.current.iso8601}.json",
      type: "application/json",
      disposition: "attachment"
  end
end
