# 929 תנ״ך ביחד - הורדת קבצי השמע
__English instructions after the Hebrew ones__

<div dir="rtl">

[פרוייקט 929](http://www.929.org.il/today) הוא פרוייקט נהדר. התוכנה הנמצאת כאן מורידה את כל קבצי השמע של הפרוייקט - פרקי התורה המוקראים וכמו כן כל סרטוני היוטוב בפורמט אמ פי 3.

התוכנה נכתבה במחשב מקינטוש, ולא בדקתי אותה על מחשב ווינדוס.

<h2>הוראות</h2>
יש להתקין את התוכנות הבאות לפני הרצה של התוכנה:

<ol>
<li> [Ruby](https://www.ruby-lang.org/en/downloads/) </li>
<li> [youtube-dl](https://rg3.github.io/youtube-dl/) </li>
<li> [ffmpeg](https://www.ffmpeg.org/download.html) </li>
<li> [Mac text to speach - hebrew](http://andynaselli.com/how-to-make-your-mac-read-text-aloud) </li>
</ol>
לאחר מכן הורידו את התוכנה והריצו אותה כך:
<pre>
ruby bible929_audio.rb
</pre>

התוכנה תתחיל להוריד הרבה קבצים. בסיום, פרקי התורה יהיו בתיקייה 
<pre>
media_downloaded/chapters
</pre>

קבצי השמע אשר הופקו מסרטוני היוטוב יהיו בתיקייה

<pre>
media_downloaded/youtube
</pre>


שמות הקבצים בנויים כך שסדר ההשמעה שלהם בנגן אמ פי 3 יהיה לפי סדר הפרקים; קודם פרק התורה, ולאחר מכן כל הפירושים. לפני כל פירוש 
ישנו קובץ השמעה עם כותרת הסרט. באם לא ניתן היה ליצור קובץ השמעה עם כותרת הסרט, יהיה קובץ בעל סיומת

<pre>
txt
<pre>

תוכלו להקליט את שמות כותרות הקבצים בעצמכם. 

</div>

# Project bibile 929 - audio download
[Project 929](http://www.929.org.il/today) is an Isreali project encouraging people to read a bible chapter a day. The content is fully in Hebrew.

This ruby script downloads the first 5 Bible books in mp3 format, and all the comments and explanations to these chapters from youtube, also in in mp3 format.

## Installation

prerequisites:

1. [Ruby](https://www.ruby-lang.org/en/downloads/)
2. [youtube-dl](https://rg3.github.io/youtube-dl/)
3. [ffmpeg](https://www.ffmpeg.org/download.html)
4. [Mac text to speach - hebrew](http://andynaselli.com/how-to-make-your-mac-read-text-aloud)

After downloading the script, run it like so:

`ruby bible929_audio.rb`

This will take a while - a few hours at least.

The output files will be located at the  `media_downloaded/chapters` and the `media_downloaded/youtube` directory.


