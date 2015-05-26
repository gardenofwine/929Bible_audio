require 'json'

bible_url_template = "http://www.929.org.il/chapter/"
posts_preview_url_template = "http://www.929.org.il/api/pages/getChapterPostsPreviews?chapterID="
post_url_template = "http://www.929.org.il/api/pages/getPost?postId="

(1..187).each do |chapter|
	Dir["jsons/#{chapter}/*"].each do |filename|
		content = File.read filename
		post_json =	JSON.parse(content)
		if post_json['embeddedVideo'] != nil &&  post_json['embeddedVideo'].length > 0
			puts "**== #{post_json['embeddedVideo']}"
			system 'youtube-dl', '-o', "jsons/#{chapter}/#{chapter}_#{filename}.mp3", post_json['embeddedVideo'], '-x', '--audio-format', 'mp3'
		end
	end
end
	

# say -v carmit -r 120 -o "audiofile.aiff" -f "textfile.rtf"

# youtube-dl http://www.youtube.com/watch\?v\=xq5-u8wvLo8 -x --audio-format mp3
