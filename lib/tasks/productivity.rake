namespace :evaluate do

  desc "Evaluate project productivity metrics."
  task :productivity, [:project] => :environment do |task, args|

    # Check for missing arguments.
    if !args[:project]
      abort("Usage: rake evaluate:productivity[project]")
    end

    # Establish configuration.
    project = args[:project].to_i

    # Check for non-existant project.
    if !Project.exists?(project)
      abort("That project does not exist.")
    end

    # Print results.
    puts Productivity.new(project)
  end

  desc "Evaluate sample productivity metrics."
  task :sample_productivity, [:project] => :environment do |task, args|

    # Check for missing arguments.
    if !args[:project]
      abort("Usage: rake evaluate:sample_productivity[project]")
    end

    # Establish configuration.
    project = args[:project].to_i

    # Check for non-existant project.
    if !Project.exists?(project)
      abort("That project does not exist.")
    end

    # Print results.
    puts SampleProductivity.new(project)
  end

end
