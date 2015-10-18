# Acceptance
# Calculates metrics for a project that has been used to create samples. This
# allows multiple algorithms to be compared against one another in terms of
# user acceptance/performance.
# Data available in the following format:
# @records[:algorithm][:measurement][:count|:min|:max|:mean|:std_dev]
class Acceptance

  attr_reader :project
  attr_reader :records

  # Constructor.
  def initialize(project)

    # Capture the parent project, whose samples are being analysed.
    @project = Project.find(project)

    # Storage for each algorithm's measurements.
    @records = {}

    # Evaluate samples.
    evaluate_samples

    # Summarise results.
    summarise_results
  end

  # Introduce an algorithm to the measurements.
  def introduce(algorithm)

    # Create new record.
    @records[algorithm] = {

      # Entity counts.
      object_count: [],

      # Information complexity.
      concept_count: [],
      leaf_count: [],
      branch_count: [],
      branch_ratio: [],

      # Work performance.
      annotation_count: [],
      cluster_count: [],
      cluster_period: [],
      cluster_rate: [],

      # Suggestion acceptance.
      accepted: [],
      created: [],
      accepted_ratio: [],
    }
  end

  # Evaluate samples produced from a parent project.
  def evaluate_samples

    # Find all samples.
    samples = Project.where(parent: @project)

    # Run through each sample.
    samples.each do |sample|

      # Determine if this algorithm is new.
      if !@records.key? sample.algorithm

        # Introduce the algorithm to the measurements.
        introduce(sample.algorithm)
      end

      # Fetch algorithm's record.
      record = @records[sample.algorithm]

      # Entity counts.
      record[:object_count] << sample.digital_objects.count

      # Information complexity.
      record[:concept_count] << sample.concepts.count
      record[:leaf_count] << leaf_count
      record[:branch_count] << branch_count
      record[:branch_ratio] << branch_ratio

      # Work performance.
      record[:annotation_count] << sample.annotations.count
      record[:cluster_count] << cluster_annotation_count
      record[:cluster_period] << cluster_annotation_period
      record[:cluster_rate] << cluster_annotation_rate

      # Suggestion acceptance.
      record[:accepted] << accepted
      record[:created] << created
      record[:accepted_ratio] << accepted_ratio
    end
  end

  # Calculate count, min, max, mean, and standard deviation of each measurement.
  def summarise_results

    # For each algorithm record:
    @records.keys.each do |algorithm|

      # Get the record.
      record = @records[algorithm]

      # Find the number of samples for this algorithm.
      samples = record[:object_count].count

      # For each measurement:
      record.keys.each do |measurement|

        # Summarise this measurement.
        record[measurement] = summarise(record[measurement])
      end

      # Record the number of samples.
      record[:sample_count] = samples
    end
  end

  # Summarise an array of measurements.
  def summarise(raw)

    # Create empty summary hash.
    summary = {}

    #Calculate count.
    count = raw.count

    # For non-empty measurements hashes:
    if count > 0

      # Calculate min and max.
      summary[:min] = raw.min
      summary[:max] = raw.max

      # Calculate mean average.
      summary[:mean] = raw.reduce(:+).to_f / count

      # Calculate variance.
      variance = raw.reduce(0.0) {
        |total, value| total + (value - summary[:mean]) ** 2
      } / count

      # Calculate standard deviation.
      summary[:std_dev] = Math.sqrt(variance)
    end

    # Return result.
    return summary
  end

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

  # Finds the average annotation rate in annotations/minute.
  def cluster_annotation_rate

    # Return average annotations/minute.
    return cluster_annotation_count * 60 / cluster_annotation_period
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

  # Find the number of concepts with one annotation.
  def leaf_count

    # Return the number.
    return @project.concepts.select { |concept| concept.annotations.count == 1 }.count
  end

  # Find the number of concepts with many annotations.
  def branch_count

    # Return the number.
    return @project.concepts.select { |concept| concept.annotations.count > 1 }.count
  end

  # Find the proportion of branch concepts.
  def branch_ratio

    # Return the percentage, or 0 if no concepts.
    if @project.concepts.count > 0
      return branch_rate.to_f / @project.concepts.count
    else
      return 0.0
    end
  end

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

  # Find the acceptance ratio.
  def accepted_ratio

    # Return the proportion of accepted to total annotations.
    return accepted.to_f / accepted + created
  end
end
