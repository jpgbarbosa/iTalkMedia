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
java_import "com.hp.hpl.jena.ontology.OntClass"
java_import "com.hp.hpl.jena.util.iterator.ExtendedIterator"


class Search < ActiveRecord::Base
  # attr_accessible :title, :body
  
  def self.search(terms)
    ontology_ns = "http://musicontology.ws.dei.uc.pt/ontology.owl#"
    
    #PROPERTIES LABELS
    properties_ont = ONTOLOGY.list_ont_properties()
    labels_properties = {}
    while properties_ont.has_next
      property = properties_ont.next
      labels_list = property.list_labels(nil)
      
      while labels_list.has_next
        if labels_properties[property.get_local_name] == nil
          labels_properties[property.get_local_name] = []
        end
        
        labels_properties[property.get_local_name] << labels_list.next.string
      end
    end
    
    # MATCH PROPERTY
    properties_query = []
    labels_properties.each do |property, label_array|
      label_array.each do |label|
        if terms.rindex(label) # property label found
          unless properties_query.include?(property) # highly unlikely
            properties_query << property
          end
        end
      end
    end
    p "Properties"
    ap properties_query
    
    # CLASS LABELS
    classes = ["Artist", "Album", "Concert", "MusicalGroup", "Track"]
    labels = {}
    classes.each do |c|
      labels_array = get_labels(c)
      
      labels_array.each do |label|
        labels[label] = c
      end
    end
    
    p "Class Labels"
    ap labels
    
    terms = terms.split(" ")
    
    terms_label = {}
    labels_query = []
    properties = []
    
    terms.each do |term|
      if labels.has_key?(term.downcase) # is label
        if terms_label[term.downcase] == nil
          terms_label[term.downcase] = []
        end
        
        labels_query << term.downcase
        
      else # is property
        properties << term
      end
    end
    
    # Assign all the labels the same terms
    labels_query.each do |label|
      properties.each do |prop|
        terms_label[label] << prop
      end
    end
    
    results = {}
    terms_label.each do |label, term_array|
      names = []
      if term_array!=[]
        names = get_names(term_array)
      end
      
      add_result(results, get_from_property(names, properties_query, labels[label]) )
      
      if labels[label] == "Artist"
        aux = get_artist(names, term_array)
        
        add_result(results, aux)
      elsif labels[label] == "Album"
        ap names
        puts "-----------------"
        aux = get_album(names, term_array)
        
        add_result(results, aux)
      elsif labels[label] == "Concert"
        aux = get_concerts(names, term_array)
        
        add_result(results, aux)
      elsif labels[label] == "MusicalGroup"
        aux = get_musicalgroup(names, term_array)
        ap names
        
        add_result(results, aux)
      elsif labels[label] == "Place"
        add_result(results, aux)
      elsif labels[label] == "Track"
        aux = get_tracks(names, term_array)
        
        add_result(results, aux)
      else
        puts "DEU BODE"
      end
    end
    
    # no class labels, only property values
    if labels_query.empty?
      names = get_names(properties)
      
      unless properties_query.empty?
        results = get_from_property(names, properties_query)
        ap names
        return results
      else # Search everywhere
        ap names
        puts "---------------"
        aux = get_musicalgroup(names, properties)
        add_result(results, aux)
      
        aux = get_artist(names, properties)
        add_result(results, aux)
      
        aux = get_album(names, properties)
        add_result(results, aux)
      
        aux = get_tracks(names, properties)
        add_result(results, aux)
      
        aux = get_concerts(names, properties)
        add_result(results, aux)
      end
    end
    
    
    sorted_results = []
    results.each do |k,v|
      sorted_results << v
    end
    
    sorted_results.sort! { |id1, id2| id2[:count] <=> id1[:count] }
    ap sorted_results
    
    return sorted_results
  end
  
  private
  
  def self.add_result(results, aux)
    aux.each do |r|
      if results[r[:name]]!=nil
        results[r[:name]][:count] += r[:count]
      else
        results[r[:name]] = r
      end
    end
  end
  
  def self.get_names(terms)
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory);
    
    begin
      dataset.begin(ReadWrite::READ)
      
      add_query = ""
      terms.each do |term|
        add_query += " {?id mo:name ?name ;
                   rdf:type ?type .
                   FILTER regex(?name, '#{term}', 'i')} "
        if term != terms.last
          add_query += " UNION "
        end
      end
      
      query = %Q(
              PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
              PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
					    SELECT ?name ?id ?type (COUNT(*) as ?count)
              WHERE {
                #{add_query}
              } GROUP BY ?id ?name ?type
              ORDER BY DESC(?count))
        
      query = QueryFactory.create(query)

      qexec = QueryExecutionFactory.create(query, dataset)
      rs = qexec.exec_select
      #ResultSetFormatter.out(rs)
      
      if !rs.has_next
        return []
      end
      
      results = []
      while rs.has_next
        qs = rs.next
        
        if qs.get("count").int == 0
          return []
        end
        
        result = {}
        result[:name] = qs.get("name").string
        result[:id] = qs.get("id").get_uri.to_s
        result[:type] = qs.get("type").get_uri.to_s
        result[:count] = qs.get("count").int
        
        results << result
      end
      
      return results
    ensure
      dataset.end()
    end
  end
  
  def self.get_from_property(instances, properties, label="")
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory);
    
    begin
      dataset.begin(ReadWrite::READ)
      
      results = []
      
      add_query = ""
      if label != ""
        add_query = " ; rdf:type mo:#{label} "
      end
      
      ap label
      ap properties
      properties.each do |property|
        instances.each do |instance|
          query = %Q(
                PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
                PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
				    
    				    SELECT ?property_value ?property_value_name
                WHERE {
                  <#{instance[:id]}> mo:#{property} ?property_value #{add_query} .
                  OPTIONAL {?property_value mo:name ?property_value_name} .
                })
          
          query = QueryFactory.create(query)

          qexec = QueryExecutionFactory.create(query, dataset)
          rs = qexec.exec_select
          #ResultSetFormatter.out(rs)
          
          while rs.has_next
            qs = rs.next
            
            result = {}
            if qs.get("property_value_name")==nil
              result[:name] = "<b>"+instance[:name]+"</b>" + " - " + qs.get("property_value").string.to_s
            else
              result[:name] = "<b>"+instance[:name]+"</b>" + " - " + qs.get("property_value_name").string.to_s
            end
            
            if instance[:type].end_with?("Track")
              result[:type] = "musics"
            elsif instance[:type].end_with?("MusicalGroup")
              result[:type] = "groups"
            elsif instance[:type].end_with?("Concert")
              result[:type] = "Concert"
            elsif instance[:type].end_with?("Album")
              result[:type] = "albums"
            end
            
            result[:count] = 1
            result[:id] = instance[:id].split("#").last
            results << result
          end
        end
        
        if instances.size == 0
          query = %Q(
                PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
                PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
				    
    				    SELECT ?id ?name ?property_value ?property_value_name ?type
                WHERE {
                  ?id mo:#{property} ?property_value ; mo:name ?name ; rdf:type ?type #{add_query} .
                  OPTIONAL {?property_value mo:name ?property_value_name} .
                })
          
          query = QueryFactory.create(query)

          qexec = QueryExecutionFactory.create(query, dataset)
          rs = qexec.exec_select
          #ResultSetFormatter.out(rs)
          
          while rs.has_next
            qs = rs.next
            
            result = {}
            if qs.get("property_value_name")==nil
              result[:name] = "<b>"+qs.get("name").string.to_s+"</b>" + " - " + qs.get("property_value").string.to_s
            else
              result[:name] = "<b>"+qs.get("name").string.to_s+"</b>" + " - " + qs.get("property_value_name").string.to_s
            end
            
            type = qs.get("type").get_uri

            if type.end_with?("Track")
              result[:type] = "musics"
            elsif type.end_with?("MusicalGroup")
              result[:type] = "groups"
            elsif type.end_with?("Concert")
              result[:type] = "Concert"
            elsif type.end_with?("Album")
              result[:type] = "albums"
            end
            
            result[:count] = 1
            result[:id] = qs.get("id").get_uri.split("#").last
            results << result
          end
        end
      end

      return results
    ensure
      dataset.end()
    end
  end
  
  def self.get_musicalgroup(terms, original_term_array)
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory);
    
    begin
      dataset.begin(ReadWrite::READ)
      
      add_query = ""
      filtered_terms = []
      terms.each do |term|
        if term[:type].end_with?("Genre") || term[:type].end_with?("Place") || term[:type].end_with?("MusicalGroup") || term[:type].end_with?("City") || term[:type].end_with?("Country") || term[:type].end_with?("Artist")
          filtered_terms << term
        end
      end
      ap filtered_terms
      filtered_terms.each do |term|
        if term[:type].end_with?("Genre")
          add_query += " { ?id mo:genre <#{term[:id]}> ; rdf:type mo:MusicalGroup ; mo:name ?name . } "
        elsif term[:type].end_with?("Place")
          add_query += " { ?id mo:placeFormed <#{term[:id]}> ; rdf:type mo:MusicalGroup ; mo:name ?name . } "
        elsif term[:type].end_with?("City")
          add_query += " { ?id rdf:type mo:MusicalGroup ; mo:placeFormed ?place ; mo:name ?name ; mo:hasBio ?bio . ?place rdf:type mo:Place ; mo:inCity <#{term[:id]}> . } "
        elsif term[:type].end_with?("Country")
          add_query += " { ?id rdf:type mo:MusicalGroup ; mo:placeFormed ?place ; mo:name ?name ; mo:hasBio ?bio . ?place rdf:type mo:Place ; mo:inCountry <#{term[:id]}> . } "
        elsif term[:type].end_with?("MusicalGroup")
          add_query += " { ?id rdf:type mo:MusicalGroup ; mo:name '#{term[:name]}' ; mo:name ?name ; mo:hasBio ?bio . } "
        elsif term[:type].end_with?("Artist")
          add_query += " { ?id rdf:type mo:MusicalGroup ; mo:name ?name ; mo:hasBio ?bio ; mo:hasArtist <#{term[:id]}> . } "
        end
        
        if term != filtered_terms.last
          add_query += " UNION "
        end
      end
      
      if original_term_array.size == 0
        query = %Q(
              PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
              PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
					    SELECT ?name ?id (COUNT(*) as ?count)
              WHERE {
                ?id rdf:type mo:MusicalGroup ;
                  mo:name ?name ;
                  mo:hasBio ?bio .
              }GROUP BY ?id ?name)
      elsif filtered_terms.size > 0
        query = %Q(
              PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
              PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
					    SELECT ?name ?id (COUNT(*) as ?count)
              WHERE {
                #{add_query}
              }GROUP BY ?id ?name
              ORDER BY DESC(?count))
      else
        return []
      end

      query = QueryFactory.create(query)

      qexec = QueryExecutionFactory.create(query, dataset)
      rs = qexec.exec_select
      #ResultSetFormatter.out(rs)
      
      if !rs.has_next
        return []
      end
      
      artists = []
      while rs.has_next
        qs = rs.next
        
        if qs.get("count").int == 0
          return []
        end
        
        artist = {}
        artist[:id] = qs.get("id").get_uri.to_s.split("#").last
        artist[:name] = qs.get("name").string
        artist[:type] = "groups"
        artist[:count] = qs.get("count").int
        artists << artist
      end
      ap artists
      return artists
    ensure
      dataset.end()
    end
  end
  
  def self.get_album(terms, original_term_array)
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory);
    
    begin
      dataset.begin(ReadWrite::READ)
      
      add_query = ""
      filtered_terms = []
      terms.each do |term|
        if term[:type].end_with?("Genre") || term[:type].end_with?("MusicalGroup") || term[:type].end_with?("Album")
          filtered_terms << term
        end
      end
      filtered_terms.each do |term|
        if term[:type].end_with?("Genre")
          add_query += " { ?id mo:genre <#{term[:id]}> ; rdf:type mo:Album ; mo:name ?name . } "
        elsif term[:type].end_with?("MusicalGroup")
          add_query += " { ?id rdf:type mo:Album ; mo:musicalgroup <#{term[:id]}> ; mo:name ?name . } "
        elsif term[:type].end_with?("Album")
          add_query += " { ?id rdf:type mo:Album ; mo:name '#{term[:name]}' ; mo:name ?name . } "
        end
        
        if term != filtered_terms.last
          add_query += " UNION "
        end
      end
      
      if original_term_array.size == 0
        query = %Q(
              PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
              PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
					    SELECT ?name ?id (COUNT(*) as ?count)
              WHERE {
                ?id rdf:type mo:Album ;
                  mo:name ?name ;
              }GROUP BY ?id ?name)
      elsif filtered_terms.size > 0
        query = %Q(
              PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
              PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
					    SELECT ?name ?id (COUNT(*) as ?count)
              WHERE {
                #{add_query}
              } GROUP BY ?id ?name
              ORDER BY DESC(?count))
              puts query
      else
        return []
      end
        
      query = QueryFactory.create(query)

      qexec = QueryExecutionFactory.create(query, dataset)
      rs = qexec.exec_select
      #ResultSetFormatter.out(rs)
      
      if !rs.has_next
        return []
      end
      
      albums = []
      while rs.has_next
        qs = rs.next
        
        if qs.get("count").int == 0
          return []
        end
        
        album = {}
        album[:id] = qs.get("id").get_uri.to_s.split("#").last
        album[:name] = qs.get("name").string
        album[:type] = "albums"
        album[:count] = qs.get("count").int
        albums << album
      end
      ap albums
      return albums
    ensure
      dataset.end()
    end
  end
  
  def self.get_tracks(terms, original_term_array)
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory);
    
    begin
      dataset.begin(ReadWrite::READ)
      
      add_query = ""
      filtered_terms = []
      terms.each do |term|
        if term[:type].end_with?("Genre") || term[:type].end_with?("MusicalGroup") || term[:type].end_with?("Album") || term[:type].end_with?("Track")
          filtered_terms << term
        end
      end
      filtered_terms.each do |term|
        if term[:type].end_with?("Genre")
          add_query += " { ?id mo:genre <#{term[:id]}> ; rdf:type mo:Track ; mo:name ?name . } "
        elsif term[:type].end_with?("MusicalGroup")
          add_query += " { <#{term[:id]}> rdf:type mo:MusicalGroup ; mo:hasAlbum ?album . ?album rdf:type mo:Album ; mo:hasTrack ?id . ?id mo:name ?name . } "
        elsif term[:type].end_with?("Album")
          add_query += " { <#{term[:id]}> rdf:type mo:Album ; mo:hasTrack ?id . ?id rdf:type mo:Track ; mo:name ?name . } "
        elsif term[:type].end_with?("Track")
          add_query += " { ?id rdf:type mo:Track ; mo:name '#{term[:name]}' ; mo:name ?name . } "
        end
        
        if term != filtered_terms.last
          add_query += " UNION "
        end
      end
      
      if original_term_array.size == 0
        query = %Q(
              PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
              PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
					    SELECT ?name ?id (COUNT(*) as ?count)
              WHERE {
                ?id rdf:type mo:Track ;
                  mo:name ?name ;
              }GROUP BY ?id ?name)
      elsif filtered_terms.size > 0
        query = %Q(
              PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
              PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
					    SELECT ?name ?id (COUNT(*) as ?count)
              WHERE {
                #{add_query}
              } GROUP BY ?id ?name
              ORDER BY DESC(?count))
              puts query
      else
        return []
      end
        
      query = QueryFactory.create(query)

      qexec = QueryExecutionFactory.create(query, dataset)
      rs = qexec.exec_select
      #ResultSetFormatter.out(rs)
      
      if !rs.has_next
        return []
      end
      
      tracks = []
      while rs.has_next
        qs = rs.next
        
        if qs.get("count").int == 0
          return []
        end
        
        track = {}
        track[:id] = qs.get("id").get_uri.to_s.split("#").last
        track[:name] = qs.get("name").string
        track[:type] = "musics"
        track[:count] = qs.get("count").int
        tracks << track
      end
      ap tracks
      return tracks
    ensure
      dataset.end()
    end
  end
  
  def self.get_concerts(terms, original_term_array)
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory);
    
    begin
      dataset.begin(ReadWrite::READ)
      
      add_query = ""
      filtered_terms = []
      terms.each do |term|
        if term[:type].end_with?("MusicalGroup") || term[:type].end_with?("Concert") || term[:type].end_with?("City") || term[:type].end_with?("Country")
          filtered_terms << term
        end
      end
      filtered_terms.each do |term|
        if term[:type].end_with?("Concert")
          add_query += " { ?id rdf:type mo:Concert ; mo:name '#{term[:name]}' ; mo:name ?name ; mo:songKickURL ?url . } "
        elsif term[:type].end_with?("MusicalGroup")
          add_query += " { ?id rdf:type mo:Concert ; mo:hasPerformance <#{term[:id]}> ; mo:name ?name ; mo:songKickURL ?url . } "
        elsif term[:type].end_with?("City")
          add_query += " { ?id rdf:type mo:Concert ; mo:inPlace ?place ; mo:name ?name ; mo:songKickURL ?url . ?place mo:inCity <#{term[:id]}> . } "
        elsif term[:type].end_with?("Country")
          add_query += " { ?id rdf:type mo:Concert ; mo:inPlace ?place ; mo:name ?name ; mo:songKickURL ?url . ?place mo:inCountry <#{term[:id]}> . } "
        end
        
        if term != filtered_terms.last
          add_query += " UNION "
        end
      end
      
      if original_term_array.size == 0
        query = %Q(
              PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
              PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
					    SELECT ?name ?id ?url (COUNT(*) as ?count)
              WHERE {
                ?id rdf:type mo:Concert ; mo:songKickURL ?url ;
                  mo:name ?name ;
              }GROUP BY ?id ?name ?url
              ORDER BY DESC(?count))
      elsif filtered_terms.size > 0
        query = %Q(
              PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
              PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
					    SELECT ?name ?id ?url (COUNT(*) as ?count)
              WHERE {
                #{add_query}
              } GROUP BY ?id ?name ?url
              ORDER BY DESC(?count))
      else
        return []
      end
        
      query = QueryFactory.create(query)

      qexec = QueryExecutionFactory.create(query, dataset)
      rs = qexec.exec_select
      #ResultSetFormatter.out(rs)
      
      if !rs.has_next
        return []
      end
      
      concerts = []
      while rs.has_next
        qs = rs.next
        
        if qs.get("count").int == 0
          return []
        end
        
        concert = {}
        concert[:id] = qs.get("id").get_uri.to_s.split("#").last
        concert[:name] = qs.get("name").string
        concert[:type] = "Concert"
        concert[:url] = qs.get("url").string
        concert[:count] = qs.get("count").int
        concerts << concert
      end
      ap concerts
      return concerts
    ensure
      dataset.end()
    end
  end
  
  
  def self.get_artist(terms, original_term_array)
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory);
    
    begin
      dataset.begin(ReadWrite::READ)
      
      add_query = ""
      filtered_terms = []
      terms.each do |term|
        if term[:type].end_with?("MusicalGroup") || term[:type].end_with?("Artist")
          filtered_terms << term
        end
      end
      filtered_terms.each do |term|
        if term[:type].end_with?("MusicalGroup")
          add_query += " { ?id rdf:type mo:MusicalGroup ; mo:name '#{term[:name]}' ; mo:hasArtist ?artist . ?artist rdf:type mo:Artist ; mo:name ?name . } "
        elsif term[:type].end_with?("Artist")
          add_query += " { ?id rdf:type mo:MusicalGroup ; mo:hasArtist <#{term[:id]}> ; mo:hasArtist ?artist . ?artist rdf:type mo:Artist ; mo:name ?name . } "
        end
        
        if term != filtered_terms.last
          add_query += " UNION "
        end
      end
      
      if original_term_array.size == 0
        query = %Q(
              PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
              PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
					    SELECT ?name ?id ?artist (COUNT(*) as ?count)
              WHERE {
                ?id rdf:type mo:MusicalGroup ; mo:hasArtist ?artist . 
                  ?artist rdf:type mo:Artist ; mo:name ?name .
              }GROUP BY ?artist ?id ?name
              ORDER BY DESC(?count))
      elsif filtered_terms.size > 0
        query = %Q(
              PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
              PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
					    SELECT ?name ?id ?artist (COUNT(*) as ?count)
              WHERE {
                #{add_query}
              } GROUP BY ?artist ?id ?name
              ORDER BY DESC(?count))
              puts query
      else
        return []
      end
        
      query = QueryFactory.create(query)

      qexec = QueryExecutionFactory.create(query, dataset)
      rs = qexec.exec_select
      #ResultSetFormatter.out(rs)
      
      if !rs.has_next
        return []
      end
      
      artists = []
      while rs.has_next
        qs = rs.next
        
        if qs.get("count").int == 0
          return []
        end
        
        artist = {}
        artist[:group_id] = qs.get("id").get_uri.to_s.split("#").last
        artist[:id] = qs.get("artist").get_uri.to_s.split("#").last
        artist[:name] = qs.get("name").string
        artist[:type] = "Artist"
        artist[:count] = 1
        artists << artist
      end
      ap artists
      return artists
    ensure
      dataset.end()
    end
  end
  
  def self.get_cenas
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory);
    
    begin
      dataset.begin(ReadWrite::READ)
      query = %Q(
              PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
              PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
					    SELECT ?id (COUNT(*) as ?count)
              WHERE {
                {
                  ?id mo:genre ?genre ;
                    rdf:type mo:MusicalGroup .
                  ?genre mo:name "indie" .
                }
                UNION
                {
                  ?id mo:genre ?genre ;
                    rdf:type mo:MusicalGroup .
                  ?genre mo:name "rock" .
                }
              } GROUP BY ?id
               ORDER BY DESC(?count))
        
      query = QueryFactory.create(query)

      qexec = QueryExecutionFactory.create(query, dataset)
      rs = qexec.exec_select
      ResultSetFormatter.out(rs)
      
      if !rs.has_next
        return []
      end
    ensure
      dataset.end()
    end
  end
  
  def self.get_labels(class_name)
    ontology_ns = "http://musicontology.ws.dei.uc.pt/ontology.owl#"
    ont_class = ONTOLOGY.get_ont_class(ontology_ns+class_name)
    
    labels_iter = ont_class.list_labels(nil)
    
    labels = []
    while labels_iter.has_next
      labels << labels_iter.next.string
    end
    
    return labels
  end
end
