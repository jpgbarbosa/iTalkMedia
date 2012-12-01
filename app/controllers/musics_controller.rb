class MusicsController < ApplicationController
  require 'lastfm'
  require 'songkick'
  require 'gmaps_geocoding'
  require 'ap'
  require 'extract'

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

  include ActionView::Helpers::TextHelper

  # GET /musics
  # GET /musics.json
  def index
    @musics = Music.get_all()

    ap @musics

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @musics }
    end
  end

  # GET /musics/1
  # GET /musics/1.json
  def show
    if params[:id]!=nil
      id_link = "http://musicontology.ws.dei.uc.pt/music##{params[:id]}"
      
      puts id_link
      @music = Music.get_by_id(params[:id])
    else
      @music = {:name => "deu erro", :error => "params not valid"}
    end


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
    Music.setJenaInfo(data_processed)

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
