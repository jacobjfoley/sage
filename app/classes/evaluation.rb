class Evaluation

  # Process project and report scores.
  # Testing partition is a value between 0 and 1. For instance, 0.4 means that
  # the first 40% is training material and remaining 60% is test material.
  def evaluate(project_id, testing_partition)

    # Retrieve the desired project.
    project = Project.find(project_id)

    # Clone the project and capture the clone's ID.
    clone_id = project.clone(1)

    # Retrieve the clone of the provided project.
    test_project = Project.find(clone_id)

    # Get the truth hash for the project.
    truth_hash = create_truth_hash(test_project)

    # Partition the data in the test project.
    partition(test_project, testing_partition)

    # Initialise algorithm hashes.
    algorithms = []
    #algorithms << { name: "SAGA", precision: [], recall: [] }
    algorithms << { name: "Baseline", precision: [], recall: [] }
    #algorithms << { name: "Vote", precision: [], recall: [] }
    #algorithms << { name: "VotePlus", precision: [], recall: [] }
    #algorithms << { name: "Sum", precision: [], recall: [] }
    #algorithms << { name: "SumPlus", precision: [], recall: [] }

    # For each test concept:
    test_project.concepts.each do |concept|

      # Test each algorithm.
      algorithms.each do |algorithm|

        # Use the algorithm to fetch suggestions.
        suggestions = concept.algorithm(algorithm[:name]).suggestions.keys

        # Calculate precision.
        algorithm[:precision] << precision(suggestions, truth_hash[concept])

        # Calculate recall.
        algorithm[:recall] << recall(suggestions, truth_hash[concept])
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
      if algorithm[:precision].count > 0
        algorithm[:average_precision] = total_precision / algorithm[:precision].count
      else
        algorithm[:average_precision] = 0
      end

      # Introduce total recall (heh) variable.
      total_recall = 0.0

      # Accumulate recall.
      algorithm[:recall].each do |score|
        total_recall += score
      end

      # Find mean average recall.
      if algorithm[:recall].count > 0
        algorithm[:average_recall] = total_recall / algorithm[:recall].count
      else
        algorithm[:average_recall] = 0
      end
    end

    # Calculate composite scores.
    algorithms.each do |algorithm|

      algorithm[:f05] = f_beta(algorithm[:average_precision],
        algorithm[:average_recall], 0.5)

      algorithm[:f1] = f_beta(algorithm[:average_precision],
        algorithm[:average_recall], 1.0)

      algorithm[:f2] = f_beta(algorithm[:average_precision],
        algorithm[:average_recall], 2)
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

      # Create truth array for that concept.
      truth_hash[concept] = concept.digital_objects
    end

    # Return truth hash.
    return truth_hash
  end

  # Removes a number of annotations from a test project to establish a
  # training data set, and a test data set.
  def partition(project, testing_partition)

    # Create empty annotation array.
    annotations = []

    # Run through every concept.
    project.concepts.each do |concept|

      # Collect the concept's annotations.
      concept.digital_objects.each do |object|
        annotations << [concept, object]
      end
    end

    # Shuffle the annotations array.
    annotations.shuffle!

    # Calculate the number of annotations to remove.
    to_remove = testing_partition * annotations.count

    # Round removal number (for accessing indexes).
    to_remove.round

    # Remove annotations.
    annotations[0...to_remove].each do |annotation|

      # Delete the object from the concept.
      annotation[0].digital_objects.delete annotation[1]
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
    if found.count > 0
      return correct / found.count
    else
      return 0.0
    end
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
    if found.count > 0
      return correct / truth.count
    else
      return 0.0
    end
  end

  # Calculate f1 score of results.
  def f_beta(precision, recall, beta)

    # Ensure a positive denominator.
    if (precision > 0 || recall > 0) && (beta != 0)

      # Return f1 score.
      return (1 + beta ** 2) * (precision * recall) / (beta ** 2 * precision + recall)
    else

      # Zero denominator, so return 0 for f1 score.
      return 0
    end
  end
end
