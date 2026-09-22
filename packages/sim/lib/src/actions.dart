import 'stocks.dart';

/// Oyuncunun bir hafta içinde yapabileceği hamleler.
///
/// Neden sealed: tick fonksiyonu switch ile hepsini kapsamalı, yeni hamle
/// eklenince derleyici unutulan yeri göstersin.
sealed class PlayerAction {
  const PlayerAction();
}

// Manipulation tipi stocks.dart'ta.

/// Haftalık vaat oranını değiştir. Anında yeni para, gecikmeli çekim patlaması.
class SetPromisedRate extends PlayerAction {
  const SetPromisedRate(this.rateWeekly);
  final double rateWeekly;
}

/// Gelen paradan cebe atılan payı değiştir.
class SetSkim extends PlayerAction {
  const SetSkim(this.skim);
  final double skim;
}

/// Yeni bir segmentin kanalını aç. Pazar havuzu büyür, gider ve şüphe artar.
class OpenSegment extends PlayerAction {
  const OpenSegment(this.segmentId, {this.setupCost = 25000});
  final String segmentId;
  final double setupCost;
}

/// Bu hafta pazarlamaya para bas. Kanal gücünü tek haftalığına çarpar.
class Marketing extends PlayerAction {
  const Marketing(this.amount);
  final double amount;
}

/// Bekleyen bir olaya cevap ver.
class ResolveEvent extends PlayerAction {
  const ResolveEvent(this.eventId, this.optionIndex);
  final String eventId;
  final int optionIndex;
}

/// Kaç. Şema biter, kasa ve cep birlikte alınır, yüz tanınır.
class Flee extends PlayerAction {
  const Flee();
}

/// Firmayı alıcıya sat. Az para ama temiz para ve az iz.
class SellScheme extends PlayerAction {
  const SellScheme();
}

/// Hisse al. Kasadan para çıkar, pozisyon büyür.
class BuyStock extends PlayerAction {
  const BuyStock(this.stockId, this.shares);
  final String stockId;
  final int shares;
}

/// Hisse sat. Pozisyon küçülür, kâr veya zarar kasaya yazılır.
class SellStock extends PlayerAction {
  const SellStock(this.stockId, this.shares);
  final String stockId;
  final int shares;
}

/// Bir hisseyi manipüle et. Fiyat anında sıçrar, sonra haftalar içinde geri
/// çekilir. Geç satan kendi balonuyla iner.
class ManipulateStock extends PlayerAction {
  const ManipulateStock(this.stockId, this.kind);
  final String stockId;
  final Manipulation kind;
}

/// Firmayı bir ortağa veya çalışana devret. Kasayı bırakırsın, cebin kalır.
class HandOverScheme extends PlayerAction {
  const HandOverScheme();
}
