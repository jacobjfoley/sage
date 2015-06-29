From DigitalObject.rb

# Determine the average number of concepts per object.
  def self.concepts_per_object

    # Get all objects.
    all = DigitalObject.all

    # For each digital object, tally the concepts.
    total = 0.0
    all.each do |item|
      total += item.concepts.count
    end

    # Return the average.
    return total / all.count
end


# Display full test scores.
  def self.evaluate_all

    # Items to evaluate.
    items = [5, 8, 12, 19, 24, 28, 38, 39, 42, 44, 47, 48, 54, 62, 72, 83, 91, 105, 106, 114]

    # Get all objects.
    all = DigitalObject.all

    # Get specific objects.
    objects = []
    items.each do |item|
      objects.push(all[item])
    end

    # Get results.
    results = []
    objects.each do |object|

      # Push results on to results array.
      results.push(object.evaluate)
    end

    # Print the evaluation for each.
    puts "Printing evaluations for each object in set: "
    results.each do |result|

      # Nicely format each result as csv.
      # Print object ID.
      print result[0], ","

      # Print middle scores.
      (1..8).each do |item|
        print result[item].round(4), ","
      end

      # Print final score.
      print result[9].round(4)

      # Newline.
      print "\n"
    end
  end

  # Commit all truth objects to the truth database.
  def self.commit_truth()

    # Read existing truth hash from file or create a new one.
    if File.exist?("/home/jacob/Apps/sage/public/truth.db")

      # Truth database exists. Load its contents.
      truth = YAML.load(File.read("/home/jacob/Apps/sage/public/truth.db"))
    else

      # Create a brand new truth database as one doesn't yet exist.
      truth = {}
    end

    # Fetch all objects in database for potential inclusion in truth database.
    all = DigitalObject.all

    # Create a list of all truth objects in the database.
    truth_objects = []
    all.each do |object|

      # Test if it's just a number in the location field. This is shorthand
      # for the object being a truth object as the location corresponds to
      # the id of the target object.
      if object.location =~ /\A\d+\z/ ? true : false
        truth_objects.push(object)
      end
    end

    # Add all truth object concept ids to the truth file under the target's name.
    truth_objects.each do |object|
      truth[object.location] = just_ids(object.concepts)
    end

    # Dump modified truth hash to file.
    File.open("/home/jacob/Apps/sage/public/truth.db", 'w+') {|f| f.write(YAML.dump(truth))}

    # Delete all truth objects.
    truth_objects.each do |object|
      DigitalObject.delete(object.id)
    end
  end

  # Restore the truth objects from the truth database.
  def self.restore_truth()

    # Read existing truth hash from file or create a new one.
    if File.exist?("/home/jacob/Apps/sage/public/truth.db")

      # Truth database exists. Load its contents.
      truth = YAML.load(File.read("/home/jacob/Apps/sage/public/truth.db"))
    else

      # Create a brand new truth database as one doesn't yet exist.
      truth = {}
    end

    # For each key in the truth file, create a new object with those values
    # as its concepts and the key as its location.
    truth.keys.each do |key|

      # Create new object with location.
      truth_object = DigitalObject.create(location: key)

      # For each value, create and associate concept.
      truth[key].each do |value|
        truth_object.concepts.push(Concept.find(value))
      end

      # Save truth object.
      #truth_object.save
    end

  end

  # Switch out for just ids
  def self.just_ids(list)

    # Strip down to just ids.
    ids = []
    list.each do |item|
      ids.push(item.id)
    end

    # Return list.
    return ids
  end

  # Method to evaluate the different similarity measures.
  def evaluate

      # Load the truth files.
      truth = YAML.load(File.read("/home/jacob/Apps/sage/public/truth.db"))
      this_truth = truth[id.to_s]

      # Generate all three kinds of similarity results.
      text = self.class.just_ids(relevant(measure = "Text"))
      local = self.class.just_ids(relevant(measure = "Local"))
      sage = self.class.just_ids(relevant(measure = "SAGE"))
      results = [text, local, sage]

      # Start results row.
      output = [id]

      # Further results.
      results.each do |result|
        this_precision = precision(result, this_truth)
        this_recall = recall(result, this_truth)
        output.push(this_precision)
        output.push(this_recall)
        output.push(f1(this_precision, this_recall))
      end

      # Return results for each.
      return output
  end

  
