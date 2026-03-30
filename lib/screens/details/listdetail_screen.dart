import 'package:flutter/material.dart';
import '../../models/shopping_list.dart';
import '../../models/list_item.dart';
import '../../services/database_service.dart';
import '../../core/app_constants.dart';

class ListDetailScreen extends StatelessWidget {
  final String userId;
  final ShoppingList list;
  final void Function(String listId, String listName) onNavigateToExplore;

  const ListDetailScreen({
    super.key,
    required this.userId,
    required this.list,
    required this.onNavigateToExplore,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(list.name)),
      body: Column(
        children: [
          //RESUMO DA LISTA
          _buildHeader(),

          //LISTA DE ITEMS
          Expanded(
            child: StreamBuilder<List<ListItem>>(
              stream: DatabaseService.getListItems(
                userId: userId,
                listId: list.id,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildItemTile(context, item);
                  },
                );
              },
            ),
          ),

          // BOTÃO ADICIONAR
          _buildAddButton(context),
        ],
      ),
    );
  }

  //HEADER
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${list.itemCount} itens',
            style: const TextStyle(
              fontSize: AppConstants.fontSizeSmall,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Estimado: \$${list.estimatedTotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: AppConstants.fontSizeBody,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  //ITEM
  Widget _buildItemTile(BuildContext context, ListItem item) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppConstants.spacingL),
        color: AppConstants.errorColor,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        DatabaseService.removeItemFromList(
          userId: userId,
          listId: list.id,
          itemId: item.id,
          averagePrice: item.averagePrice,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.productName} removido'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Card(
        child: ListTile(
          leading: item.productImageUrl.isNotEmpty
              ? Image.network(
                  item.productImageUrl,
                  width: 40,
                  errorBuilder: (_, __, ___) {
                    return const Icon(Icons.shopping_bag_outlined);
                  },
                )
              : const Icon(Icons.shopping_bag_outlined),
          title: Text(item.productName),
          subtitle: Text('\$${item.averagePrice.toStringAsFixed(2)}'),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () {
              DatabaseService.removeItemFromList(
                userId: userId,
                listId: list.id,
                itemId: item.id,
                averagePrice: item.averagePrice,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${item.productName} removido')),
              );
            },
          ),
        ),
      ),
    );
  }

  // EMPTY STATE
  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'Esta lista está vazia.\nAdiciona produtos.',
        textAlign: TextAlign.center,
      ),
    );
  }

  //BOTÃO ADICIONAR
  Widget _buildAddButton(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              onNavigateToExplore(
                list.id,
                list.name,
              ); // muda a tab no MainScreen
              Navigator.pop(context); // fecha o ListDetailScreen
            },
            child: const Text('Adicionar produtos'),
          ),
        ),
      ),
    );
  }
}
