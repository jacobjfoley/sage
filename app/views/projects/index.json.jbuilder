json.array!(@projects) do |project|
  json.extract! project, :id, :notes, :administrator_key, :contributor_key, :viewer_key
  json.url project_url(project, format: :json)
end
