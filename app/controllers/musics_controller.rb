class MusicsController < ApplicationController
  require 'lastfm'
  require 'songkick'
  require 'ap'
  require 'extract'

  require 'lib/jar/javalib/commons-codec-1.5.jar'
  require 'lib/jar/javalib/jena-core-2.7.3.jar'     
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

  include ActionView::Helpers::TextHelper

  # GET /musics
  # GET /musics.json
  def index
    @musics = Music.all

    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory);
    
    begin
      dataset.begin(ReadWrite::READ)
      query = "PREFIX mo: <http://musicontology.ws.dei.uc.pt/ontology.owl#>" +
					    "PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>" +
					    "SELECT ?x ?a WHERE { ?x mo:hasCover ?a }"
      qExec = QueryExecutionFactory.create(query, dataset)
      rs = qExec.exec_select()
      ResultSetFormatter.out(rs)
    ensure
      dataset.end()
    end

    # c = SongKick.getEventsForArtist('Muse',nil,nil)
    # if c["success"]
    #   ap c["data"]
    # else
    #   ap c["message"]
    # end

    # puts "---------------------------------------------------------------------"
    # c = LastFM.getTrack('Depeche Mode','Personal Jesus')
    # ap c["data"]

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @musics }
    end
  end

  # GET /musics/1
  # GET /musics/1.json
  def show
    @music = Music.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @music }
    end
  end

  # GET /musics/new
  # GET /musics/new.json
  def new
    @music = Music.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @music }
    end
  end

  # GET /musics/1/edit
  def edit
    @music = Music.find(params[:id])
  end

  # POST /musics
  # POST /musics.json
  def create
    # @music = Music.new(params[:music])

    upload_results = nil
    path = nil
    data_processed = nil

    if params[:music][:path] != "" && params[:music][:path] != nil
      path = params[:music][:path]

      if !path.to_s.end_with?('/')
        path = path.to_s + '/'
      end

      path_results = Extract.allMusicInfo(path)

      processed = path_results.length 

      data_processed = path_results

      ap path_results[0]

    elsif params[:music][:upload] != nil
      upload =  params[:music][:upload]
      tempfile = upload.tempfile

      puts tempfile.path

      upload_results = Extract.allMusicInfo(tempfile.path)

      data_processed = upload_results

      data_to_return = {"name" => upload.original_filename,
                        "size" => upload.size }
    end


    # WS processing
    # data_processed
    
    ontology_ns = "http://musicontology.ws.dei.uc.pt/ontology.owl#"
    ns = "http://musicontology.ws.dei.uc.pt/music#"
    directory = "music_database"
    dataset = TDBFactory.create_dataset(directory)
    
    dataset.begin(ReadWrite::WRITE)
    begin
      model = dataset.get_default_model()
      model.set_ns_prefix("mo", ontology_ns)
      model.set_ns_prefix("item", ns)
      
      # CLASSES #
			ont_artist = ONTOLOGY.get_ont_class(ontology_ns+"Artist")
      ont_album = ONTOLOGY.get_ont_class(ontology_ns+"Album")
			ont_city = ONTOLOGY.get_ont_class(ontology_ns+"City")
			ont_concert = ONTOLOGY.get_ont_class(ontology_ns+"Concert")
			ont_country = ONTOLOGY.get_ont_class(ontology_ns+"Country")
			ont_genre = ONTOLOGY.get_ont_class(ontology_ns+"Genre")
			ont_label = ONTOLOGY.get_ont_class(ontology_ns+"Label")
			ont_musicalGroup = ONTOLOGY.get_ont_class(ontology_ns+"MusicalGroup")
			ont_place = ONTOLOGY.get_ont_class(ontology_ns+"Place")
			ont_track = ONTOLOGY.get_ont_class(ontology_ns+"Track")
      
      # PROPERTIES #
			ont_p_name = ONTOLOGY.get_property(ontology_ns+"name")
			ont_p_endYear = ONTOLOGY.get_property(ontology_ns+"endYear")
			ont_p_foundationYear = ONTOLOGY.get_property(ontology_ns+"foundationYear")
			ont_p_year = ONTOLOGY.get_property(ontology_ns+"year")
			ont_p_hasAlbum = ONTOLOGY.get_property(ontology_ns+"hasAlbum")
			ont_p_hasArtist = ONTOLOGY.get_property(ontology_ns+"hasArtist")
			ont_p_hasLyric = ONTOLOGY.get_property(ontology_ns+"hasLyric")
			ont_p_hasLabel = ONTOLOGY.get_property(ontology_ns+"hasLabel")
			ont_p_hasTrack = ONTOLOGY.get_property(ontology_ns+"hasTrack")
      ont_p_hasCover = ONTOLOGY.get_property(ontology_ns+"hasCover")
      ont_p_hasBio = ONTOLOGY.get_property(ontology_ns+"hasBio")
			ont_p_trackLength = ONTOLOGY.get_property(ontology_ns+"tracklength")
			ont_p_inPlace = ONTOLOGY.get_property(ontology_ns+"inPlace")
			ont_p_inCountry = ONTOLOGY.get_property(ontology_ns+"inCountry")
			ont_p_inCity = ONTOLOGY.get_property(ontology_ns+"inCity")
      ont_p_placeFormed = ONTOLOGY.get_property(ontology_ns+"placeFormed")
      ont_p_isSimilarTo = ONTOLOGY.get_property(ontology_ns+"isSimilarTo")
      ont_p_isLastFMSimilar = ONTOLOGY.get_property(ontology_ns+"isLastFMSimilar")
			ont_p_lastFMURL = ONTOLOGY.get_property(ontology_ns+"lastFMURL")
			ont_p_bitrate = ONTOLOGY.get_property(ontology_ns+"bitrate")
			ont_p_musicalGroup = ONTOLOGY.get_property(ontology_ns+"musicalgroup")
			ont_p_genre = ONTOLOGY.get_property(ontology_ns+"genre")
			ont_p_trackcount = ONTOLOGY.get_property(ontology_ns+"trackcount")
			ont_p_date = ONTOLOGY.get_property(ontology_ns+"date")
			ont_p_tracknum = ONTOLOGY.get_property(ontology_ns+"tracknum")
      
      puts "---------\nSIZE: #{data_processed.length}\n--------"
      
      data_processed.each do |data|
        group_info = data[1]["artist"]["data"]["artist"]
        track_info = data[1]["title"]["data"]["track"]
        
        # MUSIC GROUP INFO #
        
        musical_group = model.create_resource(ns+"#{group_info["mbid"]}", ont_musicalGroup)
        track = model.create_resource(ns+"#{track_info["id"]}", ont_track)
        
        musical_group.add_property(ont_p_name, data[0]["artist"])
        musical_group.add_property(ont_p_lastFMURL, group_info["url"])
        musical_group.add_property(ont_p_hasCover, group_info["image"][-1]["#text"]) #the biggest
        
        members = group_info["bandmembers"]["member"]
        members.each do |member|
          member_resource = model.create_resource(ns+group_info["name"]+"/"+member["name"], ont_artist)
          member_resource.add_property(ont_p_name, member["name"])
          musical_group.add_property(ont_p_hasArtist, member_resource)
        end
        
        tags = group_info["tags"]["tag"]
        tags.each do |tag|
          tag_resource = model.create_resource(tag["url"], ont_genre) # tag url is the URI
          tag_resource.add_property(ont_p_name, tag["name"])
          musical_group.add_property(ont_p_genre, tag_resource)
        end
        
        bio_info = group_info["bio"]
        musical_group.add_property(ont_p_hasBio, bio_info["content"]) #could also be summary
        musical_group.add_property(ont_p_foundationYear, bio_info["formationlist"]["formation"]["yearfrom"])
        if bio_info["formationlist"]["formation"]["yearto"]!=nil && bio_info["formationlist"]["formation"]["yearto"] != ""
          musical_group.add_property(ont_p_foundationYear, bio_info["formationlist"]["formation"]["yearto"])
        end
        
        #- LastFM Similar #
        similars = group_info["similar"]["artist"]
        similars.each do |s|
          s_iter = model.list_subjects_with_property(ont_p_lastFMURL, s["url"])
          while s_iter.has_next
            sim = s_iter.next_resource
            musical_group.add_property(ont_p_isLastFMSimilar, sim)
            sim.add_property(ont_p_isLastFMSimilar, musical_group)
          end
        end
        
        
        # ALBUM INFO #
        album_info = data[1]["album"]["data"]["album"]

        album = model.create_resource(ns+"#{album_info["mbid"]}", ont_album)
        album.add_property(ont_p_name, data[0]["album"])
        album.add_property(ont_p_trackcount, album_info["tracks"].size)
        album.add_property(ont_p_lastFMURL, album_info["url"])
        puts album_info["image"][-1]["#text"]
        album.add_property(ont_p_hasCover, album_info["image"][-1]["#text"]) #the biggest
        
        tags = album_info["toptags"]["tag"]
        tags.each do |tag|
          tag_resource = model.create_resource(tag["url"], ont_genre)
          tag_resource.add_property(ont_p_name, tag["name"])
          album.add_property(ont_p_genre, tag_resource)
        end

        musical_group.add_property(ont_p_hasAlbum, album)
        
        
        # TRACK INFO #
        track.add_property(ont_p_name, data[0]["title"])
        
        if(data[0]["bitrate"]) != nil
          track.add_property(ont_p_bitrate, data[0]["bitrate"])
        end
        
        track.add_property(ont_p_trackLength, data[0]["length"])
        track.add_property(ont_p_year, data[0]["year"])
        track.add_property(ont_p_tracknum, data[0]["tracknum"])
        
        tags = track_info["toptags"]["tag"]
        tags.each do |tag|
          tag_resource = model.create_resource(tag["url"], ont_genre)
          tag_resource.add_property(ont_p_name, tag["name"])
          track.add_property(ont_p_genre, tag_resource)
        end
        model.write(java.lang.System::out, "RDF/XML-ABBREV")
        # EVENTS INFO #
      end
      
      
      
      
      dataset.commit()
    ensure
      dataset.end()
    end
    



    #redirect_to @music, 
    respond_to do |format|
      if upload_results
        format.html { 
          render :json => [data_to_return].to_json,
          :content_type => 'text/html',
          :layout => false,
          :notice => 'Music(s) were successfully added to your library!' 
        }
        format.json { render :json => [data_to_return].to_json, :status => :created, :location => @music }
      elsif path_results != nil
        format.html { redirect_to musics_path, :notice => pluralize(processed, 'music').to_s+" added to your library successfully" }
        format.json { head :no_content }
      else
        flash[:error] = 'You must provide some input!'
        format.html { redirect_to musics_path }
        format.json { render :json => {"err" => 'no inputs'}, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /musics/1
  # PUT /musics/1.json
  def update
    @music = Music.find(params[:id])

    respond_to do |format|
      if @music.update_attributes(params[:music])
        format.html { redirect_to @music, :notice => 'Music was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @music.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /musics/1
  # DELETE /musics/1.json
  def destroy
    @music = Music.find(params[:id])
    @music.destroy

    respond_to do |format|
      format.html { redirect_to musics_url }
      format.json { head :no_content }
    end
  end
end
