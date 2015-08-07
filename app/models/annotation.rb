class Annotation < ActiveRecord::Base
  belongs_to :digital_object
  belongs_to :concept
  belongs_to :project
  belongs_to :user

  validates :digital_object, presence: true
  validates :concept, presence: true

  before_create :set_project

  private

  # Automatically sets project based on object's project.
  def set_project
    self.project_id = DigitalObject.find(digital_object).project.id
  end
end
