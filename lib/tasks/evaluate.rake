namespace :evaluate do

  desc "Investigate user metrics in samples created from a source project."
  task :acceptance, [:project] => :environment do |task, args|

    # Run the acceptance utility class on the specified project.
    acceptance = Acceptance.new(args.project)

    # Output project details.
    puts "Source Project: #{acceptance.project.id} - #{acceptance.project.name}"

    # For each algorithm used:
    acceptance.records.keys.each do |algorithm|

      # Output algorithm details.
      puts "Algorithm: #{algorithm}"

      # Get record.
      record = records[algorithm]

      # Output sample count.
      puts "#{record[:count]} samples."

      # For each measurement:
      record.keys.each do |measurement|

        # Unpack measurement summary.
        min = summary[:min]
        max = summary[:max]
        mean = summary[:mean]
        std_dev = summary[:std_dev]

        # Output measurement.
        puts "#{measurement}: #{mean} (#{min} - #{max}, std dev: #{std_dev})"
      end
    end
  end

  desc "Investigate algorithm performance metrics using a test project."
  task :performance, [:project, :partition] => :environment do |task, args|

    # Run evaluation.
    results = Evaluation.new.evaluate_performance(:project, :partition, 30)

    # Display results.
    results.keys.each do |algorithm|

      # Print algorithm name.
      puts algorithm

      # For each metric:
      results[algorithm].keys.each do |metric|

        # Print metric.
        puts "#{metric}: #{results[algorithm][metric]}"
      end

      # Print separator.
      puts "\n-----\n"
    end
  end

end
