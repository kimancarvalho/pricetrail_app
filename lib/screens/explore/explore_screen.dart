import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_constants.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../widgets/product_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';

/// Ecrã de pesquisa e descoberta de produtos.
/// Usa Open Food Facts API com debounce para pesquisa eficiente.
class ExploreScreen extends StatefulWidget {
  /// Lista ativa — preenchida quando o utilizador vem do Home.
  /// null quando acede diretamente pelo tab.
  final String? activeListId;
  final String? activeListName;

  /// Callback para notificar o MainScreen quando uma lista é selecionada
  final Function(String listId, String listName)? onListSelected;

  const ExploreScreen({
    super.key,
    this.activeListId,
    this.activeListName,
    this.onListSelected,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // Lista ativa — pode ser definida ao chegar do Home
  // ou após o utilizador selecionar/criar uma lista no Explore
  String? _activeListId;
  String? _activeListName;

  // Mapeia productId → itemId do Firestore para poder remover
  final Map<String, String> _itemIds = {};

  // ID do utilizador atual
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

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
  void initState() {
    super.initState();
    // Se veio do Home com lista ativa, usa-a
    _activeListId = widget.activeListId;
    _activeListName = widget.activeListName;
  }

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

  /// Chamado quando o utilizador clica em + num produto.
  /// Gere os dois fluxos: com lista ativa e sem lista ativa.
  Future<void> _toggleProduct(
    String productId,
    double avgPrice,
    String productName,
    String productImageUrl,
  ) async {
    // Se já está adicionado — remove
    if (_addedProducts.contains(productId)) {
      final itemId = _itemIds[productId];
      if (itemId != null && _activeListId != null) {
        await DatabaseService.removeItemFromList(
          userId: _userId,
          listId: _activeListId!,
          itemId: itemId,
          averagePrice: avgPrice,
        );
      }
      setState(() {
        _addedProducts.remove(productId);
        _itemIds.remove(productId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from list'),
            duration: Duration(seconds: 1),
            backgroundColor: AppConstants.textSecondary,
          ),
        );
      }
      return;
    }

    // Não há lista ativa — mostra opções ao utilizador
    if (_activeListId == null) {
      await _showListSelectionSheet(
        productId,
        avgPrice,
        productName,
        productImageUrl,
      );
      return;
    }

    // Há lista ativa — adiciona diretamente
    await _addProductToList(productId, avgPrice, productName, productImageUrl);
  }

  /// Adiciona o produto à lista ativa no Firestore
  Future<void> _addProductToList(
    String productId,
    double avgPrice,
    String productName,
    String productImageUrl,
  ) async {
    final itemId = await DatabaseService.addItemToList(
      userId: _userId,
      listId: _activeListId!,
      productId: productId,
      productName: productName,
      productImageUrl: productImageUrl,
      averagePrice: avgPrice,
    );

    setState(() {
      _addedProducts.add(productId);
      if (itemId != null) _itemIds[productId] = itemId;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added to "$_activeListName" ✓'),
          duration: const Duration(seconds: 1),
          backgroundColor: AppConstants.primaryColor,
        ),
      );
    }
  }

  /// Mostra bottom sheet para selecionar ou criar uma lista
  Future<void> _showListSelectionSheet(
    String productId,
    double avgPrice,
    String productName,
    String productImageUrl,
  ) async {
    // Busca as listas existentes do utilizador
    final lists = await DatabaseService.getShoppingListsOnce(_userId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusM),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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
            const Text(
              'Add to a list',
              style: TextStyle(
                fontSize: AppConstants.fontSizeTitle,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
            const Text(
              'Select an existing list or create a new one',
              style: TextStyle(
                fontSize: AppConstants.fontSizeSmall,
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),

            // Listas existentes
            if (lists.isNotEmpty) ...[
              ...lists.map(
                (list) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryLight,
                      borderRadius: BorderRadius.circular(AppConstants.radiusS),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppConstants.primaryColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    list.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${list.itemCount} items',
                    style: const TextStyle(
                      fontSize: AppConstants.fontSizeSmall,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  onTap: () async {
                    // Seleciona esta lista e fecha o bottom sheet
                    setState(() {
                      _activeListId = list.id;
                      _activeListName = list.name;
                    });
                    // Notifica o MainScreen da lista selecionada
                    widget.onListSelected?.call(list.id, list.name);
                    Navigator.pop(context);
                    await _addProductToList(
                      productId,
                      avgPrice,
                      productName,
                      productImageUrl,
                    );
                  },
                ),
              ),
              const Divider(color: AppConstants.borderColor),
            ],

            // Opção de criar nova lista
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppConstants.primaryLight,
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
              ),
              title: const Text(
                'Create new list',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppConstants.primaryColor,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _showCreateListDialog(
                  productId,
                  avgPrice,
                  productName,
                  productImageUrl,
                );
              },
            ),
            const SizedBox(height: AppConstants.spacingL),
          ],
        ),
      ),
    );
  }

  /// Dialog para criar uma nova lista e adicionar o produto de imediato
  Future<void> _showCreateListDialog(
    String productId,
    double avgPrice,
    String productName,
    String productImageUrl,
  ) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        title: const Text(
          'New Shopping List',
          style: TextStyle(
            fontSize: AppConstants.fontSizeTitle,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'e.g. Weekly Groceries'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppConstants.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;

              // Cria a lista no Firestore
              final listId = await DatabaseService.createShoppingList(
                userId: _userId,
                name: controller.text.trim(),
              );

              if (context.mounted) Navigator.pop(context);

              // Define como lista ativa e adiciona o produto
              setState(() {
                _activeListId = listId;
                _activeListName = controller.text.trim();
              });
              // Notifica o MainScreen da nova lista criada
              widget.onListSelected?.call(listId, controller.text.trim());

              await _addProductToList(
                productId,
                avgPrice,
                productName,
                productImageUrl,
              );
            },
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingL,
                vertical: AppConstants.spacingS,
              ),
            ),
            child: const Text('Create'),
          ),
        ],
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Explore Products',
              style: TextStyle(
                fontSize: AppConstants.fontSizeTitle,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            // Mostra a lista ativa se existir
            if (_activeListName != null)
              Text(
                'Adding to: $_activeListName',
                style: const TextStyle(
                  fontSize: AppConstants.fontSizeSmall,
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              const Text(
                'Select a list to add products',
                style: TextStyle(
                  fontSize: AppConstants.fontSizeSmall,
                  color: AppConstants.textSecondary,
                ),
              ),
          ],
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
            itemBuilder: (context, index) {
              final product = filtered[index];
              final prices = ProductService.getSimulatedPrices(product.id);
              final avgPrice =
                  prices.map((p) => p.price).reduce((a, b) => a + b) /
                  prices.length;

              return ProductCard(
                product: product,
                isAdded: _addedProducts.contains(product.id),
                onAdd: () => _toggleProduct(
                  product.id,
                  avgPrice,
                  product.name,
                  product.imageUrl,
                ),
              );
            },
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
