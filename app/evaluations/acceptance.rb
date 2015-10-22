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
  def initialize(project_id)

    # Capture the parent project, whose samples are being analysed.
    @project = Project.find(project_id)

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
      lc = leaf_count(sample)
      bc = branch_count(sample)
      record[:leaf_count] << lc
      record[:branch_count] << bc
      record[:branch_ratio] << branch_ratio(lc, bc)

      # Work performance.
      record[:annotation_count] << sample.annotations.count
      clusters = cluster_annotations(sample)
      cac = cluster_annotation_count(clusters)
      cap =  cluster_annotation_period(clusters)
      record[:cluster_count] << cac
      record[:cluster_period] << cap
      record[:cluster_rate] << cluster_annotation_rate(cac, cap)

      # Suggestion acceptance.
      a = accepted(sample)
      c = created(sample)
      record[:accepted] << a
      record[:created] << c
      record[:accepted_ratio] << accepted_ratio(a, c)
    end
  end

  # Calculate count, min, max, mean, and standard deviation of each measurement.
  def summarise_results

    # For each algorithm record:
    @records.keys.each do |algorithm|

      # Get the record.
      record = @records[algorithm]

      # Initialise the summary hash.
      summary = {}

      # For each measurement:
      record.keys.each do |measurement|

        # Summarise this measurement.
        summary[measurement] = summarise(record[measurement])
      end

      # Add the summary details to the record.
      record[:sample_count] = record[:object_count].count
      record[:summary] = summary
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
    else

      # Default to zero.
      summary[:min] = 0
      summary[:max] = 0
      summary[:mean] = 0
      summary[:std_dev] = 0
    end

    # Return result.
    return summary
  end

  # Returns an array of annotation clusters.
  def cluster_annotations(sample)

    # Get annotations.
    annotations = sample.annotations.order(:created_at)

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
  def cluster_annotation_rate(cac, cap)

    # If the cluster annotation period is greater than zero:
    if cap > 0

      # Return average annotations/minute.
      return cac * 60.0 / cap
    else

      # Return zero.
      return 0.0
    end
  end

  # Finds the number of annotations in clusters.
  def cluster_annotation_count(clusters)

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
  def cluster_annotation_period(clusters)

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
  def leaf_count(sample)

    # Return the number.
    return sample.concepts.select { |concept| concept.annotations.count == 1 }.count
  end

  # Find the number of concepts with many annotations.
  def branch_count(sample)

    # Return the number.
    return sample.concepts.select { |concept| concept.annotations.count > 1 }.count
  end

  # Find the proportion of branch concepts.
  def branch_ratio(lc, bc)

    # Find total.
    total = lc + bc

    # Return the percentage, or 0 if no concepts.
    if total > 0
      return bc.to_f / total
    else
      return 0.0
    end
  end

  # Find the number of annotations created via the add button.
  def accepted(sample)

    # Return the number of annotations created via this provenance.
    return sample.annotations.where(provenance: "Existing").count
  end

  # Find the number of annotations created via the quick create button.
  def created(sample)

    # Return the number of annotations created via this provenance.
    return sample.annotations.where(provenance: "New").count
  end

  # Find the acceptance ratio.
  def accepted_ratio(accepted_count, created_count)

    # Find the total annotation count.
    total = accepted_count + created_count

    # Return the proportion of accepted to total annotations.
    if total > 0

      # Return proportion.
      return accepted_count.to_f / total
    else

      # Return zero, Avoid divide-by-zero error.
      return 0.0
    end
  end
end
