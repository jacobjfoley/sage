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
      record = acceptance.records[algorithm]

      # Output sample count.
      puts "#{record[:sample_count]} samples."

      # Get record's summary.
      summary = record[:summary]

      # For each measurement summary:
      summary.keys.each do |measurement|

        # Unpack measurement summary.
        min = summary[measurement][:min].round(2)
        max = summary[measurement][:max].round(2)
        mean = summary[measurement][:mean].round(2)
        std_dev = summary[measurement][:std_dev].round(2)

        # Output measurement.
        puts "#{measurement}: #{mean} (#{min} - #{max}, std dev: #{std_dev})"
      end

      # Print separator.
      puts "\n-----\n"
    end
  end

  desc "Investigate algorithm performance metrics using a test project."
  task :performance, [:project, :training] => :environment do |task, args|

    # Run evaluation.
    results = Evaluation.new.evaluate_performance(args.project.to_i, args.training.to_f, 30)

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
