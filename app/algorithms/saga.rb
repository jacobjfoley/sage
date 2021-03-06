module SAGA

  class Base < SimilarityAlgorithm

    # Find a list of relevant suggestions.
    def suggestions

      # Find relevant entities.
      results = receive(initial_influence, 3)

      # Merge these results with popular entities.
      aggregate_popular(results)

      # Prepare results.
      results = filter_weak(results)
      results = sort(results)

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
      amount = influence / (@element.annotations.count + 1)

      # Create results hash, initialised with influence for popular entities.
      results = { popular_influence: amount }

      # Query each annotation.
      annotations.each do |annotation|

        # Fetch results from associate.
        response = annotation.receive(amount, propagations - 1)

        # Merge response to results.
        aggregate(results, response)
      end

      # Return results.
      return results
    end

    private

    # Establish a cutoff point in results.
    def filter_weak(results)

      # Define candidates.
      candidates = results.select { |key, value| value < 1.0 }

      # In the event of no weak candidates:
      if candidates.empty?

        # Unaltered results.
        return results
      end

      # Sort candidates.
      candidates = sort(candidates)

      # Find cumulative influence held by the candidates.
      influence = candidates.values.reduce(:+)

      # Find candidates who are to be deleted. The base algorithm will
      # show n suggestions below the normal cutoff point, where n is the number
      # of points of influence that were allocated to the filtered candidates.
      # This is intended to provide additional insight into what SAGA will and
      # will not filter, while still removing the very low-probability
      # suggestions which (cumulatively) have less than 1.0 point of influence.
      # SAGE uses this base algorithm by default, and also shows influence.
      # To remove all candidates below the cutoff (e.g. for evaluations),
      # use SAGA Refined instead (Concept_Refined and Object_Refined).
      weak_candidates = candidates.keys[influence.ceil..-1]

      # Delete those results which didn't make it.
      weak_candidates.each do |candidate|

        # Remove from results.
        results.delete candidate
      end

      # Return new results hash.
      return results
    end

    # Aggregate popular elements with the suggestions list.
    def aggregate_popular(results)

      # Get popular elements.
      popular_results = popular(results.delete :popular_influence)

      # Aggregate them into results.
      aggregate(results, popular_results)
    end

    # Allocate influence by popularity.
    def allocate_popular(popular, influence)

      # Determine count total.
      total = 0.0
      popular.values.each do |value|
        total += value
      end

      # Distribute influence accordingly.
      popular.keys.each do |key|
        popular[key] *= (influence / total)
      end

      # Return results.
      return popular
    end
  end

  class Object < Base

    private

    # Find inital influence.
    def initial_influence

      # Return 1.0 point of influence per annotation.
      return @element.project.concepts.count.to_f
    end

    # Find the most popular entities of this type.
    def popular(influence)

      # Return popular concepts in the project.
      return allocate_popular(@element.project.popular_concepts, influence)
    end

    # Find all annotations to this entity.
    def annotations

      # Initialise array.
      annotations = []

      # For each concept:
      @element.concepts.each do |concept|

        # Create a new wrapper concept.
        annotations << SAGA::Concept.new(concept)
      end

      # Return complete list.
      return annotations
    end

  end

  class Concept < Base

    private

    # Find inital influence.
    def initial_influence

      # Return 1.0 point of influence per annotation.
      return @element.project.digital_objects.count.to_f
    end

    # Find the most popular entities of this type.
    def popular(influence)

      # Return popular concepts in the project.
      return allocate_popular(@element.project.popular_objects, influence)
    end

    # Find all annotations to this entity.
    def annotations

      # Initialise array.
      annotations = []

      # For each object:
      @element.digital_objects.each do |object|

        # Create a new wrapper object.
        annotations << SAGA::Object.new(object)
      end

      # Return complete list.
      return annotations
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
        concept = ::Concept.find(key)

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

      # Find sum of cluster values.
      total = cluster.values.reduce(:+)

      # Create results hash.
      results = {}

      # If there are useful text similarity results:
      if total > 0

        # Divide influence into portions.
        portion = influence / total

        # For each cluster member:
        cluster.keys.each do |key|

          # Call each member with their portion of total influence.
          response = key.disperse(cluster[key] * portion, propagations)

          # Assimilate response.
          aggregate(results, response)
        end

      # If there are no useful text similarity results:
      else

        # Disperse via own associations only.
        results = disperse(influence, propagations)
      end

      # Return end result.
      return results
    end
  end

  class Object_Refined < Object

    # Establish a cutoff point in results.
    def filter_weak(results)

      # Find strong results.
      strong = results.select { |key, value| value >= 1.0 }

      # Find confirmed results.
      confirmed = results.select { |key, value| @element.related.include? key }

      # Return new results hash.
      return strong.merge(confirmed)
    end
  end

  class Concept_Refined < Concept

    # Establish a cutoff point in results.
    def filter_weak(results)

      # Find strong results.
      strong = results.select { |key, value| value >= 1.0 }

      # Find confirmed results.
      confirmed = results.select { |key, value| @element.related.include? key }

      # Return new results hash.
      return strong.merge(confirmed)
    end
  end

end
