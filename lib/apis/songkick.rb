require 'httparty'
require 'json'
require 'awesome_print'

#Return strucure
# if error => hash with:
# 	success : false
# 	message : error message
# if success
# 	success : true
# 	data    : doc to be returned

module SongKick
	
	#http://www.songkick.com/developer/event-search
	# use nil for location_type to get all artist's events
	def self.getEventsForArtist(artist_name, location_type, location_id)

		if location_type==nil
			return makeRequest("events",{:artist_name => artist_name })
		end

		temp = location_type.to_s+":"+location_id.to_s
		return makeRequest("events",{:artist_name => artist_name, :location => temp})
	end

    private
    	def self.makeRequest(method, params)
    		ret_value = {}
		
			begin
			
				url = generateUrl(method, params)
				doc = HTTParty.get(url)

			rescue Exception => e

				#puts e.message
				#puts e.backtrace.join("\n")

				ret_value["success"] = false
				ret_value["message"] = e.message

				return ret_value
			end

			if doc["resultsPage"]["status"]=="error"
				ret_value["success"] = false
				ret_value["message"] = doc["resultsPage"]["error"]["message"]
			else
				ret_value["success"] = true
				ret_value["data"] = doc["resultsPage"]["results"]
			end

			return ret_value

    	end
    	
    	def self.generateUrl(method, params, type="json")

    		url = ENV['BASE_URL_SONG_KICK']
    		url += method.to_s + "." + type + "?"
    		url += 'apikey='+ENV['SONG_KICK_API_KEY']

    		params.each do |key,value|
				value_mod = value.to_s.gsub(' ','+')
				url+= '&' + key.to_s + '=' + value_mod.to_s
    		end

    		puts url

    		return url

    	end


end