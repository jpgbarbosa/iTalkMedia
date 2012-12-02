require 'json'
require 'httparty'
require 'awesome_print'

#Return strucure
# if error => hash with:
# 	success : false
# 	message : error message
# if success
# 	success : true
# 	data    : doc to be returned

module MusicBrainz

  def self.getBandMBID(name)
    return makeRequest({:name => name})
  end

  private
  def self.makeRequest(params)
    ret_value = {}

    begin

      url = generateUrl(params)
      doc = HTTParty.get(url).parsed_response

    rescue Exception => e
      ret_value["success"] = false
      ret_value["message"] = e.message

      return ret_value
    end

    ret_value["success"] = true
    ret_value["data"] = {
      :id => doc["metadata"]["artist_list"]["artist"]["id"]
    }
  
    return ret_value
  end

  def self.generateUrl(params)
    url = "http://musicbrainz.org/ws/2/artist?query="

    value_mod = params[:name].to_s.gsub(' ','+')
    url+= value_mod.to_s
    url+= "&limit=1"
    
    return url
  end
end