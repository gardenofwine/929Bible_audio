require 'httparty'
require 'json'
require 'fileutils'

WEEKLY_SUMMARY_START_INDEX = 1000
BOOK_SUMMARY_START_INDEX = 2000

START_BOOK = 26

# Starting episode 358 (Isaiah {book 12} chapter 24), The site started to host all 
# audio content exclusively in Soundcloud. 

# Genesis, Exodus, Leviticus, Numbers, Deuteronomy, Book of Joshua, Book of Judges
# book of Samuel A, book of Samuel B, Book of Kings A, Book of kings B
# Book of Isaiah, ## Jeremiah, Ezekiel,  Hosea, Joel, Amos, Obadiah, Jonah
# Micah, Nahum, Habakkuk, Zephaniah, Haggai, Zechariah, Malachi, 
# Proverbs, Song of Solomon, Job, Proverbs, Ruth, Lamentations, Ecclesiastes, Esther, 
# Daniel, Ezra, Nehemiah, Chronicles A, Chronicles B
CHAPTERS_PER_BOOK = [50, 40, 27, 36, 34, # Tanach 5
 	24, 21, 31, 24, 22, 25, 66, 52, 48, 14,	4,9,1,4,7,3,3,3,2,14,3, # neviim 21
 	150,31,42,8,4,5,12,10,12,10,13,29,36] # ktuvim
JSON_DIR = "json_downloaded"
MEDIA_DIR = "media_downloaded"
CHAPTER_POST_FILENAME_TEMPLATE = "book_%.2i_cha_%.3i_post_%s.json"
WEEKLY_SUMMARY_POST_FILENAME_TEMPLATE = "book_%.2i_cha_%.3i_weeksum_post_%s.json"
BOOK_SUMMARY_POST_FILENAME_TEMPLATE = "book_%.2i_summary_post_%s.json"
BOOK_CHAPTER_AUDIO_FILENAME_TEMPLATE = "book_%.2i_cha_%.3i_audio.mp3"

excludes = File.read "excludes.json"
EXCLUDES_LIST =	JSON.parse(excludes)
SOUND_CLOUD_CLIENT_ID = "cUa40O3Jg3Emvp6Tv4U6ymYYO50NUGpJ"


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


def youtube_filename_by_json_file(file_path)
	filename = file_path.sub(".json", "").sub("#{JSON_DIR}/", "")
	"#{MEDIA_DIR}/youtube/#{filename}" 
end

def download_youtube(title, url, output_filename)
	return if File.exist? "#{output_filename}_b.mp3"
	return if EXCLUDES_LIST.include? "#{output_filename.split("/").last}_b"
	system 'youtube-dl', '-o', "#{output_filename}_b.%(ext)s", url, '-x', '--audio-format', 'mp3', '--prefer-ffmpeg'
	if (title.length > 0)
		system 'say', '-v', 'carmit', '-r', '120', '-o', "#{output_filename}_a.aiff", title
		system 'lame', '-m', 'm', "#{output_filename}_a.aiff", "#{output_filename}_a.mp3"
		File.delete "#{output_filename}_a.aiff"
	else
		File.open  "#{output_filename}_a_missing_title.txt", 'w' do |file|
			file.write url
		end
	end
end

def download_soundcloud(title, track_id, output_filename)
	return if File.exist? "#{output_filename}_b.mp3"
	return if EXCLUDES_LIST.include? "#{output_filename.split("/").last}_b"
	soundcloud_download_url = "https://api.soundcloud.com/tracks/#{track_id}/download\?client_id\=#{SOUND_CLOUD_CLIENT_ID}"
	system 'curl', '-L', soundcloud_download_url, '-o', "temp.m4a"
	system 'ffmpeg', '-i', "temp.m4a", "#{output_filename}_b.mp3"
	if (title.length > 0)
		system 'say', '-v', 'carmit', '-r', '120', '-o', "#{output_filename}_a.aiff", title
		system 'lame', '-m', 'm', "#{output_filename}_a.aiff", "#{output_filename}_a.mp3"
		File.delete "#{output_filename}_a.aiff"
	else
		File.open "#{output_filename}_a_missing_title.txt", 'w' do |file|
			file.write soundcloud_download_url
		end
	end
end

def process_post_json(file_path)
	output_filename = youtube_filename_by_json_file(file_path)
	return if File.exist? output_filename

	content = File.read file_path
	post_json =	JSON.parse(content)
	if post_json['embeddedVideo'] != nil &&  post_json['embeddedVideo'].length > 0
		download_youtube(post_json['title'], post_json['embeddedVideo'], output_filename)
	elsif post_json['previewVideo'] != nil &&  post_json['previewVideo'].length > 0
		download_youtube(post_json['title'], post_json['previewVideo'], output_filename)
	elsif post_json['externalIframeURL'] != nil && post_json['externalIframeURL'].length > 0
		match_data = /tracks\/(\d*)/.match post_json['externalIframeURL']
		if (match_data && match_data.captures.length > 0)
			download_soundcloud(post_json['mainCaption'], match_data.captures[0], output_filename)
		end
	end
end

def iterate_chapters
	chapter_base = 1
	CHAPTERS_PER_BOOK.each_with_index do |num_of_chapters, book_idx|
		if (book_idx >= START_BOOK)
			num_of_chapters.times do |chapter_idx|
				last_chapter = (num_of_chapters == chapter_idx + 1)
				yield book_idx + 1, chapter_base + chapter_idx, last_chapter
			end
		end
		chapter_base = chapter_base + num_of_chapters
	end
end

def download_chapters
	iterate_chapters do |book, chapter, last_chapter|
		chapter_filename = "#{MEDIA_DIR}/chapters/#{BOOK_CHAPTER_AUDIO_FILENAME_TEMPLATE % [book.to_i, chapter.to_i]}"
		next if File.exists? chapter_filename
		# if windows, run sysytem './curl'
		next if get_chapter_url(chapter) == nil
		system 'curl', get_chapter_url(chapter), '-o', chapter_filename
		# The chapters after 555 are hosted in a different place
	end
end

def get_chapter_url(chapter_idx)
	if chapter_idx <= 555
		return "http://reading.929.org.il/#{chapter_idx}.mp3"
	else 
		response = HTTParty.get("https://www.929.org.il/api/pages/getChapterTracks?chapterID=#{chapter_idx}")
		if response["value"].empty? 
			puts "missing audio for chapter #{chapter_idx}"
			return
		end
		return response["value"][0]["trackURL"]
	end
end

def download_jsons
	Dir.mkdir JSON_DIR unless File.exist? JSON_DIR
	# Fetch chpater posts

	iterate_chapters do |book, chapter, last_chapter|
		download_posts_for_chapter(chapter, book)
		if last_chapter
			# download book summary
			download_book_summary_posts(BOOK_SUMMARY_START_INDEX + book, book)
		elsif chapter % 5 == 0
			# download week summary
			download_weekly_summary_posts(WEEKLY_SUMMARY_START_INDEX + chapter / 5, chapter, book)
		end
	end
end

def download_youtubes
	
	#Download videos and chapters
	Dir["#{JSON_DIR}/*"].each_with_index do |filename, index|
		process_post_json(filename)
	end
end

download_chapters
download_jsons
download_youtubes
