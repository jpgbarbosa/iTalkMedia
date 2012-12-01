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

class Album < ActiveRecord::Base
  attr_accessible :name

  def self.get_album_info(params)

  end

  def self.get_musics_by_album(params)
    
    ontology_ns = "http://musicontology.ws.dei.uc.pt/ontology.owl#"
    ns = "http://musicontology.ws.dei.uc.pt/music#"
    place_ns = "http://musicontology.ws.dei.uc.pt/place#"
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
        music[:genres] = nil #get_genres(music[:id])

        ap music[:genres]

        musics << music

      end
    ensure
      dataset.end()
    end
    
    	return musics
	end


end
