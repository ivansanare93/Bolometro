import 'catalog_ball.dart';

/// Transient prefill only. No new field is added to the owned-ball wire format.
class CatalogSelection {
  final CatalogBall product;
  final double weightLbs;
  CatalogSelection(this.product, this.weightLbs) {
    if (!weightLbs.isFinite || weightLbs <= 0 || weightLbs > 20) {
      throw ArgumentError('Invalid personal weight');
    }
    if (product.weights.isNotEmpty &&
        !product.weights.any((s) => s.weightLbs == weightLbs)) {
      throw ArgumentError('Weight is not listed for this model');
    }
  }
  String get name =>
      product.isTestData ? '[PRUEBA] ${product.model}' : product.model;
  String? get coverstock => product.coverMaterial ?? product.coverType;
}
