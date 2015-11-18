require 'set'

class Subgraphs

  # Constructor.
  def initialize(project)

    # Store the provided project.
    @project = Project.find(project)
  end

  # Create a string that represents this object.
  def to_s

    # Initialise string.
    s = ""

    # Print header.
    s << "Subgraph test on #{@project.id} - #{@project.name}\n"

    # Print data.
    s << "There are #{object_subgraphs} object subgraphs in this project.\n"

    # Return string.
    return s
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
