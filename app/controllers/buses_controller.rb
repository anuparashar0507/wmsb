class BusesController < ApplicationController
  respond_to :html, :json, only: :index
  before_filter :authenticate!

  def index
    search = AssignmentSearch.find(session[:contact_id])
    assignments = search.assignments

    if search.errors.any?
      flash.now.alert = search.errors.messages.values.flatten.first
    end

    if assignments.without_gps_data.any?
      names_of_missing = assignments.without_gps_data.map(&:student_name).join(', ')
      flash.now.alert = "We're sorry, but no GPS information is currently available for #{names_of_missing}. Please call the transportation hotline at 617-635-9520."
    end

    @assignments = ActiveModel::ArraySerializer.new(assignments.with_gps_data)
    respond_with(@assignments)
  end

  private

  def authenticate!
    if session_exists? && session_expired?
      cookies.delete(:current_assignment)
      session.delete(:contact_id)

      respond_to do |format|
        format.html { redirect_to :root, alert: 'Your session has expired.' }
        format.json { head 401 }
      end
    elsif !session[:contact_id]
      respond_to do |format|
        format.html { redirect_to :root, alert: 'You need to sign in first.' }
        format.json { head 401 }
      end
    end
  end
end
