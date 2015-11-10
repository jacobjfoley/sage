require 'set'

class Complexity

  # Constructor.
  def initialize(project)

    # Store the provided project.
    @project = Project.find(project)
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
      return annotated_objects / @project.digital_objects.count
    end
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
    if @project.annotated_objects == 0
      return 0.0
    else
      return object_branches / annotated_objects
    end
  end

  # Find the number of subgraphs in this project.
  def object_subgraphs

    # Array of subgraphs.
    subgraphs = []

    # Set of unvisited objects.
    unvisited = Set.new(
      @project.digital_objects.select { |o| o.concepts.count > 0 }
    )

    # While there are still unvisited objects:
    while !unvisited.empty?

        # Find the next set of objects.
        set = find_set(unvisited.first)

        # Remove items in this set from unvisited.
        unvisited.subtract(set)

        # Store set in subgraphs.
        subgraphs << set
    end

    # Return the number of subgraphs found.
    return subgraphs.count
  end

  # Find the set of objects associated to the given object via concepts.
  def find_set(object)

    # Track the last and current sets of found objects.
    last = Set.new
    current = Set.new([object])

    # While the last set is different to the current set:
    while last != current

      # Update last.
      last = current

      # Get the set of concepts linked to objects in the last set.
      concepts = Set.new(last.inject([]) { |all, o| all + o.concepts })

      # Get the set of objects linked to the concept set.
      current = Set.new(concepts.inject([]) {|all, c| all + c.digital_objects })
    end

    # Return the current set.
    return current
  end
end
