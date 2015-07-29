module Rank

  class Base < SimilarityAlgorithm

    # Constructor.
    def initialize(element)

      # Call to super.
      super(element)

      # Define variables.
      @m = 10
    end

    # Find the top m results.
    def top_co_occurrences

      # Get sorted co-occurrences.
      list = sort(co_occurrences)

      # Initialise results.
      results = {}

      # For the m top entries in list:
      list.keys[0...@m].each do |key|

        # Define results entry for key.
        results[key] = list[key]
      end

      # Return results.
      return results
    end

    # Find co-occurrence counts with other concepts.
    def co_occurrences

      # Initialize list.
      list = {}

      # Check each member association:
      @element.related.each do |association|

        # Initialize mapping.
        mapping = {}

        # For each co_occurring entity:
        association.related.each do |co_occurring|

          # Include it in the mapping.
          mapping[co_occurring] = 1
        end

        # Aggregate mapping for this object into overall list.
        aggregate(list, mapping)
      end

      # Return list.
      return list
    end

    # Promote a recommedation according to its characteristics.
    def promotion(other_entity)

      # Return product of rank, stability and descriptive.
      return rank(other_entity) * stability * descriptive(other_entity)
    end

    # Promote highly-ranked entities.
    def rank(other_entity)

      # Find rank position.
      rank_position = top_co_occurrences.keys.index(other_entity)

      # Return result.
      return @kr.to_f / (@kr + rank_position)
    end

    # Promote well-annotated entities.
    def stability

      # Find association count.
      count = @element.associations.count

      # Return result.
      return  @ks.to_f / (@ks + (@ks - Math.log(count)).abs)
    end

    # Dampen frequent entities.
    def descriptive(other_entity)

      # Find association count.
      count = other_entity.associations.count

      # Return result.
      return  @kd.to_f / (@kd + (@kd - Math.log(count)).abs)
    end
  end

  class Vote < Base

    # Find suggestions.
    def suggestions

      # Perform voting on all associations.
      return sort(vote_each)
    end

    # Vote on each association.
    def vote_each

      # Initialise results.
      results = {}

      # For each entity associated with this element:
      @element.related.each do |association|

        # Wrap in algorithm.
        result = wrap(association).vote

        # Aggregate results.
        aggregate(results, result)
      end

      # Return results.
      return results
    end

    # Returns the members of the top list.
    def vote

      # Initialise results.
      results = {}

      # For each key in the top list:
      top_co_occurrences.keys.each do |key|

        # Add it to the vote mapping.
        results[key] = vote_score(key)
      end

      # Return results. Entities present in the top co-occurring list have a
      # value of 1, all other entities are excluded, thus implicitly 0.
      return results
    end

    # Score to assign to entity.
    def vote_score(other_entity)

      # Return result.
      return 1
    end

    # Create a new instance of this class.
    def wrap(element)

      # Return new instance.
      return Vote.new(element)
    end
  end

  class Sum < Base

    # Find suggestions.
    def suggestions

      # Perform summing on all associations.
      return sort(sum_each)
    end

    # Sum on each association.
    def sum_each

      # Initialise results.
      results = {}

      # For each entity associated with this element:
      @element.related.each do |association|

        # Sum using this association.
        result = wrap(association).sum

        # Aggregate results.
        aggregate(results, result)
      end

      # Return results.
      return results
    end

    # Find the weighted co-occurrence sum with another entity.
    def sum

      # Initialise results.
      results = {}

      # Get the top list.
      list = top_co_occurrences

      # For each key in the top list:
      list.keys.each do |key|

        # Number of co-occurrences divided by tag count.
        results[key] = sum_score(key, list[key])
      end

      # Return results.
      return results
    end

    # Score to assign to entity.
    def sum_score(other_entity, co_occurrence)

      # Return result.
      return co_occurrence.to_f / @element.associations.count
    end

    # Create a new instance of this class.
    def wrap(element)

      # Return new instance.
      return Sum.new(element)
    end

  end

  class VotePlus < Vote

    # Constructor.
    def initialize(element)

      # Call to super.
      super(element)

      # Configure tuning variables.
      @m = 25
      @ks = 9
      @kd = 11
      @kr = 4
    end

    # Create a new instance of this class.
    def wrap(element)

      # Return new instance.
      return VotePlus.new(element)
    end

    # Score to assign to entity.
    def vote_score(other_entity)

      # Define base.
      base = 1

      # Return base weighted by promotion.
      return base * promotion(other_entity)
    end
  end

  class SumPlus < Sum

    # Constructor.
    def initialize(element)

      # Call to super.
      super(element)

      # Configure tuning variables.
      @m = 25
      @ks = 10
      @kd = 12
      @kr = 3
    end

    # Create a new instance of this class.
    def wrap(element)

      # Return new instance.
      return SumPlus.new(element)
    end

    # Score to assign to entity.
    def sum_score(other_entity, co_occurrence)

      # Define base.
      base = co_occurrence.to_f / @element.associations.count

      # Return result.
      return base * promotion(other_entity)
    end
  end

end
