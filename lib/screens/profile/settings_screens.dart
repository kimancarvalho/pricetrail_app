import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Definições')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();

                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Logout'),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _isLoading ? null : () => _confirmDelete(context),
                  child: const Text('Apagar Conta'),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  //Confirm Dialog
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Apagar Conta'),
        content: const Text(
          'Isto irá apagar os seus dados permanentemente.\nTem a certeza?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccountFlow();
            },
            child: const Text('Apagar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  //ASK Password
  Future<String?> _askPassword() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar Senha'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Digite a sua senha'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  //Reauth
  Future<void> _reauthenticate(User user, String password) async {
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );

    await user.reauthenticateWithCredential(cred);
  }

  //Delete FireStore Data
  Future<void> _deleteUserData(String userId) async {
    final db = FirebaseFirestore.instance;

    final listsSnapshot = await db
        .collection('users')
        .doc(userId)
        .collection('lists')
        .get();

    for (var listDoc in listsSnapshot.docs) {
      final itemsSnapshot = await listDoc.reference.collection('items').get();

      // apagar items
      for (var item in itemsSnapshot.docs) {
        await item.reference.delete();
      }

      // apagar lista
      await listDoc.reference.delete();
    }

    // apagar user doc
    await db.collection('users').doc(userId).delete();
  }

  //Final Flow
  Future<void> _deleteAccountFlow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      setState(() => _isLoading = true);

      // 1. pedir password
      final password = await _askPassword();
      if (password == null || password.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // 2. reauth
      await _reauthenticate(user, password);

      // 3. apagar Firestore (listas + items + user)
      await _deleteUserData(user.uid);

      // 4. apagar conta Auth
      await user.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conta Apagada Com Sucesso')),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message ?? 'Erro')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Erro Inesperado')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
