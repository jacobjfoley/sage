json.array!(@digital_objects) do |digital_object|
  json.extract! digital_object, 
  json.url digital_object_url(digital_object, format: :json)
end
