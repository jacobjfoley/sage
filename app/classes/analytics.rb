class Analytics

  # Generate project statistics.
  def analyse

    # Create a hash to store individual statistics.
    statistics = {}

    # Get objects, concepts and user counts.
    statistics[:user_count] = @users.count
    statistics[:objects_count] = @digital_objects.count
    statistics[:concepts_count] = @concepts.count

    # Define initial other counts.
    statistics[:associations_count] = 0
    statistics[:word_count] = 0

    # Define initial statistics.
    statistics[:total_object_variance] = 0.0
    statistics[:total_concept_variance] = 0.0
    statistics[:object_std_deviation] = 0.0
    statistics[:concept_std_deviation] = 0.0

    # Gather object statistics.
    @digital_objects.each do |object|

      # Get number of associations.
      associations = object.concepts.count

      # Gather associations.
      statistics[:associations_count] += associations

      # Check for min.
      if !(statistics.has_key? :min_objects) || (associations < statistics[:min_objects])
        statistics[:min_objects] = associations
      end

      # Check for max.
      if !(statistics.has_key? :max_objects) || (associations > statistics[:max_objects])
        statistics[:max_objects] = associations
      end
    end

    # Gather concept statistics.
    @concepts.each do |concept|

      # Get number of associations.
      associations = concept.digital_objects.count

      # Check for min.
      if !(statistics.has_key? :min_concepts) || (associations < statistics[:min_concepts])
        statistics[:min_concepts] = associations
      end

      # Check for max.
      if !(statistics.has_key? :max_concepts) || (associations > statistics[:max_concepts])
        statistics[:max_concepts] = associations
      end

      # Get word count.
      words = concept.description.split.size

      # Gather words.
      statistics[:word_count] += words

      # Check for min words.
      if !(statistics.has_key? :min_words) || (words < statistics[:min_words])
        statistics[:min_words] = words
      end

      # Check for max.
      if !(statistics.has_key? :max_words) || (words > statistics[:max_words])
        statistics[:max_words] = words
      end
    end

    # Determine averages.
    if statistics[:objects_count] > 0
      statistics[:avg_objects] = statistics[:associations_count].to_f / statistics[:objects_count]
    else
      statistics[:avg_objects] = 0.0
    end

    if statistics[:concepts_count] > 0
      statistics[:avg_concepts] = statistics[:associations_count].to_f / statistics[:concepts_count]
      statistics[:avg_words] = statistics[:word_count].to_f / statistics[:concepts_count]
    else
      statistics[:avg_concepts] = 0.0
      statistics[:avg_words] = 0.0
    end

    # Calculate object variance.
    @digital_objects.each do |object|

      # Calculate summed variance.
      statistics[:total_object_variance] += (object.concepts.count -
        statistics[:avg_objects]) ** 2
    end

    # Calculate concept variance.
    @concepts.each do |concept|

      # Calculate summed variance.
      statistics[:total_concept_variance] += (concept.digital_objects.count -
        statistics[:avg_concepts]) ** 2
    end

    # Determine object standard deviation.
    if statistics[:objects_count] > 1
      statistics[:object_std_deviation] = Math.sqrt(
        statistics[:total_object_variance] /
        (statistics[:objects_count] - 1.0)
      )
    end

    # Determine concept standard deviation.
    if statistics[:concepts_count] > 1
      statistics[:concept_std_deviation] = Math.sqrt(
        statistics[:total_concept_variance] /
        (statistics[:concepts_count] - 1.0)
      )
    end

    # Determine words if manually annotated.
    statistics[:manually_annotated] = manual_annotation

    # Return statistics.
    return statistics
  end

  # The number of words if manually annotated.
  def manual_annotation

    # Initialise words if manually annotated.
    manual_words = 0

    # For each concept:
    @concepts.each do |concept|

      # Calculate the number of words in the concept.
      words = concept.description.split.size

      # Calculate the number of times this concept has been associated with
      # objects.
      associations = concept.digital_objects.count

      # Increment manual words by the number of words contributed as
      # associations.
      manual_words += words * associations
    end

    # Return result.
    return manual_words
  end

  # Capture a project to analyse.
  def initialize(project)

    # Store the provided project.
    @project = project

    # Capture information from the project.
    @users = @project.users
    @digital_objects = @project.digital_objects
    @concepts = @project.concepts
  end
end
