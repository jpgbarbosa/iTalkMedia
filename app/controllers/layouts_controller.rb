class LayoutsController < ApplicationController
    
  def landing

    @old_played = Music.get_old_played_songs
    ap @old_played

    r = Random.new

    if @old_played.size != 0
    	@old_played = @old_played[r.rand(0..(@old_played.size-1))]
    end

    @concerts = Music.get_upcoming_concerts
    @concerts = @concerts[r.rand(0..(@concerts.size-1))]

    render :layout => "landing"
  end

end