class DigitalObject < ActiveRecord::Base

  # Associations with other models.
  has_and_belongs_to_many :concepts
  belongs_to :project

  # Validations.
  validates :location, presence: true

  # Find relevant objects.
  def relevant

    # Calculate influence to spread.
    influence = project.concepts.count

    # Default influence, three steps (find concept), hasn't dispersed yet.
    results = collaborate(influence, 3, false)

    # Calculate absorbed influence.
    absorbed = 0.0
    concepts.each do |concept|
      absorbed += results[concept]
    end

    # Calculate missing influence.
    missing = influence
    results.keys.each do |key|
      missing -= results[key]
    end

    # Distribute consumed and absorbed influence among popular.
    popular = project.popular_concepts(absorbed+missing)

    # Merge harmonic intuition results with popular.
    aggregate(results, popular)

    # # Filter weak results.
    # results.keys.each do |key|
    #   if results[key] < 1.0
    #     results.delete key
    #   end
    # end

    # Return filtered results.
    return results
  end

  # Collaborate with other agents to detect relationships within the project.
  def collaborate(influence, propagations, dispersal)

    # Determine what to do.
    # If at the natural end point:
    if propagations == 0

      # Assign influence to self and return.
      return {self => influence}

    # If at a termination point due to lack of associations:
    elsif concepts.count == 0

      # Consume influence and return nothing.
      return {}

    # Normal propagation step, otherwise.
    else

      # Create empty results hash.
      results = {}

      # Determine the amount of influence each.
      amount = influence / concepts.count

      # Query each association.
      concepts.each do |concept|

        # Fetch results from associate.
        response = concept.collaborate(amount, propagations - 1, dispersal)

        # Merge response to results.
        aggregate(results, response)

      end

      # Return results.
      return results

    end
  end

  # Private methods.
  private

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
