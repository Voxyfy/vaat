import 'assets.dart';
import 'career.dart';
import 'market.dart';
import 'state.dart';
import 'stocks.dart';

/// Oyun durumunun JSON'a çevrilmesi.
///
/// Neden ayrı dosya: model sınıfları kaydetme biçiminden habersiz kalsın.
/// Kayıt formatı değişirse yalnız burası değişir, oyun mantığı değişmez.
///
/// Kural: kaydedilen her alan geri okunmalı. Eksik alan sessizce varsayılana
/// düşerse oyuncu kaydını bozulmuş sanmaz, sadece tuhaf davranır; bu yüzden
/// round-trip testi var.

// --- Şema durumu ---

Map<String, dynamic> schemeToJson(SchemeState s) => {
      'typeId': s.typeId,
      'week': s.week,
      'market': _marketToJson(s.market),
      'board': _boardToJson(s.board),
      'cash': s.cash,
      'segments': {
        for (final e in s.segments.entries)
          e.key: {
            'investors': e.value.investors,
            'promised': e.value.promised,
            'open': e.value.open,
          },
      },
      'promisedRateWeekly': s.promisedRateWeekly,
      'skim': s.skim,
      'fixedCostWeekly': s.fixedCostWeekly,
      'panic': s.panic,
      'missedPayments': s.missedPayments,
      'bankRun': s.bankRun,
      'suspicion': s.suspicion,
      'totalInflow': s.totalInflow,
      'totalPaidOut': s.totalPaidOut,
      'totalSkimmed': s.totalSkimmed,
      'modifiers': [
        for (final m in s.modifiers)
          {
            'kind': m.kind.name,
            'multiplier': m.multiplier,
            'weeksLeft': m.weeksLeft,
          },
      ],
      'pendingEventIds': s.pendingEventIds,
      'firedEventIds': s.firedEventIds.toList(),
      'end': s.end?.name,
      'endReason': s.endReason,
    };

SchemeState schemeFromJson(Map<String, dynamic> j) => SchemeState(
      typeId: j['typeId'] as String,
      week: (j['week'] as num).toInt(),
      market: _marketFromJson(j['market'] as Map<String, dynamic>),
      board: _boardFromJson(j['board'] as Map<String, dynamic>),
      cash: (j['cash'] as num).toDouble(),
      segments: {
        for (final e in (j['segments'] as Map<String, dynamic>).entries)
          e.key: SegmentState(
            investors: ((e.value as Map<String, dynamic>)['investors'] as num)
                .toInt(),
            promised:
                ((e.value as Map<String, dynamic>)['promised'] as num).toDouble(),
            open: (e.value as Map<String, dynamic>)['open'] as bool,
          ),
      },
      promisedRateWeekly: (j['promisedRateWeekly'] as num).toDouble(),
      skim: (j['skim'] as num).toDouble(),
      fixedCostWeekly: (j['fixedCostWeekly'] as num).toDouble(),
      panic: (j['panic'] as num).toDouble(),
      missedPayments: (j['missedPayments'] as num).toInt(),
      bankRun: j['bankRun'] as bool,
      suspicion: (j['suspicion'] as num).toDouble(),
      totalInflow: (j['totalInflow'] as num).toDouble(),
      totalPaidOut: (j['totalPaidOut'] as num).toDouble(),
      totalSkimmed: (j['totalSkimmed'] as num).toDouble(),
      modifiers: [
        for (final raw in j['modifiers'] as List)
          () {
            final m = raw as Map<String, dynamic>;
            return TimedModifier(
              kind: ModifierKind.values.byName(m['kind'] as String),
              multiplier: (m['multiplier'] as num).toDouble(),
              weeksLeft: (m['weeksLeft'] as num).toInt(),
            );
          }(),
      ],
      pendingEventIds: [for (final v in j['pendingEventIds'] as List) v as String],
      firedEventIds: {for (final v in j['firedEventIds'] as List) v as String},
      end: j['end'] == null ? null : SchemeEnd.values.byName(j['end'] as String),
      endReason: j['endReason'] as String?,
    );

Map<String, dynamic> _marketToJson(MarketState m) => {
      'index': m.index,
      'regime': m.regime.name,
      'weeksInRegime': m.weeksInRegime,
      'lastChange': m.lastChange,
    };

MarketState _marketFromJson(Map<String, dynamic> j) => MarketState(
      index: (j['index'] as num).toDouble(),
      regime: MarketRegime.values.byName(j['regime'] as String),
      weeksInRegime: (j['weeksInRegime'] as num).toInt(),
      lastChange: (j['lastChange'] as num).toDouble(),
    );

Map<String, dynamic> _boardToJson(StockBoard b) => {
      'stocks': [
        for (final s in b.stocks)
          {
            'id': s.id,
            'name': s.name,
            'price': s.price,
            'history': s.history,
            'shares': s.shares,
            'avgCost': s.avgCost,
            'heat': s.heat,
            'floatSize': s.floatSize,
          },
      ],
      'pending': [
        for (final k in b.pending)
          {
            'stockId': k.stockId,
            'remaining': k.remaining,
            'weeksLeft': k.weeksLeft,
            'fresh': k.fresh,
          },
      ],
    };

StockBoard _boardFromJson(Map<String, dynamic> j) => StockBoard(
      stocks: [
        for (final raw in j['stocks'] as List)
          () {
            final s = raw as Map<String, dynamic>;
            return Stock(
              id: s['id'] as String,
              name: s['name'] as String,
              price: (s['price'] as num).toDouble(),
              history: [
                for (final v in s['history'] as List) (v as num).toDouble(),
              ],
              shares: (s['shares'] as num).toInt(),
              avgCost: (s['avgCost'] as num).toDouble(),
              heat: (s['heat'] as num).toDouble(),
              floatSize: (s['floatSize'] as num).toInt(),
            );
          }(),
      ],
      pending: [
        for (final raw in j['pending'] as List)
          () {
            final k = raw as Map<String, dynamic>;
            return PendingKick(
              stockId: k['stockId'] as String,
              remaining: (k['remaining'] as num).toDouble(),
              weeksLeft: (k['weeksLeft'] as num).toInt(),
              fresh: k['fresh'] as bool,
            );
          }(),
      ],
    );

// --- Kariyer ---

Map<String, dynamic> careerToJson(CareerState c) => {
      'cleanMoney': c.cleanMoney,
      'dirtyMoney': c.dirtyMoney,
      'record': c.record,
      'playedSchemeIds': c.playedSchemeIds,
      'chapters': [
        for (final ch in c.chapters)
          {
            'schemeId': ch.schemeId,
            'schemeName': ch.schemeName,
            'weeks': ch.weeks,
            'end': ch.end.name,
            'collected': ch.collected,
            'victims': ch.victims,
            'tookHome': ch.tookHome,
          },
      ],
      'businesses': c.businesses,
      'contacts': c.contacts,
      'escapeParts': c.escapeParts,
      'partner': c.partner?.name,
      'over': c.over,
      'overReason': c.overReason,
    };

CareerState careerFromJson(Map<String, dynamic> j) => CareerState(
      cleanMoney: (j['cleanMoney'] as num).toDouble(),
      dirtyMoney: (j['dirtyMoney'] as num).toDouble(),
      record: (j['record'] as num).toDouble(),
      playedSchemeIds: [
        for (final v in j['playedSchemeIds'] as List) v as String,
      ],
      chapters: [
        for (final raw in j['chapters'] as List)
          () {
            final ch = raw as Map<String, dynamic>;
            return ChapterRecord(
              schemeId: ch['schemeId'] as String,
              schemeName: ch['schemeName'] as String,
              weeks: (ch['weeks'] as num).toInt(),
              end: SchemeEnd.values.byName(ch['end'] as String),
              collected: (ch['collected'] as num).toDouble(),
              victims: (ch['victims'] as num).toInt(),
              tookHome: (ch['tookHome'] as num).toDouble(),
            );
          }(),
      ],
      businesses: [for (final v in j['businesses'] as List) v as String],
      contacts: [for (final v in j['contacts'] as List) v as String],
      escapeParts: [for (final v in j['escapeParts'] as List) v as String],
      partner: j['partner'] == null
          ? null
          : PartnerKind.values.byName(j['partner'] as String),
      over: j['over'] as bool,
      overReason: j['overReason'] as String?,
    );
