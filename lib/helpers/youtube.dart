import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Stream<Map<String, dynamic>> fetchVideoInfo(String videoUrl) async* {
  var yt = YoutubeExplode();
  var video = await yt.videos.get(videoUrl);

  // Extract necessary information from the video object
  Map<String, dynamic> videoInfo = {
    'title': video.title,
    'thumbnail': video.thumbnails.highResUrl,
    'author': video.author,
    'description': video.description,
    'duration': video.duration,
    'engagement': video.engagement,
    'isLive': video.isLive,
    'date': video.publishDate,
  };

  yt.close();

  yield videoInfo;
}
