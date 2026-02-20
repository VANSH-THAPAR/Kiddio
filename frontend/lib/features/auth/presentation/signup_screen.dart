import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../models/user_model.dart';
import '../providers/auth_controller.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _bioController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _yearsController = TextEditingController();
  
  UserRole _selectedRole = UserRole.parent;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _bioController.dispose();
    _hourlyRateController.dispose();
    _yearsController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final double? hourlyRate = _selectedRole == UserRole.sitter 
          ? double.tryParse(_hourlyRateController.text) 
          : null;
      
      final int? yearsOfExp = _selectedRole == UserRole.sitter
          ? int.tryParse(_yearsController.text)
          : null;

      await ref.read(authControllerProvider.notifier).signup(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
        hourlyRate: hourlyRate,
        bio: _bioController.text.trim(),
        yearsOfExperience: yearsOfExp,
      );

      // Navigation is handled by router based on auth state
      // but we can also manually go to home if needed, though router redirect is better
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing up: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Join Kiddio Today',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Role Selection
              SegmentedButton<UserRole>(
                segments: const [
                  ButtonSegment(
                    value: UserRole.parent,
                    label: Text('I am a Parent'),
                    icon: Icon(Icons.family_restroom),
                  ),
                  ButtonSegment(
                    value: UserRole.sitter,
                    label: Text('I am a Sitter'),
                    icon: Icon(Icons.child_care),
                  ),
                ],
                selected: {_selectedRole},
                onSelectionChanged: (Set<UserRole> newSelection) {
                  setState(() {
                    _selectedRole = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return AppTheme.primaryColor.withOpacity(0.2);
                      }
                      return Colors.transparent;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Common Fields
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null || !value.contains('@') ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) =>
                    value == null || value.length < 6 ? 'Password must be 6+ chars' : null,
              ),

              // Sitter Specific Fields
              if (_selectedRole == UserRole.sitter) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Sitter Details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _hourlyRateController,
                        decoration: const InputDecoration(
                          labelText: 'Hourly Rate (\$/hr)',
                          prefixIcon: Icon(Icons.attach_money),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_selectedRole == UserRole.sitter && 
                              (value == null || value.isEmpty)) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _yearsController,
                        decoration: const InputDecoration(
                          labelText: 'Experience (Years)',
                          prefixIcon: Icon(Icons.access_time),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_selectedRole == UserRole.sitter && 
                              (value == null || value.isEmpty)) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio / About You',
                    prefixIcon: Icon(Icons.abc),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (_selectedRole == UserRole.sitter && 
                        (value == null || value.isEmpty)) {
                      return 'Tell parents a bit about yourself';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 32),
              
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Text(
                          _selectedRole == UserRole.sitter 
                              ? 'Apply as Sitter' 
                              : 'Create Parent Account',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Already have an account? Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
