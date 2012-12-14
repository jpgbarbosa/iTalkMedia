require 'json'
require 'awesome_print'
require "mp3info"

require 'lastfm'
require 'songkick'
require 'lyrics'

# gem install ruby-mp3info

# './bc_album/*.mp3'

module Extract
	public
		def self.allMusicInfo(path)
			musics = []
			lastfm = {}
			songkick = {}
			lyrics = {}


			mp3 = {}
			puts path.to_s

			Dir.chdir('/')

			if path.to_s == "/"
				path = ""
			elsif path.to_s.end_with?('/')
				path = path.to_s + '*.mp3'
			end
			
			puts "Path to search: "+path.to_s
      
      cached_lastfm_artist = {}
      cached_lastfm_album = {}
      cached_songkick = {}

			files = Dir.glob(path.to_s)
			
			# read and display infos & tags
			files.each do |file|
				mp3 = Hash.new
				songkick = Hash.new
				lastfm = Hash.new

				Mp3Info.open(file) do |mp3info|

					mp3["title"] = mp3info.tag.title
					mp3["artist"] = mp3info.tag.artist
					mp3["album"] = mp3info.tag.album
					mp3["tracknum"] = mp3info.tag.tracknum
					mp3["length"] = mp3info.length.to_i
					mp3["bitrate"] = mp3info.bitrate
					mp3["genre"] = mp3info.tag2.TCON

          if mp3info.tag2.TYER!=nil && mp3info.tag2.TYER!=""
            mp3["year"] = mp3info.tag2.TYER
          else
            mp3["year"] = mp3info.tag2.TDRC
          end

          artist = mp3["artist"]
					#LastFM info
					if artist != nil
            if cached_lastfm_artist[artist] != nil
              lastfm["artist"] = cached_lastfm_artist[artist]
            else
              lastfm["artist"] = LastFM.getArtist(artist)
              cached_lastfm_artist[artist] = lastfm["artist"]
            end
            
            album = mp3["album"]
						if album!=nil
              if cached_lastfm_album[album]!=nil
                lastfm["album"] = cached_lastfm_album[album]
              else
                lastfm["album"] = LastFM.getAlbum(artist, album)
                cached_lastfm_album[album] = lastfm["album"]
              end
						end

						if mp3["title"]!=nil
							lastfm["title"] = LastFM.getTrack(artist, mp3["title"])
						end
					end

					#SongKick info
					if artist !=nil
            if cached_songkick[artist] != nil
              songkick["events"] = cached_songkick[artist]
            else
              songkick["events"] = SongKick.getEventsForArtist(artist, nil, nil)
              cached_songkick[artist] = songkick["events"]
            end
					end

					#Lyrics info
					if artist != nil && mp3["title"]!=nil
						lyrics["title"] = ChartLyricsAPI.getLyric(artist, mp3["title"])
					end

				end #mp3Info

				musics << [mp3,lastfm,songkick,lyrics]

			end #files each

			return musics
		end #def

	private

end
