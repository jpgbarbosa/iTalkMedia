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

module LastFM
	
	#http://www.last.fm/api/show/album.getArtist
	def self.getArtist(artist_name)
		return makeRequest({:method => "artist.getinfo", :artist => artist_name})
	end

	#http://www.last.fm/api/show/album.getInfo
	def self.getAlbum(artist_name,album_name)
		return makeRequest({:method => "album.getInfo", :artist => artist_name, :album => album_name})
	end

	#http://www.last.fm/api/show/album.getTrack
	def self.getTrack(artist_name,track_name)
		return makeRequest({:method => "track.getInfo", :artist => artist_name, :track => track_name})
	end

	#http://www.last.fm/api/show/artist.getSimilar
	def self.getSimilarArtist(artist_name)
		return makeRequest({:method => "artist.getSimilar", :artist => artist_name})
	end

    private
    	def self.makeRequest(params)
    		ret_value = {}
		
			begin
			
				url = generateUrl(params)
				doc = HTTParty.get(url)

			rescue Exception => e

				puts e.message
				puts e.backtrace.join("\n")

				ret_value["success"] = false
				ret_value["message"] = e.message

				return ret_value
			end

			if doc["error"]!=nil
				ret_value["success"] = false
				ret_value["message"] = doc["message"]
			else
				ret_value["success"] = true
				ret_value["data"] = doc
			end

			return ret_value

    	end
    	
    	def self.generateUrl(params,type="json")
    		url = ENV['BASE_URL']

    		params.each do |key,value|
    			url+= '&' + key.to_s + '=' + value.to_s
    		end

			url+= '&api_key='+ENV['LAST_FM_API_KEY_BARBOSA']
   			url+= '&format=json'

    		return url

    	end


end