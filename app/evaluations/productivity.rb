class Productivity

  # Constructor.
  def initialize(project_id)

    # Capture provided project.
    @project = Project.find(project_id)

    # Find this project's clusters.
    @clusters = cluster_annotations
  end

  # Create a string that represents this object.
  def to_s

    # Initialise string.
    s = ""

    # Print header.
    s << "Productivty test on #{@project.id} - #{@project.name}\n"

    # Print data.
    s << "Count: #{cluster_annotation_count} annotations.\n"
    s << "Period: #{cluster_annotation_period} seconds.\n"
    s << "Rate: #{cluster_annotation_rate} seconds per annotation.\n"

    # Return string.
    return s
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

    # Find count and period.
    cac = cluster_annotation_count
    cap = cluster_annotation_period

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
  def cluster_annotation_count

    # Define values.
    count = 0

    # Pass through clusters.
    @clusters.each do |cluster|

      # Increment totals.
      count += cluster[:count]
    end

    # Return total.
    return count
  end

  # Finds the length of time spent annotating.
  def cluster_annotation_period

    # Define values.
    time = 0.0

    # Pass through clusters.
    @clusters.each do |cluster|

      # Increment totals.
      time += (cluster[:end_time] - cluster[:start_time]).abs
    end

    # Return total.
    return time
  end
end
