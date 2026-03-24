import 'package:flutter/material.dart';
import 'package:gama/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/attendance_session.dart';
import '../../models/app_user.dart';
import '../../providers/data_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/pdf_service.dart';
import '../../config/theme.dart';

class TakeAttendanceScreen extends StatefulWidget {
  const TakeAttendanceScreen({super.key});

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  final FirestoreService _firestore = FirestoreService();
  late AttendanceSession session;
  String searchQuery = '';
  bool _showScanner = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit && ModalRoute.of(context)?.settings.arguments != null) {
      session = ModalRoute.of(context)!.settings.arguments as AttendanceSession;
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Overlay search dropdown ──────────────────────────────────────────────

  void _showOverlay(List<AppUser> results) {
    _removeOverlay();
    if (results.isEmpty) return;

    _overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 58),
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(14),
            shadowColor: Colors.black26,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.42,
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: results.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (ctx, index) {
                    final student = results[index];
                    final isPresent = session.presentStudents
                        .any((s) => s['uid'] == student.uid);
                    return _SearchResultTile(
                      student: student,
                      isPresent: isPresent,
                      onTap: isPresent
                          ? null
                          : () {
                              _markPresent(student);
                              _clearSearch();
                            },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => searchQuery = '');
    _removeOverlay();
    _searchFocus.unfocus();
  }

  void _onSearchChanged(String val, DataProvider data) {
    setState(() => searchQuery = val);
    if (val.trim().isEmpty) {
      _removeOverlay();
      return;
    }
    final results = data.students.where((s) {
      final q = val.toLowerCase();
      return s.name.toLowerCase().contains(q) ||
          s.phone.contains(q) ||
          s.studentCode.toLowerCase().contains(q);
    }).toList();
    _showOverlay(results);
  }

  // ── Attendance logic ─────────────────────────────────────────────────────

  double _parsePrice(String val) {
    if (val.isEmpty) return 0.0;
    String clean = val.replaceAll(RegExp(r'[^\d\.\،]'), '');
    clean = clean.replaceAll('،', '.');
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    for (int i = 0; i < 10; i++) {
      clean = clean.replaceAll(arabic[i], english[i]);
      clean = clean.replaceAll(persian[i], english[i]);
    }
    return double.tryParse(clean) ?? 0.0;
  }

  void _markPresent(AppUser student) {
    final l10n = AppLocalizations.of(context)!;
    if (session.isEnded) return;
    final alreadyPresent =
        session.presentStudents.any((s) => s['uid'] == student.uid);
    if (!alreadyPresent) {
      setState(() {
        session.presentStudents.add({
          'uid': student.uid,
          'name': student.name,
          'phone': student.phone,
          'grade': student.grade,
          'time': Timestamp.now(),
          'paidAmount': 0.0,
        });
      });
      _firestore.updateAttendanceSession(session);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('${student.name} - ${l10n.present} ✓'),
            ],
          ),
          backgroundColor: AppTheme.successGreen,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _removeStudent(String uid) {
    if (session.isEnded) return;
    setState(() => session.presentStudents.removeWhere((s) => s['uid'] == uid));
    _firestore.updateAttendanceSession(session);
  }

  void _openScanner() {
    if (session.isEnded) return;
    _removeOverlay();
    _searchFocus.unfocus();
    setState(() => _showScanner = true);
  }

  void _handleScannedCode(String code) {
    final l10n = AppLocalizations.of(context)!;
    final data = context.read<DataProvider>();
    final student = data.students.firstWhere(
      (s) => s.uid == code || s.phone == code || s.studentCode == code,
      orElse: () =>
          AppUser(uid: '', name: '', phone: '', email: '', role: 'student'),
    );
    if (student.uid.isNotEmpty) {
      _markPresent(student);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.studentNotFound)));
    }
  }

  Future<void> _endSessionFlow() async {
    final l10n = AppLocalizations.of(context)!;
    _removeOverlay();
    final priceController = TextEditingController();

    final defaultPriceStr = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.endSession),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
              labelText: l10n.sessionPrice, border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, priceController.text.trim()),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (defaultPriceStr == null || defaultPriceStr.isEmpty) return;
    final defaultPrice = _parsePrice(defaultPriceStr);

    List<Map<String, dynamic>> updatedStudents =
        List.from(session.presentStudents);
    for (var i = 0; i < updatedStudents.length; i++) {
      updatedStudents[i] = Map<String, dynamic>.from(updatedStudents[i]);
      updatedStudents[i]['paidAmount'] = defaultPrice;
    }

    if (!mounted) return;

    final confirmEnd = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          title: Text(l10n.studentPayment),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: updatedStudents.length,
              itemBuilder: (context, index) {
                final s = updatedStudents[index];
                return ListTile(
                  title: Text(s['name'] ?? ''),
                  subtitle: Text(
                    '${s['phone'] ?? ''} • ${s['grade'] ?? ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: SizedBox(
                    width: 100,
                    child: TextFormField(
                      initialValue: s['paidAmount'].toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(isDense: true),
                      onChanged: (val) => s['paidAmount'] = _parsePrice(val),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel)),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.generatePdf)),
          ],
        ),
      ),
    );

    if (confirmEnd != true) return;

    double totalCollected = 0.0;
    for (var s in updatedStudents) {
      totalCollected += (s['paidAmount'] as num).toDouble();
    }

    setState(() {
      session = session.copyWith(
        isEnded: true,
        defaultPrice: defaultPrice,
        presentStudents: updatedStudents,
      );
    });

    await _firestore.updateAttendanceSession(session);
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.sessionEndedSuccess)));
    await PdfService.generateAndShareSessionPdf(session, totalCollected);
    if (mounted) Navigator.pop(context);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = context.watch<DataProvider>();

    return GestureDetector(
      onTap: () {
        _removeOverlay();
        _searchFocus.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title:
              Text(session.title.isEmpty ? l10n.takeAttendance : session.title),
          actions: [
            Center(
              child: Container(
                margin: const EdgeInsetsDirectional.only(end: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${session.presentStudents.length}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: session.isEnded ? null : _openScanner,
            ),
          ],
        ),
        body: Stack(
          children: [
            // ── المحتوى الأساسي ───────────────────────────────────────────
            Column(
              children: [
                if (!session.isEnded)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: CompositedTransformTarget(
                      link: _layerLink,
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        decoration: InputDecoration(
                          hintText: l10n.searchStudent,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: _clearSearch,
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppTheme.primaryBlue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        onChanged: (val) => _onSearchChanged(val, data),
                        onTap: () {
                          if (searchQuery.isNotEmpty) {
                            _onSearchChanged(searchQuery, data);
                          }
                        },
                      ),
                    ),
                  ),

                // ── Present Students Header ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withAlpha(15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people,
                                color: AppTheme.primaryBlue, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              l10n.presentStudents,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${session.presentStudents.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── قايمة الحاضرين ────────────────────────────────────────
                Expanded(
                  child: session.presentStudents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_search,
                                  size: 72, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                'ابحث عن طالب وأضفه',
                                style: TextStyle(
                                    color: Colors.grey.shade400, fontSize: 15),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                          itemCount: session.presentStudents.length,
                          itemBuilder: (context, index) {
                            final s = session.presentStudents[index];
                            return _PresentStudentTile(
                              index: index,
                              studentMap: s,
                              isEnded: session.isEnded,
                              onRemove: () => _removeStudent(s['uid']),
                            );
                          },
                        ),
                ),
              ],
            ),

            // ── QR Scanner Overlay ────────────────────────────────────────
            if (_showScanner)
              GestureDetector(
                onTap: () => setState(() => _showScanner = false),
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.88,
                        height: MediaQuery.of(context).size.height * 0.52,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(100),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              // الكاميرا
                              MobileScanner(
                                onDetect: (capture) {
                                  for (final barcode in capture.barcodes) {
                                    if (barcode.rawValue != null) {
                                      setState(() => _showScanner = false);
                                      _handleScannedCode(barcode.rawValue!);
                                      break;
                                    }
                                  }
                                },
                              ),

                              // إطار التوجيه
                              Center(
                                child: Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppTheme.accentCyan,
                                      width: 2.5,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),

                              // خطوط الزوايا
                              Center(
                                child: SizedBox(
                                  width: 180,
                                  height: 180,
                                  child: CustomPaint(
                                    painter: _CornerPainter(),
                                  ),
                                ),
                              ),

                              // زر الإغلاق
                              Positioned(
                                top: 12,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _showScanner = false),
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),

                              // نص في الأسفل
                              Positioned(
                                bottom: 18,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      l10n.scanQrCode,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
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
                ),
              ),
          ],
        ),
        floatingActionButton: session.isEnded
            ? null
            : FloatingActionButton.extended(
                onPressed: _endSessionFlow,
                backgroundColor: AppTheme.accentCyan,
                icon: const Icon(Icons.done_all),
                label: Text(l10n.endSession),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}

// ── Corner Painter ────────────────────────────────────────────────────────

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accentCyan
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const len = 28.0;
    const r = 14.0;

    // Top-left
    canvas.drawLine(const Offset(r, 0), const Offset(r + len, 0), paint);
    canvas.drawLine(const Offset(0, r), const Offset(0, r + len), paint);
    canvas.drawArc(const Rect.fromLTWH(0, 0, r * 2, r * 2), 3.14159,
        3.14159 / 2, false, paint);

    // Top-right
    canvas.drawLine(
        Offset(size.width - r - len, 0), Offset(size.width - r, 0), paint);
    canvas.drawLine(Offset(size.width, r), Offset(size.width, r + len), paint);
    canvas.drawArc(Rect.fromLTWH(size.width - r * 2, 0, r * 2, r * 2),
        3.14159 * 1.5, 3.14159 / 2, false, paint);

    // Bottom-left
    canvas.drawLine(
        Offset(0, size.height - r - len), Offset(0, size.height - r), paint);
    canvas.drawLine(
        Offset(r, size.height), Offset(r + len, size.height), paint);
    canvas.drawArc(Rect.fromLTWH(0, size.height - r * 2, r * 2, r * 2),
        3.14159 / 2, 3.14159 / 2, false, paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width - r - len, size.height),
        Offset(size.width - r, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - r - len),
        Offset(size.width, size.height - r), paint);
    canvas.drawArc(
        Rect.fromLTWH(size.width - r * 2, size.height - r * 2, r * 2, r * 2),
        0,
        3.14159 / 2,
        false,
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Search Result Tile ────────────────────────────────────────────────────

class _SearchResultTile extends StatelessWidget {
  final AppUser student;
  final bool isPresent;
  final VoidCallback? onTap;

  const _SearchResultTile({
    required this.student,
    required this.isPresent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isPresent
                  ? AppTheme.successGreen.withAlpha(30)
                  : AppTheme.primaryBlue.withAlpha(20),
              child: Text(
                student.name.isNotEmpty ? student.name[0] : '?',
                style: TextStyle(
                  color:
                      isPresent ? AppTheme.successGreen : AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        student.phone,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMuted),
                        textDirection: TextDirection.ltr,
                      ),
                      if (student.grade.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withAlpha(15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            student.grade,
                            style: const TextStyle(
                                fontSize: 10, color: AppTheme.primaryBlue),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isPresent)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        color: AppTheme.successGreen, size: 14),
                    SizedBox(width: 4),
                    Text(
                      l10n.present,
                      style: const TextStyle(
                        color: AppTheme.successGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.add,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Present Student Tile ──────────────────────────────────────────────────

class _PresentStudentTile extends StatelessWidget {
  final int index;
  final Map<String, dynamic> studentMap;
  final bool isEnded;
  final VoidCallback onRemove;

  const _PresentStudentTile({
    required this.index,
    required this.studentMap,
    required this.isEnded,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: AppTheme.successGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentMap['name'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        studentMap['phone'] ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMuted),
                        textDirection: TextDirection.ltr,
                      ),
                      if ((studentMap['grade'] ?? '').isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withAlpha(15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            studentMap['grade'] ?? '',
                            style: const TextStyle(
                                fontSize: 10, color: AppTheme.primaryBlue),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isEnded)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${studentMap['paidAmount'] ?? 0} ج.م',
                  style: const TextStyle(
                    color: AppTheme.successGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              )
            else
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.remove_circle_outline,
                    color: AppTheme.errorRed, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
          ],
        ),
      ),
    );
  }
}
