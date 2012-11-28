class Group < ActiveRecord::Base
  attr_accessible :bio, :endYear, :foundationYear, :genre, :lastfmUrl, :name


  #TDB interface
  def self.tdbGetGroupInfo(id)

  	#TODO MAKE QUERY TO

  	data = {}

  	data[:name] = "teste name"
  	data[:genre] = ["1","2"]
  	data[:lastfmUrl] = "teste url"
  	data[:foundationYear] = "foundationYear teste"
  	data[:endYear] = "endYear teste"
  	data[:artist_id] = "id teste"
	data[:place_formed] = "place teste"

  	data[:bio] = "bio teste"

  	#get ohter data
	data[:albuns] = ["1","2"]

	data[:members] = ["1","2"]
	
	concert = {country: "pais", city: "cidade", name: "nome", type: "tipo", coords: "[0,0]"} #coords nil if unavailable

	data[:next_concerts] = [concert,concert]

	#future
	data[:similars] = ["art 1","art 2"]

  	return data
  end


  def self.tdbGetGroupInfoAll

  	#TODO query to get all bands ids and for each use the above func

  	data_return = []

  	#for each
  	data_return << tdbGetGroupInfo(2)

  	return  data_return
  end
end

#nome_festival, cidade, país, data, type, coords