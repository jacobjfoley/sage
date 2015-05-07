class UserRole < ActiveRecord::Base

    # Associations with other models.
    belongs_to :user
    belongs_to :project
    
    # Validations.
    validates :project_id, presence: true
    validates :user_id, presence: true
end
