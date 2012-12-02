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

class Group < ActiveRecord::Base
  attr_accessible :bio, :endYear, :foundationYear, :genre, :lastfmUrl, :name


  #TDB interface
  def self.get_by_id(id)
 		ontology_ns = "http://musicontology.ws.dei.uc.pt/ontology.owl#"
    ns = "http://musicontology.ws.dei.uc.pt/music#"
    place_ns = "http://musicontology.ws.dei.uc.pt/place#"
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory);
    
    bands = []
    
    begin
      dataset.begin(ReadWrite::READ)
      query = %Q(PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
					    SELECT ?band_id ?band_name ?bio ?cover ?lastFMURL ?foundation_year ?place_formed_id ?end_year
              WHERE {
	                  <#{ns+id}> rdf:type mo:MusicalGroup ;
	                    mo:name ?band_name ;
                      mo:hasBio ?bio ;
                      mo:hasCover ?cover ;
                      mo:lastFMURL ?lastFMURL ;
                      mo:foundationYear ?foundation_year ;
                      mo:placeFormed ?place_formed_id .
	                  OPTIONAL { ?band_id mo:endYear ?end_year . } .
              })
        
      query = QueryFactory.create(query)

      qexec = QueryExecutionFactory.create(query, dataset)
      rs = qexec.exec_select
      #ResultSetFormatter.out(rs)

      if !rs.has_next
        return nil
      end
      
      band = {}
      qs = rs.next

      band[:id] = ns+id
      band[:name] = qs.get("band_name").string.to_s
      band[:bio] = qs.get("bio").string.to_s
      band[:cover] = qs.get("cover").string.to_s
      band[:lastFMURL] = qs.get("lastFMURL").string.to_s
      band[:foundation_year] = qs.get("foundation_year").to_s
      band[:end_year] = qs.get("end_year").to_s
        
      place_formed_uri = qs.get("place_formed_id").get_uri
      band[:placeformed] = get_placeformed(place_formed_uri)
      ap band[:placeformed]
      band[:albums] = get_albums(band[:id])
      ap band[:albums]
      band[:concerts] = get_concerts(band[:id])
      ap band[:concerts]
      band[:members] = get_members(band[:id])
      ap band[:members]
      #band[:similar] = get_lastfm_similar(band[:id])
        
      #band[:lastfm_similar] = get_similar(band[:id])
        
      band[:id] = band[:id].to_s.split("#").last
      
      return band
    ensure
      dataset.end()
    end
    
    return band
  end


  def self.get_all()
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory);
    
    bands = []
    
    begin
      dataset.begin(ReadWrite::READ)
      query = %q(PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
					    SELECT ?band_id ?band_name ?bio ?cover ?lastFMURL ?foundation_year ?place_formed_id ?end_year
              WHERE {
	                  ?band_id rdf:type mo:MusicalGroup ;
	                    mo:name ?band_name ;
                      mo:hasBio ?bio ;
                      mo:hasCover ?cover ;
                      mo:lastFMURL ?lastFMURL ;
                      mo:foundationYear ?foundation_year ;
                      mo:placeFormed ?place_formed_id .
	                  OPTIONAL { ?band_id mo:endYear ?end_year . } .
              })
        
      query = QueryFactory.create(query)

      qexec = QueryExecutionFactory.create(query, dataset)
      rs = qexec.exec_select
      #ResultSetFormatter.out(rs)

      while rs.has_next
        band = {}
        qs = rs.next

        band[:id] = qs.get("band_id").get_uri
        band[:name] = qs.get("band_name").string.to_s
        band[:bio] = qs.get("bio").string.to_s
        band[:cover] = qs.get("cover").string.to_s
        band[:lastFMURL] = qs.get("lastFMURL").string.to_s
        band[:foundation_year] = qs.get("foundation_year").to_s
        band[:end_year] = qs.get("end_year").to_s
        
        place_formed_uri = qs.get("place_formed_id").get_uri
        band[:placeformed] = get_placeformed(place_formed_uri)
        ap band[:placeformed]
        band[:albums] = get_albums(band[:id])
        ap band[:albums]
        band[:concerts] = get_concerts(band[:id])
        ap band[:concerts]
        band[:members] = get_members(band[:id])
        ap band[:members]
        #band[:similar] = get_lastfm_similar(band[:id])
        
        #band[:lastfm_similar] = get_similar(band[:id])
        
        band[:id] = band[:id].to_s.split("#").last
        bands << band
      end
    ensure
      dataset.end()
    end
    
    return bands
  end
  
  def self.get_placeformed(place_id)
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory);
    
    begin
      dataset.begin(ReadWrite::READ)
      query = %Q(PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
					    SELECT ?lat ?lng ?city_name ?country_name
              WHERE {
	                  <#{place_id}> rdf:type mo:Place ;
                      mo:inCity ?city ;
                      mo:inCountry ?country ;
                      mo:latitude ?lat ;
                      mo:longitude ?lng .
                    ?city rdf:type mo:City ;
                      mo:name ?city_name .
                    ?country rdf:type mo:Country ;
                      mo:name ?country_name .
              })

      query = QueryFactory.create(query)

      qexec = QueryExecutionFactory.create(query, dataset)
      rs = qexec.exec_select

      if rs.has_next
        qs = rs.next
        place = {
          :city => qs.get("city_name").string.to_s,
          :country => qs.get("country_name").string.to_s,
          :lat => qs.get("lat").string.to_s,
          :lng => qs.get("lng").string.to_s
        }
        
        return place
      else
        return nil
      end
      
      ensure
        dataset.end()
      end
  end
  
  def self.get_albums(id)
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory);
    
    begin
      dataset.begin(ReadWrite::READ)
      query = %Q(PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
					    SELECT ?album ?name ?trackcount ?cover
              WHERE {
	                  <#{id}> rdf:type mo:MusicalGroup ;
                      mo:hasAlbum ?album .
                    ?album rdf:type mo:Album ;
                      mo:name ?name ;
                      mo:trackcount ?trackcount ;
                      mo:hasCover ?cover .
              })

      query = QueryFactory.create(query)

      qexec = QueryExecutionFactory.create(query, dataset)
      rs = qexec.exec_select
      
      if !rs.has_next
        return nil
      end
      
      albums = []
      while rs.has_next
        qs = rs.next
        album = {}
        
        album[:id] = qs.get("album").get_uri.to_s.split("#").last
        album[:name] = qs.get("name").string.to_s
        album[:trackcount] = qs.get("trackcount").string.to_s
        album[:cover] = qs.get("cover").string.to_s
        
        albums << album
      end
      
      return albums
    ensure
      dataset.end()
    end
  end
  
  def self.get_concerts(id)
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory);
    
    begin
      dataset.begin(ReadWrite::READ)
      query = %Q(PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
					    SELECT ?concert ?name ?date ?songkick ?lat ?lng ?city_name ?country_name ?venue
              WHERE {
	                  <#{id}> rdf:type mo:MusicalGroup ;
                      mo:hasConcert ?concert .
                    ?concert rdf:type mo:Concert ;
                      mo:date ?date ;
                      mo:name ?name ;
                      mo:songKickURL ?songkick ;
                      mo:inPlace ?place .
                    ?place rdf:type mo:Place ;
                      mo:inCity ?city ;
                      mo:inCountry ?country ;
                      mo:latitude ?lat ;
                      mo:longitude ?lng .
                    ?city rdf:type mo:City ;
                      mo:name ?city_name .
                    ?country rdf:type mo:Country ;
                      mo:name ?country_name .
                    OPTIONAL {?place mo:name ?venue . } .
              }ORDER BY ?date)

      query = QueryFactory.create(query)

      qexec = QueryExecutionFactory.create(query, dataset)
      rs = qexec.exec_select
      
      if !rs.has_next
        return nil
      end
      
      concerts = []
      while rs.has_next
        qs = rs.next
        
        concert = {}
        concert[:id] = qs.get("concert").to_s.split("#").last
        concert[:name] = qs.get("name").string.to_s
        concert[:date] = qs.get("date").to_s
        concert[:songkick] = qs.get("songkick").string.to_s
        concert[:lat] = qs.get("lat").float.to_s
        concert[:lng] = qs.get("lng").float.to_s
        concert[:city_name] = qs.get("city_name").string.to_s
        concert[:country_name] = qs.get("country_name").string.to_s
        concert[:venue] = qs.get("venue").string.to_s
        
        concerts << concert
      end
      
      return concerts
    ensure
      dataset.end()
    end
  end
  
  def self.get_members(id)
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory)

    begin
      dataset.begin(ReadWrite::READ)
      query = %Q(PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
					    SELECT ?artist ?name
              WHERE {
	                  <#{id}> rdf:type mo:MusicalGroup ;
                      mo:hasArtist ?artist .
                    ?artist rdf:type mo:Artist ;
                      mo:name ?name .
              })

      query = QueryFactory.create(query)

      qexec = QueryExecutionFactory.create(query, dataset)
      rs = qexec.exec_select

      if !rs.has_next
        return nil
      end
      
      members = []
      while rs.has_next
        qs = rs.next
        
        member = {}
        member[:id] = qs.get("artist").get_uri.to_s.split("#").last
        member[:name] = qs.get("name").string.to_s
        
        members << member
      end
      
      return members
    ensure
      dataset.end()
    end
  end
  
  def self.get_lastfm_similar(id)
    ns = "http://musicontology.ws.dei.uc.pt/music#"
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory);
    
    begin
      dataset.begin(ReadWrite::READ)
      query = %Q(PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
					    SELECT ?similar ?name ?bio ?cover ?lastFMURL ?foundation_year ?place_formed_id ?end_year
              WHERE {
	                  <#{id}> rdf:type mo:MusicalArtist ;
                      mo:isLastFMSimilar ?similar .
                    ?similar rdf:type mo:MusicalArtist ;
                      mo:name ?name ;
                      mo:hasBio ?bio ;
                      mo:hasCover ?cover ;
                      mo:lastFMURL ?lastFMURL ;
                      mo:foundationYear ?foundation_year ;
                      mo:placeFormed ?place_formed_id .
	                  OPTIONAL { ?similar mo:endYear ?end_year . } .
              })

      query = QueryFactory.create(query)

      qexec = QueryExecutionFactory.create(query, dataset)
      rs = qexec.exec_select
      
      if !rs.has_next
        return nil
      end
      
      similars = []
      while rs.has_next
        qs = rs.next
        
        similar = {}
        similar[:id] = qs.get("similar").get_uri.to_s.split("#").last
        similar[:name] = qs.get("name").string.to_s
        similar[:bio] = qs.get("bio").string.to_s
        similar[:cover] = qs.get("cover").string.to_s
        similar[:lastFMURL] = qs.get("lastFMURL").string.to_s
        similar[:foundation_year] = qs.get("foundation_year").to_s
        similar[:end_year] = qs.get("end_year").to_s
        
        similars << similar
      end
      
      return similars
    ensure
      dataset.end()
    end
  end
  
  def self.get_similar(id)
    ns = "http://musicontology.ws.dei.uc.pt/music#"
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory);
    
    begin
      dataset.begin(ReadWrite::READ)
      query = %Q(PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
					    SELECT ?similar ?name ?bio ?cover ?lastFMURL ?foundation_year ?place_formed_id ?end_year
              WHERE {
	                  <#{id}> rdf:type mo:MusicalArtist ;
                      mo:isSimilar ?similar .
                    ?similar rdf:type mo:MusicalArtist ;
                      mo:name ?name ;
                      mo:hasBio ?bio ;
                      mo:hasCover ?cover ;
                      mo:lastFMURL ?lastFMURL ;
                      mo:foundationYear ?foundation_year ;
                      mo:placeFormed ?place_formed_id .
	                  OPTIONAL { ?similar mo:endYear ?end_year . } .
              })

      query = QueryFactory.create(query)

      qexec = QueryExecutionFactory.create(query, dataset)
      rs = qexec.exec_select
      
      if !rs.has_next
        return nil
      end
      
      similars = []
      while rs.has_next
        qs = rs.next
        
        similar = {}
        similar[:id] = qs.get("similar").get_uri.to_s.split("#").last
        similar[:name] = qs.get("name").string.to_s
        similar[:bio] = qs.get("bio").string.to_s
        similar[:cover] = qs.get("cover").string.to_s
        similar[:lastFMURL] = qs.get("lastFMURL").string.to_s
        similar[:foundation_year] = qs.get("foundation_year").to_s
        similar[:end_year] = qs.get("end_year").to_s
        
        similars << similar
      end
      
      return similars
    ensure
      dataset.end()
    end
  end
end

#nome_festival, cidade, país, data, type, coords