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
    statistics[:annotations_count] = 0
    statistics[:word_count] = 0

    # Define initial statistics.
    statistics[:total_object_variance] = 0.0
    statistics[:total_concept_variance] = 0.0
    statistics[:object_std_deviation] = 0.0
    statistics[:concept_std_deviation] = 0.0

    # Gather object statistics.
    @digital_objects.each do |object|

      # Get number of annotations.
      annotations = object.concepts.count

      # Gather annotations.
      statistics[:annotations_count] += annotations

      # Check for min.
      if !(statistics.has_key? :min_objects) || (annotations < statistics[:min_objects])
        statistics[:min_objects] = annotations
      end

      # Check for max.
      if !(statistics.has_key? :max_objects) || (annotations > statistics[:max_objects])
        statistics[:max_objects] = annotations
      end
    end

    # Gather concept statistics.
    @concepts.each do |concept|

      # Get number of annotations.
      annotations = concept.digital_objects.count

      # Check for min.
      if !(statistics.has_key? :min_concepts) || (annotations < statistics[:min_concepts])
        statistics[:min_concepts] = annotations
      end

      # Check for max.
      if !(statistics.has_key? :max_concepts) || (annotations > statistics[:max_concepts])
        statistics[:max_concepts] = annotations
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

    # Determine annotation rate.
    statistics[:annotation_rate] = annotation_rate

    # Determine reuse rate.
    statistics[:annotation_reuse] = reuse_rate

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
      annotations = concept.digital_objects.count

      # Increment manual words by the number of words contributed as
      # annotations.
      manual_words += words * annotations
    end

    # Return result.
    return manual_words
  end

  # Returns an array of annotation clusters.
  def cluster_annotations

    # Get annotations.
    annotations = @annotations.order(:created_at)

    # Initialise results array.
    clusters = []

    # Pass through annotations.
    annotations.each do |annotation|

      # If a new cluster:
      if clusters.empty? || (annotation.created_at > (clusters.last[:end_time] + 2.minutes))

        # Create new in-progress hash.
        clusters << {
          start_time: annotation.created_at,
          end_time: annotation.created_at,
          count: 1
        }

      # Use existing.
      else

        # Append to cluster.
        clusters.last[:end_time] = annotation.created_at
        clusters.last[:count] += 1
      end
    end

    # Filter clusters with only one annotation.
    clusters.delete_if { |cluster| cluster[:count] == 1 }

    # Return results.
    return clusters
  end

  # Find the number of annotations created via the add button.
  def accepted

    # Return the number of annotations created via this provenance.
    return @annotations.where(provenance: "Existing").count
  end

  # Find the number of annotations created via the quick create button.
  def created

    # Return the number of annotations created via this provenance.
    return @annotations.where(provenance: "New").count
  end

  # Finds the number of annotations in clusters.
  def annotation_count

    # Get clusters.
    clusters = cluster_annotations

    # Define values.
    count = 0

    # Pass through clusters.
    clusters.each do |cluster|

      # Increment totals.
      count += cluster[:count]
    end

    # Return total.
    return count
  end

  # Finds the length of time spent annotating.
  def annotation_period

    # Get clusters.
    clusters = cluster_annotations

    # Define values.
    time = 0.0

    # Pass through clusters.
    clusters.each do |cluster|

      # Increment totals.
      time += (cluster[:end_time] - cluster[:start_time]).abs
    end

    # Return total.
    return time
  end

  # Finds the average annotation rate in annotations/minute.
  def annotation_rate

    # Return average annotations/minute.
    return annotation_count * 60 / annotation_period
  end

  # Find the number of concepts with one annotation.
  def one_rate

    # Return the number.
    return @concepts.select { |concept| concept.annotations.count == 1 }.count
  end

  # Find the number of concepts with many annotations.
  def many_rate

    # Return the number.
    return @concepts.select { |concept| concept.annotations.count > 1 }.count
  end

  # Find the proportion of reused concepts vs single concepts.
  def reuse_rate

    # Return the percentage, or 0 if no concepts.
    if @concepts.count > 0
      return many_rate.to_f * 100 / @concepts.count
    else
      return 0.0
    end
  end

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
end
