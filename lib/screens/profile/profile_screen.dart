import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_constants.dart';
import '../../models/app_user.dart';
import '../../services/user_service.dart';
import '../../screens/profile/settings_screens.dart';

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
            return const Center(child: Text('No user data'));
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
          // HEADER (foto + nome + email)
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
                  'Lifetime Savings',
                  style: TextStyle(
                    fontSize: AppConstants.fontSizeBody,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                Text(
                  '\$${user.lifetimeSavings.toStringAsFixed(2)}',
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
                    '+\$${user.monthlySavings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'this month',
                  style: TextStyle(color: AppConstants.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.spacingL),

          // USER DETAILS (localização + transporte)
          const Text(
            'Details',
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
              user.location.isNotEmpty ? user.location : 'No location defined',
            ),
          ),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.directions_car_outlined),
            title: Text(
              user.transport.isNotEmpty
                  ? user.transport
                  : 'No transport defined',
            ),
          ),

          const SizedBox(height: AppConstants.spacingL),

          // RECENT TRIPS (mock por agora)
          const Text(
            'Recent Trips',
            style: TextStyle(
              fontSize: AppConstants.fontSizeBody,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),

          _buildTripTile('Continente', 'Oct 12, 2023', 84.20, 18.50),
          const Divider(),
          _buildTripTile('Pingo Doce', 'Oct 05, 2023', 42.10, 5.20),

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
              child: const Text('Logout'),
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
          Text('\$${total.toStringAsFixed(2)}'),
          Text(
            'Saved \$${saved.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.green),
          ),
        ],
      ),
    );
  }
}
