import 'package:flutter/material.dart';
import '../../models/shopping_list.dart';
import '../../models/list_item.dart';
import '../../services/database_service.dart';
import '../../core/app_constants.dart';

class ListDetailScreen extends StatefulWidget {
  final String userId;
  final ShoppingList list;
  final void Function(String listId, String listName, int itemCount) onNavigateToExplore;
  final void Function(String listId, String listName) onNavigateToRoute;

  const ListDetailScreen({
    super.key,
    required this.userId,
    required this.list,
    required this.onNavigateToExplore,
    required this.onNavigateToRoute,
  });

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.list.name)),
      body: StreamBuilder<List<ListItem>>(
        stream: DatabaseService.getListItems(
          userId: widget.userId,
          listId: widget.list.id,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];

          return Column(
            children: [
              // RESUMO DA LISTA
              _buildHeader(items.length),

              // LISTA DE ITEMS
              Expanded(
                child: items.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppConstants.spacingM),
                        itemCount: items.length,
                        itemBuilder: (context, index) =>
                            _buildItemTile(context, items[index]),
                      ),
              ),

              // BOTÃO OPTIMIZE — só visível quando há items
              if (items.isNotEmpty) _buildOptimizeButton(context, items.length),

              // BOTÃO ADICIONAR — sempre visível
              _buildAddButton(context, items.length),
            ],
          );
        },
      ),
    );
  }

  // HEADER — usa items.length em vez de list.itemCount
  // porque o stream é sempre mais recente que o snapshot da lista
  Widget _buildHeader(int itemCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$itemCount itens',
            style: const TextStyle(
              fontSize: AppConstants.fontSizeSmall,
              color: AppConstants.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Estimado: \$${widget.list.estimatedTotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: AppConstants.fontSizeBody,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ITEM
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
          userId: widget.userId,
          listId: widget.list.id,
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
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.shopping_bag_outlined),
                )
              : const Icon(Icons.shopping_bag_outlined),
          title: Text(item.productName),
          subtitle: Text('\$${item.averagePrice.toStringAsFixed(2)}'),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () {
              DatabaseService.removeItemFromList(
                userId: widget.userId,
                listId: widget.list.id,
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

  // BOTÃO OPTIMIZE ROUTE
  Widget _buildOptimizeButton(BuildContext context, int itemCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingM,
        0,
        AppConstants.spacingM,
        AppConstants.spacingS,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            // TODO — navegar para Route Screen
            print("DEBUG 1: Botão clicado no Detalhe da Lista!");
            widget.onNavigateToRoute(widget.list.id, widget.list.name);
            Navigator.pop(context);
          },
          icon: const Icon(Icons.route),
          label: Text('Optimize Route ($itemCount Items)'),
        ),
      ),
    );
  }

  // BOTÃO ADICIONAR
  Widget _buildAddButton(BuildContext context, int itemCount) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              widget.onNavigateToExplore(
                widget.list.id,
                widget.list.name,
                itemCount, // passa o itemCount real do stream
              );
              Navigator.pop(context);
            },
            child: const Text('Adicionar produtos'),
          ),
        ),
      ),
    );
  }
}
