class SimilarityAlgorithm

  ##
  # Store a given element as base data for this object.
  #
  # @param [Object] element
  #   The base data for this object.
  def initialize(element)

    # Bind element to this object.
    @element = element
  end

  ##
  # Returns a hash of { element_id: score } entries as suggestions for
  # the element this object represents.
  #
  # @return [Hash]
  #   { element_id: score } pairs representing other elements and similarity.
  def suggestions

    # Implementation specific. Return no results.
    return {}
  end

  private

  ##
  # Sort results.
  #
  # @param [Hash] results
  #   {entity_id: score} pairs to sort.
  def sort(results)

    # Sort results by score.
    return results.sort_by {|key, value| value}.reverse.to_h
  end

end
