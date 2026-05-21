import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  String _selectedType = 'suggestion';
  int? _rating;
  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = Provider.of<AuthService>(context, listen: false);
    if (_emailController.text.isEmpty && authService.user?.email != null) {
      _emailController.text = authService.user!.email!;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final l10n = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (authService.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loginRequiredMessage)),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final normalizedEmail = _emailController.text.trim();
      final contactEmail = normalizedEmail.isNotEmpty
          ? normalizedEmail
          : authService.user?.email;

      await _firestoreService.enviarFeedback(
        userId: authService.userId!,
        type: _selectedType,
        message: _messageController.text.trim(),
        email: contactEmail,
        authEmail: authService.user?.email,
        rating: _rating,
        appVersion: packageInfo.version,
        platform: Platform.operatingSystem,
        languageCode: Localizations.localeOf(context).languageCode,
      );

      await analyticsService.logFeedbackSubmitted(
        type: _selectedType,
        hasEmail: contactEmail != null && contactEmail.isNotEmpty,
        hasRating: _rating != null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.feedbackSentSuccess)),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.feedbackSubmitError}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sendFeedback),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: l10n.feedbackTypeLabel,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'suggestion',
                      child: Text(l10n.feedbackTypeSuggestion),
                    ),
                    DropdownMenuItem(
                      value: 'bug',
                      child: Text(l10n.feedbackTypeBug),
                    ),
                    DropdownMenuItem(
                      value: 'other',
                      child: Text(l10n.feedbackTypeOther),
                    ),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedType = value;
                          });
                        },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  minLines: 4,
                  maxLines: 7,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: l10n.feedbackMessageLabel,
                    hintText: l10n.feedbackMessageHint,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.feedbackMessageRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: l10n.feedbackEmailLabel,
                    hintText: l10n.feedbackEmailHint,
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return null;
                    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                    if (!regex.hasMatch(email)) {
                      return l10n.feedbackInvalidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  value: _rating,
                  decoration: InputDecoration(
                    labelText: l10n.feedbackRatingLabel,
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(l10n.feedbackRatingOptional),
                    ),
                    for (var i = 1; i <= 5; i++)
                      DropdownMenuItem<int?>(
                        value: i,
                        child: Text('$i/5'),
                      ),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _rating = value;
                          });
                        },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  child: _isSubmitting
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text(l10n.feedbackSubmitting),
                          ],
                        )
                      : Text(l10n.feedbackSubmit),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
