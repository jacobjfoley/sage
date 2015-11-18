class Performance

  # Constructor
  # Proportion is a value between 0.0 and 1.0. For instance, 0.4 means
  # that the first 40% is training data and remaining 60% is testing data.
  # Tests is the number of times to run each test.
  def initialize(project_id, proportion = 0.4, tests = 30)

    # Capture the provided project and settings.
    @project = Project.find(project_id)
    @proportion = proportion
    @tests = tests

    # Define the algorithms used.
    @algorithms = ["VotePlus", "SAGA-Refined"]
  end

  # Create a string that represents this object.
  def to_s

    # Initialise string.
    s = ""

    # Print header.
    s << "Performance test on #{@project.id} - #{@project.name}\n"
    s << "Settings: #{@tests} tests @ #{@proportion} training proportion.\n"

    # Get results
    algorithm_results = results

    # For each algorithm:
    @algorithms.each do |algorithm_name|

      # Print algorithm name.
      s << "\n#{algorithm_name}:\n"

      # For each algorithm's results:
      algorithm_results[algorithm_name].values.each do |measurement|
        s << "#{measurement}\n"
      end
    end

    # Return string.
    return s
  end

  # Process project and report scores.
  def results

    # Clone the project and capture the clone's ID.
    clone_id = @project.clone(1)

    # Retrieve the clone of the provided project.
    clone = Project.find(clone_id)

    # Find the domain (the tests to run).
    domain = clone.digital_objects.shuffle[0...@tests]

    # Find the range (potential suggestions for each test).
    range = clone.concepts

    # Get the truth hash for the project.
    truth_hash = create_truth_hash(clone, domain)

    # Transform the clone project into the training data project.
    training = training_project(clone, @proportion)

    # Create algorithm results hash.
    algorithm_results = {}

    # For each algorithm:
    @algorithms.each do |algorithm|

      # Initialise the algorithm's measurements.
      algorithm_results[algorithm] = {
        precision: Measurement.new("Precision", []),
        recall: Measurement.new("Recall", []),
        f05: Measurement.new("F-0.5", []),
        f1: Measurement.new("F-1.0", []),
        f2: Measurement.new("F-2.0", []),
        phi: Measurement.new("Phi Coefficient", []),
        precision5: Measurement.new("Precision@5", []),
        success1: Measurement.new("Success@1", []),
        success5: Measurement.new("Success@5", []),
        mrr: Measurement.new("MRR", []),
      }
    end

    # For each item to be tested:
    domain.each do |item|

      # Use each algorithm and capture results.
      @algorithms.each do |algorithm_name|

        # Retrieve the algorithm's measurements.
        measurements = algorithm_results[algorithm_name]

        # Use the algorithm to fetch suggestions.
        suggestions = item.algorithm(algorithm_name).suggestions.keys

        # Get the scores of these suggestions
        score = binary_classification(suggestions, truth_hash[item], range)

        # Record measurements.
        precision_score = precision(score)
        recall_score = recall(score)
        measurements[:precision] << precision_score
        measurements[:recall] << recall_score
        measurements[:phi] << phi_coefficient(score)
        measurements[:f05] << f_score(precision_score, recall_score, 0.5)
        measurements[:f1] << f_score(precision_score, recall_score, 1.0)
        measurements[:f2] << f_score(precision_score, recall_score, 2.0)
        measurements[:success1] << success_at(suggestions, 1, truth_hash[item])
        measurements[:success5] << success_at(suggestions, 5, truth_hash[item])
        measurements[:precision5] << precision_at(suggestions, 5, truth_hash[item])
        measurements[:mrr] << reciprocal_rank(suggestions, truth_hash[item])
      end
    end

    # Destroy the training data project, cleaning up.
    training.destroy

    # Return results hash.
    return algorithm_results
  end

  # Private methods used exclusively by the results method.
  private

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
end
