import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Tracks which tab is selected: true = Admin, false = Teacher
  bool _isAdminTab = true;

  final AuthService _authService = AuthService();

  // Text controllers - one for each field, so we can read what's typed
  final _fullNameController = TextEditingController();
  final _staffIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _adminKeyController = TextEditingController();

  // Dropdown selections
  String? _selectedDepartment;
  String? _selectedDesignation;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // A simple secret key that only real admins should know.
  // NOTE: This is a beginner-friendly first step, not bank-level security -
  // we can make this stronger later once you understand the basics.
  static const String _correctAdminKey = 'NASC2024ADMIN';

  @override
  void dispose() {
    _fullNameController.dispose();
    _staffIdController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _adminKeyController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
      ),
    );
  }

  // Runs when the Register button is pressed.
  // Checks everything is filled in correctly BEFORE talking to Firebase.
  Future<void> _handleRegister() async {
    final fullName = _fullNameController.text.trim();
    final staffId = _staffIdController.text.trim();
    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Check nothing important is empty
    if (fullName.isEmpty ||
        staffId.isEmpty ||
        email.isEmpty ||
        mobile.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Please fill in all fields.');
      return;
    }

    if (_selectedDepartment == null) {
      _showMessage('Please select a department.');
      return;
    }

    if (_selectedDesignation == null) {
      _showMessage('Please select a designation.');
      return;
    }

    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    // Extra check ONLY for the Admin tab
    if (_isAdminTab) {
      if (_adminKeyController.text.trim() != _correctAdminKey) {
        _showMessage('Incorrect Admin Secret Key.');
        return;
      }
    }

    // All checks passed - now talk to Firebase
    setState(() {
      _isLoading = true;
    });

    final errorMessage = await _authService.signUp(
      fullName: fullName,
      staffId: staffId,
      department: _selectedDepartment!,
      designation: _selectedDesignation!,
      email: email,
      mobile: mobile,
      password: password,
      role: _isAdminTab ? 'admin' : 'teacher',
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (errorMessage != null) {
      _showMessage(errorMessage);
    } else {
      _showMessage('Account created successfully! Please log in.', isError: false);
      // Send them back to the Login screen after a short pause
      // so they can actually read the success message first.
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  // Reusable text field builder - saves us from repeating the same styling code 7 times
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? toggleObscure,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword ? obscureText : false,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.secondary),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onPressed: toggleObscure,
                  )
                : null,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: FlutterLogo(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isAdminTab
                        ? 'Admin Registration for NASC Grievance Portal'
                        : 'Teacher Registration for NASC Grievance Portal',
                    style: TextStyle(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),

                  // Teacher/Admin Tab Switcher
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTabButton('Teacher', !_isAdminTab, () {
                          setState(() => _isAdminTab = false);
                        }),
                        _buildTabButton('Admin', _isAdminTab, () {
                          setState(() => _isAdminTab = true);
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form fields
                  _buildTextField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _staffIdController,
                    label: _isAdminTab ? 'Admin ID' : 'Staff ID',
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 16),

                  // Department dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Department',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDepartment,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.account_balance_outlined, color: AppColors.secondary),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.outlineVariant),
                          ),
                        ),
                        hint: const Text('Select Department'),
                        items: const [
                          DropdownMenuItem(value: 'cs', child: Text('Computer Science')),
                          DropdownMenuItem(value: 'cs_ds', child: Text('Computer Science with Data Science')),
                          DropdownMenuItem(value: 'aiml', child: Text('AIML')),
                          DropdownMenuItem(value: 'bca', child: Text('BCA')),
                          DropdownMenuItem(value: 'others', child: Text('Others')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedDepartment = value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Designation dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Designation',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedDesignation,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.work_outline, color: AppColors.secondary),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.outlineVariant),
                          ),
                        ),
                        hint: const Text('Select Designation'),
                        items: const [
                          DropdownMenuItem(value: 'staff', child: Text('Staff')),
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedDesignation = value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _emailController,
                    label: 'Official Email ID',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _mobileController,
                    label: 'Mobile Number',
                    icon: Icons.phone_iphone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    toggleObscure: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    icon: Icons.lock_reset_outlined,
                    isPassword: true,
                    obscureText: _obscureConfirmPassword,
                    toggleObscure: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),

                  // Admin Secret Key - only shown when Admin tab is selected
                  if (_isAdminTab) ...[
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _adminKeyController,
                      label: 'Admin Secret Key',
                      icon: Icons.key_outlined,
                      isPassword: true,
                      obscureText: true,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Register button - now connected to Firebase!
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'Register',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context); // goes back to Login screen
                        },
                        child: Text(
                          'Login',
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Small helper widget for the Teacher/Admin tab buttons
  Widget _buildTabButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}