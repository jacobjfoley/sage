namespace :evaluate do

  desc "Evaluate algorithm performance metrics."
  task :performance, [:project, :training] => :environment do |task, args|

    # Check for missing arguments.
    if !args[:project] || !args[:training]
      abort("Usage: rake evaluate:performance[project,partition]")
    end

    # Establish configuration.
    project = args[:project].to_i
    proportion = args[:training].to_f
    tests = 30

    # Check for non-existant project.
    if !Project.exists?(project)
      abort("That project does not exist.")
    end

    # Check for bad training proportion.
    if (proportion < 0.0 || proportion > 1.0)
      abort("Provide a training proportion between 0.0 (nothing) and 1.0 (all).")
    end

    # Print results.
    puts Performance.new(project, proportion, tests)
  end
end
