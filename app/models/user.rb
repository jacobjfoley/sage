class User < ActiveRecord::Base

  # Associations with other models.
  has_many :user_roles, dependent: :destroy
  has_many :projects, through: :user_roles
  has_many :associations

  # Ensure the user has a secure password.
  has_secure_password

  # Regular expression for email validation.
  EMAIL_REGEX = /\A[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\z/i

  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: EMAIL_REGEX
end
