require 'json'
require 'awesome_print'
require 'httparty'
require 'lib/jar/javalib/jsoup-1.7.1.jar'
require 'CGI'

require 'java'

java_import "org.jsoup.Jsoup"
java_import "org.jsoup.nodes.Document"
java_import "org.jsoup.nodes.Element"
java_import "org.jsoup.select.Elements"

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
      url.gsub!(" ","_")
      ap url
      user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.97 Safari/537.11"
      doc = Jsoup.connect(url).user_agent(user_agent).get()

    rescue Exception => e
      ap e
      ret_value["success"] = false
      ret_value["message"] = e.message

      return ret_value
    end
    
    element = doc.select("div.lyricbox").first()
    if element==nil
      ret_value["success"] = false
      ret_value["message"] = "No lyric found!"

      return ret_value
    end
    
    # REMOVE RINGTONE AD
    ads = doc.select("div.lyricbox div.rtMatcher")
    element.removeChild(ads.first)
    element.removeChild(ads.last)
    
    ret_value["success"] = true
    ret_value["data"] = element.text()

    return ret_value
    
  end

  def self.generateUrl(params, type="Search")
    url = "http://lyrics.wikia.com/#{params[:artist].downcase.capitalize}:#{params[:song].downcase}"
    return url
  end
end