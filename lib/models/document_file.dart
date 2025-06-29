class DocumentFile {
  final String id;
  final String name;
  final String url;
  final String folderId;
  final String createdBy;
  final DateTime uploadedAt;
  final int? fileSize;
  final String? mimeType;
  final String? thumbnailUrl;
  final List<String> tags;

  DocumentFile({
    required this.id,
    required this.name,
    required this.url,
    required this.folderId,
    required this.createdBy,
    required this.uploadedAt,
    this.fileSize,
    this.mimeType,
    this.thumbnailUrl,
    this.tags = const [],
  });

  factory DocumentFile.fromFirestore(Map<String, dynamic> data, String id) {
    return DocumentFile(
      id: id,
      name: data['name'] ?? '',
      url: data['url'] ?? '',
      folderId: data['folderId'] ?? '',
      createdBy: data['createdBy'] ?? '',
      uploadedAt: data['uploadedAt']?.toDate() ?? DateTime.now(),
      fileSize: data['fileSize'],
      mimeType: data['mimeType'],
      thumbnailUrl: data['thumbnailUrl'],
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'url': url,
      'folderId': folderId,
      'createdBy': createdBy,
      'uploadedAt': uploadedAt,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'thumbnailUrl': thumbnailUrl,
      'tags': tags,
    };
  }

  String get fileExtension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  DocumentType get documentType {
    switch (fileExtension) {
      case 'pdf':
        return DocumentType.pdf;
      case 'doc':
      case 'docx':
        return DocumentType.word;
      case 'xls':
      case 'xlsx':
        return DocumentType.excel;
      case 'ppt':
      case 'pptx':
        return DocumentType.powerpoint;
      case 'txt':
        return DocumentType.text;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        return DocumentType.image;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'wmv':
        return DocumentType.video;
      case 'mp3':
      case 'wav':
      case 'aac':
        return DocumentType.audio;
      default:
        return DocumentType.other;
    }
  }

  String get formattedFileSize {
    if (fileSize == null) return 'Taille inconnue';

    if (fileSize! < 1024) {
      return '${fileSize!} B';
    } else if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize! < 1024 * 1024 * 1024) {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize! / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  bool get canPreview {
    return documentType == DocumentType.image ||
        documentType == DocumentType.pdf ||
        documentType == DocumentType.text;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentFile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum DocumentType {
  pdf,
  word,
  excel,
  powerpoint,
  text,
  image,
  video,
  audio,
  other,
}

extension DocumentTypeExtension on DocumentType {
  String get displayName {
    switch (this) {
      case DocumentType.pdf:
        return 'PDF';
      case DocumentType.word:
        return 'Word';
      case DocumentType.excel:
        return 'Excel';
      case DocumentType.powerpoint:
        return 'PowerPoint';
      case DocumentType.text:
        return 'Texte';
      case DocumentType.image:
        return 'Image';
      case DocumentType.video:
        return 'Vidéo';
      case DocumentType.audio:
        return 'Audio';
      case DocumentType.other:
        return 'Autre';
    }
  }

  String get iconPath {
    switch (this) {
      case DocumentType.pdf:
        return 'assets/icons/pdf.svg';
      case DocumentType.word:
        return 'assets/icons/word.svg';
      case DocumentType.excel:
        return 'assets/icons/excel.svg';
      case DocumentType.powerpoint:
        return 'assets/icons/powerpoint.svg';
      case DocumentType.text:
        return 'assets/icons/text.svg';
      case DocumentType.image:
        return 'assets/icons/image.svg';
      case DocumentType.video:
        return 'assets/icons/video.svg';
      case DocumentType.audio:
        return 'assets/icons/audio.svg';
      case DocumentType.other:
        return 'assets/icons/file.svg';
    }
  }
}
