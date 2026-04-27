enum MonetizationProduct {
  extraLife('extra_life', 'Extra life', 0.99),
  extraHint('extra_hint', 'Extra hint', 0.99),
  proUnlock('pro_unlock', 'Pro', 4.99);

  const MonetizationProduct(this.productId, this.title, this.priceUsd);

  final String productId;
  final String title;
  final double priceUsd;

  String get formattedPrice => '\$${priceUsd.toStringAsFixed(2)}';
}
