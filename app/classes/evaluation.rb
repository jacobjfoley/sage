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
          annotation_count_total: 0,
          one: 0,
          many: 0,
          reuse: 0.0,
          count: 0,
          accepted: 0,
          concept_count: 0,
          to_many: 0,
          created: 0
        }
      end

      # Add to measurements.
      measurements[algorithm][:count] += 1
      measurements[algorithm][:annotation_count] += analytics.cluster_annotation_count
      measurements[algorithm][:annotation_count_total] += analytics.annotation_count
      measurements[algorithm][:annotation_period] += analytics.cluster_annotation_period
      measurements[algorithm][:annotation_rate] += analytics.cluster_annotation_rate
      measurements[algorithm][:one] += analytics.one_rate
      measurements[algorithm][:many] += analytics.many_rate
      measurements[algorithm][:reuse] += analytics.reuse_rate
      measurements[algorithm][:accepted] += analytics.accepted
      measurements[algorithm][:created] += analytics.created
      measurements[algorithm][:concept_count] += analytics.concept_count
      measurements[algorithm][:to_many] += analytics.to_many_rate
    end

    # For each algorithm:
    measurements.keys.each do |algorithm|

      # Fetch hash for this algoritm.
      m = measurements[algorithm]

      # Calculate averages.
      avg_annotation_count_total = m[:annotation_count_total].to_f / m[:count]
      avg_annotation_count = m[:annotation_count].to_f / m[:count]
      avg_annotation_period = m[:annotation_period] / (60 * m[:count])
      avg_annotation_rate = m[:annotation_rate] / m[:count]
      avg_one = m[:one].to_f / m[:count]
      avg_many = m[:many].to_f / m[:count]
      avg_reuse = m[:reuse] / m[:count]
      avg_accepted = m[:accepted].to_f / m[:count]
      avg_created = m[:created].to_f / m[:count]
      avg_concepts = m[:concept_count].to_f / m[:count]
      avg_to_many = m[:to_many].to_f / m[:count]

      # Calculate proportion.
      if (avg_accepted > 0 || avg_created > 0)
        proportion = avg_accepted * 100.0 / (avg_accepted + avg_created)
      else
        proportion = 0.0
      end

      # Calculate hub rate.
      if (avg_to_many > 0 || avg_one > 0)
        avg_to_hub_rate = avg_to_many * 100.0 / (avg_to_many + avg_one)
      else
        avg_to_hub_rate = 0.0
      end

      # Print results.
      puts "Algorithm: #{algorithm}"
      puts "\n"
      puts "-- Averages #{avg_annotation_count_total} annotations per sample."
      puts "-- Averages #{avg_annotation_count} annotations in clusters per sample."
      puts "\n"
      puts "-- Averages #{avg_annotation_period.round(2)} minutes per sample."
      puts "-- Averages #{avg_annotation_rate.round(2)} annotations/minute."
      puts "\n"
      puts "-- Annotations to one-off concepts: #{avg_one}"
      puts "-- Annotations to hub concepts: #{avg_to_many}."
      puts "-- Hub annotation proportion: #{avg_to_hub_rate}%."
      puts "\n"
      puts "-- Averages #{avg_concepts} concepts."
      puts "-- One-off concept: #{avg_one}"
      puts "-- Hub concepts: #{avg_many}."
      puts "-- Hub concept proportion: #{avg_reuse.round(0)}%."
      puts "\n"
      puts "-- Accepted: #{avg_accepted}, Created: #{avg_created}."
      puts "-- Proportion (Accepted/All): #{proportion.round(2)}%."
      puts "\n"
    end
  end

  # Process project and report scores.
  # Training proportion is a value between 0.0 and 1.0. For instance, 0.4 means
  # that the first 40% is training data and remaining 60% is testing data.
  def evaluate_performance(project_id, training_proportion, testing_number)

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
    algorithm_names = ["VotePlus", "SAGA"]

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
        precision_score = precision(score)
        recall_score = recall(score)

        # Record scores.
        record[:precision] << precision_score
        record[:recall] << recall_score
        record[:phi] << phi_coefficient(score)
        record[:f05] << f_score(precision_score, recall_score, 0.5)
        record[:f1] << f_score(precision_score, recall_score, 1.0)
        record[:f2] << f_score(precision_score, recall_score, 2.0)
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
