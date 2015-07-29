class UserRole < ActiveRecord::Base

    belongs_to :user
    belongs_to :project

    validates :project_id, presence: true
    validates :user_id, presence: true
end
