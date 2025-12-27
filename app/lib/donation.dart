import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'l10n/dynamic_l10n.dart';


class DonationPage extends StatefulWidget {
  const DonationPage({super.key});

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  bool _isProcessing = false;
  // Stripe custom link (single link used whether monthly is toggled or not; monthly is hidden for custom)
  static const String _stripeCustomLink = 'https://donate.stripe.com/7sY9ANgkheEv2r40n38N208';
  // Méthodes de paiement simplifiées
  final List<String> _paymentMethods = [
    'Buy me a coffee',
    'Ko-Fi.com',
    'Stripe',
    'Bank Transfer',
  ];
  String? _selectedMethod;

  // Montants prédéfinis
  final List<int> _presetAmounts = [2, 5, 10, 20];
  int? _selectedPreset;
  bool _isCustomSelected = false;
  final TextEditingController _customController = TextEditingController();

  bool _isMonthly = false;

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  double? _getChosenAmount() {
    if (_isCustomSelected) {
      final text = _customController.text.trim();
      if (text.isEmpty) return null;
      final value = double.tryParse(text);
      return (value != null && value > 0) ? value : null;
    } else if (_selectedPreset != null) {
      return _selectedPreset!.toDouble();
    }
    return null;
  }

  Future<void> _onDonatePressed() async {
    setState(() {
      _isProcessing = true;
    });
    try {
      double? amount;
      final requiresAmount = _selectedMethod != 'Bank Transfer' &&
          _selectedMethod != 'Buy me a coffee' &&
          _selectedMethod != 'Ko-Fi.com' &&
          !(_selectedMethod == 'Stripe' && _isCustomSelected);
      if (requiresAmount) {
        amount = _getChosenAmount();
        if (amount == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              content: Text(
                S.of(context)!.donationErrorInvalidAmount,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface2,
                ),
              ),
            ),
          );
          return;
        }
      } else {
        amount = _getChosenAmount();
      }

      if (_selectedMethod == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            content: Text(
              S.of(context)!.donationErrorSelectMethod,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface2,
              ),
            ),
          ),
        );
        return;
      }

      String? url;
      final amtString = (amount != null) ? amount.toStringAsFixed(2) : '';

      if (_selectedMethod == 'Buy me a coffee') {
        // Redirection simple vers la page Buy Me A Coffee
        url = 'https://buymeacoffee.com/netcreative';
      } else if (_selectedMethod == 'Ko-Fi.com') {
        // Redirection vers Ko-Fi
        url = 'https://ko-fi.com/netcreativejlc';
      } else if (_selectedMethod == 'Stripe') {
        if (_isMonthly) {
          // Abonnements mensuels Stripe : vous devez avoir créé à l’avance dans Stripe Dashboard
          // des Payment Links de type “Subscription” pour chaque montant fixe.
          if (_isCustomSelected) {
            // For custom, always use the single custom link
            url = _stripeCustomLink;
          } else if (amount == 2) {
            url = 'https://donate.stripe.com/28EaER0lj53Vd5I7Pv8N204'; // Remplacez par votre lien réel 2$/mois
          } else if (amount == 5) {
            url = 'https://donate.stripe.com/4gM00dd850NF4zc3zf8N205'; // Remplacez par votre lien réel 5$/mois
          } else if (amount == 10) {
            url = 'https://donate.stripe.com/6oU8wJaZX2VNfdQc5L8N206';
          } else if (amount == 20) {
            url = 'https://donate.stripe.com/3cI14hfgdbsj0iW6Lr8N207';
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                content: Text(
                  S.of(context)!.donationErrorStripeCustomMonthly,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface2,
                  ),
                ),
              ),
            );
            return;
          }
        } else {
          // Paiement unique Stripe via Payment Links prédéfinis
          if (_isCustomSelected) {
            // For custom, always use the single custom link
            url = _stripeCustomLink;
          } else if (amount == 2) {
            url = 'https://buy.stripe.com/9B63cpgkh2VNc1E1r78N200';
          } else if (amount == 5) {
            url = 'https://buy.stripe.com/bJe7sFc410NF8Ps6Lr8N201';
          } else if (amount == 10) {
            url = 'https://buy.stripe.com/14A8wJ2traof8Ps9XD8N202';
          } else if (amount == 20) {
            url = 'https://buy.stripe.com/7sYdR3c41dArc1Eb1H8N203';
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                content: Text(
                  S.of(context)!.donationErrorStripeCustom,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface2,
                  ),
                ),
              ),
            );
            return;
          }
        }
      } else if (_selectedMethod == 'Bank Transfer') {
        // Show tabbed bank transfer dialog
        showDialog(
          context: context,
          builder: (_) => _BankTransferDialog(amount: amtString),
        );
        return;
      }

      if (url != null) {
        final uri = Uri.parse(url);
        bool launched = false;
        if (await canLaunchUrl(uri)) {
          // Prefer opening in the device browser
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!launched) {
            launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
          }
          if (!launched) {
            launched = await launchUrl(uri, mode: LaunchMode.inAppWebView);
          }
        }
        if (!launched) {
          await Clipboard.setData(ClipboardData(text: url));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                content: Text(
                  'No browser available. Link copied to clipboard.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface2,
                  ),
                ),
              ),
            );
          }
        }
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
           S.of(context)!.donationButton,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image en haut (optionnel, ajoutez asset dans pubspec.yaml)
              SizedBox(
                height: 200,
                child: Image.asset(
                  'assets/donation_banner_clear_966x499.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Text(''));
                  },
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Thank you for considering a donation. I created this app to help deaf people in Bangladesh develop their language skills and to help those who cannot sign and are isolated from the Deaf community by giving them the opportunity to learn proper sign language to communicate. Your donation will help me improve the app. I plan to extend this dictionary to other sign languages, mainly in Asia. If you have ideas or suggestions, please contact me at info@netcreative-swas.net.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
                ),
              ),
              ExpansionTile(
                title: Text(
                  'Disclaimer',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'My company Netcreatif is based in France and no donation will actually be going to a Bangladeshi bank account and is not subject to tax in Bangladesh.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. SECTION MÉTHODES DE PAIEMENT (bouton style)
              Text(
                'Payment method:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (var method in _paymentMethods)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedMethod == method
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.surface2,
                        foregroundColor: _selectedMethod == method
                            ? Theme.of(context).colorScheme.onSecondary
                            : Theme.of(context).colorScheme.onSurface2,                      ),
                      onPressed: () {
                        setState(() {
                          _selectedMethod = method;
                          if (method == 'Bank Transfer' || method == 'Buy me a coffee' || method == 'Ko-Fi.com') {
                            // Réinitialise la sélection de montant
                            _selectedPreset = null;
                            _isCustomSelected = false;
                            _customController.clear();
                          }
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (method == 'Buy me a coffee') ...[
                            Image.asset(
                              'assets/icons/L2L-sign-buy-me-a-coffee.png',
                              height: 20,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                            const SizedBox(width: 6),
                          ] else if (method == 'Ko-Fi.com') ...[
                            Image.asset(
                              'assets/icons/L2L-sign-ko-fi-white.png',
                              height: 20,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(method),
                        ],
                      ),
                    ),
                ],
              ),
              // ESPACE
              const SizedBox(height: 24),

              // 2. SECTION MONTANT (masquée pour Bank Transfer, Buy me a coffee, Ko-Fi)
              if (_selectedMethod != 'Bank Transfer' && _selectedMethod != 'Buy me a coffee' && _selectedMethod != 'Ko-Fi.com') ...[
                Text(
                  'Select amount:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var amt in _presetAmounts)
                      ChoiceChip(
                        label: Text('\$$amt'),
                        selected: !_isCustomSelected && _selectedPreset == amt,
                        backgroundColor: Theme.of(context).colorScheme.surface2,
                        selectedColor: Theme.of(context).colorScheme.secondary,
                        labelStyle: TextStyle(
                          color: (!_isCustomSelected && _selectedPreset == amt)
                              ? Theme.of(context).colorScheme.onSecondary
                              : Theme.of(context).colorScheme.onSurface2,
                        ),
                        // Remove any border styling by not setting side or shape with border
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide.none,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _isCustomSelected = false;
                            _selectedPreset = amt;
                          });
                        },
                      ),
                    ChoiceChip(
                      label: const Text('Custom'),
                      selected: _isCustomSelected,
                      backgroundColor: Theme.of(context).colorScheme.surface2,
                      selectedColor: Theme.of(context).colorScheme.secondary,
                      labelStyle: TextStyle(
                        color: _isCustomSelected
                            ? Theme.of(context).colorScheme.onSecondary
                            : Theme.of(context).colorScheme.onSurface2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide.none,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _isCustomSelected = true;
                          _selectedPreset = null;
                        });
                      },
                    ),
                  ],
                ),
                // NOTE: Custom selection no longer shows an amount input. It just marks a custom flow.
                // ESPACE
                const SizedBox(height: 24),
              ],

              // 3. CHECKBOX RÉCURRENT (affichée selon sélection)
              if ((_selectedMethod == 'Stripe' && !_isCustomSelected && _selectedPreset != null)) ...[
                CheckboxListTile(
                  title: Text(
                    'Make this donation monthly',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  value: _isMonthly,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _isMonthly = val;
                      });
                    }
                  },
                  controlAffinity: ListTileControlAffinity.leading, // case à gauche, texte à droite
                ),
              ] else ...[
                // Réinitialise si non affichée
                Builder(builder: (context) {
                  if (_isMonthly) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _isMonthly = false;
                      });
                    });
                  }
                  return const SizedBox.shrink();
                }),
              ],

              // ESPACE
              const SizedBox(height: 24),

              // 4. BOUTON DONATE
              Container(
                margin: const EdgeInsets.only(bottom: 20.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isProcessing
                        ? Theme.of(context).colorScheme.surface2
                        : Theme.of(context).colorScheme.secondary,
                    foregroundColor: _isProcessing
                        ? Theme.of(context).colorScheme.onSecondary
                        : Theme.of(context).colorScheme.onSecondary,
                  ),
                  onPressed: _isProcessing ? null : _onDonatePressed,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.volunteer_activism_outlined,
                          color: Theme.of(context).colorScheme.onSurface2,
                        ),
                  label: _isProcessing
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
            S.of(context)!.donationButton,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface2,
                                ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BankTransferDialog extends StatefulWidget {
  final String amount;
  const _BankTransferDialog({required this.amount});

  @override
  State<_BankTransferDialog> createState() => _BankTransferDialogState();
}

class _BankTransferDialogState extends State<_BankTransferDialog> {
  Future<void> _copyToClipboard(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        content: Text('$label copied to clipboard', style: TextStyle(color: Theme.of(context).colorScheme.onSurface2)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text(
          'Bank Transfer Instructions',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                tabs: const [
                  Tab(text: 'Euro Account'),
                  Tab(text: 'US Account'),
                ],
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                indicatorColor: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 250, // Fixed height for tab content
                child: TabBarView(
                  children: [
                    // Euro Account Tab
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BankLine(
                            label: 'Account holder',
                            value: 'NetCreatif',
                            onCopy: () => _copyToClipboard('Account holder', 'NetCreatif'),
                          ),
                          const SizedBox(height: 8),
                          _BankLine(
                            label: 'IBAN',
                            value: 'BE44905608281145',
                            onCopy: () => _copyToClipboard('IBAN', 'BE44905608281145'),
                          ),
                          const SizedBox(height: 8),
                          _BankLine(
                            label: 'BIC/SWIFT',
                            value: 'TRWIBEB1XXX',
                            onCopy: () => _copyToClipboard('BIC/SWIFT', 'TRWIBEB1XXX'),
                          ),
                        ],
                      ),
                    ),
                    // US Account Tab
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BankLine(
                            label: 'Name',
                            value: 'NetCreatif',
                            onCopy: () => _copyToClipboard('Name', 'NetCreatif'),
                          ),
                          const SizedBox(height: 8),
                          _BankLine(
                            label: 'Account number',
                            value: '434315636491081',
                            onCopy: () => _copyToClipboard('Account number', '434315636491081'),
                          ),
                          const SizedBox(height: 8),
                          _BankLine(
                            label: 'Account type',
                            value: 'Deposit',
                            onCopy: () => _copyToClipboard('Account type', 'Deposit'),
                          ),
                          const SizedBox(height: 8),
                          _BankLine(
                            label: 'Routing number',
                            value: '084009519',
                            onCopy: () => _copyToClipboard('Routing number', '084009519'),
                          ),
                          const SizedBox(height: 8),
                          _BankLine(
                            label: 'BIC/Swift',
                            value: 'TRWIUS35XXX',
                            onCopy: () => _copyToClipboard('BIC/Swift', 'TRWIUS35XXX'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.amount.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Reference: Donation ${widget.amount}',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                "Please mention 'Donation' in the transfer reference.",
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );
  }
}

class _BankLine extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;
  const _BankLine({required this.label, required this.value, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 2),
              SelectableText(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
            ],
          ),
        ),
        InkWell(
          onTap: onCopy,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.copy, size: 16),
                const SizedBox(width: 4),
                Text('Copy', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}