namespace :evaluate do

  desc "Evaluate project acceptance metrics."
  task :acceptance, [:project] => :environment do |task, args|

    # Check for missing arguments.
    if !args[:project]
      abort("Usage: rake evaluate:acceptance[project]")
    end

    # Establish configuration.
    project = args[:project].to_i

    # Check for non-existant project.
    if !Project.exists?(project)
      abort("That project does not exist.")
    end

    # Print results.
    puts Acceptance.new(project)
  end

  desc "Evaluate sample acceptance metrics."
  task :sample_acceptance, [:project] => :environment do |task, args|

    # Check for missing arguments.
    if !args[:project]
      abort("Usage: rake evaluate:sample_acceptance[project]")
    end

    # Establish configuration.
    project = args[:project].to_i

    # Check for non-existant project.
    if !Project.exists?(project)
      abort("That project does not exist.")
    end

    # Print results.
    puts SampleAcceptance.new(project)
  end
end
