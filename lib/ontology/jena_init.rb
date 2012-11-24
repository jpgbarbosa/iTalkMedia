
require '/lib/jar/javalib/commons-codec-1.5.jar'
require '/lib/jar/javalib/jena-core-2.7.3.jar'     
require '/lib/jar/javalib/slf4j-api-1.6.4.jar'
require '/lib/jar/javalib/httpclient-4.1.2.jar'
require '/lib/jar/javalib/jena-iri-0.9.3.jar'     
require '/lib/jar/javalib/slf4j-log4j12-1.6.4.jar'
require '/lib/jar/javalib/httpcore-4.1.3.jar'
require '/lib/jar/javalib/jena-tdb-0.9.3.jar'
require '/lib/jar/javalib/xercesImpl-2.10.0.jar'
require '/lib/jar/javalib/jena-arq-2.9.3.jar'
require '/lib/jar/javalib/log4j-1.2.16.jar'
require '/lib/jar/javalib/xml-apis-1.4.01.jar'

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

			ontology.read(FileManager.get.open("/lib/ontology/music_ontology.owl")) 
			artist = ontology.get_ont_class(ns+"Artist")
			album = ontology.get_ont_class(ns+"Album")
			city = ontology.get_ont_class(ns+"City")
			concert = ontology.get_ont_class(ns+"Concert")
			country = ontology.get_ont_class(ns+"Country")
			genre = ontology.get_ont_class(ns+"Genre")
			label = ontology.get_ont_class(ns+"Label")
			musicalGroup = ontology.get_ont_class(ns+"MusicalGroup")
			place = ontology.get_ont_class(ns+"Place")
			track = ontology.get_ont_class(ns+"Track")

			name = ontology.get_property(ns+"name")
			endYear = ontology.get_property(ns+"endYear")
			foundationYear = ontology.get_property(ns+"foundationYear")
			year = ontology.get_property(ns+"year")
			hasAlbum = ontology.get_property(ns+"hasAlbum")
			hasArtist = ontology.get_property(ns+"hasArtist")
			hasLyric = ontology.get_property(ns+"hasLyric")
			hasLabel = ontology.get_property(ns+"hasLabel")
			hasTrack = ontology.get_property(ns+"hasTrack")
			trackLength = ontology.get_property(ns+"tracklength")
			inPlace = ontology.get_property(ns+"inPlace")
			inCountry = ontology.get_property(ns+"inCountry")
			inCity = ontology.get_property(ns+"inCity")
			lastFMURL = ontology.get_property(ns+"lastFMURL")
			bitrate = ontology.get_property(ns+"bitrate")
			musicalGroup = ontology.get_property(ns+"musicalgroup")
			genre = ontology.get_property(ns+"genre")
			trackcount = ontology.get_property(ns+"trackcount")
			date = ontology.get_property(ns+"date")
			tracknum = ontology.get_property(ns+"tracknum")


			# our_rdf = FileManager.get.open "italkmedia.rdf"
			# model = ModelFactory.create_default_model()
			# model.setnsPrefix("mo", ns)
			# model.read(our_rdf, nil)


			puts " going to exit jena_init.rb "
			#ONTOLOGY = ontology

			return ontology
		end
end