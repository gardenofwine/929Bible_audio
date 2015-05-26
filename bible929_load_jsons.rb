require 'httparty'
require 'json'

posts_preview_url_template = "http://www.929.org.il/api/pages/getChapterPostsPreviews?chapterID="
post_url_template = "http://www.929.org.il/api/pages/getPost?postId="
summury_preview_url_template = "http://www.929.org.il/api/pages/getPagePostsPreviews?pageID="


CHAPTER_NUMBER = 187
WEEKLY_SUMMARY_NUMBER = CHAPTER_NUMBER / 5
WEEKLY_SUMMARY_START_INDEX = 1000
BOOK_SUMMARY_START_INDEX = 2000

# Genesis, Exodus, Leviticus, Numbers, Deuteronomy
CHAPTERS_PER_BOOK = [50, 40, 27, 36, 34]
JSON_DIR = "json_downloaded"
CHAPTER_POST_FILENAME_TEMPLATE = "book_%s_cha_%s_post_%s.json"


def book_by_chapter(chapter)
	chapter_count = 0
	CHAPTERS_PER_BOOK.each_with_index do |number_of_chapters_in_book, book|
		chapter_count = chapter_count + number_of_chapters_in_book
		return book if chapter <= chapter_count
	end
end

system 'mkdir', JSON_DIR unless File.exist? JSON_DIR
# Fetch chpater posts
(1..CHAPTER_NUMBER).each do |chapter|
	book = book_by_chapter(chapter) + 1
	response = HTTParty.get("#{posts_preview_url_template}#{chapter}")
	post_previews = JSON.parse(response.body)['value']
	post_previews.each do |post_preview|
		post_id = post_preview['postPreviewID']
		next if post_id == 0

		resp = HTTParty.get("#{post_url_template}#{post_id}")
		post_content = JSON.parse(resp.body)['value']
		post_filename =  JSON_DIR + '/' + CHAPTER_POST_FILENAME_TEMPLATE % [book, chapter, post_id]
		next if File.exist? post_filename

		File.open post_filename, "w" do |file|
			file.write post_content.to_json
		end
		# video_url = post_content['embeddedVideo']
		# puts "ch #{chapter}. post #{post_id}. video #{video_url}"
	end
end
	


# say -v carmit -r 120 -o "audiofile.aiff" -f "textfile.rtf"

# youtube-dl http://www.youtube.com/watch\?v\=xq5-u8wvLo8 -x --audio-format mp3
