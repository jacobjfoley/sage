class SampleAcceptance

  def initialize(project_id)

    # Find all samples.
    samples = []
    unchecked = Project.where(parent: project_id)

    # Check each sample for correct data.
    unchecked.each do |sample|

      # Add sample if it has provenance data.
      if sample.annotations.select { |a| a.provenance.nil? }.count == 0
        samples << sample
      end
    end

    # Find all the algorithms used by the samples.
    @algorithms = samples.map { |s| s.algorithm }.uniq

    # Divide samples into groups based on algortihm.
    @groups = {}
    @algorithms.each do |algorithm|
      @groups[algorithm] = samples.select { |s| s.algorithm.eql? algorithm }
    end
  end

  # Evaluate all children of this project.
  def acceptance_ratio

    # Create an algorithm results hash.
    algorithm_results = {}

    # For each algorithm:
    @algorithms.each do |algorithm|

      # Create results array.
      results = []

      # Run through each child.
      @groups[algorithm].each do |sample|

        # Create a new evaluation.
        results << Acceptance.new(sample.id).acceptance_ratio
      end

      # Return the results.
      algorithm_results[algorithm] = Measurement.new("Acceptance Ratio", results)
    end

    # Return the algorithm results.
    return algorithm_results
  end

  # Evaluate all children of this project.
  def partition_acceptance_ratio(partitions = 4)

    # Create an algorithm results hash.
    algorithm_results = {}

    # For each algorithm:
    @algorithms.each do |algorithm|

      # Create results array.
      results = []

      # Run through each sample.
      @groups[algorithm].each do |sample|

        # Create a new evaluation.
        results << Acceptance.new(sample.id).partition_acceptance_ratio(partitions)
      end

      # Create measurements array.
      measurements = []

      # Transpose results.
      results.transpose.each_with_index do |transposition, index|

        measurements << Measurement.new("Partition #{index}", transposition)
      end

      # Return the results.
      algorithm_results[algorithm] = measurements
    end

    # Return the algorithm results.
    return algorithm_results
  end
end
