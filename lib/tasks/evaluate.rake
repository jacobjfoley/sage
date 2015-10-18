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
end
