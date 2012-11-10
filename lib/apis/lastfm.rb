require 'httparty'
require 'json'
require 'awesome_print'

module LastFM
	
	def self.getArtist(artist_name)
		
		begin
		
			url = generateUrl({:method => "artist.getinfo", :artist => artist_name})
			doc = HTTParty.get(url)

		rescue Exception => e

			puts e.message
			puts e.backtrace.join("\n")

			if e.message == '400 Bad Request'
				@name = 'User not found.'
			else
				@name = 'Connection to Last.fm failed.'
			end

			return @name
		end

		return 'here2'
	end

    private
    	
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