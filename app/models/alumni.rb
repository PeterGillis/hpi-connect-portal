# == Schema Information
#
# Table name: alumnis
#
#  id           :integer          not null, primary key
#  firstname    :string(255)
#  lastname     :string(255)
#  email        :string(255)      not null
#  alumni_email :string(255)      not null
#  token        :string(255)      not null
#  created_at   :datetime
#  updated_at   :datetime
#

class Alumni < ActiveRecord::Base
  
  validates :email, presence: true
  validates :alumni_email, presence: true, uniqueness: { case_sensitive: false }
  validates :token, presence: true, uniqueness: { case_sensitive: true }
  validate :uniqueness_of_alumni_email_on_user

  def self.create_from_row(row)
    if row.key?(:login)
      row[:firstname] ||= row[:login].split('.')[0].capitalize
      row[:lastname] ||= row[:login].split('.')[1].capitalize
      row[:alumni_email] = row[:login]
    end
    alumni = Alumni.new firstname: row[:firstname], lastname: row[:lastname], email: row[:email], alumni_email: row[:alumni_email]
    alumni.generate_unique_token
    if alumni.save
      AlumniMailer.creation_email(alumni).deliver
      return :created
    end
    return alumni
  end

  def uniqueness_of_alumni_email_on_user
    errors.add(:alumni_email, 'is already in use by another user.') if User.exists? alumni_email: alumni_email
  end

  def generate_unique_token
    code = SecureRandom.urlsafe_base64
    code = SecureRandom.urlsafe_base64 while Alumni.exists? token: code
    self.token = code
  end

  def link(user)
    user.update_column :alumni_email, alumni_email
    user.update_column :activated, true
    self.destroy
  end
end
