class Performance

  # Process project and report scores.
  # Training proportion is a value between 0.0 and 1.0. For instance, 0.4 means
  # that the first 40% is training data and remaining 60% is testing data.
  def evaluate(project_id, training_proportion, testing_number)

    # Retrieve the desired project.
    project = Project.find(project_id)

    # Clone the project and capture the clone's ID.
    clone_id = project.clone(1)

    # Retrieve the clone of the provided project.
    clone = Project.find(clone_id)

    # Get the items to evaluate.
    range = clone.concepts
    domain = clone.digital_objects.shuffle[0..testing_number]

    # Get the truth hash for the project.
    truth_hash = create_truth_hash(clone, domain)

    # Create a training project based on the clone project.
    training = training_project(clone, training_proportion)

    # List algorithm names.
    algorithm_names = ["VotePlus", "SAGA-Refined"]

    # Initialise algorithm records.
    algorithms = {}
    algorithm_names.each do |algorithm|

      # Create the algorithm's record.
      algorithms[algorithm] = {
        precision: [],
        recall: [],
        f05: [],
        f1: [],
        f2: [],
        phi: [],
        precision5: [],
        success1: [],
        success5: [],
        mrr: [],
      }
    end

    # For each item in the project:
    domain.each do |item|

      # Cycle through each algorithm.
      algorithms.keys.each do |algorithm_name|

        # Retrieve the algorithm's record.
        record = algorithms[algorithm_name]

        # Use the algorithm to fetch suggestions.
        suggestions = item.algorithm(algorithm_name).suggestions.keys

        # Get the scores of these suggestions
        score = binary_classification(suggestions, truth_hash[item], range)

        # Record scores.
        precision_score = precision(score)
        recall_score = recall(score)
        record[:precision] << precision_score
        record[:recall] << recall_score
        record[:phi] << phi_coefficient(score)
        record[:f05] << f_score(precision_score, recall_score, 0.5)
        record[:f1] << f_score(precision_score, recall_score, 1.0)
        record[:f2] << f_score(precision_score, recall_score, 2.0)
        record[:success1] << success_at(suggestions, 1, truth_hash[item])
        record[:success5] << success_at(suggestions, 5, truth_hash[item])
        record[:precision5] << precision_at(suggestions, 5, truth_hash[item])
        record[:mrr] << reciprocal_rank(suggestions, truth_hash[item])
      end
    end

    # Cycle through each algorithm.
    algorithms.keys.each do |algorithm_name|

      # Retrieve the algorithm's record.
      record = algorithms[algorithm_name]

      # For each score in the record:
      record.keys.each do |score|

        # Replace the scores array with the average.
        record[score] = record[score].reduce(:+) / record[score].count
      end
    end

    # Remove training project.
    training.destroy

    # Return results hash.
    return algorithms
  end

  # Find the success at a given interval.
  def success_at(suggestions, interval, truth)

    # Determine if any precision at the given interval.
    if precision_at(suggestions, interval, truth) > 0
      return 1.0
    else
      return 0.0
    end
  end

  # Find the precision at a given interval.
  def precision_at(suggestions, interval, truth)

    # Determine set.
    set = suggestions[0...interval]

    # Find precision.
    if set.empty?
      return 0.0
    else
      return (set & truth).count.to_f / set.count
    end
  end

  # Find the reciprocal rank.
  def reciprocal_rank(suggestions, truth)

    # Initialise rank.
    rank = nil

    # Run through all suggestions.
    suggestions.each do |suggestion|

      # Check if this is a hit.
      if truth.include? suggestion

        # Found. Set rank and break.
        rank = suggestions.index(suggestion) + 1.0
        break
      end
    end

    # Return result.
    if rank.nil?
      return 0.0
    else
      return 1.0 / rank
    end
  end

  # Create a hash of each item mapped to its associated entities.
  def create_truth_hash(project, items)

    # Create hash.
    truth_hash = {}

    # For each item in the project:
    items.each do |item|

      # Create truth array for that item.
      truth_hash[item] = item.related
    end

    # Return truth hash.
    return truth_hash
  end

  # Establish training data set.
  def training_project(training, training_proportion)

    # Create shuffled annotation array.
    annotations = training.annotations.shuffle

    # Calculate the number of annotations to preserve.
    preserve = (training_proportion * annotations.count).round

    # Remove annotations in the testing subset.
    annotations[preserve..-1].each do |annotation|

      # Destroy the testing subset annotation.
      annotation.destroy
    end

    # Return training project.
    return training
  end

  # Find the binary classification of results.
  def binary_classification(found, truth, all)

    # Determine how many true positives were found.
    tp = (found & truth).count

    # Determine how many false positives were found.
    fp = (found - truth).count

    # Determine how many false negatives were found.
    fn = (truth - found).count

    # Determine how many true negatives were found.
    tn = all.count - (tp + fp + fn)

    # Return results.
    return {
      true_positives: tp,
      false_positives: fp,
      true_negatives: tn,
      false_negatives: fn,
    }
  end

  # Find the phi coefficient given binary classification.
  def phi_coefficient(binary_classification)

    # Extract values.
    tp = binary_classification[:true_positives]
    tn = binary_classification[:true_negatives]
    fp = binary_classification[:false_positives]
    fn = binary_classification[:false_negatives]

    # Calculate products.
    true_product = tp * tn
    false_product = fp * fn
    dot_product = (tp + fp) * (tp + fn) * (tn + fp) * (tn + fn)

    # Return result.
    if dot_product != 0.0
      return (true_product - false_product).to_f / Math.sqrt(dot_product)
    else
      return (true_product - false_product).to_f
    end
  end

  # Find the precision given the binary classification.
  def precision(binary_classification)

    # Extract values.
    tp = binary_classification[:true_positives]
    fp = binary_classification[:false_positives]

    # Return result.
    if (tp + fp) > 0
      return tp.to_f / (tp + fp)
    else
      return 0.0
    end
  end

  # Find the recall given the binary classification.
  def recall(binary_classification)

    # Extract values.
    tp = binary_classification[:true_positives]
    fn = binary_classification[:false_negatives]

    # Return result.
    if (tp + fn) > 0
      return tp.to_f / (tp + fn)
    else
      return 0.0
    end
  end

  # Calculate F score of results given precision, recall and beta.
  def f_score(precision, recall, beta)

    # Ensure a positive denominator.
    if (precision > 0.0 || recall > 0.0) && (beta != 0.0)

      # Return F score.
      return (1 + beta ** 2) * (precision * recall) / (beta ** 2 * precision + recall)
    else

      # Zero denominator, so return 0 for F score.
      return 0.0
    end
  end

end
