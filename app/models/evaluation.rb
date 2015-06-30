class Evaluation

  # Process project and report scores.
  def evaluate(project_id, partition_level)

    # Retrieve the desired project.
    project = Project.find(project_id)

    # Clone the project and capture the clone's ID.
    clone_id = project.clone

    # Retrieve the clone of the provided project.
    test_project = Project.find(clone_id)

    # Get the truth hash for the project.
    truth_hash = create_truth_hash(test_project)

    # Partition the data in the test project.
    partition(test_project, partition_level)

    # Initialise algorithm hashes.
    algorithms = []
    algorithms << {name: "SAGE-A", precision: [], recall: [] }
    #algorithms << {name: "Random", precision: [], recall: [] }

    # For each test concept:
    test_project.concepts.each do |concept|

      # Test each algorithm.
      algorithms.each do |algorithm|

        # Create empty suggestions array.
        suggestions = []

        # Use the algorithm to fetch suggestions.
        concept.relevant.keys.each do |key|
          suggestions << key
        end

        # Calculate precision.
        algorithm[:precision] << precision(suggestions, truth_hash[concept.id])

        # Calculate recall.
        algorithm[:recall] << recall(suggestions, truth_hash[concept.id])
      end
    end

    # Calculate average scores.
    algorithms.each do |algorithm|

      # Introduce total precision variable.
      total_precision = 0.0

      # Accumulate precision.
      algorithm[:precision].each do |score|
        total_precision += score
      end

      # Find mean average precision.
      algorithm[:average_precision] = total_precision / algorithm[:precision].count

      # Introduce total recall (heh) variable.
      total_recall = 0.0

      # Accumulate recall.
      algorithm[:recall].each do |score|
        total_recall += score
      end

      # Find mean average recall.
      algorithm[:average_recall] = total_recall / algorithm[:recall].count
    end

    # Calculate composite scores.
    algorithms.each do |algorithm|

      algorithm[:f05] = f_beta(algorithm[:average_precision],
        algorithm[:average_recall, 0.5])

      algorithm[:f1] = f_beta(algorithm[:average_precision],
        algorithm[:average_recall, 1.0])

      algorithm[:f2] = f_beta(algorithm[:average_precision],
        algorithm[:average_recall, 2])

    end

    # Remove clone project.
    test_project.destroy

    # Return results hash.
    return algorithms
  end

  # Create a hash of each concept id to associated objects.
  def create_truth_hash(project)

    # Create hash.
    truth_hash = {}

    # For each concept in the test project:
    project.concepts.each do |concept|

      # Create empty array for that concept.
      truth_hash[concept.id] = []

      # Add associations to truth_hash.
      concept.digital_objects.each do |object|
        truth_hash[concept.id] << object.id
      end
    end

    # Return truth hash.
    return truth_hash
  end

  # Removes a number of associations from a test project to establish a
  # training data set, and a test data set.
  def partition(project, partition_level)

    # Create empty association array.
    associations = []

    # Run through every concept.
    project.concepts each do |concept|

      # Collect the concept's associations.
      concept.digital_objects.each do |object|
        association << [concept, object]
      end
    end

    # Shuffle the associations array.
    associations.shuffle!

    # Calculate the number of associations to remove.
    to_remove = (1.0 - partition_level) * associations.count

    # Round removal number (for accessing indexes).
    to_remove.round!

    # Remove associations.
    associations[0..to_remove].each do |association|

      # Delete the object from the concept.
      association[0].digital_objects.delete association[1]
    end
  end

  # Calculate precision of results.
  def precision(found, truth)

    # Determine how many true positives were found.
    correct = 0.0
    found.each do |item|
      if truth.include?(item)
        correct += 1
      end
    end

    # Return precision.
    return correct / found.count
  end

  # Calculate recall of results.
  def recall(found, truth)

    # Determine how many were found.
    correct = 0.0
    found.each do |item|
      if truth.include?(item)
        correct += 1
      end
    end

    # Return recall.
    return correct / truth.count
  end

  # Calculate f1 score of results.
  def f_beta(precision, recall, beta)

    # Ensure a positive denominator.
    if precision > 0 || recall > 0

      # Return f1 score.
      return (1 + beta^2) * (precision * recall) / (beta^2 * precision + recall)
    else

      # Zero denominator, so return 0 for f1 score.
      return 0
    end
  end
end
