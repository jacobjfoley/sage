namespace :evaluate do

  desc "Evaluate project subgraph metrics."
  task :subgraphs, [:project] => :environment do |task, args|

    # Check for missing arguments.
    if !args[:project]
      abort("Usage: rake evaluate:subgraphs[project]")
    end

    # Establish configuration.
    project = args[:project].to_i

    # Check for non-existant project.
    if !Project.exists?(project)
      abort("That project does not exist.")
    end

    # Print results.
    puts Subgraphs.new(project)
  end

end
