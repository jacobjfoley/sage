require "securerandom"

class Project < ActiveRecord::Base

  # Associations with other models.
  has_many :concepts, dependent: :destroy
  has_many :digital_objects, dependent: :destroy
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  # Validations.
  validates :name, presence: true, length: { minimum: 1 }
  validates :viewer_key, uniqueness: true, allow_nil: true
  validates :contributor_key, uniqueness: true, allow_nil: true
  validates :administrator_key, uniqueness: true, allow_nil: true

  # Find suggestions based on concept description.
  def disperse(influence, propagations, description)

    # Find all similar concepts to the provided description.
    similar = similar_text(description)

    # Determine total weight in results.
    total = 0
    similar.values.each do |value|
      total += value
    end

    # Distribute influence according to similarity score.
    similar.keys.each do |key|
      similar[key] *= influence / total
    end

    # Create results hash.
    results = {}

    # For each similar result:
    similar.keys.each do |key|

      # Call each similar concept with their portion of total influence.
      response = key.collaborate(similar[key], propagations, true)

      # Assimilate response.
      aggregate(results, response)
    end

    # Return end result.
    return results
  end

  # Find most popular concepts.
  def popular_concepts(influence)

    # Declare results hash.
    results = {}

    # Determine count of each concept.
    concepts.each do |concept|
      results[concept] = concept.digital_objects.count + 1
    end

    # Determine count total.
    total = 0.0
    results.values.each do |value|
      total += value
    end

    # Distribute influence accordingly.
    results.keys.each do |key|
      results[key] *= (influence / total)
    end

    # Return results.
    return results
  end

  # Find most popular objects.
  def popular_objects(influence)

    # Declare results hash.
    results = {}

    # Determine count of each object.
    digital_objects.each do |object|
      results[object] = object.concepts.count + 1
    end

    # Determine count total.
    total = 0.0
    results.values.each do |value|
      total += value
    end

    # Distribute influence accordingly.
    results.keys.each do |key|
      results[key] *= influence / total
    end

    # Return results.
    return results
  end

  # Generate a new access key.
  def generate_key(type)

    # Create global list of keys.
    all_keys = []
    Project.all.each do |project|
      all_keys << project.viewer_key
      all_keys << project.contributor_key
      all_keys << project.administrator_key
    end

    # Initialise key to not unique.
    key = nil
    unique = false

    # Continue generating and checking keys until a unique key is generated.
    while !unique

      # Generate a new key.
      key = SecureRandom.base64

      # Check for uniqueness across database.
      unique = !(all_keys.include? key)
    end

    # Determine which key to assign and set it.
    if (type.eql? "Viewer")
      self.viewer_key = key
    elsif (type.eql? "Contributor")
      self.contributor_key = key
    elsif (type.eql? "Administrator")
      self.administrator_key = key
    end
  end

  # Reset an access key.
  def reset_key(type)

    # Determine which key to reset, and disable it.
    if (type.eql? "Viewer")
      self.viewer_key = nil
    elsif (type.eql? "Contributor")
      self.contributor_key = nil
    elsif (type.eql? "Administrator")
      self.administrator_key = nil
    end
  end

  # Check an access key.
  def self.check_key(key, user)

    # Create global mapping of keys.
    all_keys = {}
    Project.all.each do |project|
      all_keys[project.viewer_key] = {project: project, position: "Viewer"}
      all_keys[project.contributor_key] = {project: project, position: "Contributor"}
      all_keys[project.administrator_key] = {project: project, position: "Administrator"}
    end

    # Check if provided key is present.
    if (all_keys.key?(key) && !(key.nil?))

      # Get details.
      project = all_keys[key][:project]
      position = all_keys[key][:position]

      # Check for prior role.
      prior = UserRole.where(user_id: user.id, project_id: project.id)

      # Assign user role within project if the user has none already.
      if prior.count == 0

        # Create new role.
        UserRole.create(user_id: user.id, project_id: project.id, position: position)

        # Return success.
        return "You have successfully been added to the project."
      else

        # Check for upgrade.
        if position.eql? "Administrator"
          prior.first.update(position: "Administrator")
        elsif (prior.first.position.eql?("Viewer") && position.eql?("Contributor"))
          prior.first.update(position: "Contributor")
        else
          return "You already have an equal or better role in the project."
        end

        # Return success.
        return "You have successfully been promoted in the project."
      end
    else

      # Return error.
      return "Your key does not exist, or no longer exists, in any project."
    end
  end

  # Private methods.
  private

  # Provide an array of tokens based on description.
  def tokenise(description)

    # Return tokens formed from lowercase symbol-less description.
    return description.downcase.gsub(/[^a-z0-9\s]/i, '').split
  end

  # Provide a mapping of all words in the concept table.
  def word_table

    # Create word table for all concepts.
    words = {}

    # Populate word table.
    concepts.each do |concept|

      # Get the tokens for the current concept.
      tokens = tokenise(concept.description)

      # For each token:
      tokens.each do |word|

        # Check if word is already a word in the table.
        if words.key? word

          # Check if this concept has already registered this word.
          if words[word].key? concept

            # Increment word count for the concept.
            words[word][concept] += 1
          else

            # Add concept to this word listing.
            words[word][concept] =  1
          end

        else

          # Introduce the word into the words table.
          words[word] = {concept => 1}
        end
      end
    end

    # Return complete word table.
    return words
  end

  # Find all related concepts by text similarity.
  def similar_text(description)

    # Generate unique word list for this concept.
    tokens = tokenise(description)

    # Generate a new word table.
    words = word_table

    # Create similar concepts hash.
    similar = {}

    # Get results for each token.
    tokens.each do |token|

      # Get results for this token.
      results = token_similarity(token, words)

      # Aggregate results into similar hash.
      aggregate(similar, results)

    end

    # Normalise results.
    normalise similar

    # Return result.
    return similar
  end

  # Get a list of results for a text similarity measure.
  def token_similarity(word, table)

    # Declare results list.
    results = {}

    # Find list of matching concepts.
    matching = table[word]

    # Find inverse term frequency, idf.
    idf = Math.log(concepts.count / matching.keys.count)

    # Check each match.
    matching.keys.each do |match|

      # Find term frequency, tf, and compute tfidf for the results.
      results[match] = matching[match] * idf
    end

    # Normalise results.
    normalise results

    # Return results.
    return results
  end

  # Normalise a hash to have values between 0 and 1.
  def normalise(results)

    # Total defaults to 0.
    total = 0.0

    # Establish total weight in hash.
    results.values.each do |value|
      total += value
    end

    # Normalise results in hash.
    results.keys.each do |key|
      results[key] /= total
    end

    # Return the end result.
    return results
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
