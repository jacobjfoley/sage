class SampleProductivity

  # Constructor.
  def initialize(project_id)

    # Find all samples.
    samples = Project.where(parent: project_id)

    # Find all the algorithms used by the samples.
    @algorithms = samples.map { |s| s.algorithm }.uniq

    # Create groups hash.
    @groups = {}

    # Divide samples into groups based on algortihm.
    @algorithms.each do |algorithm|
      @groups[algorithm] = samples.select { |s| s.algorithm.eql? algorithm }
    end
  end

  # Finds the average annotation rate in annotations/minute of samples.
  def cluster_annotation_rate

    # Create an overall algorithm results hash.
    algorithm_results = {}

    # For each algorithm:
    @algorithms.each do |algorithm|

      # Create results array.
      results = []

      # For each group member in that algorithm:
      @groups[algorithm].each do |sample|

        # Get the cluster annotation rate.
        results << Productivity.new(sample.id).cluster_annotation_rate
      end

      # Store measurement for algorithm.
      algorithm_results[algorithm] = Measurement.new("Cluster Annotation Rate", results)
    end
  end

  # Finds the number of annotations in clusters in samples.
  def cluster_annotation_count

    # Create an overall algorithm results hash.
    algorithm_results = {}

    # For each algorithm:
    @algorithms.each do |algorithm|

      # Create results array.
      results = []

      # For each group member in that algorithm:
      @groups[algorithm].each do |sample|

        # Get the cluster annotation count.
        results << Productivity.new(sample.id).cluster_annotation_count
      end

      # Store measurement for algorithm.
      algorithm_results[algorithm] = Measurement.new("Cluster Annotation Count", results)
    end
  end

  # Finds the length of time spent annotating in samples.
  def cluster_annotation_period

    # Create an overall algorithm results hash.
    algorithm_results = {}

    # For each algorithm:
    @algorithms.each do |algorithm|

      # Create results array.
      results = []

      # For each group member in that algorithm:
      @groups[algorithm].each do |sample|

        # Get the cluster annotation period.
        results << Productivity.new(sample.id).cluster_annotation_period
      end

      # Store measurement for algorithm.
      algorithm_results[algorithm] = Measurement.new("Cluster Annotation Period", results)
    end
  end
end
