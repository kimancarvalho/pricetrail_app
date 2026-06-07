import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../settings/app_constants.dart';
import '../../models/app_user.dart';
import '../../services/user_service.dart';
import '../../screens/profile/settings_screens.dart';
import '../../models/shopping_list.dart';
import '../../services/database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: StreamBuilder<AppUser?>(
        stream: UserService.getUser(_userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;

          if (user == null) {
            return const Center(child: Text('Sem dados de usuário'));
          }

          return _buildProfile(user);
        },
      ),
    );
  }

  Widget _buildProfile(AppUser user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER (foto, nome, email)
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppConstants.primaryLight,
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null
                    ? const Icon(Icons.person, size: 32)
                    : null,
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: AppConstants.fontSizeTitle,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: AppConstants.fontSizeSmall,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // botão settings (opcional)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppConstants.primaryLight,
                  borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                ),
                child: IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingL),

          // LIFETIME SAVINGS CARD
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.spacingL),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Poupanças',
                  style: TextStyle(
                    fontSize: AppConstants.fontSizeBody,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                Text(
                  '€${user.lifetimeSavings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingM,
                    vertical: AppConstants.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  ),
                  child: Text(
                    '+€${user.monthlySavings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Este Mês',
                  style: TextStyle(color: AppConstants.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.spacingL),

          // USER DETAILS (localização e transporte)
          const Text(
            'Detalhes',
            style: TextStyle(
              fontSize: AppConstants.fontSizeBody,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.location_on_outlined),
            title: Text(
              user.location.isNotEmpty
                  ? user.location
                  : 'Sem Localização Definida',
            ),
          ),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.directions_car_outlined),
            title: Text(
              user.transport.isNotEmpty
                  ? user.transport
                  : 'Sem Transporte Definido',
            ),
          ),

          const SizedBox(height: AppConstants.spacingL),

          // RECENT TRIPS
          const Text(
            'Viagens Recentes',
            style: TextStyle(
              fontSize: AppConstants.fontSizeBody,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),

          StreamBuilder<List<ShoppingList>>(
            stream: DatabaseService.getShoppingLists(_userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final todasAsListas = snapshot.data ?? [];

              // Filtra só as listas concluídas
              final trips = todasAsListas
                  .where((lista) => lista.isCompleted)
                  .toList();

              if (trips.isEmpty) {
                return const Text(
                  'Ainda não tens viagens concluídas.',
                  style: TextStyle(color: AppConstants.textSecondary),
                );
              }

              return Column(
                children: trips
                    .map(
                      (trip) => _buildTripTile(
                        trip.name,
                        trip.completedAt != null
                            ? '${trip.completedAt!.day}/${trip.completedAt!.month}/${trip.completedAt!.year}'
                            : '',
                        trip.estimatedTotal,
                        0, // poupança real viria do MonthlySummary por agora 0
                      ),
                    )
                    .toList(),
              );
            },
          ),

          const SizedBox(height: AppConstants.spacingL),

          // LOGOUT
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.errorColor,
              ),
              child: const Text('Terminar Sessão'),
            ),
          ),
        ],
      ),
    );
  }

  // helper para trips
  Widget _buildTripTile(String store, String date, double total, double saved) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppConstants.primaryLight,
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
        ),
        child: const Icon(Icons.shopping_bag_outlined),
      ),
      title: Text(store),
      subtitle: Text(date),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('€${total.toStringAsFixed(2)}'),
          Text(
            'Poupado €${saved.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.green),
          ),
        ],
      ),
    );
  }
}
