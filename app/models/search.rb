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
    #get_cenas
    ontology_ns = "http://musicontology.ws.dei.uc.pt/ontology.owl#"
    
    classes = ["Artist", "Album", "City", "Concert", "Country", "Genre", "MusicalGroup", "Place", "Track"]
    
    labels = {}
    classes.each do |c|
      labels_array = get_labels(c)
      
      labels_array.each do |label|
        labels[label] = c
      end
    end
    
    ap labels
    
    terms = terms.split(" ")
    
    terms_label = {}
    previous_label = []
    previous_properties = []
    last_is_label = true
    
    terms.each do |term|
      if labels.has_key?(term.downcase) # is label
        if terms_label[term.downcase] == nil
          terms_label[term.downcase] = []
        end
        
        if last_is_label
          previous_label << term.downcase
        else
          previous_label = []
          previous_label << term.downcase
          last_is_label = true
        end
        
      else # is property
        if not previous_label.empty?
          previous_label.each do |label|
            terms_label[label] << term
          end
        else
          previous_properties << term
        end
        
        last_is_label = false
      end
    end
    
    results = {}
    terms_label.each do |label, term_array|
      names = []
      if term_array!=[]
        names = get_names(term_array)
      end
      
      if labels[label] == "Artist"
        add_result(results, aux)
      elsif labels[label] == "Album"
        add_result(results, aux)
      elsif labels[label] == "City"
        add_result(results, aux)
      elsif labels[label] == "Concert"
        add_result(results, aux)
      elsif labels[label] == "Country"
        add_result(results, aux)
      elsif labels[label] == "Genre"
        add_result(results, aux)
      elsif labels[label] == "MusicalGroup"
        aux = get_musicalgroup(names)
        
        add_result(results, aux)
      elsif labels[label] == "Place"
        add_result(results, aux)
      elsif labels[label] == "Track"
        add_result(results, aux)
      else
        puts "DEU BODE"
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
      if results[r[:id]]!=nil
        results[r[:id]][:count] += r[:count]
      else
        results[r[:id]] = r
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
  
  def self.get_musicalgroup(terms)
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory);
    
    begin
      dataset.begin(ReadWrite::READ)
      
      add_query = ""
      terms.each do |term|
        if term[:type].end_with?("Genre")
          add_query += " { ?id mo:genre <#{term[:id]}> ; rdf:type mo:MusicalGroup ; mo:name ?name . } "
        elsif term[:type].end_with?("Place")
          add_query += " { ?id mo:placeFormed <#{term[:id]}> ; rdf:type mo:MusicalGroup ; mo:name ?name . } "
        elsif term[:type].end_with?("Concert")
          add_query += " { ?id mo:hasConcert <#{term[:id]}> ; rdf:type mo:MusicalGroup ; mo:name ?name . } "
        end
        
        if term != terms.last
          add_query += " UNION "
        end
      end
      
      if terms.size > 0
        query = %Q(
              PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
              PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
					    SELECT ?name ?id (COUNT(*) as ?count)
              WHERE {
                #{add_query}
              } GROUP BY ?id ?name
              ORDER BY DESC(?count))
      else
        puts "here"
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
