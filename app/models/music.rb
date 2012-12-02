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
					    SELECT ?track_id ?track_name ?track_bitrate ?track_lyric ?track_length ?track_num ?track_year ?album ?album_name ?band ?band_name
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

        if music[:length].to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil
        	music[:length] == "undefined"
        else
        	music[:length]= "#{music[:length].to_i/60}:#{sprintf("%2d",music[:length].to_i%60)} mins"
        end

        #Read genres aside
        music[:genres] = get_genres(music[:id])

        ap music[:genres]

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
					    SELECT ?track_name ?track_bitrate ?genre_name ?track_lyric ?track_length ?track_num ?track_year ?album ?album_name ?band ?band_name
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
	                  OPTIONAL { ?track_id mo:hasLyric ?track_lyric . } .
	                } ORDER BY ?track_id)
      
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

        if music[:length].to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil
        	music[:length] == "undefined"
        else
        	music[:length]= "#{music[:length].to_i/60}:#{sprintf("%2d",music[:length].to_i%60)} mins"
        end
        
        puts "lyric #{qs.get("track_lyric")}"

        music[:genres] = get_genres(id)
      end

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
      ont_p_hasCover = ONTOLOGY.get_property(ontology_ns+"hasCover")
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
      ont_p_isSimilarTo = ONTOLOGY.get_property(ontology_ns+"isSimilarTo")
      ont_p_isLastFMSimilar = ONTOLOGY.get_property(ontology_ns+"isLastFMSimilar")
			ont_p_lastFMURL = ONTOLOGY.get_property(ontology_ns+"lastFMURL")
			ont_p_bitrate = ONTOLOGY.get_property(ontology_ns+"bitrate")
			ont_p_musicalGroup = ONTOLOGY.get_property(ontology_ns+"musicalgroup")
			ont_p_genre = ONTOLOGY.get_property(ontology_ns+"genre")
			ont_p_trackcount = ONTOLOGY.get_property(ontology_ns+"trackcount")
			ont_p_date = ONTOLOGY.get_property(ontology_ns+"date")
			ont_p_tracknum = ONTOLOGY.get_property(ontology_ns+"tracknum")
      ont_p_songKickURL = ONTOLOGY.get_property(ontology_ns+"songKickURL")
	      
      puts "---------\nSIZE: #{data_processed.length}\n--------"
	      
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
        musical_group.add_property(ont_p_hasBio, bio_info["content"]) #could also be summary
        musical_group.add_property(ont_p_foundationYear, bio_info["formationlist"]["formation"]["yearfrom"])
        if bio_info["formationlist"]["formation"]["yearto"]!=nil && bio_info["formationlist"]["formation"]["yearto"] != ""
          musical_group.add_property(ont_p_foundationYear, bio_info["formationlist"]["formation"]["yearto"])
        end
	        
        #- Geocoding Placeformed #
        placeformed_info = GoogleMapsGeocoding.getPlaceInfo(bio_info["placeformed"])
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
          s_iter = model.list_subjects_with_property(ont_p_lastFMURL, s["url"])
          while s_iter.has_next
            sim = s_iter.next_resource
            musical_group.add_property(ont_p_isLastFMSimilar, sim)
            sim.add_property(ont_p_isLastFMSimilar, musical_group)
          end
        end

        # ALBUM INFO #
        album_info = data[1]["album"]["data"]["album"]

        album = model.create_resource(ns+"#{album_info["mbid"]}", ont_album)
        album.add_property(ont_p_name, data[0]["album"])
        album.add_property(ont_p_trackcount, album_info["tracks"].size)
        album.add_property(ont_p_lastFMURL, album_info["url"])
        album.add_property(ont_p_hasCover, album_info["image"][-1]["#text"]) #the biggest
	        
        if (tags = getSafeField(album_info,["toptags","tag"]))!=nil
          tags.each do |tag|
            tag_resource = model.create_resource(tag["url"], ont_genre)
            tag_resource.add_property(ont_p_name, tag["name"])
            album.add_property(ont_p_genre, tag_resource)
          end
        end

        musical_group.add_property(ont_p_hasAlbum, album)
        album.add_property(ont_p_musicalGroup, musical_group)
	        
	        
        # TRACK INFO #
        track.add_property(ont_p_name, data[0]["title"])
        track.add_property(ont_p_musicalGroup, musical_group)
        track.add_property(ont_p_inAlbum, album)
        album.add_property(ont_p_hasTrack, track)
	        
        if(data[0]["bitrate"]) != nil
          track.add_property(ont_p_bitrate, data[0]["bitrate"])
        end
	        
        track.add_property(ont_p_trackLength, data[0]["length"])
        track.add_property(ont_p_year, data[0]["year"])
        track.add_property(ont_p_tracknum, data[0]["tracknum"])
	        
        tags = track_info["toptags"]["tag"]
        tags.each do |tag|
          tag_resource = model.create_resource(tag["url"], ont_genre)
          tag_resource.add_property(ont_p_name, tag["name"])
          track.add_property(ont_p_genre, tag_resource)
        end
	        
        # EVENTS INFO #
        if data[2]["events"]["success"] == true
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
            place.add_property(ont_p_latitude, e["location"]["lat"])
            place.add_property(ont_p_longitude, e["location"]["lng"])

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
	        
        model.write(java.lang.System::out, "RDF/XML-ABBREV")
      end
	      
	      
	      
	      
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
