class SampleAcceptance

  def initialize(project_id)

    # Find all samples.
    samples = []
    unchecked = Project.where(parent: project_id)

    # Check each sample for correct data.
    unchecked.each do |sample|

      # Add sample if all annotations have provenance data.
      if sample.annotations.select { |a| a.provenance.nil? }.count == 0
        samples << sample
      end
    end

    # Find all the algorithms used by the samples.
    @algorithms = samples.map { |s| s.algorithm }.uniq

    # Create groups hash.
    @groups = {}

    # Divide samples into groups based on algortihm.
    @algorithms.each do |algorithm|
      @groups[algorithm] = samples.select { |s| s.algorithm.eql? algorithm }
    end
  end

  # Create a string that represents this object.
  def to_s

    # Initialise string.
    s = ""

    # Print header.
    s << "Sample Acceptance using samples of #{@project.id} - #{@project.name}\n"

    # Get data.
    ar = acceptance_ratio
    par = partition_acceptance_ratio

    # For each algorithm:
    @algorithms.each do |algorithm|

      # Print algorithm name.
      s << "\n#{algortihm}:\n"

      # Print overall acceptance data.
      s << "Overall:\n"
      s << "Acceptance ratio: #{ar[algorithm]}\n"

      # Print partition acceptance data.
      s << "Partitions:\n"
      par[algorithm].each do |measurement|
        s << "#{measurement}\n"
      end
    end

    # Return string.
    return s
  end

  # Find the acceptance ratio of all samples.
  def acceptance_ratio

    # Create an overall algorithm results hash.
    algorithm_results = {}

    # For each algorithm:
    @algorithms.each do |algorithm|

      # Create an ongoing results array.
      results = []

      # Run through each sample.
      @groups[algorithm].each do |sample|

        # Store evaluation.
        results << Acceptance.new(sample.id).acceptance_ratio
      end

      # Store the algorithm's results as a new measurement.
      algorithm_results[algorithm] = Measurement.new("Acceptance Ratio", results)
    end

    # Return the algorithm results.
    return algorithm_results
  end

  # Find the partitioned acceptance average of all samples.
  def partition_acceptance_ratio(partitions = 4)

    # Create an overall algorithm results hash.
    algorithm_results = {}

    # For each algorithm:
    @algorithms.each do |algorithm|

      # Create an ongoing results array.
      results = []

      # Run through each sample.
      @groups[algorithm].each do |sample|

        # Store evaluation.
        results << Acceptance.new(sample.id).partition_acceptance_ratio(partitions)
      end

      # Create measurements array.
      measurements = []

      # Transpose results -- group by partition number instead of sample.
      results.transpose.each_with_index do |transposition, index|

        # Store new measurement.
        measurements << Measurement.new("Partition #{index}", transposition)
      end

      # Store the algorithm's results. Each element in array is a partition.
      algorithm_results[algorithm] = measurements
    end

    # Return the algorithm results.
    return algorithm_results
  end
end
