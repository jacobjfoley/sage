namespace :evaluate do

  desc "Investigate user metrics in samples created from a source project."
  task :acceptance, [:project] => :environment do |task, args|

    # Check for missing arguments.
    if !args[:project]
      abort("Usage: rake evaluate:acceptance[source_project]")
    end

    # Check for non-existant project.
    if !Project.exists?(args[:project])
      abort("That project does not exist.")
    end

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
      puts "\n\n"
    end
  end

  desc "Investigate algorithm performance metrics using a test project."
  task :performance, [:project, :training] => :environment do |task, args|

    # Check for missing arguments.
    if !args[:project] || !args[:training]
      abort("Usage: rake evaluate:performance[project,partition]")
    end

    # Check for non-existant project.
    if !Project.exists?(args[:project])
      abort("That project does not exist.")
    end

    # Check for bad training partition.
    if (args[:training].to_f < 0.0) || (args[:training].to_f > 1.0)
      abort("Provide a training partition between 0.0 (nothing) and 1.0 (all).")
    end

    # Run evaluation.
    results = Performance.new.evaluate(args.project.to_i, args.training.to_f, 30)

    # Display results.
    results.keys.each do |algorithm|

      # Print algorithm name.
      puts algorithm

      # For each metric:
      results[algorithm].keys.each do |metric|

        # Print metric.
        puts "#{metric}: #{results[algorithm][metric].round(2)}"
      end

      # Print separator.
      puts "\n\n"
    end
  end

end
