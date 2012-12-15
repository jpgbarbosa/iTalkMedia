class LayoutsController < ApplicationController
    
  def landing
    @old_played = Music.get_old_played_songs
    ap @old_played
    @concerts = Music.get_upcoming_concerts
    ap @concerts

    render :layout => "landing"
  end

end