module SAGA

  class Base < SimilarityAlgorithm

    # Find a list of relevant suggestions.
    def suggestions

      # Find relevant entities.
      results = receive(initial_influence, 3)

      # Merge these results with popular entities.
      aggregate_popular(results)

      # Prepare results.
      filter(results)
      sort(results)

      # Return results.
      return results
    end

    # Receive influence from another entity.
    def receive(influence, propagations)

      # Determine what to do.
      # If at the natural end point:
      if propagations == 0

        # Assign influence to self and return.
        return { @element => influence }

      # Normal propagation step, otherwise.
      else

        # Determine influence allocation.
        return allocate(influence, propagations)
      end
    end

    # Determine what to do with influence.
    def allocate(influence, propagations)

      # Disperse to associated entities.
      disperse(influence, propagations)
    end

    # Propagate influence to other entities.
    def disperse(influence, propagations)

      # Determine the amount of influence each.
      amount = influence / (@element.associations.count + 1)

      # Create results hash, initialised with influence for popular entities.
      results = { popular_influence: amount }

      # Query each association.
      associations.each do |association|

        # Fetch results from associate.
        response = association.receive(amount, propagations - 1)

        # Merge response to results.
        aggregate(results, response)
      end

      # Return results.
      return results
    end

    private

    # Establish a cutoff point in results.
    def filter(results)

      # Establish the cutoff value.
      cutoff = 1.0 - results.values.min

      # For each result:
      results.keys.each do |key|

        # If a result is below the cutoff, remove result.
        if results[key] < cutoff
          results.delete key
        end
      end
    end

    # Sort results.
    def sort(results)

      # Sort results by score.
      results.sort_by {|key, value| value}.reverse.to_h
    end

    # Aggregate popular elements with the suggestions list.
    def aggregate_popular(results)

      # Get popular elements.
      popular_results = popular(results.delete :popular_influence)

      # Aggregate them into results.
      aggregate(results, popular_results)
    end

    # Aggregate a response with the in-progress results hash.
    def aggregate(results, response)

      # For each element in the response:
      response.keys.each do |key|

        # If the key is already in the results:
        if results.key? key

          # Add to the key's influence.
          results[key] += response[key]
        else

          # Introduce key to results with its influence.
          results[key] = response[key]
        end
      end
    end

  end

  class Object < Base

    private

    # Find inital influence.
    def initial_influence

      # Return 1.0 point of influence per association.
      return @element.project.concepts.count.to_f
    end

    # Find the most popular entities of this type.
    def popular(influence)

      # Return popular concepts in the project.
      return @element.project.popular_concepts(influence)
    end

    # Find all associations to this entity.
    def associations

      # Initialise array.
      associations = []

      # For each concept:
      @element.concepts.each do |concept|

        # Create a new wrapper concept.
        associations << SAGA::Concept.new(concept)
      end

      # Return complete list.
      return associations
    end

  end

  class Concept < Base

    private

    # Find inital influence.
    def initial_influence

      # Return 1.0 point of influence per association.
      return @element.project.digital_objects.count.to_f
    end

    # Find the most popular entities of this type.
    def popular(influence)

      # Return popular concepts in the project.
      return @element.project.popular_objects(influence)
    end

    # Find all associations to this entity.
    def associations

      # Initialise array.
      associations = []

      # For each object:
      @element.digital_objects.each do |object|

        # Create a new wrapper object.
        associations << SAGA::Object.new(object)
      end

      # Return complete list.
      return associations
    end

    # Find this Concept's cluster.
    def find_cluster(id)

      # Find the ids of concepts with similar text.
      cluster_id = WordTable.text_similarity(id)

      # Initialise concept cluster.
      cluster = {}

      # For each concept cluster id:
      cluster_id.keys.each do |key|

        # Find the specified concept.
        concept = @element.class.find(key)

        # Wrap concept in a SAGA concept.
        cluster[SAGA::Concept.new(concept)] = cluster_id[key]
      end

      # Return completed concept cluster listing.
      return cluster
    end

    # Signal all concepts within this cluster.
    def allocate(influence, propagations)

      # Find all cluster members.
      cluster = find_cluster(@element.id)

      # Determine portion of influence.
      portion = influence / cluster.values.reduce(:+)

      # Create results hash.
      results = {}

      # For each cluster member:
      cluster.keys.each do |key|

        # Call each member with their portion of total influence.
        response = key.disperse(cluster[key] * portion, propagations)

        # Assimilate response.
        aggregate(results, response)
      end

      # Return end result.
      return results
    end

  end

end
