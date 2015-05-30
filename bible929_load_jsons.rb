require 'httparty'
require 'json'
require 'fileutils'

WEEKLY_SUMMARY_START_INDEX = 1000
BOOK_SUMMARY_START_INDEX = 2000

# Genesis, Exodus, Leviticus, Numbers, Deuteronomy
CHAPTERS_PER_BOOK = [50, 40, 27, 36, 34]
JSON_DIR = "json_downloaded"
MEDIA_DIR = "media_downloaded"
CHAPTER_POST_FILENAME_TEMPLATE = "book_%.2i_cha_%.3i_post_%s.json"
WEEKLY_SUMMARY_POST_FILENAME_TEMPLATE = "book_%.2i_cha_%.3i_weeksum_post_%s.json"
BOOK_SUMMARY_POST_FILENAME_TEMPLATE = "book_%.2i_summary_post_%s.json"
BOOK_CHAPTER_AUDIO_FILENAME_TEMPLATE = "book_%.2i_cha_%.3i_audio.mp3"


POST_FILENAME_REGEX = /book_(\d*)_cha_(\d*)_post_(\d*).json/
WEEKLY_POST_FILENAME_REGEX = /book_(\d*)_cha_(\d*)_weeksum_post_(\d*).json/
BOOK_SUMMARY_POST_FILENAME_REGEX = /book_(\d*)_summary_post_(\d*).json/

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


def download_jsons
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
end

def youtube_filename_by_json_file(file_path)
	filename = file_path.sub(".json", "").sub("#{JSON_DIR}/", "")
	"#{MEDIA_DIR}/youtube/#{filename}" 
end

def process_post_json(file_path)
	output_filename = youtube_filename_by_json_file(file_path)
	return if File.exist? output_filename
	content = File.read file_path
	post_json =	JSON.parse(content)
	if post_json['embeddedVideo'] != nil &&  post_json['embeddedVideo'].length > 0
		system 'youtube-dl', '-o', "#{output_filename}_b.%(ext)s", post_json['embeddedVideo'], '-x', '--audio-format', 'mp3', '--prefer-ffmpeg'
		if (post_json['title'].length > 0)
			system 'say', '-v', 'carmit', '-r', '120', '-o', "#{output_filename}_a.aiff", post_json['title']
			system 'lame', '-m', 'm', "#{output_filename}_a.aiff", "#{output_filename}_a.mp3"
			File.delete "#{output_filename}_a.aiff"
		else
			File.open  "#{output_filename}_a_missing_title.txt", 'w' do |file|
				file.write post_json['embeddedVideo']
			end
		end
	end
end

def download_youtubes
	#Download videos and chapters
	Dir["#{JSON_DIR}/*"].each_with_index do |filename, index|
		process_post_json(filename)
	end
end

def layout_cd_files
	Dir["#{JSON_DIR}/*"].each_with_index do |filename, index|
		match = filename.match /book_([\d]*)_cha_([\d]*)/
		next unless match
		book, chapter = match.captures

		#copy chapter audio 
		source_chapter_audio_file = "#{MEDIA_DIR}/chapters/#{chapter.to_i}.mp3"
		output_chapter_audio_file = "output/#{BOOK_CHAPTER_AUDIO_FILENAME_TEMPLATE % [book.to_i, chapter.to_i]}"
		if !File.exist? output_chapter_audio_file
			FileUtils.copy source_chapter_audio_file, output_chapter_audio_file
		end
	end
end

# download_jsons
# download_youtubes
layout_cd_files
