import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class PhotoCropScreen extends StatefulWidget {
  const PhotoCropScreen({
    super.key,
    required this.imageBytes,
  });

  final Uint8List imageBytes;

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  static const _purple = Color(0xFF9B5CFF);
  static const _background = Color(0xFFFFF8FF);

  ui.Image? _image;
  bool _isLoading = true;
  bool _isSaving = false;

  double _zoom = 1.0;
  Offset _offset = Offset.zero;
  double _startZoom = 1.0;
  Offset _startOffset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  double _viewportSide = 0;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  Future<void> _decodeImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      if (!mounted) return;
      setState(() {
        _image = frame.image;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _baseScale(double side) {
    final image = _image;
    if (image == null) return 1;
    final horizontal = side / image.width;
    final vertical = side / image.height;
    return horizontal > vertical ? horizontal : vertical;
  }

  Offset _clampOffset(Offset value, double side, double zoom) {
    final image = _image;
    if (image == null) return Offset.zero;

    final scale = _baseScale(side) * zoom;
    final displayedWidth = image.width * scale;
    final displayedHeight = image.height * scale;
    final maxX = ((displayedWidth - side) / 2).clamp(0.0, double.infinity);
    final maxY = ((displayedHeight - side) / 2).clamp(0.0, double.infinity);

    return Offset(
      value.dx.clamp(-maxX, maxX).toDouble(),
      value.dy.clamp(-maxY, maxY).toDouble(),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _startZoom = _zoom;
    _startOffset = _offset;
    _startFocalPoint = details.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (_viewportSide <= 0) return;

    final nextZoom = (_startZoom * details.scale).clamp(1.0, 4.0).toDouble();
    final moved = _startOffset + (details.focalPoint - _startFocalPoint);

    setState(() {
      _zoom = nextZoom;
      _offset = _clampOffset(moved, _viewportSide, nextZoom);
    });
  }

  void _onSliderChanged(double value) {
    if (_viewportSide <= 0) return;
    setState(() {
      _zoom = value;
      _offset = _clampOffset(_offset, _viewportSide, value);
    });
  }

  Future<void> _saveCrop() async {
    final image = _image;
    final side = _viewportSide;
    if (image == null || side <= 0 || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final scale = _baseScale(side) * _zoom;
      final cropSize = side / scale;

      final displayedWidth = image.width * scale;
      final displayedHeight = image.height * scale;
      final leftOnViewport = (side - displayedWidth) / 2 + _offset.dx;
      final topOnViewport = (side - displayedHeight) / 2 + _offset.dy;

      var sourceLeft = -leftOnViewport / scale;
      var sourceTop = -topOnViewport / scale;

      sourceLeft = sourceLeft.clamp(0.0, image.width - cropSize).toDouble();
      sourceTop = sourceTop.clamp(0.0, image.height - cropSize).toDouble();

      final source = Rect.fromLTWH(sourceLeft, sourceTop, cropSize, cropSize);
      const outputSize = 420.0;
      final destination = const Rect.fromLTWH(0, 0, outputSize, outputSize);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(image, source, destination, Paint());
      final picture = recorder.endRecording();
      final resultImage = await picture.toImage(outputSize.toInt(), outputSize.toInt());
      final byteData = await resultImage.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData?.buffer.asUint8List();

      if (!mounted || bytes == null) return;
      Navigator.of(context).pop<Uint8List>(bytes);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '写真を調整',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading || _isSaving ? null : _saveCrop,
            child: const Text(
              '決定',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _purple))
                : _image == null
                    ? const Center(child: Text('画像を読み込めませんでした'))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final side = (constraints.maxWidth - 36).clamp(220.0, 360.0).toDouble();
                          _viewportSide = side;
                          final image = _image!;

                          return ListView(
                            padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                            children: [
                              const Text(
                                '正方形の中に残したい部分を合わせてね',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF5F5965),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onScaleStart: _onScaleStart,
                                  onScaleUpdate: _onScaleUpdate,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Container(
                                      width: side,
                                      height: side,
                                      color: const Color(0xFF241E2B),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          CustomPaint(
                                            painter: _CropImagePainter(
                                              image: image,
                                              zoom: _zoom,
                                              offset: _offset,
                                            ),
                                          ),
                                          IgnorePointer(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(24),
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 3,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              Row(
                                children: [
                                  const Icon(Icons.zoom_out_rounded, color: _purple),
                                  Expanded(
                                    child: Slider(
                                      value: _zoom,
                                      min: 1,
                                      max: 4,
                                      divisions: 30,
                                      activeColor: _purple,
                                      onChanged: _onSliderChanged,
                                    ),
                                  ),
                                  const Icon(Icons.zoom_in_rounded, color: _purple),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'ドラッグで位置調整・ピンチまたはスライダーで拡大できます。',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                              const SizedBox(height: 22),
                              FilledButton.icon(
                                onPressed: _isSaving ? null : _saveCrop,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _purple,
                                  minimumSize: const Size(double.infinity, 54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.check_rounded),
                                label: const Text(
                                  'この範囲で決定',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ),
      ),
    );
  }
}


class _CropImagePainter extends CustomPainter {
  const _CropImagePainter({
    required this.image,
    required this.zoom,
    required this.offset,
  });

  final ui.Image image;
  final double zoom;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    final horizontal = size.width / image.width;
    final vertical = size.height / image.height;
    final baseScale = horizontal > vertical ? horizontal : vertical;
    final scale = baseScale * zoom;
    final width = image.width * scale;
    final height = image.height * scale;
    final left = (size.width - width) / 2 + offset.dx;
    final top = (size.height - height) / 2 + offset.dy;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(left, top, width, height),
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant _CropImagePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.zoom != zoom ||
        oldDelegate.offset != offset;
  }
}
