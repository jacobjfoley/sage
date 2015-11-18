class Statistics

  # Capture a project to analyse.
  def initialize(project_id)

    # Store the provided project.
    @project = Project.find(project_id)
  end

  # Create a string that represents this object.
  def to_s

    # Initialise string.
    s = ""

    # Print header.
    s << "Statistics about #{@project.id} - #{@project.name}\n"

    # Print data.
    s << "Users: #{user_count}\n"
    s << "Annotations: #{annotation_count}\n"
    s << "#{object_statistics}\n"
    s << "#{concept_statistics}\n"
    s << "#{word_statistics}\n"

    # Return string.
    return s
  end

  # Get the number of users.
  def user_count

    return @project.users.count
  end

  # Get the number of objects.
  def object_count

    return @project.digital_objects.count
  end

  # Get the number of concpets.
  def concept_count

    return @project.concepts.count
  end

  # Get the number of annoations.
  def annotation_count

    return @project.annotations.count
  end

  # Find the concept word count statistics.
  def word_statistics

    # Find the word count data.
    data = @project.concepts.map { |c| c.description.split.size }

    # Create and return new measurement.
    return Measurement.new("Word Count", data)
  end

  # Find the object statistics.
  def object_statistics

    # Find the object data.
    data = @project.digital_objects.map { |o| o.annotations.count }

    # Create and return new measurement.
    return Measurement.new("Object Annotations Count", data)
  end

  # Find the concept statistics.
  def concept_statistics

    # Find the concept data.
    data = @project.concepts.map { |c| c.annotations.count }

    # Create and return new measurement.
    return Measurement.new("Concept Annotations Count", data)
  end
end
