import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/pet.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pet_provider.dart';
import '../../utils/theme.dart';

class FirstRunOnboardingScreen extends StatefulWidget {
  const FirstRunOnboardingScreen({super.key});

  @override
  State<FirstRunOnboardingScreen> createState() =>
      _FirstRunOnboardingScreenState();
}

class _FirstRunOnboardingScreenState extends State<FirstRunOnboardingScreen> {
  final _ownerController = TextEditingController();
  final _petController = TextEditingController();
  final _ownerFocus = FocusNode();
  final _petFocus = FocusNode();
  final _picker = ImagePicker();

  bool _initialized = false;
  bool _saving = false;
  int _step = 0;
  String _petId = const Uuid().v4();
  String _species = 'Dog';
  DateTime? _birthday;
  XFile? _photo;
  String? _validationMessage;

  static const _titles = [
    ('Let’s get acquainted', 'What should PawPal call you?'),
    (
      'Meet your best friend',
      'A couple of details makes PawPal feel like home.',
    ),
    (
      'Add a personal touch',
      'These details are optional—you can add them later.',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final profile = context.read<AuthProvider>().userProfile;
    final draft = profile?.onboardingDraft ?? const <String, dynamic>{};
    _step = (profile?.onboardingStep ?? 0).clamp(0, 2);
    _ownerController.text =
        (draft['owner_name'] as String?) ?? profile?.name ?? '';
    _petController.text = (draft['pet_name'] as String?) ?? '';
    _petId = (draft['pet_id'] as String?) ?? _petId;
    _species = (draft['species'] as String?) ?? 'Dog';
    final birthday = draft['birthday'] as String?;
    if (birthday != null) _birthday = DateTime.tryParse(birthday);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusCurrentStep());
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _petController.dispose();
    _ownerFocus.dispose();
    _petFocus.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _draft => {
    'owner_name': _ownerController.text.trim(),
    'pet_id': _petId,
    'pet_name': _petController.text.trim(),
    'species': _species,
    if (_birthday != null)
      'birthday': _birthday!.toIso8601String().split('T').first,
  };

  void _focusCurrentStep() {
    if (!mounted) return;
    final focus = _step == 0
        ? _ownerFocus
        : _step == 1
        ? _petFocus
        : null;
    if (focus != null) FocusScope.of(context).requestFocus(focus);
  }

  bool _validateStep() {
    final message = switch (_step) {
      0 when _ownerController.text.trim().isEmpty =>
        'Please tell us what you’d like to be called.',
      1 when _petController.text.trim().isEmpty =>
        'Please enter your pet’s name.',
      _ => null,
    };
    setState(() => _validationMessage = message);
    return message == null;
  }

  Future<void> _next() async {
    if (!_validateStep()) return;
    if (_step == 2) {
      await _finish();
      return;
    }

    setState(() => _saving = true);
    final nextStep = _step + 1;
    final saved = await context.read<AuthProvider>().saveOnboardingProgress(
      step: nextStep,
      draft: _draft,
      preferredName: _ownerController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (saved) _step = nextStep;
    });
    if (saved) {
      _focusCurrentStep();
    } else {
      _showError(context.read<AuthProvider>().error);
    }
  }

  Future<void> _back() async {
    if (_step == 0 || _saving) return;
    final previousStep = _step - 1;
    setState(() {
      _step = previousStep;
      _validationMessage = null;
    });
    await context.read<AuthProvider>().saveOnboardingProgress(
      step: previousStep,
      draft: _draft,
      preferredName: _ownerController.text.trim(),
    );
    _focusCurrentStep();
  }

  Future<void> _finish() async {
    final auth = context.read<AuthProvider>();
    final petProvider = context.read<PetProvider>();
    final profile = auth.userProfile;
    if (profile == null) return;

    setState(() => _saving = true);
    await auth.saveOnboardingProgress(
      step: 2,
      draft: _draft,
      preferredName: _ownerController.text.trim(),
    );
    final now = DateTime.now();
    final created = await petProvider.createInitialPet(
      Pet(
        id: _petId,
        userId: profile.id,
        name: _petController.text.trim(),
        species: _species,
        dateOfBirth: _birthday,
        gender: 'Unknown',
        createdAt: now,
        updatedAt: now,
      ),
      photoFile: _photo,
    );
    if (!created) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(petProvider.error);
      return;
    }

    final completed = await auth.completeFirstRunOnboarding(
      _ownerController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!completed) {
      _showError(auth.error);
      return;
    }
    context.go(
      auth.userProfile?.hasSeenPricing == false ? '/welcome' : '/home',
    );
  }

  Future<void> _pickPhoto() async {
    final photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (photo != null && mounted) setState(() => _photo = photo);
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 1, now.month, now.day),
      firstDate: DateTime(now.year - 40),
      lastDate: now,
      helpText: 'Pet birthday (optional)',
    );
    if (selected != null && mounted) setState(() => _birthday = selected);
  }

  void _showError(String? message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'We couldn’t save that. Please try again.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _titles[_step];
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.isDark(context)
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF171420), Color(0xFF29213A)],
                )
              : AppTheme.playfulGradient,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 700;
              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 48 : 20,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Semantics(
                      namesRoute: true,
                      label: 'PawPal setup, step ${_step + 1} of 3',
                      child: Container(
                        padding: EdgeInsets.all(wide ? 44 : 24),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground(context),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusHero,
                          ),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          boxShadow: AppTheme.mediumShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ProgressHeader(step: _step),
                            const SizedBox(height: 32),
                            Icon(
                              _step == 0
                                  ? Icons.waving_hand_rounded
                                  : _step == 1
                                  ? Icons.pets_rounded
                                  : Icons.auto_awesome_rounded,
                              color: AppTheme.primaryColor,
                              size: 34,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              title.$1,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title.$2,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: AppTheme.secondaryText(context),
                                  ),
                            ),
                            const SizedBox(height: 28),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: KeyedSubtree(
                                key: ValueKey(_step),
                                child: _buildStep(context),
                              ),
                            ),
                            if (_validationMessage != null) ...[
                              const SizedBox(height: 12),
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  _validationMessage!,
                                  style: const TextStyle(
                                    color: AppTheme.errorColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                if (_step > 0)
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                                    onPressed: _saving ? null : _back,
                                    icon: const Icon(Icons.arrow_back_rounded),
                                    label: const Text('Back'),
                                  ),
                                if (_step > 0) const SizedBox(width: 12),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: FilledButton.icon(
                                      onPressed: _saving ? null : _next,
                                      icon: _saving
                                          ? const SizedBox.square(
                                              dimension: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Icon(
                                              _step == 2
                                                  ? Icons.check_rounded
                                                  : Icons.arrow_forward_rounded,
                                            ),
                                      label: Text(
                                        _step == 2
                                            ? 'Finish setup'
                                            : 'Continue',
                                      ),
                                    ),
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
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case 0:
        return TextField(
          controller: _ownerController,
          focusNode: _ownerFocus,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.name],
          onSubmitted: (_) => _next(),
          decoration: const InputDecoration(
            labelText: 'Your preferred name',
            hintText: 'e.g. Sam',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _petController,
              focusNode: _petFocus,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _next(),
              decoration: const InputDecoration(
                labelText: 'Pet name',
                hintText: 'e.g. Milo',
                prefixIcon: Icon(Icons.pets_outlined),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'What kind of pet?',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final species in const ['Dog', 'Cat', 'Bird', 'Other'])
                  ChoiceChip(
                    label: Text(species),
                    selected: _species == species,
                    onSelected: (_) => setState(() => _species = species),
                  ),
              ],
            ),
          ],
        );
      default:
        return Column(
          children: [
            _OptionalTile(
              icon: Icons.cake_outlined,
              title: 'Birthday',
              subtitle: _birthday == null
                  ? 'Skip if you don’t know it'
                  : DateFormat.yMMMMd().format(_birthday!),
              onTap: _pickBirthday,
              onClear: _birthday == null
                  ? null
                  : () => setState(() => _birthday = null),
            ),
            const SizedBox(height: 12),
            _OptionalTile(
              icon: Icons.add_a_photo_outlined,
              title: 'Profile photo',
              subtitle: _photo == null
                  ? 'Choose from your library'
                  : _photo!.name,
              onTap: _pickPhoto,
              onClear: _photo == null
                  ? null
                  : () => setState(() => _photo = null),
            ),
            const SizedBox(height: 16),
            Text(
              'You can change any of this later in your pet’s profile.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.secondaryText(context),
              ),
            ),
          ],
        );
    }
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'PAWPAL',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.6,
          ),
        ),
        const Spacer(),
        Text(
          '${step + 1} of 3',
          style: TextStyle(
            color: AppTheme.secondaryText(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 96,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (step + 1) / 3,
              minHeight: 7,
              backgroundColor: AppTheme.softTint(
                context,
                AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionalTile extends StatelessWidget {
  const _OptionalTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.onClear,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primaryColor.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: onClear == null
            ? const Icon(Icons.chevron_right_rounded)
            : IconButton(
                tooltip: 'Remove $title',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              ),
        onTap: onTap,
      ),
    );
  }
}
