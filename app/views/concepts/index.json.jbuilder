json.array!(@concepts) do |concept|
  json.extract! concept, 
  json.url concept_url(concept, format: :json)
end
