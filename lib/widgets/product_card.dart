import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/app_constants.dart';
import '../models/product.dart';
import '../models/store_price.dart';
import '../services/product_service.dart';

/// Card de produto na grelha de pesquisa.
/// Mostra imagem, nome, marca e preço médio.
/// Ao tocar expande para mostrar preços por loja.
class ProductCard extends StatelessWidget {
  final Product product;
  final bool isAdded;
  final VoidCallback onAdd;

  const ProductCard({
    super.key,
    required this.product,
    required this.isAdded,
    required this.onAdd,
  });

  /// Calcula o preço médio entre lojas
  double _averagePrice(List<StorePrice> prices) {
    if (prices.isEmpty) return 0;
    return prices.map((p) => p.price).reduce((a, b) => a + b) / prices.length;
  }

  /// Mostra bottom sheet com preços por loja
  void _showPriceComparison(BuildContext context) {
    final prices = ProductService.getSimulatedPrices(product.id);

    // Ordena por preço crescente — mais barato primeiro
    prices.sort((a, b) => a.price.compareTo(b.price));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // ← permite que o bottom sheet cresça
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusM),
        ),
      ),
      builder: (_) => DraggableScrollableSheet(
        // Altura inicial e máxima do bottom sheet relativas ao ecrã
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle do bottom sheet
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppConstants.borderColor,
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: AppConstants.fontSizeTitle,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingS),
              const Text(
                'Price comparison by store',
                style: TextStyle(
                  fontSize: AppConstants.fontSizeSmall,
                  color: AppConstants.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.spacingL),
              ...prices.map(
                (price) => _buildStorePriceRow(price, prices.first),
              ),
              const SizedBox(height: AppConstants.spacingL),
            ],
          ),
        ),
      ),
    );
  }

  /// Linha de preço por loja no bottom sheet
  Widget _buildStorePriceRow(StorePrice price, StorePrice cheapest) {
    final isCheapest = price.storeId == cheapest.storeId;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: isCheapest
            ? AppConstants.primaryLight
            : AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: isCheapest
              ? AppConstants.primaryColor
              : AppConstants.borderColor,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      price.storeName,
                      style: TextStyle(
                        fontSize: AppConstants.fontSizeBody,
                        fontWeight: FontWeight.w600,
                        color: isCheapest
                            ? AppConstants.primaryColor
                            : AppConstants.textPrimary,
                      ),
                    ),
                    if (isCheapest) ...[
                      const SizedBox(width: AppConstants.spacingXS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingS,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusS,
                          ),
                        ),
                        child: const Text(
                          'Cheapest',
                          style: TextStyle(
                            color: AppConstants.surfaceColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // Badges de promoção e marca própria
                Row(
                  children: [
                    if (price.isPromotion)
                      _buildBadge('Promotion', AppConstants.cautionColor),
                    if (price.isStoreBrand)
                      _buildBadge('Store brand', AppConstants.primaryColor),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '€${price.price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: AppConstants.fontSizeTitle,
              fontWeight: FontWeight.bold,
              color: isCheapest
                  ? AppConstants.primaryColor
                  : AppConstants.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Badge colorido para promoção ou marca própria
  Widget _buildBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: AppConstants.spacingXS, top: 2),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusS),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prices = ProductService.getSimulatedPrices(product.id);
    final avgPrice = _averagePrice(prices);

    return GestureDetector(
      onTap: () => _showPriceComparison(context),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Row(
            children: [
              // Imagem do produto
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.radiusS),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => Container(
                    width: 64,
                    height: 64,
                    color: AppConstants.backgroundColor,
                    child: const Icon(
                      Icons.image_outlined,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 64,
                    height: 64,
                    color: AppConstants.backgroundColor,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              // Informações do produto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: AppConstants.fontSizeBody,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      'Avg. €${avgPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: AppConstants.fontSizeBody,
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Found in ${prices.length} stores',
                      style: const TextStyle(
                        fontSize: AppConstants.fontSizeSmall,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Botão de adicionar à lista
              GestureDetector(
                onTap: onAdd,
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: AppConstants.animationFastMs,
                  ),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isAdded
                        ? AppConstants.primaryColor
                        : AppConstants.primaryLight,
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                  ),
                  child: Icon(
                    isAdded ? Icons.check : Icons.add,
                    color: isAdded
                        ? AppConstants.surfaceColor
                        : AppConstants.primaryColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
