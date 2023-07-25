import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtubedownload/helpers/previousDownload.dart';
import 'package:youtubedownload/widgets/snackbar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

Future<bool> _checkPermission() async {
  return await Permission.storage.isGranted;
}

Future<void> _requestPermission() async {
  var status = await Permission.storage.request();
  print('Permission status: $status');
  if (status.isGranted) {
    print('allowed');
  } else {
    // Permission denied, handle it accordingly
    print('not allowed.');
  }
}

class _MyAppState extends State<MyApp> {
  List<PreviousDownload> _downloadedFiles =
      []; // Declare the _downloadedFiles list

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    // Check if the required permission is granted
    if (await _checkPermission() == false) {
      // Request the permission if it's not granted
      await _requestPermission();
    }

    // Load previous downloads once the permission is granted
    _loadPreviousDownloads();
  }

  // Check if the required permission is granted
  Future<bool> _checkPermission() async {
    PermissionStatus status = await Permission.storage.status;
    return status == PermissionStatus.granted;
  }

  // Request the required permission
  Future<void> _requestPermission() async {
    PermissionStatus status = await Permission.storage.request();
    if (status.isPermanentlyDenied) {
      // Handle the permanently denied status
      // You can show a snackbar or an alert dialog to inform the user
      // and guide them on how to manually enable the permission.

      // For example, you can use a snackbar with an action to open app settings.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please grant storage permission to use this app.'),
          action: SnackBarAction(
            label: 'SETTINGS',
            onPressed: () {
              openAppSettings();
            },
          ),
        ),
      );
    } else if (status.isDenied) {
      // Handle if the user denies the permission request
      // You can show a snackbar or an alert dialog to inform the user.
      print("Permission denied.");
    }
  }

  Future<void> _loadPreviousDownloads() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      String? jsonString = prefs.getString('downloaded_files');
      if (jsonString != null) {
        print('found files');

        List<dynamic>? jsonList = jsonDecode(jsonString);
        if (jsonList != null) {
          _downloadedFiles = jsonList
              .map((json) => PreviousDownload.fromJson(jsonDecode(json)))
              .toList();
          _downloadedFiles.forEach((element) {
            print(element.videoId);
          });
        } else {
          _downloadedFiles = [];
          print('not found files');
        }
      } else {
        _downloadedFiles = [];
        print('not found files');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.red),
      debugShowCheckedModeBanner: false,
      title: 'YouTube Downloader',
      initialRoute: '/',
      routes: {
        '/': (context) => YouTubeDownloaderWidget(),
        '/previous_downloads': (context) => PreviousDownloadsPage(),
      },
    );
  }
}

enum DownloadOptions {
  VideoAndAudio,
  AudioOnly,
}

class YouTubeDownloaderWidget extends StatefulWidget {
  @override
  _YouTubeDownloaderWidgetState createState() =>
      _YouTubeDownloaderWidgetState();
}

class HomePage extends StatelessWidget {
  final _YouTubeDownloaderWidgetState parentState;
  final TextEditingController _textEditingController = TextEditingController();

  HomePage(this.parentState);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoTextField(
            controller: _textEditingController,
            padding: EdgeInsets.all(15),
            placeholder: 'Enter YouTube Url',
          ),
          SizedBox(height: 16),
          Text(
            'Choose Download Option:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          ListTile(
            title: const Text('Video and Audio'),
            leading: Radio(
              value: DownloadOptions.VideoAndAudio,
              groupValue: parentState._downloadOption,
              onChanged: (value) => parentState._setDownloadOption(value!),
            ),
          ),
          ListTile(
            title: const Text('Audio Only'),
            leading: Radio(
              value: DownloadOptions.AudioOnly,
              groupValue: parentState._downloadOption,
              onChanged: (value) => parentState._setDownloadOption(value!),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              parentState._downloadVideo(_textEditingController.value.text);
            },
            child: Text('Download Video'),
          ),
        ],
      ),
    );
  }
}

class _YouTubeDownloaderWidgetState extends State<YouTubeDownloaderWidget> {
  double _downloadProgress = 0.0;
  bool _downloading = false;
  DownloadOptions _downloadOption =
      DownloadOptions.VideoAndAudio; // Default option

  String _downloadedFilePath = '';
  List<PreviousDownload> _downloadedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadPreviousDownloads(); // Load downloaded files on app start
  }

  Future<void> _loadPreviousDownloads() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? jsonStringList = prefs.getStringList('downloaded_files');
    print(jsonStringList);
    if (jsonStringList != null) {
      setState(() {
        _downloadedFiles = jsonStringList
            .map((jsonString) =>
                PreviousDownload.fromJson(jsonDecode(jsonString)))
            .toList();
      });
    }
  }

  Future<void> _saveDownloadedFiles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> jsonList = _downloadedFiles
        .map((download) => jsonEncode(download.toJson()))
        .toList();
    print(jsonList);

    await prefs.setStringList('downloaded_files', jsonList);
  }

  void _setDownloadOption(DownloadOptions option) {
    setState(() {
      _downloadOption = option;
    });
  }

  void _downloadVideo(String url) async {
    if (url.isNotEmpty) {
      // Check and request storage permission if not granted
      if (!(await _checkPermission())) {
        await _requestPermission();
        return;
      }

      _downloading = true;
      setState(() {});

      var yt = YoutubeExplode();
      var video = await yt.videos.get(url);
      var duplicate = _downloadedFiles.any((download) {
        return download.videoId == video.id.value &&
            download.downloadOption == _downloadOption;
      });
      if (duplicate) {
        showTopSnackBar(context, 'Video is already downloaded');
        setState(() {
          _downloading = false;

          _downloadProgress = 0.0;
        });
        return;
      }

      var manifest = await yt.videos.streamsClient.getManifest(video.id.value);
      var streams = List.from(manifest.muxed);
      streams.sort((a, b) {
        // Sort by video quality
        return b.videoResolution.compareTo(a.videoResolution);
      });

      MuxedStreamInfo? videoStreamInfo;
      MuxedStreamInfo? audioStreamInfo;
      switch (_downloadOption) {
        case DownloadOptions.VideoAndAudio:
          videoStreamInfo = streams.firstWhere(
            (stream) => stream.audioCodec != null && stream.videoCodec != null,
            orElse: () => null,
          );
          break;
        case DownloadOptions.AudioOnly:
          audioStreamInfo = streams.firstWhere(
            (stream) => stream.audioCodec != null && stream.videoCodec != null,
            orElse: () => null,
          );
          break;
      }

      if (_downloadOption == DownloadOptions.AudioOnly &&
          audioStreamInfo != null) {
        Directory? appExternalDir = await getExternalStorageDirectory();
        if (appExternalDir != null) {
          String downloadDirectory = appExternalDir.path;

          var file = File('$downloadDirectory/${video.title}.mp3');
          var fileStream = file.openWrite();

          var audioStream = yt.videos.streamsClient.get(audioStreamInfo);
          var length = audioStreamInfo.size.totalBytes;

          var receivedBytes = 0;

          await for (var data in audioStream) {
            receivedBytes += data.length;
            _downloadProgress = receivedBytes.toDouble() / length.toDouble();
            setState(() {});

            fileStream.add(data);
          }

          await fileStream.flush();
          await fileStream.close();
          yt.close();
          setState(() {
            _downloadedFilePath = file.path;
            print(_downloadedFilePath);
            _downloadedFiles.add(PreviousDownload(
                thumbnailUrl: video.thumbnails.highResUrl,
                videoId: video.id.value, // Add the video ID here

                title: video.title,
                filePath: file.path,
                videoUrl: video.url,
                downloadOption: DownloadOptions.AudioOnly));
            _downloading = false;
            print('done');
            _saveDownloadedFiles();
            showTopSnackBar(context, 'Downloaded Audio');
          });
        } else {
          print('error');
        }
      } else if (_downloadOption == DownloadOptions.VideoAndAudio &&
          videoStreamInfo != null) {
        Directory? appExternalDir = await getExternalStorageDirectory();
        if (appExternalDir != null) {
          String downloadDirectory = appExternalDir.path;

          var file = File(
              '$downloadDirectory/${video.title}.${videoStreamInfo.container.name}.mp4');
          var fileStream = file.openWrite();

          var videoStream = yt.videos.streamsClient.get(videoStreamInfo);
          var length = videoStreamInfo.size.totalBytes;

          var receivedBytes = 0;

          await for (var data in videoStream) {
            receivedBytes += data.length;
            _downloadProgress = receivedBytes.toDouble() / length.toDouble();
            setState(() {});

            fileStream.add(data);
          }

          await fileStream.flush();
          await fileStream.close();
          yt.close();
          setState(() {
            _downloadedFilePath = file.path;
            _downloadedFiles.add(PreviousDownload(
                thumbnailUrl: video.thumbnails.highResUrl,
                videoId: video.id.value, // Add the video ID here

                title: video.title,
                filePath: file.path,
                videoUrl: video.url,
                downloadOption: DownloadOptions.VideoAndAudio));

            print(_downloadedFilePath);

            _downloading = false;
            print('done');
            _saveDownloadedFiles();
            showTopSnackBar(context, 'Downloaded File');
            setState(() {
              _downloadProgress = 0.0;
            });
          });
        } else {
          print('error');
        }
      } else {
        // If no suitable stream found
        yt.close();
        setState(() {
          _downloading = false;
          _downloadProgress = 0.0;
          print('No suitable stream found.');
        });
      }
    }
  }

  void _openDownloadedFile() async {
    _requestPermission();
    if (_downloadedFilePath.isNotEmpty) {
      showTopSnackBar(context, 'File Opening...');

      var result = await OpenFile.open(_downloadedFilePath);

      print(result.message);
    }
  }

  Future<bool> _checkPermission() async {
    return await Permission.storage.isGranted;
  }

  Future<void> _requestPermission() async {
    var status = await Permission.storage.request();
    print('Permission status: $status');
    if (status.isGranted) {
      print('allowed');
    } else {
      // Permission denied, handle it accordingly
      print('not allowed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'YouTube Downloader',
              style: TextStyle(color: Colors.black),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _downloading
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HomePage(this),
                      SizedBox(height: 16.0),
                      Container(
                        height: 50,
                        child: LiquidLinearProgressIndicator(
                          value: _downloadProgress,
                          valueColor: AlwaysStoppedAnimation(Colors.lightBlue),
                          backgroundColor: Colors.white,
                          borderColor: Colors.lightBlue,
                          borderWidth: 2.0,
                          borderRadius: 20.0,
                          direction: Axis.horizontal,
                          center: Text(
                            '${(_downloadProgress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      HomePage(this),
                      if (_downloadedFilePath.isNotEmpty)
                        ElevatedButton(
                          onPressed: _openDownloadedFile,
                          child: Text('Open Downloaded File'),
                        ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/previous_downloads',
                              arguments: _downloadedFiles);
                        },
                        child: Text('Previous Downloads'),
                      ), // Add the button for navigating to Previous Downloads
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
