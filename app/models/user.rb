# == Schema Information
#
# Table name: users
#
#  id                  :integer          not null, primary key
#  email               :string(255)      default(""), not null
#  remember_created_at :datetime
#  sign_in_count       :integer          default(0)
#  current_sign_in_at  :datetime
#  last_sign_in_at     :datetime
#  current_sign_in_ip  :string(255)
#  last_sign_in_ip     :string(255)
#  created_at          :datetime
#  updated_at          :datetime
#  identity_url        :string(255)
#  is_student          :boolean
#  lastname            :string(255)
#  firstname           :string(255)
#  role_id             :integer          default(1), not null
#

class User < ActiveRecord::Base
    # Include default devise modules. Others available are:
    # :token_authenticatable, :confirmable,
    # :lockable, :timeoutable and :omniauthable
    devise :trackable, :openid_authenticatable

    has_many :applications
    has_many :job_offers, through: :applications
    has_many :programming_languages_users
    has_many :programming_languages, :through => :programming_languages_users
    accepts_nested_attributes_for :programming_languages
    has_and_belongs_to_many :languages
    
    
    belongs_to :role
    belongs_to :chair
    belongs_to :user_status

    has_attached_file   :photo,
                        :url  => "/assets/students/:id/:style/:basename.:extension",
                        :path => ":rails_root/public/assets/students/:id/:style/:basename.:extension"
    validates_attachment_content_type :photo, :content_type => ['image/jpeg', 'image/jpg', 'image/png', 'image/gif']

    has_attached_file   :cv,
                        :url  => "/assets/students/:id/:style/:basename.:extension",
                        :path => ":rails_root/public/assets/students/:id/:style/:basename.:extension"
    validates_attachment_content_type :cv, :content_type => ['application/pdf']

    validates :email, uniqueness: { case_sensitive: false }
    validates :identity_url, uniqueness: true
    validates :firstname, :lastname, presence: true

    def self.build_from_identity_url(identity_url)
        username = identity_url.reverse[0..identity_url.reverse.index('/')-1].reverse

        first_name = username.split('.').first.capitalize
        last_name = username.split('.').second.capitalize
        email = username + '@student.hpi.uni-potsdam.de'

        User.new(identity_url: identity_url, email: email, firstname: first_name, lastname: last_name, is_student: true, role: Role.where(name: "Student").first)
    end

    def applied?(job_offer)
        applications.find_by_job_offer_id job_offer.id
    end

    def student?
        role.name == 'Student'
    end

    def research_assistant?
        role.name == 'Research Assistant'
    end

    def admin?
        role.name == 'Admin'
    end

    def self.search_student(string)
        string = string.downcase
        search_results = User.where("
                is_student=true
                AND (lower(firstname) LIKE ?
                OR lower(lastname) LIKE ?
                OR lower(email) LIKE ?
                OR lower(academic_program) LIKE ?
                OR lower(education) LIKE ?
                OR lower(homepage) LIKE ?
                OR lower(github) LIKE ?
                OR lower(facebook) LIKE ?
                OR lower(xing) LIKE ?
                OR lower(linkedin) LIKE ?)
                ",
                string, string, string, string, string,
                string, string, string, string, string)
        search_results += search_students_by_programming_language(string)
        search_results += search_students_by_language(string)
        search_results.uniq.sort_by{|x| [x.lastname, x.firstname]}
    end

    def self.search_students_by_programming_language(string)
        User.joins(:programming_languages).where('lower(programming_languages.name) LIKE ? AND is_student = true',string.downcase).
        sort_by{|x| [x.lastname, x.firstname]}
    end

     def self.search_students_by_language(string)
        User.joins(:languages).where('lower(languages.name) LIKE ? AND is_student = true',string.downcase).
        sort_by{|x| [x.lastname, x.firstname]}
    end

    def self.search_students_by_language_and_programming_language(language_array, programming_language_array)
       matching_students = User.all 

       language_array.each do |language|
        matching_students = matching_students & search_students_by_language(language)
       end
       
       programming_language_array.each do |programming_language|
        matching_students = matching_students & search_students_by_programming_language(programming_language)
       end

       matching_students
    end 
end
