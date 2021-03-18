# == Schema Information
#
# Table name: students
#
#  id                     :integer          not null, primary key
#  semester               :integer
#  academic_program       :string(255)
#  education              :text
#  additional_information :text
#  birthday               :date
#  homepage               :string(255)
#  github                 :string(255)
#  facebook               :string(255)
#  xing                   :string(255)
#  linkedin               :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  employment_status_id   :integer          default(0), not null
#  frequency              :integer          default(1), not null
#  academic_program_id    :integer          default(0), not null
#  graduation_id          :integer          default(0), not null
#  visibility_id          :integer          default(0), not null
#  dschool_status_id      :integer          default(0), not null
#  group_id               :integer          default(0), not null
#

class StudentsController < ApplicationController
  include UsersHelper

  skip_before_action :signed_in_user, only: [:new, :create]

  authorize_resource except: [:destroy, :edit]
  before_action :set_student, only: [:show, :edit, :update, :destroy, :activate]
  before_action :birthdate_params_valid?, only: [:update]

  has_scope :filter_students, only: [:index], as: :q
  has_scope :filter_programming_languages, type: :array, only: [:index], as: :programming_language_ids
  has_scope :filter_languages, type: :array, only: [:index], as: :language_ids
  has_scope :filter_semester, only: [:index],  as: :semester
  has_scope :filter_employer, only: [:index],  as: :employer
  has_scope :filter_academic_program, only: [:index],  as: :academic_program_id
  has_scope :filter_graduation, only: [:index],  as: :graduation_id

  def index
    @students = Student.joins(:user).order('lastname', 'firstname').paginate(page: params[:page], per_page: 20)
    @students = apply_scopes(@students)
  end

  def show
    authorize! :show, @student
    @job_offers = @student.assigned_job_offers.paginate page: params[:page], per_page: 5
  end

  def new
    @student = Student.new
    @student.build_user
  end

  def create
    @student = Student.new student_params
    if @student.save
      sign_in @student.user
      flash[:success] = I18n.t('users.messages.successfully_created')
      redirect_to [:edit, @student]
      StudentsMailer.new_student_email(@student).deliver_now
    else
      render 'new'
    end
  end

  def edit
    authorize! :edit, @student

    @languages = Language.all
    @employers = Employer.all

    @student.cv_jobs.build
    @student.cv_educations.build

    # build options for select
    ProgrammingLanguage.selectable_for_student(@student).each do |programming_language|
      @student.programming_languages_users.build(programming_language: programming_language)
    end
    @student.programming_languages_users.build(programming_language_attributes: { private: true })
  end

  def update
    update_from_params_for_languages params, student_path(@student)

    if @student.update student_params.to_h
      respond_and_redirect_to(@student, I18n.t('users.messages.successfully_updated.'))
    else
      render_errors_and_action(@student, 'edit')
    end
  end

  def destroy
    authorize! :destroy, @student
    @student.destroy
    respond_and_redirect_to(students_url, I18n.t('users.messages.successfully_deleted.'))
  end

  def activate
    authorize! :activate, @student
    admin_activation and return if current_user.admin?
    url = 'https://openid.hpi.uni-potsdam.de/user/' + params[:student][:username] rescue ''
    authenticate_with_open_id url, return_to: "#{request.protocol}#{request.host_with_port}#{request.fullpath}" do |result, identity_url|
      if result.successful?
        current_user.update_column :activated, true
        flash[:success] = I18n.t('users.messages.successfully_activated')
      else
        flash[:error] = I18n.t('users.messages.unsuccessfully_activated')
      end
      redirect_to current_user.manifestation
    end
  end

  def export_alumni
  end

  def send_alumni_csv
    require 'csv'

    case params[:which_alumni]
      when 'from_to'
        from_date = Date.new(params[:from_date]["year"].to_i,params[:from_date]["month"].to_i,params[:from_date]["day"].to_i)
        to_date = Date.new(params[:to_date]["year"].to_i,params[:to_date]["month"].to_i,params[:to_date]["day"].to_i)
        send_data Student.export_registered_alumni(from_date, to_date), filename: "alumni-#{from_date}-#{to_date}.csv", type: "text/csv"
      when 'registered'
        send_data Student.export_registered_alumni(nil, nil), filename: "registered-alumni-#{Date.today}.csv", type: "text/csv"
      when 'unregistered'
        send_data Alumni.export_unregistered_alumni, filename: "unregistered-alumni-#{Date.today}.csv", type: "text/csv"
      else
        flash[:error] = I18n.t('errors.not_found')
        redirect_to export_alumni_students_path
    end
  end

  private
    def set_student
      @student = Student.find params[:id]
    end

    def student_params
      params.require(:student).permit(:semester, :dschool_status_id, :group_id, :visibility_id, :academic_program_id, :graduation_id, :additional_information, :birthday, :homepage, :github, :facebook, :xing, :linkedin, :employment_status_id, :languages, :programming_languages, user_attributes: [:firstname, :lastname, :email, :password, :password_confirmation, :photo], cv_jobs_attributes: [:id, :_destroy, :position, :employer, :start_date, :end_date, :current, :description], cv_educations_attributes: [:id, :_destroy, :degree, :field, :institution, :start_date, :end_date, :current], programming_languages_users_attributes: [:id, :_destroy, :programming_language_id, :skill, programming_language_attributes: [:id, :name, :private]])
    end

    def rescue_from_exception(exception)
      if [:index].include? exception.action
        redirect_to root_path, notice: exception.message
      elsif [:edit, :destroy, :update].include? exception.action
        redirect_to student_path(exception.subject), notice: exception.message
      else
        redirect_to root_path, notice: exception.message
      end
    end

    def admin_activation
      @student.user.update_column :activated, true
      flash[:success] = I18n.t('users.messages.successfully_activated')
      redirect_to @student
    end

    def birthdate_params_valid?
      birthdate_day = params["student"]["birthday(1i)"]
      birthdate_month = params["student"]["birthday(2i)"]
      birthdate_year = params["student"]["birthday(3i)"]

      birthdate_valid = (birthdate_day.blank? && birthdate_month.blank? && birthdate_year.blank?) || (!birthdate_day.blank? && !birthdate_month.blank? && !birthdate_year.blank?)

      if !birthdate_valid
        @student.errors.add(:birthday, I18n.t("errors.messages.invalid"))
        render_errors_and_action(@student, 'edit')
      end
    end
end
