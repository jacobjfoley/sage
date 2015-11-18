namespace :evaluate do

  desc "Evaluate project complexity metrics."
  task :complexity, [:project] => :environment do |task, args|

    # Check for missing arguments.
    if !args[:project]
      abort("Usage: rake evaluate:complexity[project]")
    end

    # Establish configuration.
    project = args[:project].to_i

    # Check for non-existant project.
    if !Project.exists?(project)
      abort("That project does not exist.")
    end

    # Print results.
    puts Complexity.new(project)
  end

end
