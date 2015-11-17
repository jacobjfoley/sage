module All

  class Base < SimilarityAlgorithm

    # Find suggestions.
    def suggestions

      # Initialise results
      results = {}

      # Populate results.
      entities.each do |entity|

        # Each entity has a random score.
        results[entity] = 1.0
      end

      # Sort results.
      results = sort(results)

      # Return results.
      return results
    end
  end

  class Object < Base

    # Find all entities.
    def entities

      # Find all concepts associated with this element.
      return @element.project.concepts
    end
  end

  class Concept < Base

    # Find all entities.
    def entities

      # Find all objects associated with this element.
      return @element.project.digital_objects
    end
  end

end
