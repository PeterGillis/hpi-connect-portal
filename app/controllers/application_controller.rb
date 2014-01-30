class ApplicationController < ActionController::Base
  include SessionsHelper
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :set_locale
  before_action :set_constants

  before_filter :signed_in_user


  def default_url_options(options={})
    logger.debug "default_url_options is passed options: #{options.inspect}\n"
    { locale: I18n.locale }
  end

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  def after_sign_in_path_for(resource)
    if resource.should_redirect_to_profile
      student_path resource
    else
      job_offers_path
    end
  end

  def render_errors_and_action(object, action=nil)
    respond_to do |format|
        if action.nil?
          format.html { redirect_to object }
        else
          format.html { render action: action }
        end
        format.json { render json: object.errors, status: :unprocessable_entity }
    end
  end

  def respond_and_redirect_to(url, notice, action=nil, status=nil)
    respond_to do |format|
      format.html { redirect_to url, notice: notice }
      if action && status
        format.json { render action: action, status: status, location: object }
      end
    end
  end

  def set_role_from_staff_to_student(user_id, deputy_id)
    user = User.find user_id
    if deputy_id
      User.find(deputy_id).update(role: Role.find_by_level(2), employer: user.employer)
      user.employer.update deputy_id: deputy_id
    end   
    user.update role: Role.find_by_level(1), employer: nil
  end

  protected

    def set_constants
      @flagnames = {
        :en => "famfamfam-flag-gb",
        :de => "famfamfam-flag-de"
      }
    end

end
