/// Tasarım dokümanındaki aylık basit model.
///
/// Neden ayrı: oyunun haftalık lojistik modeli değil, araştırma raporundaki
/// çöküş tablosunu yeniden üreten en yalın Ponzi denklemi. Tablo doğrulanmadan
/// denge parametrelerine güvenilmez.
///
/// Aylık adımlar: P faiz kazanır, çekim P'nin rw kadarı, yeni para I0*(1+g)^t
/// (plato ayından sonra sabit), S = S + I - W. S sıfırın altına düşünce çöküş.
int? monthsToCollapse({
  required double promisedMonthly,
  required double withdrawMonthly,
  required double inflowGrowthMonthly,
  int? plateauMonth,
  double initialInflow = 100,
  double initialCash = 0,
  double realReturnMonthly = 0,
  int maxMonths = 600,
}) {
  var cash = initialCash;
  var promised = 0.0;
  var inflow = initialInflow;
  for (var month = 1; month <= maxMonths; month++) {
    promised *= 1 + promisedMonthly;
    final withdraw = promised * withdrawMonthly;
    cash = cash * (1 + realReturnMonthly) + inflow - withdraw;
    promised = promised - withdraw + inflow;
    if (cash < 0) return month;
    final growing = plateauMonth == null || month < plateauMonth;
    if (growing) inflow *= 1 + inflowGrowthMonthly;
  }
  return null;
}
