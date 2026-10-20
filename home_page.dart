import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'board_viz.dart';
import 'packing.dart';
import 'theme.dart';
import 'utils.dart';
import 'widgets.dart';

const String _storageKey = 'qass-alwah-flutter-v1';

class _Preset {
  const _Preset(this.w, this.h);
  final double w;
  final double h;
}

const List<_Preset> _presets = [
  _Preset(244, 122),
  _Preset(280, 207),
  _Preset(305, 122),
  _Preset(183, 122),
];

class _BoardCfg {
  _BoardCfg({
    this.width = 244,
    this.height = 122,
    this.available = 0,
    this.kerf = 0.4,
    this.price = 0,
    this.allowRotate = true,
  });

  double width;
  double height;
  int available; // 0 = غير محدود
  double kerf;
  double price;
  bool allowRotate;

  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
        'available': available,
        'kerf': kerf,
        'price': price,
        'allowRotate': allowRotate,
      };

  factory _BoardCfg.fromJson(Map<String, dynamic> j) => _BoardCfg(
        width: (j['width'] as num).toDouble(),
        height: (j['height'] as num).toDouble(),
        available: (j['available'] as num).toInt(),
        kerf: (j['kerf'] as num).toDouble(),
        price: (j['price'] as num).toDouble(),
        allowRotate: j['allowRotate'] as bool,
      );
}

class _NewPiece {
  double width = 0;
  double height = 0;
  int quantity = 1;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.prefs});

  final SharedPreferences? prefs;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  _BoardCfg _board = _BoardCfg();
  List<PieceInput> _pieces = [];
  CutResult? _result;

  _NewPiece _np = _NewPiece();
  String _formError = '';
  final TextEditingController _nameCtl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final GlobalKey _resultsKey = GlobalKey();
  int _idCounter = 0;

  @override
  void initState() {
    super.initState();
    if (!_load()) _defaults();
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

  void _defaults() {
    _board = _BoardCfg();
    _pieces = [
      PieceInput(id: _newId(), name: 'ظهر دولاب', width: 200, height: 60, quantity: 1),
      PieceInput(id: _newId(), name: 'رف', width: 80, height: 40, quantity: 4),
      PieceInput(id: _newId(), name: 'باب', width: 50, height: 70, quantity: 2),
    ];
  }

  bool _load() {
    final raw = widget.prefs?.getString(_storageKey);
    if (raw == null) return false;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final b = _BoardCfg.fromJson(m['board'] as Map<String, dynamic>);
      final ps = (m['pieces'] as List)
          .map((e) => PieceInput.fromJson(e as Map<String, dynamic>))
          .toList();
      _board = b;
      _pieces = ps;
      return true;
    } catch (_) {
      return false;
    }
  }

  void _save() {
    widget.prefs?.setString(
      _storageKey,
      jsonEncode({
        'board': _board.toJson(),
        'pieces': _pieces.map((p) => p.toJson()).toList(),
      }),
    );
  }

  void _updateBoard(void Function() fn) {
    setState(fn);
    _save();
  }

  void _addPiece() {
    if (_np.width <= 0 || _np.height <= 0) {
      setState(() => _formError = 'أدخل مقاساً صحيحاً للقطعة (العرض والطول أكبر من صفر)');
      return;
    }
    if (_np.quantity <= 0) {
      setState(() => _formError = 'الكمية يجب أن تكون 1 على الأقل');
      return;
    }
    final name = _nameCtl.text.trim();
    setState(() {
      _formError = '';
      _pieces = [
        ..._pieces,
        PieceInput(
          id: _newId(),
          name: name.isEmpty ? 'قطعة ${_pieces.length + 1}' : name,
          width: _np.width,
          height: _np.height,
          quantity: _np.quantity,
        ),
      ];
      _np = _NewPiece();
      _nameCtl.clear();
    });
    _save();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _removePiece(String id) {
    setState(() => _pieces = _pieces.where((p) => p.id != id).toList());
    _save();
  }

  String get _calcError {
    if (_board.width <= 0 || _board.height <= 0) return 'أدخل مقاس اللوح الخام أولاً';
    if (_pieces.isEmpty) return 'أضف قطعة واحدة على الأقل';
    return '';
  }

  void _runCalc() {
    if (_calcError.isNotEmpty) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final r = computeCutPlan(
      boardWidth: _board.width,
      boardHeight: _board.height,
      boardsAvailable: _board.available,
      kerf: _board.kerf,
      allowRotate: _board.allowRotate,
      pieces: _pieces,
    );
    setState(() => _result = r);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultsKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /* ---------- أقسام الواجهة ---------- */

  Widget _header() {
    return Container(
      padding: const EdgeInsets.only(top: 28, bottom: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: const Row(
        children: [
          LogoIcon(size: 36),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'قصّ الألواح',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  'أدخل مقاس اللوح الخام والقطع المطلوبة، واحصل على خطة القص وعدد الألواح',
                  style: TextStyle(color: AppColors.textDim, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _boardSection(bool wide) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(number: '1', title: 'اللوح الخام'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _presets)
                _presetButton(p),
            ],
          ),
          const SizedBox(height: 16),
          GridWrap(
            columns: wide ? 3 : 2,
            children: [
              NumField(
                label: 'عرض اللوح',
                value: _board.width,
                suffix: 'سم',
                onChanged: (v) => _updateBoard(() => _board.width = v),
              ),
              NumField(
                label: 'طول اللوح',
                value: _board.height,
                suffix: 'سم',
                onChanged: (v) => _updateBoard(() => _board.height = v),
              ),
              NumField(
                label: 'سماكة المنشار',
                value: _board.kerf,
                suffix: 'سم',
                onChanged: (v) =>
                    _updateBoard(() => _board.kerf = v < 0 ? 0 : v),
              ),
              NumField(
                label: 'الألواح المتوفرة',
                value: _board.available.toDouble(),
                hint: '0',
                suffix: '0 = بلا حد',
                decimal: false,
                onChanged: (v) =>
                    _updateBoard(() => _board.available = v.round()),
              ),
              NumField(
                label: 'سعر اللوح (اختياري)',
                value: _board.price,
                onChanged: (v) => _updateBoard(() => _board.price = v),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 22),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () =>
                      _updateBoard(() => _board.allowRotate = !_board.allowRotate),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: Checkbox(
                          value: _board.allowRotate,
                          activeColor: AppColors.accent,
                          checkColor: AppColors.accentInk,
                          onChanged: (v) => _updateBoard(
                              () => _board.allowRotate = v ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'السماح بتدوير القطع ${ltr('90°')}',
                          style: const TextStyle(
                              color: AppColors.textDim, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetButton(_Preset p) {
    final active = _board.width == p.w && _board.height == p.h;
    return OutlinedButton(
      onPressed: () => _updateBoard(() {
        _board.width = p.w;
        _board.height = p.h;
      }),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        foregroundColor: active ? AppColors.accent : AppColors.textDim,
        side: BorderSide(color: active ? AppColors.accent : AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(ltr('${fmtNum(p.w)} × ${fmtNum(p.h)}')),
    );
  }

  Widget _piecesSection() {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(number: '2', title: 'القطع المطلوبة'),
          const SizedBox(height: 16),
          const FieldLabel('اسم القطعة'),
          TextField(
            controller: _nameCtl,
            style: const TextStyle(fontSize: 16),
            decoration: fieldDecoration(hint: 'مثال: رف، باب، جانب…'),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: NumField(
                  label: 'العرض (سم)',
                  value: _np.width,
                  onChanged: (v) => setState(() => _np.width = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: NumField(
                  label: 'الطول (سم)',
                  value: _np.height,
                  onChanged: (v) => setState(() => _np.height = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: NumField(
                  label: 'الكمية',
                  value: _np.quantity.toDouble(),
                  decimal: false,
                  onChanged: (v) => setState(() => _np.quantity = v.round()),
                ),
              ),
            ],
          ),
          if (_formError.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _formError,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _addPiece,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 46),
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                '+ إضافة القطعة',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
          if (_pieces.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < _pieces.length; i++) _pieceRow(_pieces[i], i),
          ],
        ],
      ),
    );
  }

  Widget _pieceRow(PieceInput p, int i) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Color(0xFF000000 | pieceColor(i)),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${ltr('${fmtNum(p.width)}×${fmtNum(p.height)}')} سم',
            style: const TextStyle(color: AppColors.textDim, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.inset,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              ltr('×${p.quantity}'),
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _removePiece(p.id),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 40),
              foregroundColor: AppColors.textDim,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Widget _resultsSection(CutResult r, bool wide) {
    final totalCost =
        _board.price > 0 ? r.boardsNeeded * _board.price : null;

    final cards = <_StatData>[
      _StatData('عدد الألواح', '${r.boardsNeeded}', accent: true),
      _StatData('نسبة الاستغلال', '${r.utilization.toStringAsFixed(1)}%'),
      _StatData('الهالك', fmtArea(r.totalBoardArea - r.totalUsedArea)),
      totalCost != null
          ? _StatData('التكلفة التقديرية', totalCost.toStringAsFixed(2))
          : _StatData('مساحة مستغلة', fmtArea(r.totalUsedArea)),
    ];

    return Column(
      key: _resultsKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(number: '3', title: 'النتائج'),
        const SizedBox(height: 16),
        if (r.unplaced.isNotEmpty) ...[
          Panel(
            borderColor: AppColors.danger,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الألواح المتوفرة لا تكفي — قطع لم يتم قصّها:',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                for (final u in r.unplaced)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${u.name}: ${ltr('${fmtNum(u.width)}×${fmtNum(u.height)}')} سم × ${u.count}',
                      style: const TextStyle(
                          color: AppColors.textDim, fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        GridWrap(
          columns: wide ? 4 : 2,
          children: [for (final c in cards) _statCard(c)],
        ),
        const SizedBox(height: 20),
        for (final plan in r.boards) ...[
          _boardCard(plan),
          const SizedBox(height: 20),
        ],
        _summaryTable(),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'الخطة تقريبية تعتمد ترتيب قصّ مستقيم (guillotine) — راجعها قبل القص الفعلي.\n'
            'بياناتك محفوظة في هذا الجهاز فقط.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _statCard(_StatData s) {
    return Panel(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            s.value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: s.accent ? AppColors.accent : AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            s.label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _boardCard(BoardPlan plan) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'اللوح ${plan.index} ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text:
                          '${ltr('${fmtNum(plan.width)}×${fmtNum(plan.height)}')} سم',
                      style: const TextStyle(
                          color: AppColors.textDim, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(
                'استغلال ${plan.utilization.toStringAsFixed(1)}%',
                style: const TextStyle(color: AppColors.accent, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BoardViz(plan: plan),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Container(
              height: 10,
              color: AppColors.inset,
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: (plan.utilization / 100).clamp(0.0, 1.0),
                child: Container(color: AppColors.accent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              for (final p in plan.placed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Color(0xFF000000 | p.color),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${p.name} ${ltr('${fmtNum(p.width)}×${fmtNum(p.height)}')}'
                      '${p.rotated ? ' ⟳' : ''}',
                      style: const TextStyle(
                          color: AppColors.textDim, fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryTable() {
    const head = TextStyle(color: AppColors.textDim, fontWeight: FontWeight.w500);
    Widget cell(String t, {TextStyle? style}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(t, style: style),
        );

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ملخص القطع',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.2),
              1: FlexColumnWidth(1.8),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1.8),
            },
            children: [
              TableRow(children: [
                cell('القطعة', style: head),
                cell('المقاس', style: head),
                cell('الكمية', style: head),
                cell('المساحة', style: head),
              ]),
              for (final p in _pieces)
                TableRow(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.line)),
                  ),
                  children: [
                    cell(p.name,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    cell(ltr('${fmtNum(p.width)}×${fmtNum(p.height)}')),
                    cell('${p.quantity}'),
                    cell(fmtArea(p.width * p.height * p.quantity)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    final err = _calcError;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (err.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    err,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.warn,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: err.isEmpty ? _runCalc : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.accentInk,
                    disabledBackgroundColor: const Color(0x8025E4D1),
                    disabledForegroundColor: AppColors.accentInk,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('احسب خطة القص'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final wide = MediaQuery.of(context).size.width >= 560;
    final r = _result;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scroll,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 768),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(),
                        const SizedBox(height: 24),
                        _boardSection(wide),
                        const SizedBox(height: 20),
                        _piecesSection(),
                        if (r != null) ...[
                          const SizedBox(height: 24),
                          _resultsSection(r, wide),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!keyboardOpen) _bottomBar(),
          ],
        ),
      ),
    );
  }
}

class _StatData {
  _StatData(this.label, this.value, {this.accent = false});
  final String label;
  final String value;
  final bool accent;
}
