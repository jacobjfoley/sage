class Complexity

  # Constructor.
  def initialize(project_id)

    # Store the provided project.
    @project = Project.find(project_id)
  end

  # Create a string that represents this object.
  def to_s

    # Initialise string.
    s = ""

    # Print header.
    s << "Complexity test on #{@project.id} - #{@project.name}\n"

    # Completeness.
    s << "Completeness:\n"
    s << "#{annotated_objects} (#{annotated_objects_ratio}) are annotated.\n"

    # Complexity.
    s << "\nComplexity:\n"
    s << "Leaves: #{object_leaves},"
    s << "Branches: #{object_branches},"
    s << "Ratio: #{object_branches_ratio}\n"

    # Object distributions.
    s << "\nObject Annotation Count Distributions:\n"
    object_annotation_distribution.each do |k, v|
      s << "#{k}: #{v}\n"
    end

    # Concept distributions.
    s << "\nConcept Annotation Count Distributions:\n"
    concept_annotation_distribution.each do |k, v|
      s << "#{k}: #{v}\n"
    end

    # Return string.
    return s
  end

  # Find the number of objects that have been annotated.
  def annotated_objects

    # Return the number of digital objects with at least one concept.
    return @project.digital_objects.select { |o| o.concepts.count > 0 }.count
  end

  # Find the ratio of annotated objects compared to the total.
  def annotated_objects_ratio

    # Return annotated ratio.
    if @project.digital_objects.empty?
      return 0.0
    else
      return (annotated_objects.to_f / @project.digital_objects.count).round(2)
    end
  end

  # Find the distribution of objects with varying annotation levels.
  def object_annotation_distribution

    # Get the project's digital objects annotation count mapping.
    mapping = Hash[@project.digital_objects.map {|o|
      [o, o.annotations.count]
    }]

    # Find the object with the highest number of annotations.
    max = mapping.values.max

    # Create results hash.
    results = {}

    # Define counts from 1 to max.
    (1..max).each do |index|
      results[index] = mapping.select { |k,v| v == index }.count}
    end

    # Return results.
    return results
  end

  # Find the distribution of concepts with varying annotation levels.
  def concept_annotation_distribution

    # Get the project's digital objects annotation count mapping.
    mapping = Hash[@project.concepts.map {|c|
      [c, c.annotations.count]
    }]

    # Find the concept with the highest number of annotations.
    max = mapping.values.max

    # Create results hash.
    results = {}

    # Define counts from 1 to max.
    (1..max).each do |index|
      results[index] = mapping.select { |k,v| v == index }.count}
    end

    # Return results.
    return results
  end

  # Find the number of objects that have only a single annotation.
  def object_leaves

    # Return the number of digital objects with at least one concept.
    return @project.digital_objects.select { |o| o.concepts.count == 1 }.count
  end

  # Find the number of objects with more than one annotation.
  def object_branches

    # Return the number of digital objects with at least one concept.
    return @project.digital_objects.select { |o| o.concepts.count > 1 }.count
  end

  # Find the ratio of branches compared to branches + leaves.
  def object_branches_ratio

    # Return annotated ratio.
    if @project.digital_objects == 0
      return 0.0
    else
      return (object_branches.to_f / annotated_objects).round(2)
    end
  end
end
