class Stock {
  final String warehouse;
  final String gtin;
  final int qty;

  Stock({
    required this.warehouse,
    required this.gtin,
    required this.qty,
  });

  Stock copyWith({String? warehouse, String? gtin, int? qty}) => Stock(
        warehouse: warehouse ?? this.warehouse,
        gtin: gtin ?? this.gtin,
        qty: qty ?? this.qty,
      );

  Map<String, dynamic> toMap() => {
        'warehouse': warehouse,
        'gtin': gtin,
        'qty': qty,
      };

  factory Stock.fromMap(Map<String, dynamic> map) => Stock(
        warehouse: map['warehouse'] ?? '',
        gtin: map['gtin'] ?? '',
        qty: (map['qty'] ?? 0) as int,
      );
}
