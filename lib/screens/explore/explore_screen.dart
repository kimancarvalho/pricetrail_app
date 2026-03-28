import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_constants.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../widgets/product_card.dart';

/// Ecrã de pesquisa e descoberta de produtos.
/// Usa Open Food Facts API com debounce para pesquisa eficiente.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  List<Product> _results = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasSearched = false;

  // Produtos adicionados à lista atual — Set para O(1) lookup
  final Set<String> _addedProducts = {};

  // Filtro ativo
  String _activeFilter = AppConstants.filterAll;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Chamado a cada letra escrita — aplica debounce
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _errorMessage = null;
      });
      return;
    }

    _debounceTimer = Timer(
      const Duration(milliseconds: AppConstants.searchDebounceMs),
      () => _search(query),
    );
  }

  /// Executa a pesquisa à API
  Future<void> _search(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final results = await ProductService.searchProducts(query);
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching products. Try again.';
        _isLoading = false;
      });
    }
  }

  /// Filtra os resultados pelo filtro ativo
  List<Product> get _filteredResults {
    if (_activeFilter == AppConstants.filterAll) return _results;

    return _results.where((product) {
      final prices = ProductService.getSimulatedPrices(product.id);
      if (_activeFilter == AppConstants.filterPromotion) {
        return prices.any((p) => p.isPromotion);
      }
      if (_activeFilter == AppConstants.filterStoreBrand) {
        return prices.any((p) => p.isStoreBrand);
      }
      return true;
    }).toList();
  }

  /// Adiciona ou remove um produto da lista
  void _toggleProduct(String productId) {
    setState(() {
      if (_addedProducts.contains(productId)) {
        _addedProducts.remove(productId);
      } else {
        _addedProducts.add(productId);
      }
    });

    // Feedback ao utilizador
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _addedProducts.contains(productId)
              ? 'Product added to list'
              : 'Product removed from list',
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: _addedProducts.contains(productId)
            ? AppConstants.primaryColor
            : AppConstants.textSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: AppConstants.spacingL),
              _buildSearchField(),
              const SizedBox(height: AppConstants.spacingM),
              _buildFilterChips(),
              const SizedBox(height: AppConstants.spacingL),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
      // Botão de otimizar rota — só visível quando há produtos adicionados
      bottomNavigationBar: _addedProducts.isNotEmpty
          ? _buildOptimizeButton()
          : null,
    );
  }

  /// Cabeçalho com título e nome da lista ativa
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppConstants.primaryLight,
            borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          ),
          child: const Icon(
            Icons.list_alt,
            color: AppConstants.primaryColor,
            size: 18,
          ),
        ),
        const SizedBox(width: AppConstants.spacingM),
        const Text(
          'Explore Products',
          style: TextStyle(
            fontSize: AppConstants.fontSizeTitle,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Campo de pesquisa com ícone de microfone
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search products...',
        prefixIcon: const Icon(Icons.search, color: AppConstants.textSecondary),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.clear,
                  color: AppConstants.textSecondary,
                ),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              )
            : const Icon(Icons.mic_outlined, color: AppConstants.primaryColor),
      ),
    );
  }

  /// Chips de filtro — All, Promotion, Store brand
  Widget _buildFilterChips() {
    return Row(
      children: AppConstants.filterOptions.map((filter) {
        final isActive = _activeFilter == filter['value'];
        return Padding(
          padding: const EdgeInsets.only(right: AppConstants.spacingS),
          child: GestureDetector(
            onTap: () => setState(() => _activeFilter = filter['value']!),
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: AppConstants.animationFastMs,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingM,
                vertical: AppConstants.spacingS,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? AppConstants.primaryColor
                    : AppConstants.surfaceColor,
                borderRadius: BorderRadius.circular(AppConstants.radiusL),
                border: Border.all(
                  color: isActive
                      ? AppConstants.primaryColor
                      : AppConstants.borderColor,
                ),
              ),
              child: Text(
                filter['label']!,
                style: TextStyle(
                  fontSize: AppConstants.fontSizeSmall,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? AppConstants.surfaceColor
                      : AppConstants.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Corpo do ecrã — muda consoante o estado
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppConstants.errorColor,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppConstants.textSecondary),
            ),
          ],
        ),
      );
    }

    // Estado inicial
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: AppConstants.spacingM),
            const Text(
              'Search for products to compare prices',
              style: TextStyle(color: AppConstants.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final filtered = _filteredResults;

    // Sem resultados
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sentiment_dissatisfied,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: AppConstants.spacingM),
            const Text(
              'No products found',
              style: TextStyle(color: AppConstants.textSecondary),
            ),
          ],
        ),
      );
    }

    // Resultados
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Results',
          style: const TextStyle(
            fontSize: AppConstants.fontSizeBody,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        Expanded(
          child: ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppConstants.spacingS),
            itemBuilder: (context, index) => ProductCard(
              product: filtered[index],
              isAdded: _addedProducts.contains(filtered[index].id),
              onAdd: () => _toggleProduct(filtered[index].id),
            ),
          ),
        ),
      ],
    );
  }

  /// Botão fixo no fundo para otimizar a rota
  Widget _buildOptimizeButton() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: ElevatedButton(
        onPressed: () {
          // TODO — navegar para Route Screen com os produtos selecionados
        },
        child: Text('Optimize Route (${_addedProducts.length} Items)'),
      ),
    );
  }
}
