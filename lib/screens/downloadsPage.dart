import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:youtubedownload/helpers/previousDownload.dart';

class DownloadedFilePage extends StatelessWidget {
  final PreviousDownload download;

  DownloadedFilePage(this.download);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Downloaded File'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Title: ${download.title}'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => OpenFile.open(download.filePath),
              child: Text('Open Downloaded File'),
            ),
          ],
        ),
      ),
    );
  }
}
