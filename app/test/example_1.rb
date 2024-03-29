require '/lib/jar/javalib/jena-2.6.4.jar'
require '/lib/jar/javalib/icu4j-3.4.4.jar'
require '/lib/jar/javalib/iri-0.8.jar'
require '/lib/jar/javalib/log4j-1.2.13.jar'
require '/lib/jar/javalib/slf4j-api-1.5.8.jar'
require '/lib/jar/javalib/slf4j-log4j12-1.5.8.jar'
require '/lib/jar/javalib/xercesImpl-2.7.1.jar'
require 'java'


java_import 'com.hp.hpl.jena.vocabulary.VCARD'
java_import 'com.hp.hpl.jena.rdf.model.ModelFactory'

#Tutorial 1 Creating a Simple Model

class TestOne
	def cenas
		#creating the model
		model = ModelFactory.create_default_model

		#creating the resource
		person_uri = "http://somewhere/JohnSmith"
		full_name = "John Smith"
		john_smith = model.create_resource(person_uri)

		#adding property to resource
		john_smith.add_property(VCARD::FN, full_name)
		model.write(java.lang.System::out)
	end
end