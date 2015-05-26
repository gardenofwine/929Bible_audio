require 'fileutils'
(1..187).each do |chapter|
	# copy chapter mp3	
	source_file = "chapters/#{chapter}.mp3"
	FileUtils.mv(source_file, "cd/#{chapter}_a.mp3") if File.exist? source_file
	Dir["jsons/#{chapter}/#{chapter}_jsons/#{chapter}/*"].each_with_index do |filename, index|
		source_post = "#{filename}" 
		puts source_post
		if File.exist? source_post
			FileUtils.mv(source_post, "cd/#{chapter}_b_#{index}.mp3")
		end
	end
end
	

# say -v carmit -r 120 -o "audiofile.aiff" -f "textfile.rtf"

# youtube-dl http://www.youtube.com/watch\?v\=xq5-u8wvLo8 -x --audio-format mp3
