require 'lib/jar/javalib/commons-codec-1.5.jar'
require 'lib/jar/javalib/jena-core-2.7.3.jar'     
require 'lib/jar/javalib/slf4j-api-1.6.4.jar'
require 'lib/jar/javalib/httpclient-4.1.2.jar'
require 'lib/jar/javalib/jena-iri-0.9.3.jar'     
require 'lib/jar/javalib/slf4j-log4j12-1.6.4.jar'
require 'lib/jar/javalib/httpcore-4.1.3.jar'
require 'lib/jar/javalib/jena-tdb-0.9.3.jar'
require 'lib/jar/javalib/xercesImpl-2.10.0.jar'
require 'lib/jar/javalib/jena-arq-2.9.3.jar'
require 'lib/jar/javalib/log4j-1.2.16.jar'
require 'lib/jar/javalib/xml-apis-1.4.01.jar'

require 'musicbrainz'
require 'date'
require 'CGI'

require 'java'

java_import "com.hp.hpl.jena.query.Dataset"
java_import "com.hp.hpl.jena.query.QueryExecution"
java_import "com.hp.hpl.jena.query.QueryFactory"
java_import "com.hp.hpl.jena.query.QueryExecutionFactory"
java_import "com.hp.hpl.jena.query.ReadWrite"
java_import "com.hp.hpl.jena.query.ResultSet"
java_import "com.hp.hpl.jena.query.ResultSetFormatter"
java_import "com.hp.hpl.jena.tdb.TDBFactory"
java_import "com.hp.hpl.jena.rdf.model.Model"
java_import "com.hp.hpl.jena.rdf.model.ModelFactory"
java_import "com.hp.hpl.jena.rdf.model.Property"
java_import "com.hp.hpl.jena.ontology.OntProperty"
java_import "com.hp.hpl.jena.rdf.model.Resource"

class Music < ActiveRecord::Base
  attr_accessible :name, :path

	def self.get_all()
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory);
    
    musics = []
    
  	begin
      dataset.begin(ReadWrite::READ)
      query = %q(PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#> 
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> 
					    SELECT ?track_id ?track_name ?track_bitrate ?track_lyric ?track_length ?track_num ?track_year ?album ?album_name ?band ?band_name ?lastPlayed ?playcount
              WHERE {
	                  ?track_id rdf:type mo:Track ; 
	                    mo:name ?track_name ; 
	                    mo:bitrate ?track_bitrate ;
	                    mo:tracklength ?track_length ; 
	                    mo:tracknum ?track_num ; 
	                    mo:year ?track_year ;
                      mo:musicalgroup ?band ;
                      mo:inAlbum ?album .
                    ?band rdf:type mo:MusicalGroup ;
                      mo:name ?band_name .
                    ?album rdf:type mo:Album ;
                      mo:name ?album_name .
	                  OPTIONAL { ?track_id mo:hasLyric ?track_lyric . } .
                    OPTIONAL { ?track_id mo:lastPlayed ?lastPlayed . } .
                    OPTIONAL { ?track_id mo:playcount ?playcount . } .
	                } ORDER BY ?track_id)
        
      query = QueryFactory.create(query)

      qexec = QueryExecutionFactory.create(query, dataset)
      rs = qexec.exec_select
      
      genres = []

      while rs.has_next
        music = {}
        qs = rs.next

        music[:id] = qs.get("track_id").get_uri.to_s.split("#").last
        music[:name] = qs.get("track_name").string.to_s
        music[:bitrate] = qs.get("track_bitrate").string.to_s
        music[:length] = qs.get("track_length").string.to_s
        music[:num] = qs.get("track_num").string.to_s
        music[:year] = qs.get("track_year").string.to_s
        music[:artist] = qs.get("band_name").string.to_s
        music[:artist_id] = qs.get("band").get_uri.to_s.split("#").last
        music[:album] = qs.get("album_name").string.to_s
        music[:album_id] = qs.get("album").get_uri.to_s.split("#").last
        lyric = qs.get("track_lyric")
        if lyric==nil
          music[:lyric] = ""
        else
          music[:lyric] = lyric.string.to_s
        end
        
        if qs.get("lastPlayed")==nil
          music[:lastPlayed] = ""
        else
          music[:lastPlayed] = qs.get("lastPlayed").string.to_s
        end
        
        if qs.get("playcount")==nil
          music[:playcount] = 0
        else
          music[:playcount] = qs.get("playcount").get_int
        end
        

        if music[:length].to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil
        	music[:length] == "undefined"
        else
        	music[:length]= "#{music[:length].to_i/60}:#{sprintf("%02d",music[:length].to_i%60)} mins"
        end

        #Read genres aside
        music[:genres] = get_genres(music[:id])

        musics << music

      end
    ensure
      dataset.end()
    end
    
    return musics
	end
  
  def self.get_by_id(id)
 		ontology_ns = "http://musicontology.ws.dei.uc.pt/ontology.owl#"
    ns = "http://musicontology.ws.dei.uc.pt/music#"
    place_ns = "http://musicontology.ws.dei.uc.pt/place#"
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory)
	    
    dataset.begin(ReadWrite::READ )
    begin
      query = %Q(PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#> 
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> 
					    SELECT ?track_name ?track_bitrate ?genre_name ?track_lyric ?track_length ?track_num ?track_year ?album ?album_name ?band ?band_name ?lastPlayed ?playcount
              WHERE {
	                  <#{ns+id}> rdf:type mo:Track ;
	                    mo:name ?track_name ; 
	                    mo:bitrate ?track_bitrate ;
	                    mo:genre ?genre ; 
	                    mo:tracklength ?track_length ; 
	                    mo:tracknum ?track_num ; 
	                    mo:year ?track_year ;
                      mo:musicalgroup ?band ;
                      mo:inAlbum ?album .
	                  ?genre rdf:type mo:Genre ; 
	                    mo:name ?genre_name .
                    ?band rdf:type mo:MusicalGroup ;
                      mo:name ?band_name .
                    ?album rdf:type mo:Album ;
                      mo:name ?album_name .
	                  OPTIONAL { <#{ns+id}> mo:hasLyric ?track_lyric . } .
                    OPTIONAL { <#{ns+id}> mo:lastPlayed ?lastPlayed . } .
                    OPTIONAL { <#{ns+id}> mo:playcount ?playcount . } .
	                } )
      
      query = QueryFactory.create(query)

      qexec = QueryExecutionFactory.create(query, dataset)
      rs = qexec.exec_select
      
      if rs.has_next
        music = {}
        qs = rs.next

        music[:id] = id
        music[:name] = qs.get("track_name").string.to_s
        music[:bitrate] = qs.get("track_bitrate").string.to_s
        music[:length] = qs.get("track_length").string.to_s
        music[:num] = qs.get("track_num").string.to_s
        music[:year] = qs.get("track_year").string.to_s
        music[:artist] = qs.get("band_name").string.to_s
        music[:artist_id] = qs.get("band").get_uri.to_s.split("#").last
        music[:album] = qs.get("album_name").string.to_s
        music[:album_id] = qs.get("album").get_uri.to_s.split("#").last
        lyric = qs.get("track_lyric")
        if lyric==nil
          music[:lyric] = ""
        else
          music[:lyric] = lyric.string.to_s
        end
        
        if qs.get("lastPlayed")==nil
          music[:lastPlayed] = ""
        else
          music[:lastPlayed] = qs.get("lastPlayed").string.to_s
        end
        
        if qs.get("playcount")==nil
          music[:playcount] = 0
        else
          music[:playcount] = qs.get("playcount").get_int
        end
        

        if music[:length].to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil
        	music[:length] == "undefined"
        else
        	music[:length]= "#{music[:length].to_i/60}:#{sprintf("%02d",music[:length].to_i%60)} mins"
        end

        music[:genres] = get_genres(id)
      end
      ap music
      return music
    ensure
      dataset.end()
    end
  end


  def self.get_genres(id)
    ns = "http://musicontology.ws.dei.uc.pt/music#"
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory)
    
    begin
      dataset.begin(ReadWrite::READ)
      query = %Q(PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
              PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
              SELECT ?genre_name
              WHERE {
                    <#{ns+id}> rdf:type mo:Track ;
                      mo:genre ?genre .
                    ?genre rdf:type mo:Genre ; 
                      mo:name ?genre_name .
              })

      query = QueryFactory.create(query)
      qexec = QueryExecutionFactory.create(query, dataset)
      rs = qexec.exec_select
      
      if !rs.has_next
        return nil
      end
      
      genres = []
      while rs.has_next
        qs = rs.next

        genres << qs.get("genre_name").string.to_s

      end

      return genres
    ensure
      dataset.end()
    end
  end
  
  def self.get_album_cover(album_id)
    ns = "http://musicontology.ws.dei.uc.pt/music#"
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory)
    
    begin
      dataset.begin(ReadWrite::READ)
      query = %Q(PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
              PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
              SELECT ?cover
              WHERE {
                    <#{ns+album_id}> rdf:type mo:Album ;
                      mo:hasCover ?cover .
              })

      query = QueryFactory.create(query)
      qexec = QueryExecutionFactory.create(query, dataset)
      rs = qexec.exec_select
      
      if !rs.has_next
        return ""
      end
      
      qs = rs.next
      cover = qs.get("cover").string.to_s

      return cover
    ensure
      dataset.end()
    end
  end
  
  def self.get_recommendation(genres, track_id)
    genres_hash = {}
    
    genres.each do |g|
      genres_hash[g] = 1
    end
    
    recommended = []
    
    all_tracks = get_all
    all_tracks.each do |track|
      if track[:id] != track_id
        count = 0
        
        track[:genres].each do |genre|
          # genre also in the album genre
          if genres_hash[genre] != nil
            count = count+1
          end
        end
        
        if count > 0
          plays = track[:playcount]
          
          if plays==nil
            plays = 0
          end
          
          track_rec = {
            :track => {
              :id => track[:id],
              :name => track[:name],
              :cover => get_album_cover(track[:album_id])
            },
            :count => count*5 + plays
          }
          
          recommended << track_rec
        end
      end
    end
    
    # sort by count (descending)
    recommended.sort! { |track1, track2| track2[:count] <=> track1[:count] }
    # return the first 5
    recommended = recommended[0..4]
    ap recommended
    return recommended
  end


 	def self.setJenaInfo(data_processed)
 		ontology_ns = "http://musicontology.ws.dei.uc.pt/ontology.owl#"
    ns = "http://musicontology.ws.dei.uc.pt/music#"
    place_ns = "http://musicontology.ws.dei.uc.pt/place#"
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory)
	    
    dataset.begin(ReadWrite::WRITE)
    begin
      model = dataset.get_default_model()
      model.set_ns_prefix("mo", ontology_ns)
      model.set_ns_prefix("item", ns)
      model.set_ns_prefix("place", place_ns)
      
      iterator = model.list_statements()
      ctr = 0
      while iterator.has_next
        ctr+=1
        iterator.next
      end
      
      puts ctr
	      
      # CLASSES #
			ont_artist = ONTOLOGY.get_ont_class(ontology_ns+"Artist")
      ont_album = ONTOLOGY.get_ont_class(ontology_ns+"Album")
			ont_city = ONTOLOGY.get_ont_class(ontology_ns+"City")
			ont_concert = ONTOLOGY.get_ont_class(ontology_ns+"Concert")
			ont_country = ONTOLOGY.get_ont_class(ontology_ns+"Country")
			ont_genre = ONTOLOGY.get_ont_class(ontology_ns+"Genre")
			ont_label = ONTOLOGY.get_ont_class(ontology_ns+"Label")
			ont_musicalGroup = ONTOLOGY.get_ont_class(ontology_ns+"MusicalGroup")
			ont_place = ONTOLOGY.get_ont_class(ontology_ns+"Place")
			ont_track = ONTOLOGY.get_ont_class(ontology_ns+"Track")
      puts ont_track
	      
      # PROPERTIES #
			ont_p_name = ONTOLOGY.get_property(ontology_ns+"name")
			ont_p_endYear = ONTOLOGY.get_property(ontology_ns+"endYear")
			ont_p_foundationYear = ONTOLOGY.get_property(ontology_ns+"foundationYear")
			ont_p_year = ONTOLOGY.get_property(ontology_ns+"year")
			ont_p_hasAlbum = ONTOLOGY.get_property(ontology_ns+"hasAlbum")
			ont_p_hasArtist = ONTOLOGY.get_property(ontology_ns+"hasArtist")
			ont_p_hasLyric = ONTOLOGY.get_property(ontology_ns+"hasLyric")
			ont_p_hasLabel = ONTOLOGY.get_property(ontology_ns+"hasLabel")
			ont_p_hasTrack = ONTOLOGY.get_property(ontology_ns+"hasTrack")
      ont_p_hasCover = ONTOLOGY.get_ont_property(ontology_ns+"hasCover")
      ont_p_hasBio = ONTOLOGY.get_property(ontology_ns+"hasBio")
      ont_p_hasPerformance = ONTOLOGY.get_property(ontology_ns+"hasPerformance")
      ont_p_hasConcert = ONTOLOGY.get_property(ontology_ns+"hasConcert")
			ont_p_trackLength = ONTOLOGY.get_property(ontology_ns+"tracklength")
			ont_p_inPlace = ONTOLOGY.get_property(ontology_ns+"inPlace")
			ont_p_inCountry = ONTOLOGY.get_property(ontology_ns+"inCountry")
			ont_p_inCity = ONTOLOGY.get_property(ontology_ns+"inCity")
      ont_p_inAlbum = ONTOLOGY.get_property(ontology_ns+"inAlbum")
      ont_p_latitude = ONTOLOGY.get_property(ontology_ns+"latitude")
      ont_p_longitude = ONTOLOGY.get_property(ontology_ns+"longitude")
      ont_p_placeFormed = ONTOLOGY.get_property(ontology_ns+"placeFormed")
      ont_p_isSimilarTo = ONTOLOGY.get_ont_property(ontology_ns+"isSimilarTo")
      ont_p_isLastFMSimilar = ONTOLOGY.get_ont_property(ontology_ns+"isLastFMSimilar")
			ont_p_lastFMURL = ONTOLOGY.get_property(ontology_ns+"lastFMURL")
			ont_p_bitrate = ONTOLOGY.get_property(ontology_ns+"bitrate")
			ont_p_musicalGroup = ONTOLOGY.get_property(ontology_ns+"musicalgroup")
			ont_p_genre = ONTOLOGY.get_property(ontology_ns+"genre")
			ont_p_trackcount = ONTOLOGY.get_ont_property(ontology_ns+"trackcount")
			ont_p_date = ONTOLOGY.get_ont_property(ontology_ns+"date")
			ont_p_tracknum = ONTOLOGY.get_ont_property(ontology_ns+"tracknum")
      ont_p_songKickURL = ONTOLOGY.get_ont_property(ontology_ns+"songKickURL")
      # iTunes properties
      ont_p_lastPlayed = ONTOLOGY.get_ont_property(ontology_ns+"lastPlayed")
      ont_p_playcount = ONTOLOGY.get_ont_property(ontology_ns+"playcount")
	      
      puts "---------\nSIZE: #{data_processed.length}\n--------"
      
      cached_musicbrainz = {}
	      
      data_processed.each do |data|
        group_info = data[1]["artist"]["data"]["artist"]
        track_info = data[1]["title"]["data"]["track"]
	        
        # MUSIC GROUP INFO #
	        
        musical_group = model.create_resource(ns+"#{group_info["mbid"]}", ont_musicalGroup)
        track = model.create_resource(ns+"#{track_info["id"]}", ont_track)
	        
        musical_group.add_property(ont_p_name, data[0]["artist"])
        musical_group.add_property(ont_p_lastFMURL, group_info["url"])
        musical_group.add_property(ont_p_hasCover, group_info["image"][-1]["#text"]) #the biggest

        if (members = getSafeField(group_info,["bandmembers","member"]))!=nil
          members.each do |member|
            member_resource = model.create_resource(ns+group_info["name"]+"/"+member["name"], ont_artist)
            member_resource.add_property(ont_p_name, member["name"])
            musical_group.add_property(ont_p_hasArtist, member_resource)
            member_resource.add_property(ont_p_musicalGroup, musical_group)
          end
        end
	        
        tags = group_info["tags"]["tag"]
        tags.each do |tag|
          tag_resource = model.create_resource(tag["url"], ont_genre) # tag url is the URI
          tag_resource.add_property(ont_p_name, tag["name"])
          musical_group.add_property(ont_p_genre, tag_resource)
        end
	        
        bio_info = group_info["bio"]
        musical_group.add_property(ont_p_hasBio, bio_info["content"]) #could also be summary (shorter version)
        if bio_info["formationlist"]["formation"].class == Hash 
          musical_group.add_property(ont_p_foundationYear, bio_info["formationlist"]["formation"]["yearfrom"])
          if bio_info["formationlist"]["formation"]["yearto"]!=nil && bio_info["formationlist"]["formation"]["yearto"] != ""
            musical_group.add_property(ont_p_endYear, bio_info["formationlist"]["formation"]["yearto"])
          end
        else # is array
          musical_group.add_property(ont_p_foundationYear, bio_info["formationlist"]["formation"][0]["yearfrom"])
          if bio_info["formationlist"]["formation"].last["yearto"]!=nil && bio_info["formationlist"]["formation"].last["yearto"] != ""
            musical_group.add_property(ont_p_endYear, bio_info["formationlist"]["formation"].last["yearto"])
          end
        end
	        
        #- Geocoding Placeformed #
        placeformed_info = GoogleMapsGeocoding.getPlaceInfo(CGI.escape(bio_info["placeformed"]))
        if placeformed_info["success"]
          placeformed_info=placeformed_info["data"]
          placeformed = model.create_resource(place_ns+"#{placeformed_info[:lat]}-#{placeformed_info[:lng]}", ont_place)
          placeformed_city = model.create_resource(place_ns+"#{placeformed_info[:city]}", ont_city)
          placeformed_city.add_property(ont_p_name, placeformed_info[:city])
          placeformed_country = model.create_resource(place_ns+"#{placeformed_info[:country]}", ont_country)
          placeformed_country.add_property(ont_p_name, placeformed_info[:country])
          placeformed.add_property(ont_p_inCity, placeformed_city).add_property(ont_p_inCountry, placeformed_country)
          placeformed.add_property(ont_p_latitude, placeformed_info[:lat]).add_property(ont_p_longitude, placeformed_info[:lng])
          musical_group.add_property(ont_p_placeFormed, placeformed)
        end
	        
        #- LastFM Similar #
        similars = group_info["similar"]["artist"]
        similars.each do |s|
          if !cached_musicbrainz.has_key?(s["name"])
            mbid = MusicBrainz.getBandMBID(s["name"])
            if mbid["success"]
              sim = model.create_resource(ns+mbid["data"][:id], ont_musicalGroup)
              sim.add_property(ont_p_name, s["name"])
              sim.add_property(ont_p_lastFMURL, s["url"])
              sim.add_property(ont_p_hasCover, s["image"].last["#text"])
              musical_group.add_property(ont_p_isLastFMSimilar, sim)
              sim.add_property(ont_p_isLastFMSimilar, musical_group)
              cached_musicbrainz[s["name"]] = {
                :id => mbid["data"][:id],
              }
            end
          else
            sim_info = cached_musicbrainz[s["name"]]
            sim = model.create_resource(ns+sim_info[:id], ont_musicalGroup)
            sim.add_property(ont_p_name, s["name"])
            sim.add_property(ont_p_lastFMURL, s["url"])
            sim.add_property(ont_p_hasCover, s["image"].last["#text"])
            musical_group.add_property(ont_p_isLastFMSimilar, sim)
            sim.add_property(ont_p_isLastFMSimilar, musical_group)
          end
        end

        # ALBUM INFO #
        album_info = data[1]["album"]["data"]["album"]
        
        if album_info["mbid"]!=""
          album = model.create_resource(ns+"#{album_info["mbid"]}", ont_album)
        else
          album_mbid = MusicBrainz.getAlbumMBID(data[0]["album"])
          if album_mbid["success"]
            album_mbid = album_mbid["data"][:id]
            album = model.create_resource(ns+"#{album_mbid}", ont_album)
          end
        end
        album.add_property(ont_p_name, data[0]["album"])
        album.add_property(ont_p_trackcount, album_info["tracks"]["track"].size)
        album.add_property(ont_p_lastFMURL, album_info["url"])
        album.add_property(ont_p_hasCover, album_info["image"][-1]["#text"]) #the biggest

        if (tags = getSafeField(album_info,["toptags","tag"]))!=nil
          tags.each do |tag|
            tag_resource = model.create_resource(tag["url"], ont_genre)
            tag_resource.add_property(ont_p_name, tag["name"])
            album.add_property(ont_p_genre, tag_resource)
          end
        end
        
        if album_info["releasedate"]!=nil && album_info["releasedate"].strip!=""
          album.add_property(ont_p_date, Date.parse(album_info["releasedate"]).to_s)
        end

        musical_group.add_property(ont_p_hasAlbum, album)
        album.add_property(ont_p_musicalGroup, musical_group)
	        
	        
        # TRACK INFO #
        track.add_property(ont_p_name, data[0]["title"])
        track.add_property(ont_p_musicalGroup, musical_group)
        track.add_property(ont_p_inAlbum, album)
        album.add_property(ont_p_hasTrack, track)
	        
        if data[0]["bitrate"] != nil
          track.add_property(ont_p_bitrate, data[0]["bitrate"])
        end
	        
        track.add_property(ont_p_trackLength, data[0]["length"])
        track.add_property(ont_p_year, data[0]["year"])
        track.add_property(ont_p_tracknum, data[0]["tracknum"])
        
        #-Lyric
        if data[3]["title"]["success"]
          track.add_property(ont_p_hasLyric, data[3]["title"]["data"])
        end
	        
        tags = track_info["toptags"]["tag"]
        tags.each do |tag|
          begin
            tag_resource = model.create_resource(tag["url"].to_s, ont_genre)
            tag_resource.add_property(ont_p_name, tag["name"])
            track.add_property(ont_p_genre, tag_resource)
          rescue Exception => e
            puts "Invalid TAG!"
          end
        end
	        
        # EVENTS INFO #
        if data[2]["events"]["success"] == true && data[2]["events"]["data"]!={}
          events_info = data[2]["events"]["data"]["event"]

          events_info.each do |e|
            event = model.create_resource(ns+e["id"].to_s, ont_concert)
            event.add_property(ont_p_hasPerformance, musical_group)
            musical_group.add_property(ont_p_hasConcert, event)

            event.add_property(ont_p_name, e["displayName"])
            event.add_property(ont_p_songKickURL, e["uri"])
            event.add_property(ont_p_date, e["start"]["date"])

            place = model.create_resource(place_ns+"#{e["venue"]["id"].to_s}", ont_place)
            place.add_property(ont_p_name, e["venue"]["displayName"])
            if e["location"]["lat"]!=nil && e["location"]["lng"]!=nil
              place.add_property(ont_p_latitude, e["location"]["lat"])
              place.add_property(ont_p_longitude, e["location"]["lng"])
            end

            city, country = e["location"]["city"].split(",")
            city.strip!
            country.strip!
            city_r = model.create_resource(place_ns+"#{country}-#{city}", ont_city)
            city_r.add_property(ont_p_name, city)
            country_r = model.create_resource(place_ns+"#{country}", ont_country)
            country_r.add_property(ont_p_name, country)

            place.add_property(ont_p_inCity, city_r)
            place.add_property(ont_p_inCountry, country_r)
	            
            event.add_property(ont_p_inPlace, place)
          end
        end
        
        #--- iTunes INFO ---#
        last_played_date = `osascript -e 'tell application "iTunes" to get played date of track "#{data[0]["title"]}" in playlist "#{data[0]["artist"]}"'`
        if last_played_date != ""
          last_played_date = Date.parse(last_played_date)
          track.add_property(ont_p_lastPlayed, last_played_date.to_s)
        end
        
        played_count = `osascript -e 'tell application "iTunes" to get played count of track "#{data[0]["title"]}" in playlist "#{data[0]["artist"]}"'`
        if played_count != ""
          played_count = played_count.to_i
          track.add_property(ont_p_playcount, played_count)
        end
        
      end
	    
      #model.write(java.lang.System::out, "RDF/XML-ABBREV")
      
      dataset.commit()
    ensure
      dataset.end()
    end
	end

  def self.getSafeField(base, fields=[])

    hash = base

    begin
      fields.each do |f|

        hash = hash[f]
      end

      return hash
    rescue
      return nil
    end

  end

end
