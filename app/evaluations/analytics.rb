class Analytics

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

    # Calculate object variance.
    @digital_objects.each do |object|

      # Calculate summed variance.
      statistics[:total_object_variance] += (object_counts[object.id] -
        statistics[:avg_objects]) ** 2
    end

    # Calculate concept variance.
    @concepts.each do |concept|

      # Calculate summed variance.
      statistics[:total_concept_variance] += (concept_counts[concept.id] -
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

    # Return statistics.
    return statistics
  end

  # Returns the number of concepts in this project.
  def concept_count

    # Return concept count.
    return @concepts.count
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
  def cluster_annotation_count

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

  # Find the number of annotations.
  def annotation_count

    # Return count.
    return @annotations.count
  end

  # Finds the length of time spent annotating.
  def cluster_annotation_period

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
  def cluster_annotation_rate

    # Return average annotations/minute.
    return cluster_annotation_count * 60 / cluster_annotation_period
  end

  # Find the number of annotations which link to a well-annotated concept.
  def to_many_rate

    # Find the "hub" concepts with > 1 annotation.
    hubs = @concepts.select { |concept| concept.annotations.count > 1 }

    # Accumulate annotation count within these hubs.
    count = 0
    hubs.each do |hub|
      count += hub.annotations.count
    end

    # Return the number.
    return count
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
end
