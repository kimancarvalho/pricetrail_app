import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/app_constants.dart';
import '../../models/monthly_summary.dart';
import '../../models/shopping_list.dart';
import '../../services/database_service.dart';

/// Home Dashboard — ecrã principal da app.
/// Mostra o resumo mensal e as listas de compras do utilizador.
class HomeScreen extends StatefulWidget {
  /// Callback chamado quando o utilizador clica numa lista
  /// para navegar para o Explore com a lista ativa.
  final Function(String listId, String listName) onNavigateToExplore;

  const HomeScreen({super.key, required this.onNavigateToExplore});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Utilizador atual — nunca é null porque chegámos aqui autenticados
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  // Mês atual formatado como chave do Firestore (ex: "2025-03")
  final String _currentMonth =
      '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

  MonthlySummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  /// Carrega o resumo mensal do Firestore
  Future<void> _loadSummary() async {
    final summary = await DatabaseService.getMonthlySummary(
      userId: _userId,
      month: _currentMonth,
    );
    if (mounted) setState(() => _summary = summary);
  }

  /// Mostra o dialog para criar uma nova lista
  void _showCreateListDialog() {
    final controller = TextEditingController();

    showDialog(
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
          decoration: const InputDecoration(hintText: 'e.g. Weekend BBQ'),
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
              await DatabaseService.createShoppingList(
                userId: _userId,
                name: controller.text.trim(),
              );
              if (context.mounted) Navigator.pop(context);
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
              _buildHeader(),
              const SizedBox(height: AppConstants.spacingL),
              if (_summary != null) ...[
                _buildMonthlySummaryCard(),
                const SizedBox(height: AppConstants.spacingL),
              ],
              _buildSectionTitle(),
              const SizedBox(height: AppConstants.spacingM),
              Expanded(child: _buildShoppingLists()),
            ],
          ),
        ),
      ),
      // Botão flutuante para criar nova lista
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateListDialog,
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: AppConstants.surfaceColor),
      ),
    );
  }

  /// Cabeçalho com título e badge de notificações
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'PriceTrail',
          style: TextStyle(
            fontSize: AppConstants.fontSizeTitle,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryColor,
          ),
        ),
        // Badge de notificações
        Stack(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppConstants.primaryLight,
                borderRadius: BorderRadius.circular(AppConstants.radiusXL),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: AppConstants.primaryColor,
              ),
            ),
            // Badge com número de notificações
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppConstants.errorColor,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '2',
                    style: TextStyle(
                      color: AppConstants.surfaceColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Card verde de resumo mensal — fiel ao mockup
  Widget _buildMonthlySummaryCard() {
    final monthName = _getMonthName(DateTime.now().month);
    final growth = _summary!.savingsGrowth;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título e seletor de mês
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monthly\nOverview',
                style: TextStyle(
                  color: AppConstants.surfaceColor,
                  fontSize: AppConstants.fontSizeTitle,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                  vertical: AppConstants.spacingS,
                ),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(AppConstants.radiusM),
                ),
                child: Text(
                  monthName,
                  style: const TextStyle(
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: AppConstants.fontSizeBody,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          // Total gasto e poupado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Spent',
                    style: TextStyle(
                      color: AppConstants.surfaceColor,
                      fontSize: AppConstants.fontSizeSmall,
                    ),
                  ),
                  Text(
                    '\$${_summary!.totalSpent.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppConstants.surfaceColor,
                      fontSize: AppConstants.fontSizeDisplay,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Total Saved',
                    style: TextStyle(
                      color: AppConstants.surfaceColor,
                      fontSize: AppConstants.fontSizeSmall,
                    ),
                  ),
                  Text(
                    '\$${_summary!.totalSaved.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppConstants.surfaceColor,
                      fontSize: AppConstants.fontSizeDisplay,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          // Barra de progresso
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusS),
            child: LinearProgressIndicator(
              value:
                  _summary!.totalSaved /
                  (_summary!.totalSpent + _summary!.totalSaved),
              backgroundColor: AppConstants.surfaceColor.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppConstants.surfaceColor,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          // Mensagem de crescimento
          if (growth > 0)
            Text(
              "You've saved ${growth.toStringAsFixed(0)}% more than last month!",
              style: const TextStyle(
                color: AppConstants.surfaceColor,
                fontSize: AppConstants.fontSizeSmall,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  /// Título da secção de listas
  Widget _buildSectionTitle() {
    return const Text(
      'My Shopping Lists',
      style: TextStyle(
        fontSize: AppConstants.fontSizeTitle,
        fontWeight: FontWeight.bold,
        color: AppConstants.textPrimary,
      ),
    );
  }

  /// Lista de compras via StreamBuilder — atualiza em tempo real
  Widget _buildShoppingLists() {
    return StreamBuilder<List<ShoppingList>>(
      stream: DatabaseService.getShoppingLists(_userId),
      builder: (context, snapshot) {
        // A carregar
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Erro
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final lists = snapshot.data ?? [];

        // Estado vazio
        if (lists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.list_alt_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: AppConstants.spacingM),
                const Text(
                  'No lists yet',
                  style: TextStyle(
                    fontSize: AppConstants.fontSizeTitle,
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingS),
                const Text(
                  'Tap + to create your first shopping list',
                  style: TextStyle(color: AppConstants.textSecondary),
                ),
              ],
            ),
          );
        }

        // Lista de compras
        return ListView.separated(
          itemCount: lists.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppConstants.spacingS),
          itemBuilder: (context, index) => _buildListCard(lists[index]),
        );
      },
    );
  }

  /// Card de uma lista de compras
  Widget _buildListCard(ShoppingList list) {
    return Dismissible(
      key: ValueKey(list.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppConstants.spacingL),
        decoration: BoxDecoration(
          color: AppConstants.errorColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: AppConstants.surfaceColor,
        ),
      ),
      onDismissed: (_) =>
          DatabaseService.deleteShoppingList(userId: _userId, listId: list.id),
      // GestureDetector envolve o Card para detetar o toque
      child: GestureDetector(
        onTap: () => widget.onNavigateToExplore(list.id, list.name),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: list.isCompleted
                        ? Colors.grey.shade100
                        : AppConstants.primaryLight,
                    borderRadius: BorderRadius.circular(AppConstants.radiusS),
                    border: list.isCompleted
                        ? Border.all(color: AppConstants.borderColor)
                        : null,
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: list.isCompleted
                        ? AppConstants.textSecondary
                        : AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        style: TextStyle(
                          fontSize: AppConstants.fontSizeBody,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                          decoration: list.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppConstants.spacingXS),
                      Text(
                        list.isCompleted
                            ? 'Completed ${_formatDate(list.completedAt!)}'
                            : '${list.itemCount} items • Est. \$${list.estimatedTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: AppConstants.fontSizeSmall,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppConstants.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Converte o número do mês no nome — ex: 3 → "March"
  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  /// Formata uma data para exibição — ex: "yesterday" ou "Oct 12"
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    return '${_getMonthName(date.month).substring(0, 3)} ${date.day}';
  }
}
