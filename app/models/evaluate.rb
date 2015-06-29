class evaluate

  # Process and report database scores.
  def results(truth_project_id, partition_level, number_of_tests)

    # Register project to be used as ground truth.
    @truth_project = Project.find(truth_project_id)

    # Create and retrieve a clone of the provided project.
    @test_project = Project.find(@truth_project.clone)

    # Partition the data in the test project.
    partition(@test_project, partition_level)

    # Select a number of concepts to be used as tests:
    concepts = @test_project.concepts.shuffle[0..number_of_tests]

    # Initialise algorithm hashes.
    algorithms = []
    algorithms << {name: "SAGE-A", precision: [], recall: [], f1: [] }

    # For each test concept:
    concepts.each do |concept|

      # Test each algorithm.
      algorithms.each do |algorithm|

        # Get the truth.


      end
    end

    # Calculate average scores.

    # Calculate composite scores.

    # Return results hash.

  end

  # Removes a number of associations from a test project to establish a
  # training data set, and a test data set.
  def partition(project)



  end

  # Remove all temporary files associated with this evaluation.
  def cleanup()

    # Destroy the test clone.
    @test_project.destroy

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
  def f1(precision, recall)

    # Ensure a positive denominator.
    if precision > 0 || recall > 0

      # Return f1 score.
      return 2 * (precision * recall) / (precision + recall)
    else

      # Zero denominator, so return 0 for f1 score.
      return 0
    end
  end

end
