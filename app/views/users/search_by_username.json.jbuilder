json.set! :results do
	json.array! @results do |result|
		json.id result.id
		json.username result.username
		json.displayname result.display_name
	end
end