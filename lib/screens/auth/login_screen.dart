import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../settings/app_constants.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';

/// Ecrã de autenticação login com email/password.
/// Fiel ao mockup: erro no topo, campos, botão com estado,
/// OAuth e link para registo.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Tenta fazer login atualiza o estado consoante o resultado
  Future<void> _login() async {
    // Limpa erro anterior e ativa o loading
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await AuthService.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Login bem sucedido navegação tratada pelo auth state listener
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = AuthService.getErrorMessage(e.code);
      });
    } finally {
      // Garante que o loading é desativado mesmo em caso de erro
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Envia email de recuperação de password
  Future<void> _forgotPassword() async {
    if (_emailController.text.isEmpty) {
      setState(() => _errorMessage = 'Insira o seu email.');
      return;
    }

    try {
      await AuthService.sendPasswordResetEmail(_emailController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email de recuperação enviado')),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = AuthService.getErrorMessage(e.code));
    }
  }

  /// Tenta fazer login com o Google
  Future<void> _loginWithGoogle() async {
    // limpa erro anterior e ativa o loading
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    try {
      // chama o metodo do AuthService
      final result = await AuthService.signInWithGoogle();

      // null, significa que o user fechou a janela do google sem escolher conta
      if (result == null) {
        setState(() => _isLoading = false);
        return;
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = AuthService.getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = AuthService.getErrorMessage('Desconhecido');
      });
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
              const SizedBox(height: AppConstants.spacingXXL),
              _buildLogo(),
              const SizedBox(height: AppConstants.spacingXXL),
              // Erro: só visível quando existe
              if (_errorMessage != null) ...[
                _buildErrorBanner(),
                const SizedBox(height: AppConstants.spacingL),
              ],
              _buildEmailField(),
              const SizedBox(height: AppConstants.spacingM),
              _buildPasswordField(),
              const SizedBox(height: AppConstants.spacingS),
              _buildForgotPassword(),
              const SizedBox(height: AppConstants.spacingL),
              _buildLoginButton(),
              const SizedBox(height: AppConstants.spacingXL),
              _buildDivider(),
              const SizedBox(height: AppConstants.spacingL),
              const SizedBox(height: AppConstants.spacingM),
              _buildOAuthButton(
                label: 'Continuar com Google',
                icon: Icons.g_mobiledata,
                onTap: _isLoading ? () {} : _loginWithGoogle,
              ),
              const SizedBox(height: AppConstants.spacingXL),
              _buildCreateAccount(),
            ],
          ),
        ),
      ),
    );
  }

  /// Logo e tagline da app
  Widget _buildLogo() {
    return Center(
      child: Column(
        children: [
          // Logo real da app
          Image.asset(AppConstants.logoPath, width: 72, height: 72),
          const SizedBox(height: AppConstants.spacingM),
          const Text(
            'PriceTrail',
            style: TextStyle(
              fontSize: AppConstants.fontSizeHeading,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingXS),
          const Text(
            'Otimize os seus percursos de compras',
            style: TextStyle(
              fontSize: AppConstants.fontSizeBody,
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Banner de erro
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

  /// Campo de email
  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email Address',
          style: TextStyle(
            fontSize: AppConstants.fontSizeBody,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(hintText: 'john@example.com'),
        ),
      ],
    );
  }

  /// Campo de password com toggle de visibilidade
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password',
          style: TextStyle(
            fontSize: AppConstants.fontSizeBody,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        TextField(
          controller: _passwordController,
          obscureText: !_passwordVisible,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _login(),
          decoration: InputDecoration(
            hintText: '••••••••',
            // Botão para mostrar/esconder password
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility_off : Icons.visibility,
                color: AppConstants.textSecondary,
              ),
              onPressed: () =>
                  setState(() => _passwordVisible = !_passwordVisible),
            ),
          ),
        ),
      ],
    );
  }

  /// Link "Esqueceu a Senha?" alinhado à direita
  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: _forgotPassword,
        child: const Text(
          'Esqueceu a Senha?',
          style: TextStyle(
            color: AppConstants.primaryColor,
            fontSize: AppConstants.fontSizeBody,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Botão de login com estado loading
  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _login,
      child: Text(_isLoading ? '...' : 'Iniciar Sessão'),
    );
  }

  /// Divisor "Or continue with"
  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppConstants.borderColor)),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
          ),
          child: Text(
            'Or continue with',
            style: TextStyle(
              fontSize: AppConstants.fontSizeSmall,
              color: AppConstants.textSecondary,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppConstants.borderColor)),
      ],
    );
  }

  /// Botão OAuth genérico (Apple, Google)
  Widget _buildOAuthButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingL),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(color: AppConstants.borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppConstants.textPrimary),
            const SizedBox(width: AppConstants.spacingS),
            Text(
              label,
              style: const TextStyle(
                fontSize: AppConstants.fontSizeBody,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Link "Novo no PriceTrail? Criar Conta"
  Widget _buildCreateAccount() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Novo no PriceTrail?',
            style: TextStyle(
              color: AppConstants.textSecondary,
              fontSize: AppConstants.fontSizeBody,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            ), //navegar para ecrã de registo
            child: const Text(
              'Criar Conta',
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
