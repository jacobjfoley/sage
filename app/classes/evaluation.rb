class Evaluation

  # Evaluate samples produced from a sample collection.
  def evaluate_samples(project_id)

    # Find all samples.
    samples = Project.where(parent_id: project_id)

    # Define measurements.
    measurements = {}

    # Run through each sample.
    samples.each do |sample|

      # Create new analytics device.
      analytics = Analytics.new(sample)

      # Get the algorithm.
      algorithm = sample.algorithm

      # Determine if this algorithm is new.
      if !measurements.key? algorithm

        # Introduce algorithm.
        measurements[algorithm] = {
          annotation_count: 0,
          annotation_period: 0.0,
          annotation_rate: 0.0,
          one: 0,
          many: 0,
          reuse: 0.0,
          count: 0,
          accepted: 0,
          concept_count: 0,
          created: 0
        }
      end

      # Add to measurements.
      measurements[algorithm][:annotation_count] += analytics.annotation_count
      measurements[algorithm][:annotation_period] += analytics.annotation_period
      measurements[algorithm][:annotation_rate] += analytics.annotation_rate
      measurements[algorithm][:one] += analytics.one_rate
      measurements[algorithm][:many] += analytics.many_rate
      measurements[algorithm][:reuse] += analytics.reuse_rate
      measurements[algorithm][:count] += 1
      measurements[algorithm][:accepted] += analytics.accepted
      measurements[algorithm][:created] += analytics.created
      measurements[algorithm][:concept_count] += analytics.concept_count
    end

    # For each algorithm:
    measurements.keys.each do |key|

      # Fetch hash for this algoritm.
      m = measurements[key]

      # Calculate averages.
      avg_annotation_count = m[:annotation_count].to_f / m[:count]
      avg_annotation_period = m[:annotation_period] / (60 * m[:count])
      avg_annotation_rate = m[:annotation_rate] / m[:count]
      avg_one = m[:one].to_f / m[:count]
      avg_many = m[:many].to_f / m[:count]
      avg_reuse = m[:reuse] / m[:count]
      avg_accepted = m[:accepted].to_f / m[:count]
      avg_created = m[:created].to_f / m[:count]
      avg_concepts = m[:concept_count].to_f / m[:count]

      # Calculate proportion.
      if (avg_accepted > 0 || avg_created > 0)
        proportion = avg_accepted * 100.0 / (avg_accepted + avg_created)
      else
        proportion = 0.0
      end

      # Print results.
      puts "Algorithm: #{key}"
      puts "\n"
      puts "-- Averages #{avg_annotation_count} annotations per sample."
      puts "-- Averages #{avg_annotation_period.round(2)} minutes per sample."
      puts "-- Averages #{avg_annotation_rate.round(2)} annotations/minute."
      puts "\n"
      puts "-- #{avg_concepts} concepts, on average."
      puts "-- #{avg_one} one-shot annotations and #{avg_many} reused annotations."
      puts "-- Annotation reuse rate of #{avg_reuse.round(0)}%."
      puts "\n"
      puts "-- Accepted: #{avg_accepted}, Created: #{avg_created}."
      puts "-- Proportion (Accepted/All): #{proportion.round(2)}%."
    end
  end

  # Process project and report scores.
  # Testing partition is a value between 0 and 1. For instance, 0.4 means that
  # the first 40% is training material and remaining 60% is test material.
  def evaluate_performance(project_id, testing_partition)

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
