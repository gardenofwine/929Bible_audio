require 'httparty'
require 'json'

post_url_template = "http://www.929.org.il/api/pages/getPost?postId="

system 'mkdir', 'summary_1'
response = HTTParty.get("http://www.929.org.il/api/pages/getPagePostsPreviews?pageID=2001")
chapter_summary_posts = JSON.parse(response.body)['value']
chapter_summary_posts.each do |post_preview|
	post_id = post_preview['postPreviewID']
	resp = HTTParty.get("#{post_url_template}#{post_id}")
	post_content = JSON.parse(resp.body)['value']

	post_filename =  "summary_1/post_#{post_id}.json"
	File.delete post_filename if File.exist? post_filename
	File.open post_filename, "w" do |file|
		file.write post_content.to_json
	end

	if post_content['embeddedVideo'] != nil &&  post_content['embeddedVideo'].length > 0
		system 'youtube-dl', '-o', "summry_1/#{post_id}.mp3", post_content['embeddedVideo'], '-x', '--audio-format', 'mp3'
	end
end
	# video_url = post_content['embeddedVideo']
	# puts "ch #{chapter}. post #{post_id}. video #{video_url}"
	

# say -v carmit -r 120 -o "audiofile.aiff" -f "textfile.rtf"

# youtube-dl http://www.youtube.com/watch\?v\=xq5-u8wvLo8 -x --audio-format mp3
