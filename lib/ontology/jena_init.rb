
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

java_import "com.hp.hpl.jena.ontology.OntClass"
java_import "com.hp.hpl.jena.ontology.OntModel"
java_import "com.hp.hpl.jena.rdf.model.Model"
java_import "com.hp.hpl.jena.rdf.model.ModelFactory"
java_import "com.hp.hpl.jena.rdf.model.Property"
java_import "com.hp.hpl.jena.rdf.model.Resource"
java_import 'com.hp.hpl.jena.util.FileManager'

module JenaInit
	public

		def self.init()
			ontology = ModelFactory.create_ontology_model

			ns = "http://musicontology.ws.dei.uc.pt/ontology.owl#"
			ontology.read("file:./lib/ontology/music_ontology.owl")
			ap ontology

			puts " going to exit jena_init.rb "
			#ONTOLOGY = ontology

			return ontology
		end
end