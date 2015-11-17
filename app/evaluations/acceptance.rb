class Acceptance

  # Constructor.
  def initialize(project_id)

    # Capture the parent project, whose samples are being analysed.
    @project = Project.find(project_id)
  end

  # Find the number of annotations created via the add button.
  def accepted(annotations = @project.annotations)

    # Return the number of annotations created via this provenance.
    return annotations.select { |a| a.provenance.eql? "Existing" }.count
  end

  # Find the number of annotations created via the quick create button.
  def created(annotations = @project.annotations)

    # Return the number of annotations created via this provenance.
    return annotations.select { |a| a.provenance.eql? "New" }.count
  end

  # Find the acceptance ratio.
  def acceptance_ratio(annotations = @project.annotations)

    # Find accepted and created.
    accepted_count = accepted(annotations)
    created_count = created(annotations)

    # Find the total annotation count.
    total = accepted_count + created_count

    # Return the proportion of accepted to total annotations.
    if total > 0
      return (accepted_count.to_f / total).round(2)
    else
      return 0.0
    end
  end

  # Partition a sample's annotations into n groups.
  def partition_acceptance_ratio(partitions = 1)

    # Get the annotations from this sample.
    annotations = @project.annotations.order(:created_at)

    # Split these annotations into partitions.
    partitions = annotations.in_groups(partitions, false)

    # Create a results array.
    results = []

    # For each partition, calculate accepted ratio.
    partitions.each do |partition|
      results << acceptance_ratio(partition)
    end

    # Return the number of annotations created via this provenance.
    return results
  end
end
