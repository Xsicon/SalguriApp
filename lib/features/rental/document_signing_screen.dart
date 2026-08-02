import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:signature/signature.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/app_colors.dart';
import '../../core/models/document_template.dart';
import '../../services/api_service.dart';
import '../../services/supabase_service.dart';
import 'zoom_bar.dart';

/// Tenant-side signing screen — mirrors business-app's
/// `document_signing_screen.dart` (same backend, same interaction pattern:
/// render the base PDF, tap your field, draw a signature, submit).
class DocumentSigningScreen extends StatefulWidget {
  final String documentType; // 'lease' | 'inspection'
  final String documentId;
  final String? templateId;
  final String? fallbackDocumentUrl;

  const DocumentSigningScreen({
    super.key,
    required this.documentType,
    required this.documentId,
    this.templateId,
    this.fallbackDocumentUrl,
  });

  @override
  State<DocumentSigningScreen> createState() => _DocumentSigningScreenState();
}

class _DocumentSigningScreenState extends State<DocumentSigningScreen> {
  bool _loading = true;
  String? _error;
  List<DocumentField> _fields = const [];
  pdfx.PdfDocument? _pdfDoc;
  Uint8List? _pageImage;
  double _pageAspectRatio = 612 / 792;
  int _currentPage = 1;
  bool _consentGiven = false;
  final Set<String> _signedFieldIds = {};
  bool _submitting = false;
  bool _sealed = false;

  static const double _minZoom = 1.0;
  static const double _maxZoom = 4.0;
  double _zoomScale = 1.0;
  final Map<int, Offset> _activePointers = {};
  double? _pinchStartDistance;
  double? _pinchStartZoom;

  // Raw pointer tracking (not a GestureDetector) so pinch detection never
  // competes in the gesture arena with tapping a field to sign it.
  void _onPointerDown(PointerDownEvent e) {
    _activePointers[e.pointer] = e.position;
    if (_activePointers.length == 2) {
      final pts = _activePointers.values.toList();
      _pinchStartDistance = (pts[0] - pts[1]).distance;
      _pinchStartZoom = _zoomScale;
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_activePointers.containsKey(e.pointer)) return;
    _activePointers[e.pointer] = e.position;
    final startDistance = _pinchStartDistance;
    final startZoom = _pinchStartZoom;
    if (_activePointers.length == 2 && startDistance != null && startDistance > 10 && startZoom != null) {
      final pts = _activePointers.values.toList();
      final newDistance = (pts[0] - pts[1]).distance;
      setState(() => _zoomScale = (startZoom * newDistance / startDistance).clamp(_minZoom, _maxZoom));
    }
  }

  void _onPointerUpOrCancel(PointerEvent e) {
    _activePointers.remove(e.pointer);
    if (_activePointers.length < 2) {
      _pinchStartDistance = null;
      _pinchStartZoom = null;
    }
  }

  void _setZoom(double z) => setState(() => _zoomScale = z.clamp(_minZoom, _maxZoom));

  String get _signerName {
    final meta = SupabaseService.currentUser?.userMetadata?['full_name'] as String?;
    if (meta != null && meta.trim().isNotEmpty) return meta.trim();
    return SupabaseService.currentUser?.email ?? 'Tenant';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pdfDoc?.close();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      String? baseUrl = widget.fallbackDocumentUrl;
      List<DocumentField> fields = const [];

      // Resolved by document ownership/tenancy, not template ownership —
      // ApiService.getDocumentTemplates only ever returns templates owned by
      // the caller, which is never true for a tenant (templates are owned by
      // the business), so it can never find a tenant's own lease's template.
      final template = await ApiService.getTemplateForDocument(
        documentType: widget.documentType,
        documentId: widget.documentId,
      );
      if (template != null) {
        baseUrl = template.basePdfUrl;
        fields = template.fields;
      }

      if (baseUrl == null || baseUrl.isEmpty) {
        throw StateError('No document is attached to this lease yet.');
      }

      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode >= 400) {
        throw StateError('Could not download the document (${response.statusCode}).');
      }
      final doc = await pdfx.PdfDocument.openData(response.bodyBytes);

      if (!mounted) return;
      setState(() {
        _fields = fields;
        _pdfDoc = doc;
      });
      await _renderPage(1);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _renderPage(int pageNumber) async {
    final doc = _pdfDoc;
    if (doc == null) return;
    final page = await doc.getPage(pageNumber);
    final aspectRatio = page.width / page.height;
    final image = await page.render(
      width: page.width * 2,
      height: page.height * 2,
      format: pdfx.PdfPageImageFormat.png,
    );
    await page.close();
    if (!mounted) return;
    setState(() {
      _currentPage = pageNumber;
      _pageImage = image?.bytes;
      _pageAspectRatio = aspectRatio;
      _loading = false;
    });
  }

  /// The PDF page is drawn with BoxFit.contain, which letterboxes it inside
  /// [box] rather than filling it — so field percentages must be measured
  /// against this rect, not the raw layout box, or they drift relative to
  /// where the Business App's Template Designer placed them.
  Rect _imageRect(Size box) {
    double width = box.width;
    double height = width / _pageAspectRatio;
    if (height > box.height) {
      height = box.height;
      width = height * _pageAspectRatio;
    }
    final dx = (box.width - width) / 2;
    final dy = (box.height - height) / 2;
    return Rect.fromLTWH(dx, dy, width, height);
  }

  Future<void> _signField(DocumentField field) async {
    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm consent to sign electronically first.')),
      );
      return;
    }
    final pngBytes = await _showSignaturePad();
    if (pngBytes == null || !mounted) return;

    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ApiService.submitDocumentSignature(
        documentType: widget.documentType,
        documentId: widget.documentId,
        signerRole: 'tenant',
        signerName: _signerName,
        signaturePngBase64: base64Encode(pngBytes),
        fieldId: field.id,
      );
      if (!mounted) return;
      setState(() {
        _signedFieldIds.add(field.id);
        if (result.allSignaturesComplete) _sealed = true;
      });
      messenger.showSnackBar(SnackBar(
        content: Text(_sealed ? 'Signed — document fully executed and sealed.' : 'Signed.'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not submit signature: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // A regular dialog, not a bottom sheet: showModalBottomSheet's internal
  // "size listener" layout code (Flutter's own bottom_sheet.dart) hits a
  // framework-level layout assertion on this SDK build when opened from a
  // pushed route (this screen), regardless of the sheet's own content or
  // parameters. showDialog uses a completely different, simpler internal
  // path with no such machinery, so it sidesteps the bug entirely.
  Future<Uint8List?> _showSignaturePad() {
    final controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    return showDialog<Uint8List>(
      context: context,
      builder: (dialogCtx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Draw your signature',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Signature(controller: controller, backgroundColor: Colors.white),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(onPressed: controller.clear, child: const Text('Clear')),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () async {
                        if (controller.isEmpty) return;
                        final bytes = await controller.toPngBytes();
                        if (dialogCtx.mounted) Navigator.of(dialogCtx).pop(bytes);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Use This Signature'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Document')),
      body: Stack(
        children: [
          SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                  )
                : Column(
                    children: [
                      if (_sealed)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          color: AppColors.success.withValues(alpha: 0.12),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_outlined, color: AppColors.success, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Every required signature is in — this document has been sealed.',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.success),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        CheckboxListTile(
                          value: _consentGiven,
                          onChanged: (v) => setState(() => _consentGiven = v ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                          title: const Text(
                            'I consent to use electronic records and e-signatures for this document.',
                            style: TextStyle(fontSize: 12.5),
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _pageImage == null
                              ? const Center(child: CircularProgressIndicator())
                              : Stack(
                                  children: [
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final baseSize = Size(constraints.maxWidth, constraints.maxHeight);
                                        final imgRect = _imageRect(baseSize);
                                        final content = SizedBox(
                                          width: baseSize.width,
                                          height: baseSize.height,
                                          child: Stack(
                                            children: [
                                              Positioned.fill(
                                                child: Image.memory(_pageImage!, fit: BoxFit.contain),
                                              ),
                                              // Only signature fields are interactive here — a role's
                                              // date/text fields (e.g. "Date Signed", "Printed Name")
                                              // are auto-filled from that same role's signature when
                                              // the document is sealed, not tapped individually.
                                              for (final f in _fields.where((f) =>
                                                  f.pageNumber == _currentPage && f.fieldType == 'signature'))
                                                Positioned(
                                                  left: imgRect.left + imgRect.width * f.xPercent,
                                                  top: imgRect.top + imgRect.height * f.yPercent,
                                                  width: imgRect.width * f.widthPercent,
                                                  height: imgRect.height * f.heightPercent,
                                                  child: _FieldOverlay(
                                                    field: f,
                                                    isSigned: _signedFieldIds.contains(f.id),
                                                    onTap: f.assignedRole == 'tenant' &&
                                                            f.fieldType == 'signature' &&
                                                            !_signedFieldIds.contains(f.id) &&
                                                            !_submitting
                                                        ? () => _signField(f)
                                                        : null,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                        return Listener(
                                          onPointerDown: _onPointerDown,
                                          onPointerMove: _onPointerMove,
                                          onPointerUp: _onPointerUpOrCancel,
                                          onPointerCancel: _onPointerUpOrCancel,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: SingleChildScrollView(
                                              child: SizedBox(
                                                width: baseSize.width * _zoomScale,
                                                height: baseSize.height * _zoomScale,
                                                child: Transform.scale(
                                                  scale: _zoomScale,
                                                  alignment: Alignment.topLeft,
                                                  child: content,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    Positioned(
                                      right: 8,
                                      bottom: 8,
                                      child: ZoomBar(
                                        zoom: _zoomScale,
                                        minZoom: _minZoom,
                                        maxZoom: _maxZoom,
                                        onZoomIn: () => _setZoom(_zoomScale + 0.25),
                                        onZoomOut: () => _setZoom(_zoomScale - 0.25),
                                        onReset: () => _setZoom(1.0),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
          ),
          if (_submitting)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              alignment: Alignment.center,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Submitting signature...', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      backgroundColor: cs.surface,
    );
  }
}

class _FieldOverlay extends StatelessWidget {
  final DocumentField field;
  final bool isSigned;
  final VoidCallback? onTap;

  const _FieldOverlay({required this.field, required this.isSigned, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isMine = field.assignedRole == 'tenant' && field.fieldType == 'signature';
    final color = isSigned ? AppColors.success : (isMine ? AppColors.warning : AppColors.textMuted);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          isSigned ? 'SIGNED' : (isMine ? 'TAP TO SIGN' : 'AWAITING OTHER SIGNER'),
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
