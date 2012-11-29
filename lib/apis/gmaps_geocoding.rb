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

module GoogleMapsGeocoding

  def self.getPlaceInfo(place)
    return makeRequest({:search_place => place})
  end

  private
  def self.makeRequest(params)
    ret_value = {}

    begin

      url = generateUrl(params)
      doc = HTTParty.get(url).parsed_response

    rescue Exception => e

      #puts e.message
      #puts e.backtrace.join("\n")

      ret_value["success"] = false
      ret_value["message"] = e.message

      return ret_value
    end

    if doc["status"] != nil && doc["status"] != "OK"
      ret_value["success"] = false
      ret_value["message"] = e.message

      return ret_value
    end

    location = doc["results"][0]["geometry"]["location"]

    address_components = doc["results"][0]["address_components"]

    city = ""
    country = ""
    address_components.each do |address|
      if address["types"][0] == "locality"
        city = address["long_name"]
      elsif address["types"][0] == "country"
        country = address["long_name"]
      end
    end

    ret_value["success"] = true
    ret_value["data"] = {
      :lat => location["lat"],
      :lng => location["lng"],
      :country => country,
      :city => city
    }
  
    return ret_value
  end

  def self.generateUrl(params)
    url = "http://maps.googleapis.com/maps/api/geocode/json?sensor=false&address="

    value_mod = params[:search_place].to_s.gsub(' ','+')
    url+= value_mod.to_s

    return url
  end
end