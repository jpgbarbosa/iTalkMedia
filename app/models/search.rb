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
    
    terms_label.each do |label, term_array|
      if labels[label] == "Artist"
        
      elsif labels[label] == "Album"
        
      elsif labels[label] == "City"
        
      elsif labels[label] == "Concert"
        
      elsif labels[label] == "Country"
        
      elsif labels[label] == "Genre"
        
      elsif labels[label] == "MusicalGroup"
      
      elsif labels[label] == "Place"
      
      elsif labels[label] == "Track"
        
      else
        puts "DEU BODE"
      end
    end
    
    
    ap terms_label
    
    #names = get_names(terms)
    #ap names
    return []
  end
  
  private
  
  def self.get_names(term)
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory);
    
    begin
      dataset.begin(ReadWrite::READ)
      query = %Q(
              PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>
					    PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
              PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
					    SELECT ?name ?id ?type
              WHERE {
                ?id mo:name ?name ;
                   rdf:type ?type .
                FILTER regex(?name, #{term}, "i")
              })
        
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
        
        result = []
        result[0] = qs.get("name").string
        result[1] = qs.get("id").get_uri.to_s
        result[2] = qs.get("type").get_uri.to_s
        
        results << result
      end
      
      return results
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
