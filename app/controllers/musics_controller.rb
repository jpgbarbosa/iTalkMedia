class MusicsController < ApplicationController

  #require 'example_1.rb'
  require 'lastfm'
  require 'songkick'
  require 'ap'
  require 'extract'

  # GET /musics
  # GET /musics.json
  def index
    @musics = Music.all

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

    upload =  params[:music][:upload]
    tempfile = upload.tempfile

    puts tempfile.path

    results = Extract.allMusicInfo(tempfile.path)

    data_to_return = {"name" => upload.original_filename,
                      "size" => upload.size }

    #redirect_to @music, 
    respond_to do |format|
      if results
        format.html { 
          render :json => [data_to_return].to_json,
          :content_type => 'text/html',
          :layout => false,
          :notice => 'Music(s) were successfully added to your library!' 
        }
        format.json { render :json => [data_to_return].to_json, :status => :created, :location => @music }
      else
        format.html { render :action => "new" }
        format.json { render :json => @music.errors, :status => :unprocessable_entity }
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
