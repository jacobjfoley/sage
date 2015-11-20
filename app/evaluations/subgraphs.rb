require 'set'

class Subgraphs

  # Constructor.
  def initialize(project)

    # Store the provided project.
    @project = Project.find(project)

    # Find all subgraphs.
    @subgraphs = object_subgraphs
  end

  # Create a string that represents this object.
  def to_s

    # Initialise string.
    s = ""

    # Print header.
    s << "Subgraph test on #{@project.id} - #{@project.name}\n"

    # Print data.
    s << "There are #{object_subgraph_count} subgraphs in this project.\n"

    # Print summary.
    s << "#{object_subgraph_summary}\n"

    # Print individual details
    object_subgraph_details.each_with_index do |detail, index|
      s << "Subgraph #{index}: #{detail} objects.\n"
    end

    # Return string.
    return s
  end

  # Find the number of subgraphs in this project.
  def object_subgraph_count

    # Return the number of subgraphs.
    return @subgraphs.count
  end

  # Display details about each subgraph.
  def object_subgraph_details

    # Return the counts per subgraph.
    return @subgraphs.map { |s| s.count }
  end

  # Find the number of objects in each subgraph.
  def object_subgraph_summary

    # Return counts summary.
    return Measurement.new("Subgraph Object Counts", object_subgraph_details)
  end

  # Find the object subgraphs in this project.
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

    # Return the subgraphs found.
    return subgraphs
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
