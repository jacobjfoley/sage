class Statistics

  # Capture a project to analyse.
  def initialize(project)

    # Store the provided project.
    @project = project

    # Capture information from the project.
    @users = @project.users
    @digital_objects = @project.digital_objects
    @concepts = @project.concepts
    @annotations = @project.annotations
  end

  # Generate project statistics.
  def analyse

    # Create a hash to store individual statistics.
    statistics = {}

    # Get objects, concepts, annotations and user counts.
    statistics[:user_count] = @users.count
    statistics[:objects_count] = @digital_objects.count
    statistics[:concepts_count] = @concepts.count
    statistics[:annotations_count] = @annotations.count

    # Create hashes for object and concept annotation counts.
    object_counts = @digital_objects.map {|k| [k.id, 0]}.to_h
    concept_counts = @concepts.map {|k| [k.id, 0]}.to_h

    # Explore annotation distribution.
    @annotations.each do |annotation|

      # Increment counts.
      object_counts[annotation.digital_object_id] += 1
      concept_counts[annotation.concept_id] += 1
    end

    # Find max and min values.
    statistics[:min_objects] = object_counts.values.min
    statistics[:max_objects] = object_counts.values.max
    statistics[:min_concepts] = concept_counts.values.min
    statistics[:max_concepts] = concept_counts.values.max

    # Create word count array.
    word_counts = @concepts.map {|k| k.description.split.size}

    # Find total, max and min values.
    statistics[:word_count] = word_counts.reduce(:+)
    statistics[:min_words] = word_counts.min
    statistics[:max_words] = word_counts.max

    # Determine averages.
    if statistics[:objects_count] > 0
      statistics[:avg_objects] = statistics[:annotations_count].to_f / statistics[:objects_count]
    else
      statistics[:avg_objects] = 0.0
    end

    if statistics[:concepts_count] > 0
      statistics[:avg_concepts] = statistics[:annotations_count].to_f / statistics[:concepts_count]
      statistics[:avg_words] = statistics[:word_count].to_f / statistics[:concepts_count]
    else
      statistics[:avg_concepts] = 0.0
      statistics[:avg_words] = 0.0
    end

    # Define initial statistics.
    statistics[:total_object_variance] = 0.0
    statistics[:total_concept_variance] = 0.0
    statistics[:object_std_deviation] = 0.0
    statistics[:concept_std_deviation] = 0.0

    # If more than one object:
    if statistics[:objects_count] > 0

      # Calculate object variance.
      @digital_objects.each do |object|

        # Calculate summed variance.
        statistics[:total_object_variance] += (object_counts[object.id] -
            statistics[:avg_objects]) ** 2
      end
      statistics[:total_object_variance] /= @digital_objects.count

      # Determine object standard deviation.
      statistics[:object_std_deviation] = Math.sqrt(
        statistics[:total_object_variance]
      )
    end

    # If more than one concept:
    if statistics[:concepts_count] > 0

      # Calculate concept variance.
      @concepts.each do |concept|

        # Calculate summed variance.
        statistics[:total_concept_variance] += (concept_counts[concept.id] -
            statistics[:avg_concepts]) ** 2
      end
      statistics[:total_concept_variance] /= @concepts.count

      # Determine concept standard deviation.
      statistics[:concept_std_deviation] = Math.sqrt(
        statistics[:total_concept_variance]
      )
    end

    # Return statistics.
    return statistics
  end
end
