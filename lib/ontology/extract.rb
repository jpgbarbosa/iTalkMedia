require 'json'
require 'awesome_print'
require "mp3info"

require 'lastfm'
require 'songkick'
# gem install ruby-mp3info

# './bc_album/*.mp3'


module Extract
	public
		def self.allMusicInfo(path)
			musics = []
			lastfm = {}
			songkick = {}
			mp3 = {}
			puts path.to_s+'*.mp3'

			files = Dir.glob(path.to_s+'*.mp3')
			

			# read and display infos & tags
			files.each do |file|
				mp3 = Hash.new
				songkick = Hash.new
				lastfm = Hash.new

				Mp3Info.open(file) do |mp3info|
					puts mp3info.tag.title
					puts mp3info.tag.artist
					puts mp3info.tag.album
					puts mp3info.tag.tracknum
					puts mp3info.length
					puts mp3info.bitrate

					#genre
					puts mp3info.tag2.TCON

					#year
					puts mp3info.tag2.TYER

					mp3["title"] = mp3info.tag.title
					mp3["artist"] = mp3info.tag.artist
					mp3["album"] = mp3info.tag.album
					mp3["tracknum"] = mp3info.tag.tracknum
					mp3["length"] = mp3info.tag.length
					mp3["bitrate"] = mp3info.tag.bitrate
					mp3["genre"] = mp3info.tag2.TCON
					mp3["year"] = mp3info.tag2.TYER


					#LastFM info
					if mp3["artist"]!=nil
						lastfm["artist"] = LastFM.getArtist(mp3["artist"])

						if mp3["album"]!=nil
							lastfm["album"] = LastFM.getAlbum(mp3["artist"],mp3["album"])
						end

						if mp3["title"]!=nil
							lastfm["title"] = LastFM.getTrack(mp3["artist"],mp3["title"])
						end
					end

					#SongKick info
					if mp3["artist"]!=nil
						songkick["events"] = SongKick.getEventsForArtist(mp3["artist"],nil,nil)
					end

				end #mp3Info

				musics << [mp3,lastfm,songkick]

			end #files each
		end #def

	private

end