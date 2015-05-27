require 'httparty'
require 'json'

WEEKLY_SUMMARY_START_INDEX = 1000
BOOK_SUMMARY_START_INDEX = 2000

# Genesis, Exodus, Leviticus, Numbers, Deuteronomy
CHAPTERS_PER_BOOK = [50, 40, 27, 36, 34]
JSON_DIR = "json_downloaded"
CHAPTER_POST_FILENAME_TEMPLATE = "book_%s_cha_%s_post_%s.json"
WEEKLY_SUMMARY_POST_FILENAME_TEMPLATE = "book_%s_cha_%s_weeksum_post_%s.json"
BOOK_SUMMARY_POST_FILENAME_TEMPLATE = "book_%s_summary_post_%s.json"


def book_by_chapter(chapter)
	chapter_count = 0
	CHAPTERS_PER_BOOK.each_with_index do |number_of_chapters_in_book, book|
		chapter_count = chapter_count + number_of_chapters_in_book
		return book if chapter <= chapter_count
	end
end

def download_posts(url, filename)
	post_url_template = "http://www.929.org.il/api/pages/getPost?postId="

	response = HTTParty.get(url)
	post_previews = JSON.parse(response.body)['value']
	post_previews.each do |post_preview|
		post_id = post_preview['postPreviewID']
		next if post_id == 0

		post_filename =  JSON_DIR + '/' + filename % post_id
		next if File.exist? post_filename
		
		post_url = "#{post_url_template}#{post_id}"
		resp = HTTParty.get(post_url)
		post_content = JSON.parse(resp.body)['value']

		puts "**== writing #{post_filename}"
		File.open post_filename, "w" do |file|
			file.write post_content.to_json
		end
		# video_url = post_content['embeddedVideo']
		# puts "ch #{chapter}. post #{post_id}. video #{video_url}"
	end

end

def download_posts_for_chapter(chapter, book)
	posts_preview_url_template = "http://www.929.org.il/api/pages/getChapterPostsPreviews?chapterID="
	download_posts("#{posts_preview_url_template}#{chapter}", CHAPTER_POST_FILENAME_TEMPLATE % [book, chapter, "%s"])
end

def download_weekly_summary_posts(index, chapter, book)
	summury_preview_url_template = "http://www.929.org.il/api/pages/getPagePostsPreviews?pageID="
	download_posts("#{summury_preview_url_template}#{index}", WEEKLY_SUMMARY_POST_FILENAME_TEMPLATE % [book, chapter, "%s"])
end

def download_book_summary_posts(index, book)
	summury_preview_url_template = "http://www.929.org.il/api/pages/getPagePostsPreviews?pageID="
	download_posts("#{summury_preview_url_template}#{index}", BOOK_SUMMARY_POST_FILENAME_TEMPLATE % [book, "%s"])
end

Dir.mkdir JSON_DIR unless File.exist? JSON_DIR
# Fetch chpater posts
chapter_base = 1
CHAPTERS_PER_BOOK.each_with_index do |num_of_chapters, book_idx|
	current_chapter = 0
	num_of_chapters.times do |chapter_idx|
		current_chapter = chapter_base + chapter_idx
		download_posts_for_chapter(current_chapter, book_idx + 1)
		if chapter_idx + 1 == num_of_chapters
			# download book summary
			puts "**== book summary"
			download_book_summary_posts(BOOK_SUMMARY_START_INDEX + book_idx + 1, book_idx + 1)
		elsif current_chapter % 5 == 0
			# download week summary
			puts "**== week summary"
			download_weekly_summary_posts(WEEKLY_SUMMARY_START_INDEX + current_chapter / 5, current_chapter, book_idx + 1)
		end
	end
	chapter_base = current_chapter + 1
end

# video_url = post_content['embeddedVideo']
# puts "ch #{chapter}. post #{post_id}. video #{video_url}"

# say -v carmit -r 120 -o "audiofile.aiff" -f "textfile.rtf"

# youtube-dl http://www.youtube.com/watch\?v\=xq5-u8wvLo8 -x --audio-format mp3
