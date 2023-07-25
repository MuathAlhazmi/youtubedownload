import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:share_extend/share_extend.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtubedownload/main.dart';

class PreviousDownload {
  String title;
  String filePath;
  String videoUrl;
  String videoId; // Add videoId property
  DownloadOptions downloadOption;
  String thumbnailUrl;

  PreviousDownload({
    required this.title,
    required this.filePath,
    required this.videoUrl,
    required this.videoId, // Initialize the videoId property
    required this.downloadOption,
    required this.thumbnailUrl,
  });

  factory PreviousDownload.fromJson(Map<String, dynamic> json) {
    return PreviousDownload(
      title: json['title'],
      filePath: json['filePath'],
      videoUrl: json['videoUrl'],
      videoId: json['videoId'], // Deserialize the videoId property
      downloadOption: DownloadOptions.values[json['downloadOption']],
      thumbnailUrl: json['thumbnailUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'filePath': filePath,
      'videoUrl': videoUrl,
      'videoId': videoId, // Serialize the videoId property
      'downloadOption': downloadOption.index,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}

class PreviousDownloadsPage extends StatefulWidget {
  @override
  State<PreviousDownloadsPage> createState() => _PreviousDownloadsPageState();
}

class _PreviousDownloadsPageState extends State<PreviousDownloadsPage> {
  List<PreviousDownload> _downloadedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadPreviousDownloads();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Previous Downloads'),
      ),
      body: ListView.builder(
        itemCount: _downloadedFiles.length,
        itemBuilder: (context, index) {
          return ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            leading: _downloadedFiles[index].downloadOption ==
                    DownloadOptions.AudioOnly
                ? Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    height: 100,
                    width: 80,
                    child: Icon(
                      CupertinoIcons.music_note_2,
                      color: Colors.red,
                      size: 40,
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      _downloadedFiles[index].thumbnailUrl,
                      fit: BoxFit.fitWidth,
                      height: 100,
                      width: 80,
                    ),
                  ),
            title: Text(_downloadedFiles[index].title),
            onTap: () {
              print(_downloadedFiles[index].thumbnailUrl + "the url");
              _openFile(_downloadedFiles[index].filePath);
            },
            onLongPress: () {
              _showContextMenu(context, index);
            },
          );
        },
      ),
    );
  }

  void _openFile(String filePath) async {
    var result = await OpenFile.open(filePath);
    print(result.message);
  }

  void _showContextMenu(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.share),
              title: Text('Share'),
              onTap: () {
                ShareExtend.share(
                  _downloadedFiles[index].filePath,
                  _downloadedFiles[index].downloadOption ==
                          DownloadOptions.VideoAndAudio
                      ? 'video'
                      : 'audio',
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete'),
              onTap: () async {
                await _deleteItem(index);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadPreviousDownloads() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? jsonStringList = prefs.getStringList('downloaded_files');
    if (jsonStringList != null) {
      setState(() {
        _downloadedFiles = jsonStringList
            .map((jsonString) =>
                PreviousDownload.fromJson(jsonDecode(jsonString)))
            .toList();
      });
    }
  }

  Future<void> _deleteItem(int index) async {
    if (index >= 0 && index < _downloadedFiles.length) {
      // Get the item to be deleted
      PreviousDownload item = _downloadedFiles[index];

      // Remove the item from the list
      _downloadedFiles.removeAt(index);

      // Delete the file from the phone's storage
      File fileToDelete = File(item.filePath);
      if (await fileToDelete.exists()) {
        await fileToDelete.delete();
      }

      // Update shared preferences if needed
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? jsonStringList = prefs.getStringList('downloaded_files');
      if (jsonStringList != null) {
        jsonStringList.remove(jsonEncode(item.toJson()));
        await prefs.setStringList('downloaded_files', jsonStringList);
      }

      // Update the UI by rebuilding the widget
      // This will automatically remove the deleted item from the list view
      // without the need to call setState explicitly.
      // However, we do call setState here just to trigger the rebuild.

      setState(() {});

      // Show a snackbar to indicate the file was deleted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File deleted and please restart the app'),
        ),
      );
    }
  }
}
