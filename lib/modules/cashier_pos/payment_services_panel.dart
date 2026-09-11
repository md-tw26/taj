import 'package:flutter/material.dart';

import '../../core/theme/taj_colors.dart';

/// A dedicated panel showing all Libyan electronic payment services
/// with their details, API info, and status.
class PaymentServicesPanel extends StatelessWidget {
  const PaymentServicesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('خدمات الدفع الإلكترونية الليبية'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── CBL Approved Services ─────────────────────────────────────
            _buildSectionHeader(
              taj,
              'الخدمات المعتمدة من البنك المركزي الليبي',
              Icons.verified_outlined,
              taj.primary.main,
            ),
            const SizedBox(height: 12),
            _buildServiceGrid(context, isCompact, _cblApprovedServices, taj),

            const SizedBox(height: 32),

            // ── National Payment Infrastructure ────────────────────────────
            _buildSectionHeader(
              taj,
              'البنية التحتية للدفع الوطني',
              Icons.account_balance_outlined,
              taj.info.main,
            ),
            const SizedBox(height: 12),
            _buildServiceGrid(context, isCompact, _nationalInfrastructure, taj),

            const SizedBox(height: 32),

            // ── Payment Aggregators & Gateways ────────────────────────────
            _buildSectionHeader(
              taj,
              'بوابات الدفع والمجمعات',
              Icons.payment_outlined,
              taj.warning.main,
            ),
            const SizedBox(height: 12),
            _buildServiceGrid(context, isCompact, _paymentGateways, taj),

            const SizedBox(height: 32),

            // ── API Integration Status ────────────────────────────────────
            _buildSectionHeader(
              taj,
              'حالة تكامل الـ API',
              Icons.api_outlined,
              taj.success.main,
            ),
            const SizedBox(height: 12),
            _buildIntegrationStatus(context, taj),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    dynamic taj,
    String title,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceGrid(
    BuildContext context,
    bool isCompact,
    List<PaymentService> services,
    dynamic taj,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children:
          services.map((service) {
            return SizedBox(
              width: isCompact ? double.infinity : 320,
              child: _ServiceCard(service: service, taj: taj),
            );
          }).toList(),
    );
  }

  Widget _buildIntegrationStatus(BuildContext context, dynamic taj) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _IntegrationRow(
              name: 'LYPay',
              status: 'متاح',
              endpoint: '/api/v1/payments/funds-transfers',
              auth: 'Bearer Token',
              statusColor: taj.success.main,
            ),
            const Divider(),
            _IntegrationRow(
              name: 'DPAY',
              status: 'متاح',
              endpoint: '/api/v1/payment/sessions/open',
              auth: 'Laravel Sanctum',
              statusColor: taj.success.main,
            ),
            const Divider(),
            _IntegrationRow(
              name: 'Sadad (سداد)',
              status: 'قريباً',
              endpoint: '—',
              auth: '—',
              statusColor: taj.warning.main,
            ),
            const Divider(),
            _IntegrationRow(
              name: 'NUMO QR',
              status: 'قريباً',
              endpoint: 'Standard EMVCo',
              auth: '—',
              statusColor: taj.warning.main,
            ),
            const Divider(),
            _IntegrationRow(
              name: 'MobiCash',
              status: 'قريباً',
              endpoint: ' عبر DPAY',
              auth: '—',
              statusColor: taj.warning.main,
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.taj});
  final PaymentService service;
  final dynamic taj;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and status
          Container(
            padding: const EdgeInsets.all(12),
            color: service.color.withValues(alpha: 0.08),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: service.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(service.icon, color: service.color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: taj.textPrimary,
                        ),
                      ),
                      Text(
                        service.nameEn,
                        style: TextStyle(
                          fontSize: 11,
                          color: taj.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(
                  status: service.status,
                  color: service.statusColor,
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: taj.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                if (service.features.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children:
                        service.features.map((f) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: service.color.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: service.color.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 10,
                                color: service.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});
  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _IntegrationRow extends StatelessWidget {
  const _IntegrationRow({
    required this.name,
    required this.status,
    required this.endpoint,
    required this.auth,
    required this.statusColor,
  });

  final String name;
  final String status;
  final String endpoint;
  final String auth;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: taj.textPrimary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            endpoint,
            style: TextStyle(
              fontSize: 11,
              color: taj.textSecondary,
            ),
          ),

        ),
        Expanded(
          flex: 2,
          child: Text(
            auth,
            style: TextStyle(fontSize: 11, color: taj.textSecondary),
          ),
        ),
        _StatusBadge(status: status, color: statusColor),
      ],
    );
  }
}

// ── Data Models ──────────────────────────────────────────────────────────────

class PaymentService {
  const PaymentService({
    required this.name,
    required this.nameEn,
    required this.description,
    required this.icon,
    required this.color,
    required this.status,
    required this.statusColor,
    this.features = const [],
  });

  final String name;
  final String nameEn;
  final String description;
  final IconData icon;
  final Color color;
  final String status;
  final Color statusColor;
  final List<String> features;
}

// ── Service Data ─────────────────────────────────────────────────────────────

final _cblApprovedServices = [
  PaymentService(
    name: 'سداد',
    nameEn: 'Sadad (Almadar Aljadid)',
    description:
        'خدمة الدفع الإلكتروني من المدار الجديد. تدعم التحويلات الفورية والدفع عبر الطرق المتعددة.',
    icon: Icons.send_to_mobile_outlined,
    color: const Color(0xFF2196F3),
    status: 'متاح',
    statusColor: const Color(0xFF4CAF50),
    features: ['تحويل فوري', 'دفع عبر الهاتف', 'QR Code', 'Webhook'],
  ),
  PaymentService(
    name: 'ال numo',
    nameEn: 'NUMO (CBL Standard)',
    description:
        'المعيار الوطني لرمز الاستجابة السريع (EMVCo). يدعم الطرق العرضية للمستهلك والتاجر.',
    icon: Icons.qr_code_2_outlined,
    color: const Color(0xFF9C27B0),
    status: 'متاح',
    statusColor: const Color(0xFF4CAF50),
    features: [
      'EMVCo Standard',
      'Consumer-presented',
      'Merchant-presented',
      'Free',
    ],
  ),
  PaymentService(
    name: 'موبايل كاش',
    nameEn: 'MobiCash',
    description:
        'خدمة الدفع عبر الهاتف المحمول. متاحة عبر شبكة MobiCash وبوابات الدفع المتعددة.',
    icon: Icons.phone_android_outlined,
    color: const Color(0xFFFF9800),
    status: 'متاح',
    statusColor: const Color(0xFF4CAF50),
    features: ['Phone Payment', 'USSD', 'QR Code', 'Multi-gateway'],
  ),
  PaymentService(
    name: 'ميزة',
    nameEn: 'Meza',
    description:
        'منصة الدفع الإلكتروني من الاتصالات الليبية. تدعم المحافظ الإلكترونية والدفع عبر البطاقات.',
    icon: Icons.credit_card_outlined,
    color: const Color(0xFF00BCD4),
    status: 'متاح',
    statusColor: const Color(0xFF4CAF50),
    features: ['E-wallet', 'Card Payment', 'Online Payment'],
  ),
  PaymentService(
    name: 'دليل ليبيا',
    nameEn: 'Dalil Libya',
    description:
        'دليل الخدمات والدفع الإلكتروني. يوفر قائمة شاملة بخدمات الدفع المتاحة في ليبيا.',
    icon: Icons.menu_book_outlined,
    color: const Color(0xFF795548),
    status: 'متاح',
    statusColor: const Color(0xFF4CAF50),
    features: ['Service Directory', 'Payment Guide'],
  ),
  PaymentService(
    name: 'تادلول',
    nameEn: 'Tadalul',
    description:
        'منصة الدفع الإلكتروني. تدعم التحويلات المالية والدفع عبر المحافظ الرقمية.',
    icon: Icons.account_balance_wallet_outlined,
    color: const Color(0xFF607D8B),
    status: 'متاح',
    statusColor: const Color(0xFF4CAF50),
    features: ['Digital Wallet', 'Transfer', 'QR Payment'],
  ),
  PaymentService(
    name: 'تافاني',
    nameEn: 'Tafani',
    description:
        'خدمة الدفع الإلكتروني. تدعم الدفع عبر الهاتف والتحويلات المالية الفورية.',
    icon: Icons.phonelink_ring_outlined,
    color: const Color(0xFFE91E63),
    status: 'متاح',
    statusColor: const Color(0xFF4CAF50),
    features: ['Mobile Payment', 'Instant Transfer'],
  ),
  PaymentService(
    name: 'عبور',
    nameEn: 'Oboor',
    description:
        'منصة الدفع والتحويلات المالية. تدعم الدفع عبر الإنترنت والتحويلات البنكية.',
    icon: Icons.language_outlined,
    color: const Color(0xFF3F51B5),
    status: 'متاح',
    statusColor: const Color(0xFF4CAF50),
    features: ['Online Payment', 'Bank Transfer', 'API Available'],
  ),
  PaymentService(
    name: 'مسارات',
    nameEn: 'Masarat',
    description:
        'مسارات الدفع الإلكتروني. توفر حلولاً متكاملة للمتاجر والشركات.',
    icon: Icons.alt_route_outlined,
    color: const Color(0xFF009688),
    status: 'متاح',
    statusColor: const Color(0xFF4CAF50),
    features: ['E-commerce', 'POS Integration', 'API'],
  ),
  PaymentService(
    name: 'إثمار',
    nameEn: 'Ethmar',
    description:
        'منصة الدفع الإسلامي. توفر حلولاً متوافقة مع الشريعة الإسلامية للدفع الإلكتروني.',
    icon: Icons.account_balance_outlined,
    color: const Color(0xFF4CAF50),
    status: 'متاح',
    statusColor: const Color(0xFF4CAF50),
    features: ['Islamic Finance', 'Sharia Compliant', 'Halal Payment'],
  ),
  PaymentService(
    name: 'فوري',
    nameEn: 'Fawry',
    description:
        'خدمة الدفع السريع. تدعم الدفع عبر نقاط البيع والدفع الإلكتروني.',
    icon: Icons.flash_on_outlined,
    color: const Color(0xFFFF5722),
    status: 'متاح',
    statusColor: const Color(0xFF4CAF50),
    features: ['Quick Payment', 'POS Network', 'Bill Payment'],
  ),
  PaymentService(
    name: 'روب باي',
    nameEn: 'RunPay',
    description:
        'منصة الدفع الإلكتروني. توفر حلولاً متكاملة للمتاجر والشركات.Libyan e-payment.',
    icon: Icons.play_circle_outline,
    color: const Color(0xFF8BC34A),
    status: 'متاح',
    statusColor: const Color(0xFF4CAF50),
    features: ['E-commerce', 'Subscription', 'API'],
  ),
  PaymentService(
    name: 'ال_bidaya',
    nameEn: 'Albidaya',
    description:
        'منصة الدفع الأولى. توفر خدمات الدفع عبر الإنترنت والتحويلات المالية.',
    icon: Icons.play_arrow_outlined,
    color: const Color(0xFFCDDC39),
    status: 'متاح',
    statusColor: const Color(0xFF4CAF50),
    features: ['Online Payment', 'Transfer', 'Mobile'],
  ),
  PaymentService(
    name: 'mysahamat',
    nameEn: 'Mousahamat (RunPay)',
    description:
        'خدمة المساهمات والدفع. تدعم الدفع عبر الإنترنت والتحويلات المالية.',
    icon: Icons.group_add_outlined,
    color: const Color(0xFF03A9F4),
    status: 'متاح',
    statusColor: const Color(0xFF4CAF50),
    features: ['Donation', 'Payment', 'Online'],
  ),
];

final _nationalInfrastructure = [
  PaymentService(
    name: 'LYPay',
    nameEn: 'Libyan Payment Gateway',
    description:
        ' بوابة الدفع الرسمية من البنك المركزي Libyan. تدعم التحويلات الفورية والدفع عبر المحافظ الرقمية.',
    icon: Icons.account_balance_outlined,
    color: const Color(0xFF1565C0),
    status: 'متاح',
    statusColor: const Color(0xFF4CAF50),
    features: ['CBL Official', 'Bearer Token', 'Webhooks', 'Two-step'],
  ),
  PaymentService(
    name: 'DPAY',
    nameEn: 'Multi-Gateway Platform',
    description:
        'منصة الدفع المتعدد. تدعم Moamalat, MobiCash, Edfali, OnePay والمزيد.',
    icon: Icons.hub_outlined,
    color: const Color(0xFF7B1FA2),
    status: 'متاح',
    statusColor: const Color(0xFF4CAF50),
    features: ['Multi-gateway', 'Sanctum Auth', 'Free', 'Laravel'],
  ),
];

final _paymentGateways = [
  PaymentService(
    name: 'موحد',
    nameEn: 'Unified Gateway',
    description: ' بوابة الدفع الموحدة. تجمع جميع خدمات الدفع في واجهة واحدة.',
    icon: Icons.merge_outlined,
    color: const Color(0xFF0277BD),
    status: 'قريباً',
    statusColor: const Color(0xFFFFC107),
    features: ['Unified API', 'All Services', 'Single Integration'],
  ),
  PaymentService(
    name: 'Local Pay',
    nameEn: 'Local Payment Hub',
    description:
        'مركز الدفع المحلي. يوفر واجهة موحدة لجميع خدمات الدفع الليبية.',
    icon: Icons.location_on_outlined,
    color: const Color(0xFF558B2F),
    status: 'قريباً',
    statusColor: const Color(0xFFFFC107),
    features: ['Local Focus', 'Unified', 'All Banks'],
  ),
];

