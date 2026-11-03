enum Occasion { wedding, engagement, birthday, sebou3, graduation, dedication }

enum Mood { joyful, romantic, grand, playful }

/// Stage that has been completed; the pipeline resumes from here.
enum OrderStatus { draft, lyrics, audio, video, done }

extension OccasionKey on Occasion {
  String get l10nKey => switch (this) {
        Occasion.wedding => 'occasionWedding',
        Occasion.engagement => 'occasionEngagement',
        Occasion.birthday => 'occasionBirthday',
        Occasion.sebou3 => 'occasionSebou3',
        Occasion.graduation => 'occasionGraduation',
        Occasion.dedication => 'occasionDedication',
      };
}

extension MoodKey on Mood {
  String get l10nKey => switch (this) {
        Mood.joyful => 'moodJoyful',
        Mood.romantic => 'moodRomantic',
        Mood.grand => 'moodGrand',
        Mood.playful => 'moodPlayful',
      };
}

extension OrderStatusKey on OrderStatus {
  String get l10nKey => switch (this) {
        OrderStatus.draft => 'statusDraft',
        OrderStatus.lyrics => 'statusLyrics',
        OrderStatus.audio => 'statusAudio',
        OrderStatus.video => 'statusVideo',
        OrderStatus.done => 'statusDone',
      };
}

class Order {
  final String id;
  final String clientName;
  final Occasion occasion;
  final Mood mood;
  final String details;
  final List<String> photoPaths;

  final String verse1;
  final String verse2;
  final String chorus;
  final String stylePrompt;

  final String audioPath;
  final String videoPath;
  final OrderStatus status;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.clientName,
    required this.occasion,
    required this.mood,
    this.details = '',
    this.photoPaths = const [],
    this.verse1 = '',
    this.verse2 = '',
    this.chorus = '',
    this.stylePrompt = '',
    this.audioPath = '',
    this.videoPath = '',
    this.status = OrderStatus.draft,
    required this.createdAt,
  });

  String get lyricsText => [verse1, verse2, chorus].where((s) => s.isNotEmpty).join('\n\n');

  Order copyWith({
    String? clientName,
    Occasion? occasion,
    Mood? mood,
    String? details,
    List<String>? photoPaths,
    String? verse1,
    String? verse2,
    String? chorus,
    String? stylePrompt,
    String? audioPath,
    String? videoPath,
    OrderStatus? status,
  }) {
    return Order(
      id: id,
      clientName: clientName ?? this.clientName,
      occasion: occasion ?? this.occasion,
      mood: mood ?? this.mood,
      details: details ?? this.details,
      photoPaths: photoPaths ?? this.photoPaths,
      verse1: verse1 ?? this.verse1,
      verse2: verse2 ?? this.verse2,
      chorus: chorus ?? this.chorus,
      stylePrompt: stylePrompt ?? this.stylePrompt,
      audioPath: audioPath ?? this.audioPath,
      videoPath: videoPath ?? this.videoPath,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientName': clientName,
        'occasion': occasion.name,
        'mood': mood.name,
        'details': details,
        'photoPaths': photoPaths,
        'verse1': verse1,
        'verse2': verse2,
        'chorus': chorus,
        'stylePrompt': stylePrompt,
        'audioPath': audioPath,
        'videoPath': videoPath,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'] as String,
        clientName: j['clientName'] as String? ?? '',
        occasion: Occasion.values.asNameMap()[j['occasion']] ?? Occasion.wedding,
        mood: Mood.values.asNameMap()[j['mood']] ?? Mood.joyful,
        details: j['details'] as String? ?? '',
        photoPaths: (j['photoPaths'] as List? ?? const []).cast<String>(),
        verse1: j['verse1'] as String? ?? '',
        verse2: j['verse2'] as String? ?? '',
        chorus: j['chorus'] as String? ?? '',
        stylePrompt: j['stylePrompt'] as String? ?? '',
        audioPath: j['audioPath'] as String? ?? '',
        videoPath: j['videoPath'] as String? ?? '',
        status: OrderStatus.values.asNameMap()[j['status']] ?? OrderStatus.draft,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
