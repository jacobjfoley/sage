class Acceptance

  # Constructor.
  def initialize(project)

    # Capture the parent project, whose samples are being analysed.
    @project = project

    # Storage for each algorithm's measurements.
    @measurements = {}
  end

  # Introduce an algorithm to the measurements.
  def introduce(algorithm)

    # Introduce algorithm.
    @measurements[algorithm] = {
      annotation_count_total: 0,
      concept_count: 0,
      object_count: 0,

      annotation_count: 0,
      annotation_period: 0.0,
      annotation_rate: 0.0,

      one: 0,
      many: 0,
      reuse: 0.0,

      accepted: 0,
      created: 0,
      to_many: 0,
    }
  end

  # Evaluate samples produced from a parent project.
  def evaluate_samples

    # Find all samples.
    samples = Project.where(parent: project)

    # Run through each sample.
    samples.each do |sample|

      # Get the algorithm.
      algorithm = sample.algorithm

      # Determine if this algorithm is new.
      if !@measurements.key? algorithm

        # Introduce the algorithm to the measurements.
        introduce(algorithm)
      end

      # Record overall details.
      @measurements[algorithm][:annotation_count_total] += @project.annotations.count
      @measurements[algorithm][:concept_count] += @project.concepts.count
      @measurements[algorithm][:object_count] += @project.digital_objects.count

      # Record cluster details.
      @measurements[algorithm][:annotation_count] += cluster_annotation_count
      @measurements[algorithm][:annotation_period] += cluster_annotation_period
      @measurements[algorithm][:annotation_rate] += cluster_annotation_rate

      # Record structural details.
      @measurements[algorithm][:one] += one_rate
      @measurements[algorithm][:many] += many_rate
      @measurements[algorithm][:reuse] += reuse_rate

      # Record acceptance details.
      @measurements[algorithm][:accepted] += accepted
      @measurements[algorithm][:created] += created
      @measurements[algorithm][:to_many] += to_many_rate
    end
  end

  # Display results of analysis.
  def display_results

    # For each algorithm:
    @measurements.keys.each do |algorithm|

      # Fetch hash for this algoritm.
      m = @measurements[algorithm]

      # Calculate averages.
      avg_annotation_count_total = m[:annotation_count_total].to_f / m[:count]
      avg_annotation_count = m[:annotation_count].to_f / m[:count]
      avg_annotation_period = m[:annotation_period] / (60 * m[:count])
      avg_annotation_rate = m[:annotation_rate] / m[:count]
      avg_one = m[:one].to_f / m[:count]
      avg_many = m[:many].to_f / m[:count]
      avg_reuse = m[:reuse] / m[:count]
      avg_accepted = m[:accepted].to_f / m[:count]
      avg_created = m[:created].to_f / m[:count]
      avg_concepts = m[:concept_count].to_f / m[:count]
      avg_to_many = m[:to_many].to_f / m[:count]

      # Calculate proportion.
      if (avg_accepted > 0 || avg_created > 0)
        proportion = avg_accepted * 100.0 / (avg_accepted + avg_created)
      else
        proportion = 0.0
      end

      # Calculate hub rate.
      if (avg_to_many > 0 || avg_one > 0)
        avg_to_hub_rate = avg_to_many * 100.0 / (avg_to_many + avg_one)
      else
        avg_to_hub_rate = 0.0
      end

      # Print results.
      puts "Algorithm: #{algorithm}"
      puts "\n"
      puts "-- Averages #{avg_annotation_count_total} annotations per sample."
      puts "-- Averages #{avg_annotation_count} annotations in clusters per sample."
      puts "\n"
      puts "-- Averages #{avg_annotation_period.round(2)} minutes per sample."
      puts "-- Averages #{avg_annotation_rate.round(2)} annotations/minute."
      puts "\n"
      puts "-- Annotations to one-off concepts: #{avg_one}"
      puts "-- Annotations to hub concepts: #{avg_to_many}."
      puts "-- Hub annotation proportion: #{avg_to_hub_rate}%."
      puts "\n"
      puts "-- Averages #{avg_concepts} concepts."
      puts "-- One-off concept: #{avg_one}"
      puts "-- Hub concepts: #{avg_many}."
      puts "-- Hub concept proportion: #{avg_reuse.round(0)}%."
      puts "\n"
      puts "-- Accepted: #{avg_accepted}, Created: #{avg_created}."
      puts "-- Proportion (Accepted/All): #{proportion.round(2)}%."
      puts "\n"
    end
  end

  ### Clustering ###

  # Returns an array of annotation clusters.
  def cluster_annotations

    # Get annotations.
    annotations = @project.annotations.order(:created_at)

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

  ### Accepted ###

  # Find the number of annotations created via the add button.
  def accepted

    # Return the number of annotations created via this provenance.
    return @project.annotations.where(provenance: "Existing").count
  end

  # Find the number of annotations created via the quick create button.
  def created

    # Return the number of annotations created via this provenance.
    return @project.annotations.where(provenance: "New").count
  end

  ### Link Analysis ###

  # Find the number of annotations which link to a well-annotated concept.
  def to_many_rate

    # Find the "hub" concepts with > 1 annotation.
    hubs = @project.concepts.select { |concept| concept.annotations.count > 1 }

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
    return @project.concepts.select { |concept| concept.annotations.count == 1 }.count
  end

  # Find the number of concepts with many annotations.
  def many_rate

    # Return the number.
    return @project.concepts.select { |concept| concept.annotations.count > 1 }.count
  end

  # Find the proportion of reused concepts vs single concepts.
  def reuse_rate

    # Return the percentage, or 0 if no concepts.
    if @project.concepts.count > 0
      return many_rate.to_f * 100 / @project.concepts.count
    else
      return 0.0
    end
  end
end
