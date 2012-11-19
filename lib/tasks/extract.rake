desc 'Extracting info'

require 'ontology/extract'

task :extract_info => :environment do

	puts Dir.pwd
	Extract.allMusicInfo("~/")
end
