import 'package:intl/intl.dart';

extension MoneyFormat on num {
  String toRupiah({bool withSymbol = true, int decimalCount = 0}) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: withSymbol ? 'Rp ' : '',
      decimalDigits: decimalCount,
    );
    return formatter.format(this);
  }
}
