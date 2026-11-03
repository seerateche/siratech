import '../../orders/domain/order.dart';

abstract class VideoComposer {
  /// Burns a Ken-Burns slideshow of [photoPaths] with [audioPath] and
  /// gold/purple captions into an MP4 at [outputPath].
  Future<String> compose({
    required Order order,
    required String audioPath,
    required List<String> photoPaths,
    required String outputPath,
    required int width,
    required int height,
    void Function(double progress)? onProgress,
  });
}
