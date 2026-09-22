import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaat_sim/vaat_sim.dart';

/// Denge ve olay içeriği. Kaynağı depo kökündeki `content/`, uygulamaya
/// `assets/content` sembolik bağıyla giriyor; tek doğruluk kaynağı kalsın.
class GameContent {
  const GameContent({
    required this.balance,
    required this.events,
    required this.schemes,
    required this.businesses,
    required this.contacts,
    required this.escapeParts,
  });

  final BalanceConfig balance;
  final EventEngine events;
  final List<SchemeType> schemes;
  final List<BusinessType> businesses;
  final List<ContactType> contacts;
  final List<EscapePart> escapeParts;

  SchemeType scheme(String id) => schemes.firstWhere((t) => t.id == id);
  BusinessType business(String id) => businesses.firstWhere((b) => b.id == id);
  ContactType contact(String id) => contacts.firstWhere((c) => c.id == id);
  EscapePart escapePart(String id) =>
      escapeParts.firstWhere((p) => p.id == id);

  /// Şimdilik olay dosyaları elle listeleniyor. Neden: Flutter asset
  /// manifestinde klasör listelemek için ek paket gerekir, 2 dosya için değmez.
  static const _eventFiles = [
    'core.json',
    'market.json',
    'schemes.json',
    'stocks.json',
    'people.json',
    'pressure.json',
    'assets.json',
    'investors.json',
    'endgame.json',
  ];

  static Future<GameContent> load() async {
    final balanceJson =
        await rootBundle.loadString('assets/content/balance.json');
    final defs = <EventDef>[];
    for (final name in _eventFiles) {
      final source =
          await rootBundle.loadString('assets/content/events/$name');
      defs.addAll(EventDef.listFromJsonString(source));
    }
    final schemesJson =
        await rootBundle.loadString('assets/content/schemes.json');
    final bizJson =
        await rootBundle.loadString('assets/content/businesses.json');
    final contactsJson =
        await rootBundle.loadString('assets/content/contacts.json');
    final escapeJson =
        await rootBundle.loadString('assets/content/escape_plan.json');
    return GameContent(
      balance: BalanceConfig.fromJsonString(balanceJson),
      events: EventEngine(defs),
      schemes: SchemeType.listFromJsonString(schemesJson),
      businesses: BusinessType.listFromJsonString(bizJson),
      contacts: ContactType.listFromJsonString(contactsJson),
      escapeParts: EscapePart.listFromJsonString(escapeJson),
    );
  }
}

/// main() içinde override edilir. Neden: içerik ilk kare çizilmeden önce
/// hazır olsun, ekranlar `AsyncValue` ile boğuşmasın.
final contentProvider = Provider<GameContent>(
  (_) => throw UnimplementedError('contentProvider main() içinde override edilmeli'),
);
