class WordTable

  # Find all related concepts in a project by text similarity.
  def self.text_similarity(concept_id, project_id)

    # Get the concept.
    concept = Concept.find(concept_id)

    # Generate unique word list for this concept.
    tokens = tokenise(concept)

    # Generate a new word table.
    table = create_word_table

    # Create similar concepts hash.
    similar = {}

    # Get results for each token.
    tokens.each do |token|

      # Get results for this token.
      results = token_similarity(token, table, project_id)

      # Aggregate results into similar hash.
      aggregate(similar, results)
    end

    # Return result.
    return similar
  end

  private

  # Provide an array of tokens based on a concept's description.
  def self.tokenise(concept)

    # Return tokens formed from lowercase symbol-less description.
    return concept.matchable_description.split
  end

  # Add a concept to the word table.
  def self.develop_word_table(concept, table)

    # Get the tokens for the current concept.
    tokens = tokenise(concept)

    # For each token:
    tokens.each do |token|

      # Check if word is already a word in the table.
      if table.key? token

        # Check if this concept has already registered this word.
        if table[token].key? concept.id

          # Increment word count for the concept.
          table[token][concept.id] += 1
        else

          # Add concept to this word listing.
          table[token][concept.id] = 1
        end

      else

        # Introduce the word into the words table.
        table[token] = {concept.id => 1}
      end
    end
  end

  # Provide a mapping of all words in the concept table.
  def self.create_word_table

    # Create word table for all concepts.
    table = {}

    # Populate word table.
    Concept.all.each do |concept|

      # Expand the word table by this word.
      develop_word_table(concept, table)
    end

    # Return complete word table.
    return table
  end

  # Get a list of results for a text similarity measure.
  def self.token_similarity(word, table, project_id)

    # Declare results list.
    results = {}

    # Find the project.
    project = Project.find(project_id)

    # If the word table contains the specified word:
    if table.key? word

      # Find list of matching concepts.
      matching = table[word]

      # Find inverse term frequency, idf.
      idf = Math.log(project.concepts.count / matching.keys.count.to_f)

      # Check each match.
      matching.keys.each do |match|

        # Find term frequency, tf, and compute tfidf for the results.
        results[match] = matching[match] * idf
      end
    end

    # Return results.
    return results
  end

  # Aggregate a response with the in-progress results hash.
  def self.aggregate(results, response)

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
