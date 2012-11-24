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

module ChartLyricsAPI
  
  def self.getLyric(artist_name, song_name)
    return makeRequest({:artist=>artist_name, :song=>song_name})
  end
  
  private
  def self.makeRequest(params)
    ret_value = {}
		
    begin
			
      url = generateUrl(params)
      doc = HTTParty.get(url).parsed_response

    rescue Exception => e

      puts e.message
      puts e.backtrace.join("\n")

      ret_value["success"] = false
      ret_value["message"] = e.message

      return ret_value
    end
  
    if doc["ArrayOfSearchLyricResult"]["SearchLyricResult"]["xsi:nil"]
      ret_value["success"] = false
      ret_value["message"] = doc["message"]
      return ret_value
    end
  
    begin
      lyricID = doc["ArrayOfSearchLyricResult"]["SearchLyricResult"][0]["LyricId"]
      lyricCS = doc["ArrayOfSearchLyricResult"]["SearchLyricResult"][0]["LyricChecksum"]
      params = {:lyricID => lyricID, :lyricCheckSum => lyricCS}
      url = generateUrl(params, "getLyric")
      doc = HTTParty.get(url).parsed_response
    rescue Exception => e
      puts e.message
      puts e.backtrace.join("\n")

      ret_value["success"] = false
      ret_value["message"] = e.message

      return ret_value
    end
  
    ret_value["success"] = true
    ret_value["data"] = doc["GetLyricResult"]["Lyric"]
  
    return ret_value
  end

  def self.generateUrl(params, type="Search")
    if type=="Search"
      url = "http://api.chartlyrics.com/apiv1.asmx/SearchLyric?" #ENV['BASE_URL_LAST_FM']
    else
      url = "http://api.chartlyrics.com/apiv1.asmx/GetLyric?" #ENV['BASE_URL_LAST_FM']
    end
	

    params.each do |key,value|
      value_mod = value.to_s.gsub(' ','%20')
      url+= '&' + key.to_s + '=' + value_mod.to_s
    end

    return url

  end
end