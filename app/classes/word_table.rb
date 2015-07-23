class WordTable

  ##
  # Find all related concepts in a project by text similarity.
  # @return [Hash]
  #   Concept ids paired with their similarity score.
  def self.text_similarity(concept_id)

    # Find the project this concept is associated with.
    project_id = Concept.find(concept_id).project_id

    # Generate a new word table.
    table = create_word_table(project_id)

    # Find matching concepts.
    matching = partial_matches(concept_id, table)

    # Create similar concepts hash.
    similar = {}

    # Original concept vector.
    concept_vector = vector_for(concept_id, table)

    # For every matching concept:
    matching.each do |match|

      # Calculate the vector for this concept.
      other_vector = vector_for(match, table)

      # Find the distance between original and prospective concept.
      similar[match] = cosine_similarity(concept_vector, other_vector)
    end

    # Return result.
    return similar
  end

  private

  ##
  # Find the cosine similarity between two vectors.
  def self.cosine_similarity(vector1, vector2)

    # Find the dot product of the two vectors.
    product = dot_product(vector1, vector2)

    # Find the summed euclidean distance of the two vectors.
    distance = euclidean_distance(vector1) + euclidean_distance(vector2)

    # Divide and return dot product by distance.
    return product / distance
  end

  ##
  # Provide a mapping of all words in the concept table.
  def self.create_word_table(project_id)

    # Create word table for all concepts.
    table = {}

    # Get the project.
    project = Project.find(project_id)

    # Populate word table.
    project.concepts.each do |concept|

      # Expand the word table by this word.
      develop_word_table(concept.id, table)
    end

    # Return complete word table.
    return table
  end

  ##
  # Add a concept to the word table.
  def self.develop_word_table(concept_id, table)

    # Get the tokens for the current concept.
    tokens = tokenise(concept_id)

    # For each token:
    tokens.each do |token|

      # Check if word is already a word in the table.
      if table.key? token

        # Check if this concept has already registered this word.
        if table[token].key? concept_id

          # Increment word count for the concept.
          table[token][concept_id] += 1
        else

          # Add concept to this word listing.
          table[token][concept_id] = 1
        end

      else

        # Introduce the word into the words table.
        table[token] = {concept_id => 1}
      end
    end
  end

  ##
  # Find the dot product between two vectors.
  def self.dot_product(vector1, vector2)

    # Initialise result.
    result = 0.0

    # Determine combined component list.
    components = (vector1.keys + vector2.keys).uniq

    # Multiply and sum each component.
    components.each do |component|

      # Default components.
      vector1_component = 0.0
      vector2_component = 0.0

      # Establish components if present.
      vector1_component = vector1[component] if vector1.has_key? component
      vector2_component = vector2[component] if vector2.has_key? component

      # Multiply components and add to total.
      result += vector1_component * vector2_component
    end

    # Return result.
    return result
  end

  ##
  # Find the euclidean distance between a vector's components.
  def self.euclidean_distance(vector)

    # Initialise result.
    result = 0.0

    # For each component:
    vector.keys.each do |key|

      # Square and sum each component.
      result += vector[key] ** 2
    end

    # Take the square root of the sum.
    result = Math.sqrt(result)

    # Return result.
    return result
  end

  ##
  # Find all partial or complete matches to the given concept.
  def self.partial_matches(concept_id, table)

    # Generate unique word list for this concept.
    tokens = tokenise(concept_id)

    # Initialise matching.
    matching = []

    # For each token in this concept:
    tokens.each do |token|

      # For each concept that shares this token:
      matching.concat(table[token].keys)
    end

    # Filter duplicates.
    matching.uniq!

    # Return results.
    return matching
  end

  ##
  # Get the tf-idf score for the given token.
  def self.tf_idf(token, table, concept_id)

    # Initialise result.
    result = 0.0

    # If the word table contains the specified word:
    if (table.has_key? token) && (table[token].has_key? concept_id)

      # Get term frequency, tf, for this word.
      tf = table[token][concept_id]

      # Get the project.
      project = Concept.find(concept_id).project

      # Find inverse term frequency, idf.
      idf = Math.log(project.concepts.count / (table[token].size.to_f))

      # Compute tfidf for the results.
      result = tf * idf
    end

    # Return results.
    return result
  end

  ##
  # Provide an array of tokens based on a concept's description.
  def self.tokenise(concept_id)

    # Get the concept.
    concept = Concept.find(concept_id)

    # Return tokens formed from lowercase symbol-less description.
    return concept.matchable_description.split
  end

  ##
  # Find the vector for a given concept.
  def self.vector_for(concept_id, table)

    # Get a list of tokens for this concept.
    tokens = tokenise(concept_id)

    # Initialise vector.
    vector = {}

    # Move through all tokens.
    tokens.each do |token|

      # Calculate tf-idf for each token.
      vector[token] = tf_idf(token, table, concept_id)
    end

    # Return completed vector.
    return vector
  end
end
