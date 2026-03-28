import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/app_constants.dart';
import '../../services/auth_service.dart';

/// Ecrã de registo de novo utilizador.
/// Segue o mesmo estilo visual do LoginScreen.
/// Campos baseados no requisito F01 do enunciado.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _localityController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  String? _errorMessage;

  // Meio de transporte selecionado — valor por omissão: a pé
  String _selectedTransport = AppConstants.transportWalk;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _localityController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Valida os campos e regista o utilizador
  Future<void> _register() async {
    setState(() => _errorMessage = null);

    // Validações locais antes de ir ao Firebase
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your name.');
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your email.');
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await AuthService.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Atualiza o nome de exibição do utilizador no Firebase Auth
      await credential.user?.updateDisplayName(_nameController.text.trim());

      // TODO — guardar localidade e transporte no Firestore (Fase seguinte)

      // Registo bem sucedido — o StreamBuilder do main.dart deteta
      // automaticamente o novo utilizador autenticado e navega para o MainScreen.
      // Limpamos toda a pilha de navegação para o utilizador não poder
      // voltar ao ecrã de registo com o botão de voltar.
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = AuthService.getErrorMessage(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacingXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: AppConstants.spacingXL),
              // Erro — só visível quando existe
              if (_errorMessage != null) ...[
                _buildErrorBanner(),
                const SizedBox(height: AppConstants.spacingL),
              ],
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                hint: 'John Smith',
                inputType: TextInputType.name,
                action: TextInputAction.next,
              ),
              const SizedBox(height: AppConstants.spacingM),
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'john@example.com',
                inputType: TextInputType.emailAddress,
                action: TextInputAction.next,
              ),
              const SizedBox(height: AppConstants.spacingM),
              _buildTextField(
                controller: _localityController,
                label: 'Locality',
                hint: 'e.g. Lisbon',
                inputType: TextInputType.streetAddress,
                action: TextInputAction.next,
              ),
              const SizedBox(height: AppConstants.spacingM),
              _buildPasswordField(
                controller: _passwordController,
                label: 'Password',
                visible: _passwordVisible,
                onToggle: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
                action: TextInputAction.next,
              ),
              const SizedBox(height: AppConstants.spacingM),
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                visible: _confirmPasswordVisible,
                onToggle: () => setState(
                  () => _confirmPasswordVisible = !_confirmPasswordVisible,
                ),
                action: TextInputAction.done,
                onSubmitted: (_) => _register(),
              ),
              const SizedBox(height: AppConstants.spacingL),
              _buildTransportSelector(),
              const SizedBox(height: AppConstants.spacingXL),
              _buildRegisterButton(),
              const SizedBox(height: AppConstants.spacingXL),
              _buildLoginLink(),
            ],
          ),
        ),
      ),
    );
  }

  /// Cabeçalho com botão de voltar e título
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(AppConstants.spacingS),
            decoration: BoxDecoration(
              color: AppConstants.primaryLight,
              borderRadius: BorderRadius.circular(AppConstants.radiusS),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppConstants.primaryColor,
            ),
          ),
        ),
        const SizedBox(width: AppConstants.spacingM),
        const Text(
          'Create Account',
          style: TextStyle(
            fontSize: AppConstants.fontSizeTitle,
            fontWeight: FontWeight.bold,
            color: AppConstants.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Banner de erro — mesmo estilo do LoginScreen
  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingL),
      decoration: BoxDecoration(
        color: AppConstants.errorColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Text(
        _errorMessage!,
        style: const TextStyle(
          color: AppConstants.surfaceColor,
          fontSize: AppConstants.fontSizeBody,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Campo de texto genérico reutilizável
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required TextInputType inputType,
    required TextInputAction action,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppConstants.fontSizeBody,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        TextField(
          controller: controller,
          keyboardType: inputType,
          textInputAction: action,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  /// Campo de password com toggle de visibilidade
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required VoidCallback onToggle,
    required TextInputAction action,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppConstants.fontSizeBody,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        TextField(
          controller: controller,
          obscureText: !visible,
          textInputAction: action,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: '••••••••',
            suffixIcon: IconButton(
              icon: Icon(
                visible ? Icons.visibility_off : Icons.visibility,
                color: AppConstants.textSecondary,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }

  /// Seletor de meio de transporte — chips selecionáveis
  Widget _buildTransportSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transport Mode',
          style: TextStyle(
            fontSize: AppConstants.fontSizeBody,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        Row(
          children: AppConstants.transportOptions.map((option) {
            final isSelected = _selectedTransport == option['value'];
            return Expanded(
              child: GestureDetector(
                onTap: () =>
                    setState(() => _selectedTransport = option['value']!),
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: AppConstants.animationFastMs,
                  ),
                  margin: const EdgeInsets.only(right: AppConstants.spacingS),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacingM,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppConstants.primaryColor
                        : AppConstants.surfaceColor,
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    border: Border.all(
                      color: isSelected
                          ? AppConstants.primaryColor
                          : AppConstants.borderColor,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        option['icon']!,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: AppConstants.spacingXS),
                      Text(
                        option['label']!,
                        style: TextStyle(
                          fontSize: AppConstants.fontSizeSmall,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? AppConstants.surfaceColor
                              : AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Botão de registo com estado loading
  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _register,
      child: Text(_isLoading ? 'Creating account...' : 'Create Account'),
    );
  }

  /// Link para voltar ao login
  Widget _buildLoginLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Already have an account? ',
            style: TextStyle(
              color: AppConstants.textSecondary,
              fontSize: AppConstants.fontSizeBody,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text(
              'Log In',
              style: TextStyle(
                color: AppConstants.primaryColor,
                fontSize: AppConstants.fontSizeBody,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
