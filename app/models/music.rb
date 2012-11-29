class Music < ActiveRecord::Base
  attr_accessible :name, :path
  
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
  java_import "com.hp.hpl.jena.query.QueryExecutionFactory"
  java_import "com.hp.hpl.jena.query.ReadWrite"
  java_import "com.hp.hpl.jena.query.ResultSet"
  java_import "com.hp.hpl.jena.query.ResultSetFormatter"
  java_import "com.hp.hpl.jena.tdb.TDBFactory"
  java_import "com.hp.hpl.jena.rdf.model.Model"
  java_import "com.hp.hpl.jena.rdf.model.ModelFactory"
  java_import "com.hp.hpl.jena.rdf.model.Property"
  java_import "com.hp.hpl.jena.rdf.model.Resource"
  
  def self.get_all
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory);
    
    musics = []
    
    begin
      dataset.begin(ReadWrite::READ)
      query = "PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#> " +
					    "PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> " +
					    "SELECT ?track_id ?track_name ?track_bitrate ?genre_name ?track_lyric ?track_length ?track_num ?track_year WHERE {"+
                "?track_id rdf:type mo:Track ; "+
                " mo:name ?track_name ; "+
                " mo:bitrate ?track_bitrate ; "+
                " mo:genre ?genre ; "+
                " mo:tracklength ?track_length ; "+
                " mo:tracknum ?track_num ; "+
                " mo:year ?track_year . "+
                "?genre rdf:type mo:Genre ; "+
                " mo:name ?genre_name ."+
                " OPTIONAL { ?track_id mo:hasLyric ?track_lyric . } ."+
              "} ORDER BY ?track_id"
              puts query
      qExec = QueryExecutionFactory.create(query, dataset)
      rs = qExec.exec_select()
      ResultSetFormatter.out(rs)
      
      id = ""
      genres = []
      while rs.has_next
        music = {}
        qs = rs.next
        if qs.get("?track_id") == id
          genres << qs.get("?genre_name")
        else
          music[:id] = qs.get("?track_id")
          music[:name] = qs.get("?track_name")
          music[:bitrate] = qs.get("?track_bitrate")
          music[:length] = qs.get("?track_length")
          music[:num] = qs.get("?track_num")
          music[:year] = qs.get("?track_year")
          genres = []
          music[:genres] = genres
          genres << qs.get("?genre_name")
        end

        musics << music
      end
    ensure
      dataset.end()
    end
    
    return musics
  end
  
  def self.get_with_id(id)
    uri = "http://musicontology.ws.dei.uc.pt/ontology.owl#"+id
    
    begin
      dataset.begin(ReadWrite::READ)
      query = "PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#> " +
					    "PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> " +
					    "SELECT ?track_id ?track_name ?track_bitrate ?genre_name ?track_lyric ?track_length ?track_num ?track_year WHERE {"+
                "?track_id rdf:type mo:Track ; "+
                " mo:name ?track_name ; "+
                " mo:bitrate ?track_bitrate ; "+
                " mo:genre ?genre ; "+
                " mo:tracklength ?track_length ; "+
                " mo:tracknum ?track_num ; "+
                " mo:year ?track_year . "+
                "?genre rdf:type mo:Genre ; "+
                " mo:name ?genre_name ."+
                " OPTIONAL { ?track_id mo:hasLyric ?track_lyric . } ."+
              "} ORDER BY ?track_id"
              puts query
      qExec = QueryExecutionFactory.create(query, dataset)
      rs = qExec.exec_select()
      ResultSetFormatter.out(rs)
      
      id = ""
      genres = []
      while rs.has_next
        music = {}
        qs = rs.next
        if qs.get("?track_id") == id
          genres << qs.get("?genre_name")
        else
          music[:id] = qs.get("?track_id")
          music[:name] = qs.get("?track_name")
          music[:bitrate] = qs.get("?track_bitrate")
          music[:length] = qs.get("?track_length")
          music[:num] = qs.get("?track_num")
          music[:year] = qs.get("?track_year")
          genres = []
          music[:genres] = genres
          genres << qs.get("?genre_name")
        end

        musics << music
      end
    ensure
      dataset.end()
    end
    
    return musics
  end
  
end
