# == Schema Information
#
# Table name: job_offers
#
#  id           :integer          not null, primary key
#  description  :text
#  title        :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#  chair        :string(255)
#  start_date   :date
#  end_date     :date
#  time_effort  :float
#  compensation :float
#  room_number  :string(255)
#  status       :string(255)
#

class JobOffer < ActiveRecord::Base

    has_many :applications
    has_many :users, through: :applications
	has_and_belongs_to_many :programming_languages
    has_and_belongs_to_many :languages
    belongs_to :chair
    belongs_to :responsible_user, class_name: "User"

	accepts_nested_attributes_for :programming_languages
    accepts_nested_attributes_for :languages

	validates :title, :description, :chair, :start_date, :time_effort, :compensation, presence: true
    validates :compensation, :time_effort, numericality: true
	validates_datetime :end_date, :on_or_after => :start_date, :allow_blank => :end_date

    self.per_page = 5


    def self.find_jobs(attributes={})

        result = all

        if !attributes[:search].blank?
            result = search(attributes[:search])
        end

        if !attributes[:filter].empty?
            result = result.filter(attributes[:filter])
        end

        if !attributes[:sort].blank?
            result = result.sort(attributes[:sort])
        end

        result
    end

	def self.sort(order_attribute) 
		if order_attribute == "date"
			order(:created_at)
		elsif order_attribute == "chair"
			includes(:chair).order("chairs.name ASC")
		end
	end

	def self.search(search_attribute)
			search_string = "%" + search_attribute + "%"
			search_string = search_string.downcase
			includes(:programming_languages,:chair).where('lower(title) LIKE ? OR lower(job_offers.description) LIKE ? OR lower(chairs.name) LIKE ? OR lower(programming_languages.name) LIKE ?', search_string, search_string, search_string, search_string).references(:programming_languages,:chair)
	end

	def self.filter(options={})

		filter_chair(options[:chair]).
        filter_start_date(options[:start_date]).
        filter_end_date(options[:end_date]).
        filter_time_effort(options[:time_effort]).
        filter_compensation(options[:compensation]).
        filter_status(options[:status]).
        filter_programming_languages(options[:programming_language_ids]).
        filter_languages(options[:language_ids])
    end


    def self.filter_chair(chair)
    	chair.blank? ? all : where(chair_id: chair.to_i)             
    end

    def self.filter_start_date(start_date)
        start_date.blank? ? all : where('start_date >= ?', Date.parse(start_date))
    end        

    def self.filter_end_date(end_date)
        end_date.blank? ? all : where('end_date <= ?', Date.parse(end_date))
    end

    def self.filter_time_effort(time_effort)
        time_effort.blank? ? all : where('time_effort <= ?', time_effort.to_f)
    end

    def self.filter_compensation(compensation)
        compensation.blank? ? all : where('compensation >= ?', compensation.to_f)
    end

    def self.filter_status(status)
        status.blank? ? all : where('status <= ?', status)
    end

    def self.filter_programming_languages(programming_language_ids)
        programming_language_ids.blank? ? all : includes(:job_offers_programming_languages).where('programming_language_id in ?', programming_language_ids)
    end

    def self.filter_languages(language_ids)
        # programming_language_ids.blank? ? all : includes(:programming_languages).where('programming_language_id @> ?', programming_language_ids)
        all
    end
end
