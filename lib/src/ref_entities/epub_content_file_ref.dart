import 'dart:async';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'dart:convert' as convert;
import 'package:collection/collection.dart' show IterableExtension;
import 'package:quiver/core.dart';

import '../entities/epub_content_type.dart';
import '../utils/zip_path_utils.dart';
import 'epub_book_ref.dart';

abstract class EpubContentFileRef {
  late EpubBookRef epubBookRef;

  String? FileName;

  EpubContentType? ContentType;
  String? ContentMimeType;
  EpubContentFileRef(this.epubBookRef);

  @override
  int get hashCode =>
      hash3(FileName.hashCode, ContentMimeType.hashCode, ContentType.hashCode);

  @override
  bool operator ==(other) {
    return (other is EpubContentFileRef &&
        other.FileName == FileName &&
        other.ContentMimeType == ContentMimeType &&
        other.ContentType == ContentType);
  }

  ArchiveFile getContentFileEntry() {
    var contentFilePath = ZipPathUtils.combine(
        epubBookRef.Schema!.ContentDirectoryPath, FileName);
    var contentFileEntry = epubBookRef.EpubArchive()!
        .files
        .firstWhereOrNull((ArchiveFile x) => x.name == contentFilePath);
    if (contentFileEntry == null) {
      throw Exception(
          'EPUB parsing error: file $contentFilePath not found in archive.');
    }
    return contentFileEntry;
  }

  Uint8List getContentStream() {
    return openContentStream(getContentFileEntry());
  }

  Uint8List openContentStream(ArchiveFile contentFileEntry) {
    if (contentFileEntry.rawContent == null) {
      throw Exception(
          'Incorrect EPUB file: content file \"$FileName\" specified in manifest is not found.');
    }
    return contentFileEntry.rawContent!.toUint8List();
  }

  Future<Uint8List> readContentAsBytes() async {
    var contentFileEntry = getContentFileEntry();
    var content = openContentStream(contentFileEntry);
    return content;
  }

  Future<String> readContentAsText() async {
    var contentStream = getContentStream();
    var result = convert.utf8.decode(contentStream);
    return result;
  }
}
