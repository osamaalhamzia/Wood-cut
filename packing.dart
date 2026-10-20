// خوارزمية ترتيب القص ثنائية الأبعاد (Guillotine / مستطيلات حرة)
// تضع القطع في ألواح خام مع احتساب سماكة شفرة المنشار (kerf)

class PieceInput {
  PieceInput({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.quantity,
  });

  final String id;
  final String name;
  final double width; // سم
  final double height; // سم
  final int quantity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'width': width,
        'height': height,
        'quantity': quantity,
      };

  factory PieceInput.fromJson(Map<String, dynamic> j) => PieceInput(
        id: j['id'] as String,
        name: j['name'] as String,
        width: (j['width'] as num).toDouble(),
        height: (j['height'] as num).toDouble(),
        quantity: (j['quantity'] as num).toInt(),
      );
}

class PlacedPiece {
  PlacedPiece({
    required this.pieceId,
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotated,
    required this.color,
  });

  final String pieceId;
  final String name;
  final double x;
  final double y;
  final double width;
  final double height;
  final bool rotated;
  final int color; // 0xRRGGBB
}

class BoardPlan {
  BoardPlan({
    required this.index,
    required this.width,
    required this.height,
    required this.placed,
    required this.usedArea,
    required this.wasteArea,
    required this.utilization,
  });

  final int index;
  final double width;
  final double height;
  final List<PlacedPiece> placed;
  final double usedArea;
  final double wasteArea;
  final double utilization;
}

class UnplacedPiece {
  UnplacedPiece({
    required this.name,
    required this.width,
    required this.height,
    required this.count,
  });

  final String name;
  final double width;
  final double height;
  int count;
}

class CutResult {
  CutResult({
    required this.boards,
    required this.boardsNeeded,
    required this.unplaced,
    required this.totalUsedArea,
    required this.totalBoardArea,
    required this.utilization,
  });

  final List<BoardPlan> boards;
  final int boardsNeeded;
  final List<UnplacedPiece> unplaced;
  final double totalUsedArea;
  final double totalBoardArea;
  final double utilization;
}

const List<int> kPalette = [
  0x25E4D1, 0xE4B54A, 0x7EA8F8, 0xE47E5C, 0x8FE07E,
  0xD97ED9, 0x5CC7E4, 0xF0E06B, 0xB09AF5, 0x6FD9A8,
  0xF08FA8, 0xA8D94A,
];

int pieceColor(int index) => kPalette[index % kPalette.length];

class _FreeRect {
  _FreeRect(this.x, this.y, this.w, this.h);
  final double x;
  final double y;
  final double w;
  final double h;
}

class _OpenBoard {
  _OpenBoard(this.width, this.height)
      : free = [_FreeRect(0, 0, width, height)],
        placed = [],
        usedArea = 0;

  final double width;
  final double height;
  final List<_FreeRect> free;
  final List<PlacedPiece> placed;
  double usedArea;
}

class _Item {
  _Item(this.order, this.pieceId, this.name, this.w, this.h, this.color);
  final int order;
  final String pieceId;
  final String name;
  final double w;
  final double h;
  final int color;
}

class _Candidate {
  _Candidate(this.w, this.h, this.rotated);
  final double w;
  final double h;
  final bool rotated;
}

bool _fits(double fw, double fh, double w, double h) {
  return w <= fw + 1e-9 && h <= fh + 1e-9;
}

// تقسيم المستطيل الحر بعد وضع قطعة (تقسيم قصّي: أفقي ثم عمودي)
void _splitFreeRect(List<_FreeRect> free, _FreeRect rect, double w, double h) {
  free.remove(rect);
  final rightW = rect.w - w;
  final bottomH = rect.h - h;
  if (rightW >= bottomH) {
    if (rightW > 1e-9) free.add(_FreeRect(rect.x + w, rect.y, rightW, rect.h));
    if (bottomH > 1e-9) free.add(_FreeRect(rect.x, rect.y + h, w, bottomH));
  } else {
    if (bottomH > 1e-9) free.add(_FreeRect(rect.x, rect.y + h, rect.w, bottomH));
    if (rightW > 1e-9) free.add(_FreeRect(rect.x + w, rect.y, rightW, h));
  }
}

bool _tryPlace(
  _OpenBoard board,
  _Item item,
  double kerf,
  bool allowRotate,
) {
  final pw = item.w;
  final ph = item.h;
  final kpw = pw + kerf;
  final kph = ph + kerf;

  _FreeRect? bestRect;
  _Candidate? bestCand;
  double bestScore = double.infinity;

  for (final fr in board.free) {
    final candidates = <_Candidate>[];
    if (_fits(fr.w, fr.h, kpw, kph)) candidates.add(_Candidate(kpw, kph, false));
    if (allowRotate && _fits(fr.w, fr.h, kph, kpw)) {
      candidates.add(_Candidate(kph, kpw, true));
    }
    for (final c in candidates) {
      final leftoverW = fr.w - c.w;
      final leftoverH = fr.h - c.h;
      final score = leftoverW < leftoverH ? leftoverW : leftoverH;
      if (bestRect == null || score < bestScore) {
        bestRect = fr;
        bestCand = c;
        bestScore = score;
      }
    }
  }

  if (bestRect == null || bestCand == null) return false;

  _splitFreeRect(board.free, bestRect, bestCand.w, bestCand.h);
  board.placed.add(PlacedPiece(
    pieceId: item.pieceId,
    name: item.name,
    x: bestRect.x,
    y: bestRect.y,
    width: bestCand.rotated ? ph : pw,
    height: bestCand.rotated ? pw : ph,
    rotated: bestCand.rotated,
    color: item.color,
  ));
  board.usedArea += pw * ph;
  return true;
}

CutResult computeCutPlan({
  required double boardWidth,
  required double boardHeight,
  required int boardsAvailable, // 0 = غير محدود
  required double kerf,
  required bool allowRotate,
  required List<PieceInput> pieces,
}) {
  // توسيع الكميات وفرز حسب المساحة تنازلياً
  final expanded = <_Item>[];
  var order = 0;
  for (var i = 0; i < pieces.length; i++) {
    final p = pieces[i];
    final color = pieceColor(i);
    for (var q = 0; q < p.quantity; q++) {
      expanded.add(_Item(order++, p.id, p.name, p.width, p.height, color));
    }
  }
  expanded.sort((a, b) {
    final c = (b.w * b.h).compareTo(a.w * a.h);
    return c != 0 ? c : a.order.compareTo(b.order);
  });

  final boards = <_OpenBoard>[];
  final unplaced = <UnplacedPiece>[];
  final limit = boardsAvailable > 0 ? boardsAvailable : (1 << 30);

  void addUnplaced(_Item item) {
    for (final u in unplaced) {
      if (u.name == item.name && u.width == item.w && u.height == item.h) {
        u.count += 1;
        return;
      }
    }
    unplaced.add(UnplacedPiece(
      name: item.name,
      width: item.w,
      height: item.h,
      count: 1,
    ));
  }

  for (final item in expanded) {
    var placedOk = false;
    for (final b in boards) {
      if (_tryPlace(b, item, kerf, allowRotate)) {
        placedOk = true;
        break;
      }
    }
    if (placedOk) continue;

    // هل تتسع القطعة في لوح فارغ أصلاً؟ (تفادي حلقة لا نهائية للقطع الأكبر من اللوح)
    final kw = item.w + kerf;
    final kh = item.h + kerf;
    final fitsEmpty = _fits(boardWidth, boardHeight, kw, kh) ||
        (allowRotate && _fits(boardWidth, boardHeight, kh, kw));

    if (!fitsEmpty || boards.length >= limit) {
      addUnplaced(item);
      continue;
    }

    final nb = _OpenBoard(boardWidth, boardHeight);
    boards.add(nb);
    _tryPlace(nb, item, kerf, allowRotate);
  }

  final plans = <BoardPlan>[];
  for (var i = 0; i < boards.length; i++) {
    final b = boards[i];
    final total = b.width * b.height;
    plans.add(BoardPlan(
      index: i + 1,
      width: b.width,
      height: b.height,
      placed: b.placed,
      usedArea: b.usedArea,
      wasteArea: total - b.usedArea,
      utilization: total > 0 ? (b.usedArea / total) * 100 : 0,
    ));
  }

  final totalBoardArea = plans.fold<double>(0, (s, b) => s + b.width * b.height);
  final totalUsedArea = plans.fold<double>(0, (s, b) => s + b.usedArea);

  return CutResult(
    boards: plans,
    boardsNeeded: plans.length,
    unplaced: unplaced,
    totalUsedArea: totalUsedArea,
    totalBoardArea: totalBoardArea,
    utilization: totalBoardArea > 0 ? (totalUsedArea / totalBoardArea) * 100 : 0,
  );
}
