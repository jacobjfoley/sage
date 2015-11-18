namespace :evaluate do

  desc "Evaluate project statistics."
  task :statistics, [:project] => :environment do |task, args|

    # Check for missing arguments.
    if !args[:project]
      abort("Usage: rake evaluate:statistics[project]")
    end

    # Establish configuration.
    project = args[:project].to_i

    # Check for non-existant project.
    if !Project.exists?(project)
      abort("That project does not exist.")
    end

    # Print results.
    puts Statistics.new(project)
  end

end
