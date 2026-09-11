import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/taj_colors.dart';
import '../../core/responsive.dart';
import '../../core/format.dart';
import '../../core/sale_sound.dart';
import '../../core/user_role.dart';
import '../../core/demo/demo_models.dart';
import '../../core/demo/demo_provider.dart';
import 'payment_services_panel.dart';

/// Cashier POS screen — ultimate point of sale interface.
/// Combines best practices from Odoo, Shopify, Dripos, LuoPos, CAKE POS, Mashgin.
/// Features: category sidebar, grid/list toggle, quantity badges, smart search.
class CashierPosScreen extends StatefulWidget {
  const CashierPosScreen({
    super.key,
    required this.branchName,
    required this.userName,
    this.permissions = UserPermissions.cashier,
    this.initialCart,
    this.testOpenReports = false,
    required this.onLogout,
    required this.onToggleTheme,
  });

  final String branchName;
  final String userName;
  final UserPermissions permissions;
  final Map<String, int>? initialCart;
  final bool testOpenReports;
  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;

  @override
  State<CashierPosScreen> createState() => _CashierPosScreenState();
}

class _CashierPosScreenState extends State<CashierPosScreen>
    with SingleTickerProviderStateMixin {
  final Map<String, int> _cart = {};
  String _searchQuery = '';
  String _selectedCategory = 'الكل';
  bool _isOnline = true;
  bool _isGridView = true;
  bool _isSidebarCollapsed = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Simple vs. Professional mode. Persisted per-user via shared_preferences.
  bool _isProfessional = false;

  // Professional features state.
  final List<_HeldOrder> _heldOrders = [];
  bool _shiftOpen = false;
  String? _linkedCustomer;
  String? _editingLineId;

  // Professional: per-line price overrides + order-level discount + note.
  final Map<String, double> _priceOverrides = {};
  double _discountPercent = 0;
  String _orderNote = '';

  // Completed sales this session (order history / Z-report data).
  final List<_CompletedSale> _completedSales = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialCart != null) {
      _cart.addAll(widget.initialCart!);
    }
    _loadProfessionalMode();
    if (widget.testOpenReports) {
      _seedTestSales();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showReportsSheet();
      });
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _seedTestSales() {
    final now = DateTime.now();
    _completedSales.addAll([
      _CompletedSale(
        method: PaymentMethod.cash,
        total: 250,
        itemCount: 3,
        time: now,
      ),
      _CompletedSale(
        method: PaymentMethod.cash,
        total: 90,
        itemCount: 1,
        time: now,
      ),
      _CompletedSale(
        method: PaymentMethod.sadad,
        total: 150,
        itemCount: 2,
        time: now,
      ),
      _CompletedSale(
        method: PaymentMethod.bank,
        total: 320,
        itemCount: 4,
        time: now,
      ),
    ]);
  }

  static const _professionalModePrefKey = 'pos_mode_professional_';

  Future<void> _loadProfessionalMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_professionalModePrefKey + widget.userName);
    if (saved != null && mounted) {
      setState(() => _isProfessional = saved);
    }
  }

  Future<void> _toggleProfessionalMode() async {
    final next = !_isProfessional;
    setState(() => _isProfessional = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_professionalModePrefKey + widget.userName, next);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ── Categories ──────────────────────────────────────────────────────────

  List<_Product> get _products =>
      DemoStoreProvider.of(context).products
          .map(
            (p) => _Product(
              id: p.id,
              name: p.name,
              barcode: p.barcode,
              category: p.category,
              price: p.price,
              stock: p.stock,
            ),
          )
          .toList();

  List<String> get _customers =>
      DemoStoreProvider.of(context).customers.map((c) => c.name).toList();

  List<String> get _categories {
    final cats = _products.map((p) => p.category).toSet().toList();
    return ['الكل', ...cats];
  }

  // ── Filtered products ───────────────────────────────────────────────────

  List<_Product> get _filteredProducts {
    var list = _products;
    if (_selectedCategory != 'الكل') {
      list = list.where((p) => p.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list =
          list.where((p) {
            return p.name.toLowerCase().contains(q) ||
                p.barcode.toLowerCase().contains(q);
          }).toList();
    }
    return list;
  }

  // ── Cart calculations ───────────────────────────────────────────────────

  /// Effective unit price for a cart line (list price or professional override).
  double _linePrice(String productId) =>
      _priceOverrides[productId] ??
      _products.firstWhere((p) => p.id == productId).price;

  double get _subtotal =>
      _cart.entries.fold(0, (sum, e) => sum + (_linePrice(e.key) * e.value));

  double get _discountedTotal => _subtotal * (1 - _discountPercent / 100);

  int get _itemCount => _cart.values.fold(0, (sum, q) => sum + q);

  int get _sessionSaleCount => _completedSales.length;

  double get _sessionCashTotal => _completedSales
      .where((s) => s.method == PaymentMethod.cash)
      .fold(0, (sum, s) => sum + s.total);

  // ── Cart operations ─────────────────────────────────────────────────────

  void _addToCart(String productId) {
    setState(() {
      _cart[productId] = (_cart[productId] ?? 0) + 1;
    });
    HapticFeedback.mediumImpact();
  }

  void _incrementQuantity(String productId) {
    setState(() {
      _cart[productId] = (_cart[productId] ?? 0) + 1;
    });
  }

  void _decrementQuantity(String productId) {
    setState(() {
      final current = _cart[productId] ?? 0;
      if (current <= 1) {
        _cart.remove(productId);
      } else {
        _cart[productId] = current - 1;
      }
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      _cart.remove(productId);
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
    });
  }

  // ── One-tap Cash Sale (no confirmation dialog — instant checkout) ──────────

  void _completeCashSale() {
    if (_cart.isEmpty) return;
    HapticFeedback.mediumImpact();
    _showSuccessReceipt(PaymentMethod.cash);
  }

  // ── Professional: Recall a held order ──────────────────────────────────────

  void _recallOrder(_HeldOrder order) {
    HapticFeedback.mediumImpact();
    setState(() {
      _heldOrders.removeWhere((o) => o.id == order.id);
      _cart
        ..clear()
        ..addAll(order.cart);
      _discountPercent = 0;
      _orderNote = '';
    });
    _searchFocusNode.requestFocus();
  }

  // ── Professional: Order discount ───────────────────────────────────────────

  void _setDiscount(double percent) {
    setState(() {
      _discountPercent = percent.clamp(0, 100).toDouble();
    });
  }

  // ── Professional: Link a customer ──────────────────────────────────────────

  void _pickCustomer() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder:
          (_) => _CustomerPickerSheet(
            selected: _linkedCustomer,
            customers: _customers,
            onSelect: (name) {
              Navigator.of(context).pop();
              setState(() => _linkedCustomer = name);
            },
          ),
    );
  }

  // ── Professional: Hold / Park ─────────────────────────────────────────────────

  void _holdOrder() {
    if (_cart.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _heldOrders.add(
        _HeldOrder(
          id: 'H${_heldOrders.length + 1}',
          name: 'طلب ${_heldOrders.length + 1}',
          itemCount: _itemCount,
          subtotal: _subtotal,
          cart: Map<String, int>.from(_cart),
        ),
      );
      _cart.clear();
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = 'الكل';
    });
    _searchFocusNode.requestFocus();
  }

  // ── Professional: Split payment ───────────────────────────────────────────────

  void _splitPayment() {
    if (_cart.isEmpty) return;
    _showSplitPaymentSheet();
  }

  void _showSplitPaymentSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (_) => _SplitPaymentSheet(
            subtotal: _discountedTotal,
            onConfirm: (method, amounts) {
              Navigator.of(context).pop();
              _showSuccessReceipt(method);
            },
          ),
    );
  }

  // ── Professional: Shift open / close ─────────────────────────────────────────

  void _toggleShift() {
    HapticFeedback.mediumImpact();
    setState(() => _shiftOpen = !_shiftOpen);
    if (!_shiftOpen) {
      _showShiftClosedSheet();
    }
  }

  void _showShiftClosedSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (_) => _ShiftClosedSheet(
            totalSales: _completedSales.fold(0, (s, c) => s + c.total),
            transactionCount: _completedSales.length,
            cashTotal: _sessionCashTotal,
            itemCount: _completedSales.fold(0, (s, c) => s + c.itemCount),
          ),
    );
  }

  // ── Professional: Session report ─────────────────────────────────────────────

  void _showReportsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (_) => _ReportsSheet(
            sales: _completedSales,
            totalSales: _completedSales.fold(0, (s, c) => s + c.total),
            cashTotal: _sessionCashTotal,
            itemCount: _completedSales.fold(0, (s, c) => s + c.itemCount),
            onCloseShift: () {
              Navigator.of(context).pop();
              if (_shiftOpen) _toggleShift();
            },
          ),
    );
  }

  // ── Professional: Edit cart line ─────────────────────────────────────────────

  void _editLine(String productId) {
    if (!_isProfessional) return;
    final product = _products.firstWhere((p) => p.id == productId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (_) => _CartLineEditSheet(
            product: product,
            initialQuantity: _cart[productId] ?? 1,
            initialPrice: _linePrice(productId),
            canChangePrice: widget.permissions.changePrice,
            onSave: (newQty, newPrice) {
              Navigator.of(context).pop();
              setState(() {
                if (newQty == 0) {
                  _cart.remove(productId);
                  _priceOverrides.remove(productId);
                } else {
                  _cart[productId] = newQty;
                  if (widget.permissions.changePrice) {
                    if (newPrice != product.price) {
                      _priceOverrides[productId] = newPrice;
                    } else {
                      _priceOverrides.remove(productId);
                    }
                  }
                }
              });
            },
            onRemove: () {
              Navigator.of(context).pop();
              setState(() {
                _cart.remove(productId);
                _priceOverrides.remove(productId);
              });
            },
          ),
    );
  }

  // ── Payment dialogs ─────────────────────────────────────────────────────

  void _confirmPrePayment(PaymentMethod method) {
    if (_cart.isEmpty) return;
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder:
          (ctx) => _PaymentDialog(
            subtotal: _discountedTotal,
            itemCount: _itemCount,
            method: method,
            isProfessional: _isProfessional,
            onConfirm: () {
              Navigator.of(ctx).pop();
              _showSuccessReceipt(method);
            },
            onSplit:
                _isProfessional
                    ? () {
                      Navigator.of(ctx).pop();
                      _showSplitPaymentSheet();
                    }
                    : null,
          ),
    );
  }

  Future<void> _showSuccessReceipt(PaymentMethod method) async {
    final total = _discountedTotal;
    final methodName = switch (method) {
      PaymentMethod.cash => 'نقدي',
      PaymentMethod.credit => 'آجل',
      PaymentMethod.bank => 'تحويل مصرفي',
      PaymentMethod.sadad => 'سداد',
      PaymentMethod.numoQr => 'NUMO QR',
      PaymentMethod.mobicash => 'MobiCash',
      PaymentMethod.bankTransfer => 'تحويل الى حساب',
      PaymentMethod.bankTransferSadad => 'تحويل عبر سداد',
      PaymentMethod.bankTransferMobCash => 'تحويل عبر MobiCash',
    };
    final soldLines =
        _cart.entries.map((e) {
          final p = _products.firstWhere((x) => x.id == e.key);
          return (p, e.value, _linePrice(e.key));
        }).toList();
    final itemCount = _itemCount;
    final note = _orderNote;
    try {
      await DemoStoreProvider.of(context).addSale(
        quantities: Map<String, int>.from(_cart),
        paymentMethod: _demoPaymentMethod(method),
        branchId: 'b1',
        totalOverride: total,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
      return;
    }
    setState(() {
      _completedSales.add(
        _CompletedSale(
          method: method,
          total: total,
          itemCount: itemCount,
          time: DateTime.now(),
        ),
      );
      _cart.clear();
      _priceOverrides.clear();
      _discountPercent = 0;
      _orderNote = '';
    });
    _searchController.clear();
    _searchQuery = '';
    _selectedCategory = 'الكل';
    _searchFocusNode.requestFocus();

    // Play sale sound after completing the sale (cash one-tap included).
    SaleSound.instance.play();

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            content: ConstrainedBox(
              // Cap the width on desktop but allow it to shrink on small phones
              // (a hard width: 340 overflowed inside the dialog's inset margins).
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.taj.success.lighter,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 36,
                      color: context.taj.success.dark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'تم البيع بنجاح',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    arDinar(total),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.taj.accentText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$itemCount منتج • $methodName',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.taj.textSecondary),
                  ),
                  if (soldLines.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Divider(height: 1, color: context.taj.divider),
                    const SizedBox(height: 6),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              for (final (p, q, price) in soldLines)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 3,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${p.name} × $q',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: context.taj.textSecondary,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        arDinar(price * q),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: context.taj.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'ملاحظة: $note',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.taj.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('تم'),
                ),
              ),
            ],
          ),
    );
  }

  DemoPaymentMethod _demoPaymentMethod(PaymentMethod method) =>
      switch (method) {
        PaymentMethod.cash => DemoPaymentMethod.cash,
        PaymentMethod.credit => DemoPaymentMethod.credit,
        PaymentMethod.bank ||
        PaymentMethod.bankTransfer ||
        PaymentMethod.bankTransferSadad ||
        PaymentMethod.bankTransferMobCash => DemoPaymentMethod.bank,
        PaymentMethod.sadad ||
        PaymentMethod.numoQr ||
        PaymentMethod.mobicash => DemoPaymentMethod.card,
      };

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final isWide = MediaQuery.sizeOf(context).width >= AppBreakpoints.splitPane;

    return Scaffold(
      backgroundColor: taj.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ──
            _TopBar(
              branchName: widget.branchName,
              userName: widget.userName,
              isOnline: _isOnline,
              isGridView: _isGridView,
              isProfessional: _isProfessional,
              onToggleMode: _toggleProfessionalMode,
              onToggleTheme: widget.onToggleTheme,
              onLogout: widget.onLogout,
              onToggleOnline: () => setState(() => _isOnline = !_isOnline),
              onToggleView: () => setState(() => _isGridView = !_isGridView),
              onOpenReports: _isProfessional ? _showReportsSheet : null,
            ),

            // ── Main content ──
            Expanded(
              child:
                  isWide
                      ? _WideLayout(
                        products: _filteredProducts,
                        categories: _categories,
                        selectedCategory: _selectedCategory,
                        isSidebarCollapsed: _isSidebarCollapsed,
                        cart: _cart,
                        subtotal: _subtotal,
                        itemCount: _itemCount,
                        isGridView: _isGridView,
                        isProfessional: _isProfessional,
                        canChangePrice: widget.permissions.changePrice,
                        heldOrders: _heldOrders,
                        shiftOpen: _shiftOpen,
                        linkedCustomer: _linkedCustomer,
                        isEditingLine: _editingLineId,
                        searchQuery: _searchQuery,
                        searchController: _searchController,
                        searchFocusNode: _searchFocusNode,
                        onSearchChanged:
                            (v) => setState(() => _searchQuery = v),
                        onCategoryChanged:
                            (v) => setState(() => _selectedCategory = v),
                        onToggleSidebar:
                            () => setState(
                              () => _isSidebarCollapsed = !_isSidebarCollapsed,
                            ),
                        onAddToCart: _addToCart,
                        onIncrement: _incrementQuantity,
                        onDecrement: _decrementQuantity,
                        onRemove: _removeFromCart,
                        onClearCart: _clearCart,
                        onPayCash: _completeCashSale,
                        onPayCredit:
                            () => _confirmPrePayment(PaymentMethod.credit),
                        onPayBank: () => _confirmPrePayment(PaymentMethod.bank),
                        onPaySadad:
                            () => _confirmPrePayment(PaymentMethod.sadad),
                        onPayNumoQr:
                            () => _confirmPrePayment(PaymentMethod.numoQr),
                        onPayMobicash:
                            () => _confirmPrePayment(PaymentMethod.mobicash),
                        onPayBankTransfer:
                            () =>
                                _confirmPrePayment(PaymentMethod.bankTransfer),
                        onPayBankTransferSadad:
                            () => _confirmPrePayment(
                              PaymentMethod.bankTransferSadad,
                            ),
                        onPayBankTransferMobCash:
                            () => _confirmPrePayment(
                              PaymentMethod.bankTransferMobCash,
                            ),
                        onHoldOrder: _holdOrder,
                        onSplitPayment: _splitPayment,
                        onPressShift: _toggleShift,
                        onEditLine: _editLine,
                        onRecallOrder: _recallOrder,
                        onLinkCustomer: _pickCustomer,
                        discountPercent: _discountPercent,
                        onDiscountChanged: _setDiscount,
                        priceOverrides: _priceOverrides,
                        orderNote: _orderNote,
                        onOrderNoteChanged:
                            (v) => setState(() => _orderNote = v),
                        sessionSaleCount: _sessionSaleCount,
                        sessionCashTotal: _sessionCashTotal,
                      )
                      : _NarrowLayout(
                        products: _filteredProducts,
                        categories: _categories,
                        selectedCategory: _selectedCategory,
                        cart: _cart,
                        subtotal: _subtotal,
                        itemCount: _itemCount,
                        isGridView: _isGridView,
                        isProfessional: _isProfessional,
                        canChangePrice: widget.permissions.changePrice,
                        heldOrders: _heldOrders,
                        shiftOpen: _shiftOpen,
                        linkedCustomer: _linkedCustomer,
                        isEditingLine: _editingLineId,
                        searchQuery: _searchQuery,
                        searchController: _searchController,
                        searchFocusNode: _searchFocusNode,
                        onSearchChanged:
                            (v) => setState(() => _searchQuery = v),
                        onCategoryChanged:
                            (v) => setState(() => _selectedCategory = v),
                        onAddToCart: _addToCart,
                        onIncrement: _incrementQuantity,
                        onDecrement: _decrementQuantity,
                        onRemove: _removeFromCart,
                        onClearCart: _clearCart,
                        onPayCash: _completeCashSale,
                        onPayCredit:
                            () => _confirmPrePayment(PaymentMethod.credit),
                        onPayBank: () => _confirmPrePayment(PaymentMethod.bank),
                        onPaySadad:
                            () => _confirmPrePayment(PaymentMethod.sadad),
                        onPayNumoQr:
                            () => _confirmPrePayment(PaymentMethod.numoQr),
                        onPayMobicash:
                            () => _confirmPrePayment(PaymentMethod.mobicash),
                        onPayBankTransfer:
                            () =>
                                _confirmPrePayment(PaymentMethod.bankTransfer),
                        onPayBankTransferSadad:
                            () => _confirmPrePayment(
                              PaymentMethod.bankTransferSadad,
                            ),
                        onPayBankTransferMobCash:
                            () => _confirmPrePayment(
                              PaymentMethod.bankTransferMobCash,
                            ),
                        onHoldOrder: _holdOrder,
                        onSplitPayment: _splitPayment,
                        onPressShift: _toggleShift,
                        onEditLine: _editLine,
                        onRecallOrder: _recallOrder,
                        onLinkCustomer: _pickCustomer,
                        discountPercent: _discountPercent,
                        onDiscountChanged: _setDiscount,
                        priceOverrides: _priceOverrides,
                        orderNote: _orderNote,
                        onOrderNoteChanged:
                            (v) => setState(() => _orderNote = v),
                        sessionSaleCount: _sessionSaleCount,
                        sessionCashTotal: _sessionCashTotal,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Payment Methods ──────────────────────────────────────────────────────────

enum PaymentMethod {
  cash,
  credit,
  bank,
  sadad,
  numoQr,
  mobicash,
  bankTransfer,
  bankTransferSadad,
  bankTransferMobCash,
}

IconData _categoryIcon(String category) => switch (category) {
  'قمصان' => Icons.checkroom_outlined,
  'بناطيل' => Icons.style_outlined,
  'فساتين' => Icons.woman_outlined,
  'جاكيتات' => Icons.thermostat_outlined,
  'أحذية' => Icons.directions_walk_outlined,
  'حقائب' => Icons.shopping_bag_outlined,
  'إكسسوارات' => Icons.watch_outlined,
  _ => Icons.inventory_2_outlined,
};

// ── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.branchName,
    required this.userName,
    required this.isOnline,
    required this.isGridView,
    required this.isProfessional,
    required this.onToggleMode,
    required this.onToggleTheme,
    required this.onLogout,
    required this.onToggleOnline,
    required this.onToggleView,
    this.onOpenReports,
  });

  final String branchName;
  final String userName;
  final bool isOnline;
  final bool isGridView;
  final bool isProfessional;
  final VoidCallback onToggleMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;
  final VoidCallback onToggleOnline;
  final VoidCallback onToggleView;
  final VoidCallback? onOpenReports;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initial =
        userName.isEmpty ? '؟' : String.fromCharCode(userName.runes.first);

    // Simple ↔ Professional segmented toggle (full, desktop/tablet form).
    final modeToggle = SegmentedButton<bool>(
      segments: const [
        ButtonSegment(
          value: false,
          icon: Icon(Icons.touch_app_outlined, size: 15),
          label: Text('بسيط'),
        ),
        ButtonSegment(
          value: true,
          icon: Icon(Icons.workspace_premium_outlined, size: 15),
          label: Text('محترف'),
        ),
      ],
      selected: {isProfessional},
      onSelectionChanged: (_) => onToggleMode(),
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.almarai(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        side: WidgetStatePropertyAll(BorderSide(color: taj.divider)),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? taj.primary.dark
                  : taj.textSecondary,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? taj.primary.lighter
                  : Colors.transparent,
        ),
      ),
    );

    final viewToggle = IconButton(
      tooltip: isGridView ? 'عرض القائمة' : 'عرض الشبكة',
      onPressed: onToggleView,
      icon: Icon(
        isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
        size: 20,
      ),
    );

    return LayoutBuilder(
      builder: (context, c) {
        // The cashier bar carries a lot of controls. Below this width they can't
        // all fit beside the operator name without overflowing, so the mode
        // toggle collapses to a single icon and the low-frequency actions
        // (reports / theme / logout) move into an overflow menu.
        final narrow = c.maxWidth < 720;

        return Container(
          height: 60,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: taj.paper,
            border: Border(bottom: BorderSide(color: taj.divider)),
          ),
          child: Row(
            children: [
              // Operator avatar + name + branch
              CircleAvatar(
                radius: 17,
                backgroundColor: taj.primary.lighter,
                child: Text(
                  initial.toUpperCase(),
                  style: TextStyle(
                    color: taj.primary.dark,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: taj.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      branchName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: taj.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 26, color: taj.divider),
              const SizedBox(width: 12),

              // Online badge
              _OnlineBadge(isOnline: isOnline, onTap: onToggleOnline),

              const Spacer(),

              if (!narrow) ...[
                modeToggle,
                viewToggle,
                if (isProfessional && onOpenReports != null)
                  IconButton(
                    tooltip: 'تقارير الجلسة',
                    onPressed: onOpenReports,
                    icon: const Icon(Icons.bar_chart_rounded, size: 20),
                  ),
                IconButton(
                  tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
                  onPressed: onToggleTheme,
                  icon: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    size: 20,
                  ),
                ),
                IconButton(
                  tooltip: 'تسجيل الخروج',
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_outlined, size: 20),
                ),
              ] else ...[
                // Compact: single-icon mode toggle + view toggle + overflow menu.
                IconButton(
                  tooltip: isProfessional ? 'الوضع المحترف' : 'الوضع البسيط',
                  onPressed: onToggleMode,
                  icon: Icon(
                    isProfessional
                        ? Icons.workspace_premium_outlined
                        : Icons.touch_app_outlined,
                    size: 20,
                    color: taj.primary.dark,
                  ),
                ),
                viewToggle,
                PopupMenuButton<String>(
                  tooltip: 'المزيد',
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  onSelected: (v) {
                    switch (v) {
                      case 'reports':
                        onOpenReports?.call();
                      case 'theme':
                        onToggleTheme();
                      case 'logout':
                        onLogout();
                    }
                  },
                  itemBuilder:
                      (_) => [
                        if (isProfessional && onOpenReports != null)
                          const PopupMenuItem(
                            value: 'reports',
                            child: ListTile(
                              leading: Icon(Icons.bar_chart_rounded),
                              title: Text('تقارير الجلسة'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        PopupMenuItem(
                          value: 'theme',
                          child: ListTile(
                            leading: Icon(
                              isDark
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode_outlined,
                            ),
                            title: Text(
                              isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'logout',
                          child: ListTile(
                            leading: Icon(Icons.logout_outlined),
                            title: Text('تسجيل الخروج'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge({required this.isOnline, required this.onTap});
  final bool isOnline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final color = isOnline ? taj.success : taj.warning;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.lighter,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color.main,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isOnline ? 'متصل' : 'غير متصل',
              style: TextStyle(
                color: color.dark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Wide Layout (Desktop) ────────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.products,
    required this.categories,
    required this.selectedCategory,
    required this.isSidebarCollapsed,
    required this.cart,
    required this.subtotal,
    required this.itemCount,
    required this.isGridView,
    required this.isProfessional,
    required this.canChangePrice,
    required this.heldOrders,
    required this.shiftOpen,
    required this.linkedCustomer,
    required this.isEditingLine,
    required this.searchQuery,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onToggleSidebar,
    required this.onAddToCart,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onClearCart,
    required this.onPayCash,
    required this.onPayCredit,
    required this.onPayBank,
    required this.onPaySadad,
    required this.onPayNumoQr,
    required this.onPayMobicash,
    required this.onPayBankTransfer,
    required this.onPayBankTransferSadad,
    required this.onPayBankTransferMobCash,
    required this.onHoldOrder,
    required this.onSplitPayment,
    required this.onPressShift,
    required this.onEditLine,
    required this.onRecallOrder,
    required this.onLinkCustomer,
    required this.discountPercent,
    required this.onDiscountChanged,
    required this.priceOverrides,
    required this.orderNote,
    required this.onOrderNoteChanged,
    required this.sessionSaleCount,
    required this.sessionCashTotal,
  });

  final List<_Product> products;
  final List<String> categories;
  final String selectedCategory;
  final bool isSidebarCollapsed;
  final Map<String, int> cart;
  final double subtotal;
  final int itemCount;
  final bool isGridView;
  final bool isProfessional;
  final bool canChangePrice;
  final List<_HeldOrder> heldOrders;
  final bool shiftOpen;
  final String? linkedCustomer;
  final String? isEditingLine;
  final String searchQuery;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onToggleSidebar;
  final ValueChanged<String> onAddToCart;
  final ValueChanged<String> onIncrement;
  final ValueChanged<String> onDecrement;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearCart;
  final VoidCallback onPayCash;
  final VoidCallback onPayCredit;
  final VoidCallback onPayBank;
  final VoidCallback onPaySadad;
  final VoidCallback onPayNumoQr;
  final VoidCallback onPayMobicash;
  final VoidCallback onPayBankTransfer;
  final VoidCallback onPayBankTransferSadad;
  final VoidCallback onPayBankTransferMobCash;
  final VoidCallback onHoldOrder;
  final VoidCallback onSplitPayment;
  final VoidCallback onPressShift;
  final ValueChanged<String> onEditLine;
  final ValueChanged<_HeldOrder> onRecallOrder;
  final VoidCallback onLinkCustomer;
  final double discountPercent;
  final ValueChanged<double> onDiscountChanged;
  final Map<String, double> priceOverrides;
  final String orderNote;
  final ValueChanged<String> onOrderNoteChanged;
  final int sessionSaleCount;
  final double sessionCashTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Category Sidebar (collapsible, like Odoo)
        _CategorySidebar(
          categories: categories,
          selectedCategory: selectedCategory,
          isCollapsed: isSidebarCollapsed,
          onCategoryChanged: onCategoryChanged,
          onToggleCollapse: onToggleSidebar,
        ),

        // Products (dominant area, ~56%)
        Expanded(
          flex: 5,
          child: _ProductSection(
            products: products,
            cart: cart,
            isGridView: isGridView,
            searchQuery: searchQuery,
            searchController: searchController,
            searchFocusNode: searchFocusNode,
            onSearchChanged: onSearchChanged,
            onProductTap: onAddToCart,
            canChangePrice: canChangePrice,
          ),
        ),

        // Cart / invoice (~44%, enlarged)
        Expanded(
          flex: 4,
          child: _CartSection(
            products: products,
            lowStockCount: products.where((p) => p.stock <= 5).length,
            cart: cart,
            subtotal: subtotal,
            itemCount: itemCount,
            isProfessional: isProfessional,
            canChangePrice: canChangePrice,
            heldOrders: heldOrders,
            shiftOpen: shiftOpen,
            linkedCustomer: linkedCustomer,
            isEditingLine: isEditingLine,
            priceOverrides: priceOverrides,
            discountPercent: discountPercent,
            onDiscountChanged: onDiscountChanged,
            orderNote: orderNote,
            onOrderNoteChanged: onOrderNoteChanged,
            sessionSaleCount: sessionSaleCount,
            sessionCashTotal: sessionCashTotal,
            onRecallOrder: onRecallOrder,
            onLinkCustomer: onLinkCustomer,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
            onRemove: onRemove,
            onClearCart: onClearCart,
            onPayCash: onPayCash,
            onPayCredit: onPayCredit,
            onPayBank: onPayBank,
            onPaySadad: onPaySadad,
            onPayNumoQr: onPayNumoQr,
            onPayMobicash: onPayMobicash,
            onPayBankTransfer: onPayBankTransfer,
            onPayBankTransferSadad: onPayBankTransferSadad,
            onPayBankTransferMobCash: onPayBankTransferMobCash,
            onHoldOrder: onHoldOrder,
            onSplitPayment: onSplitPayment,
            onPressShift: onPressShift,
            onEditLine: onEditLine,
          ),
        ),
      ],
    );
  }
}

// ── Category Sidebar (Odoo-style collapsible) ───────────────────────────────

class _CategorySidebar extends StatelessWidget {
  const _CategorySidebar({
    required this.categories,
    required this.selectedCategory,
    required this.isCollapsed,
    required this.onCategoryChanged,
    required this.onToggleCollapse,
  });

  final List<String> categories;
  final String selectedCategory;
  final bool isCollapsed;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isCollapsed ? 56 : 160,
      decoration: BoxDecoration(
        color: taj.paper,
        border: Border(left: BorderSide(color: taj.divider)),
      ),
      child: Column(
        children: [
          // Header with toggle
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 4 : 8,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: taj.divider)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onToggleCollapse,
                  icon: Icon(
                    isCollapsed
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                    size: 20,
                  ),
                  tooltip: isCollapsed ? 'توسيع' : 'طي',
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'الفئات',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: taj.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Category list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final cat = categories[i];
                final isSelected = cat == selectedCategory;
                final catColor = _categoryColor(cat, taj);

                return InkWell(
                  onTap: () => onCategoryChanged(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isCollapsed ? 0 : 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? catColor.lighter : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? catColor.main : Colors.transparent,
                        width: isSelected ? 2 : 0,
                      ),
                    ),
                    child:
                        isCollapsed
                            ? Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: catColor.main,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                            : Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: catColor.main,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? catColor.dark
                                              : taj.textPrimary,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  TajSwatch _categoryColor(String category, TajColors taj) =>
      _tajCategoryColor(category, taj);
}

// ── Narrow Layout (Mobile) ───────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.products,
    required this.categories,
    required this.selectedCategory,
    required this.cart,
    required this.subtotal,
    required this.itemCount,
    required this.isGridView,
    required this.isProfessional,
    required this.canChangePrice,
    required this.heldOrders,
    required this.shiftOpen,
    required this.linkedCustomer,
    required this.isEditingLine,
    required this.searchQuery,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onAddToCart,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onClearCart,
    required this.onPayCash,
    required this.onPayCredit,
    required this.onPayBank,
    required this.onPaySadad,
    required this.onPayNumoQr,
    required this.onPayMobicash,
    required this.onPayBankTransfer,
    required this.onPayBankTransferSadad,
    required this.onPayBankTransferMobCash,
    required this.onHoldOrder,
    required this.onSplitPayment,
    required this.onPressShift,
    required this.onEditLine,
    required this.onRecallOrder,
    required this.onLinkCustomer,
    required this.discountPercent,
    required this.onDiscountChanged,
    required this.priceOverrides,
    required this.orderNote,
    required this.onOrderNoteChanged,
    required this.sessionSaleCount,
    required this.sessionCashTotal,
  });

  final List<_Product> products;
  final List<String> categories;
  final String selectedCategory;
  final Map<String, int> cart;
  final double subtotal;
  final int itemCount;
  final bool isGridView;
  final bool isProfessional;
  final bool canChangePrice;
  final List<_HeldOrder> heldOrders;
  final bool shiftOpen;
  final String? linkedCustomer;
  final String? isEditingLine;
  final String searchQuery;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onAddToCart;
  final ValueChanged<String> onIncrement;
  final ValueChanged<String> onDecrement;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearCart;
  final VoidCallback onPayCash;
  final VoidCallback onPayCredit;
  final VoidCallback onPayBank;
  final VoidCallback onPaySadad;
  final VoidCallback onPayNumoQr;
  final VoidCallback onPayMobicash;
  final VoidCallback onPayBankTransfer;
  final VoidCallback onPayBankTransferSadad;
  final VoidCallback onPayBankTransferMobCash;
  final VoidCallback onHoldOrder;
  final VoidCallback onSplitPayment;
  final VoidCallback onPressShift;
  final ValueChanged<String> onEditLine;
  final ValueChanged<_HeldOrder> onRecallOrder;
  final VoidCallback onLinkCustomer;
  final double discountPercent;
  final ValueChanged<double> onDiscountChanged;
  final Map<String, double> priceOverrides;
  final String orderNote;
  final ValueChanged<String> onOrderNoteChanged;
  final int sessionSaleCount;
  final double sessionCashTotal;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category chips (horizontal scroll)
        _CategoryChips(
          categories: categories,
          selectedCategory: selectedCategory,
          onCategoryChanged: onCategoryChanged,
        ),

        // Products
        Expanded(
          child: _ProductSection(
            products: products,
            cart: cart,
            isGridView: isGridView,
            searchQuery: searchQuery,
            searchController: searchController,
            searchFocusNode: searchFocusNode,
            onSearchChanged: onSearchChanged,
            onProductTap: onAddToCart,
            canChangePrice: canChangePrice,
          ),
        ),
        if (cart.isNotEmpty)
          _MobileCartBar(
            itemCount: itemCount,
            subtotal: subtotal,
            onTap: () => _showCartSheet(context),
          ),
      ],
    );
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (_) => DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder:
                (ctx, controller) => _CartSection(
                  products: products,
                  lowStockCount: products.where((p) => p.stock <= 5).length,
                  cart: cart,
                  subtotal: subtotal,
                  itemCount: itemCount,
                  isProfessional: isProfessional,
                  canChangePrice: canChangePrice,
                  heldOrders: heldOrders,
                  shiftOpen: shiftOpen,
                  linkedCustomer: linkedCustomer,
                  isEditingLine: isEditingLine,
                  priceOverrides: priceOverrides,
                  discountPercent: discountPercent,
                  onDiscountChanged: onDiscountChanged,
                  orderNote: orderNote,
                  onOrderNoteChanged: onOrderNoteChanged,
                  sessionSaleCount: sessionSaleCount,
                  sessionCashTotal: sessionCashTotal,
                  onRecallOrder: onRecallOrder,
                  onLinkCustomer: onLinkCustomer,
                  onIncrement: onIncrement,
                  onDecrement: onDecrement,
                  onRemove: onRemove,
                  onClearCart: onClearCart,
                  onPayCash: onPayCash,
                  onPayCredit: onPayCredit,
                  onPayBank: onPayBank,
                  onPaySadad: onPaySadad,
                  onPayNumoQr: onPayNumoQr,
                  onPayMobicash: onPayMobicash,
                  onPayBankTransfer: onPayBankTransfer,
                  onPayBankTransferSadad: onPayBankTransferSadad,
                  onPayBankTransferMobCash: onPayBankTransferMobCash,
                  onHoldOrder: onHoldOrder,
                  onSplitPayment: onSplitPayment,
                  onPressShift: onPressShift,
                  onEditLine: onEditLine,
                  scrollController: controller,
                ),
          ),
    );
  }
}

// ── Mobile Cart Bar (Bottom bar on narrow screens) ─────────────────────────

class _MobileCartBar extends StatelessWidget {
  const _MobileCartBar({
    required this.itemCount,
    required this.subtotal,
    required this.onTap,
  });

  final int itemCount;
  final double subtotal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: taj.primary.main,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  '$itemCount منتج',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  arDinar(subtotal),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Category Chips (Mobile horizontal) ──────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: taj.paper,
        border: Border(bottom: BorderSide(color: taj.divider)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSelected = cat == selectedCategory;
          final catColor = _categoryColor(cat, taj);

          return GestureDetector(
            onTap: () => onCategoryChanged(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? catColor.main : taj.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? catColor.main : taj.divider,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isSelected) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: catColor.main,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    cat,
                    style: TextStyle(
                      color:
                          isSelected ? catColor.contrastText : taj.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  TajSwatch _categoryColor(String category, TajColors taj) =>
      _tajCategoryColor(category, taj);
}

// ── Product Section ──────────────────────────────────────────────────────────

class _ProductSection extends StatelessWidget {
  const _ProductSection({
    required this.products,
    required this.cart,
    required this.isGridView,
    required this.searchQuery,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onProductTap,
    this.canChangePrice = true,
  });

  final List<_Product> products;
  final Map<String, int> cart;
  final bool isGridView;
  final String searchQuery;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onProductTap;
  final bool canChangePrice;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: searchController,
            focusNode: searchFocusNode,
            onChanged: onSearchChanged,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم أو الباركود...',
              prefixIcon: const Icon(Icons.search_rounded, size: 22),
              suffixIcon:
                  searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                          searchFocusNode.requestFocus();
                        },
                      )
                      : const Icon(Icons.qr_code_scanner_rounded, size: 22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: taj.background,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),

        // Product list/grid
        Expanded(
          child:
              products.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 56,
                          color: taj.textDisabled,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد منتجات',
                          style: TextStyle(
                            color: taj.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'جرّب البحث بالاسم أو الباركود',
                          style: TextStyle(
                            color: taj.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                  : isGridView
                  ? GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 150,
                          mainAxisExtent: 110,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: products.length,
                    itemBuilder:
                        (_, i) => _ProductTile(
                          product: products[i],
                          quantityInCart: cart[products[i].id] ?? 0,
                          onTap: () => onProductTap(products[i].id),
                          canChangePrice: canChangePrice,
                        ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: products.length,
                    itemBuilder:
                        (_, i) => _ProductListTile(
                          product: products[i],
                          quantityInCart: cart[products[i].id] ?? 0,
                          onTap: () => onProductTap(products[i].id),
                          canChangePrice: canChangePrice,
                        ),
                  ),
        ),
      ],
    );
  }
}

// ── Product Tile (Grid view) ────────────────────────────────────────────────

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.quantityInCart,
    required this.onTap,
    this.canChangePrice = true,
  });

  final _Product product;
  final int quantityInCart;
  final VoidCallback onTap;
  final bool canChangePrice;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final categoryColor = _categoryColor(product.category, taj);
    final inCart = quantityInCart > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: taj.paper,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: inCart ? categoryColor.main : taj.divider,
              width: inCart ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon area — subtle category-tinted surface
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: categoryColor.lighter.withValues(
                      alpha: isDark ? 0.16 : 0.55,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(11),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    _categoryIcon(product.category),
                    size: 28,
                    color: taj.accentFor(categoryColor),
                  ),
                ),
              ),

              // Details
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: taj.textPrimary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (canChangePrice)
                          Expanded(
                            child: Text(
                              '${arNum(product.price)} د.ل',
                              style: TextStyle(
                                color: taj.accentText,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (inCart)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: categoryColor.main,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$quantityInCart',
                              style: TextStyle(
                                color: categoryColor.contrastText,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TajSwatch _categoryColor(String category, TajColors taj) =>
      _tajCategoryColor(category, taj);
}

// ── Product List Tile (List view) ───────────────────────────────────────────

class _ProductListTile extends StatelessWidget {
  const _ProductListTile({
    required this.product,
    required this.quantityInCart,
    required this.onTap,
    this.canChangePrice = true,
  });

  final _Product product;
  final int quantityInCart;
  final VoidCallback onTap;
  final bool canChangePrice;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = _categoryColor(product.category, taj);
    final inCart = quantityInCart > 0;

    return Material(
      color: taj.paper,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: inCart ? categoryColor.main : taj.divider,
              width: inCart ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Category icon chip
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: categoryColor.lighter.withValues(
                    alpha: isDark ? 0.18 : 0.5,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  _categoryIcon(product.category),
                  size: 19,
                  color: taj.accentFor(categoryColor),
                ),
              ),
              const SizedBox(width: 12),

              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: taj.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Price (only if the user has the sales.change_price permission)
              if (canChangePrice)
                Text(
                  '${arNum(product.price)} د.ل',
                  style: TextStyle(
                    color: taj.accentText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

              // Quantity badge
              if (inCart) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: categoryColor.main,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$quantityInCart',
                    style: TextStyle(
                      color: categoryColor.contrastText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  TajSwatch _categoryColor(String category, TajColors taj) =>
      _tajCategoryColor(category, taj);
}

// ── Cart Section ─────────────────────────────────────────────────────────────

class _CartSection extends StatelessWidget {
  const _CartSection({
    required this.products,
    required this.lowStockCount,
    required this.cart,
    required this.subtotal,
    required this.itemCount,
    required this.isProfessional,
    required this.canChangePrice,
    required this.heldOrders,
    required this.shiftOpen,
    required this.linkedCustomer,
    required this.isEditingLine,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onClearCart,
    required this.onPayCash,
    required this.onPayCredit,
    required this.onPayBank,
    required this.onPaySadad,
    required this.onPayNumoQr,
    required this.onPayMobicash,
    required this.onPayBankTransfer,
    required this.onPayBankTransferSadad,
    required this.onPayBankTransferMobCash,
    required this.onHoldOrder,
    required this.onSplitPayment,
    required this.onPressShift,
    required this.onEditLine,
    required this.onRecallOrder,
    required this.onLinkCustomer,
    required this.discountPercent,
    required this.onDiscountChanged,
    required this.priceOverrides,
    required this.orderNote,
    required this.onOrderNoteChanged,
    required this.sessionSaleCount,
    required this.sessionCashTotal,
    this.scrollController,
  });

  final List<_Product> products;
  final int lowStockCount;
  final Map<String, int> cart;
  final double subtotal;
  final int itemCount;
  final bool isProfessional;
  final bool canChangePrice;
  final List<_HeldOrder> heldOrders;
  final bool shiftOpen;
  final String? linkedCustomer;
  final String? isEditingLine;
  final ValueChanged<String> onIncrement;
  final ValueChanged<String> onDecrement;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearCart;
  final VoidCallback onPayCash;
  final VoidCallback onPayCredit;
  final VoidCallback onPayBank;
  final VoidCallback onPaySadad;
  final VoidCallback onPayNumoQr;
  final VoidCallback onPayMobicash;
  final VoidCallback onPayBankTransfer;
  final VoidCallback onPayBankTransferSadad;
  final VoidCallback onPayBankTransferMobCash;
  final VoidCallback onHoldOrder;
  final VoidCallback onSplitPayment;
  final VoidCallback onPressShift;
  final ValueChanged<String> onEditLine;
  final ValueChanged<_HeldOrder> onRecallOrder;
  final VoidCallback onLinkCustomer;
  final double discountPercent;
  final ValueChanged<double> onDiscountChanged;
  final Map<String, double> priceOverrides;
  final String orderNote;
  final ValueChanged<String> onOrderNoteChanged;
  final int sessionSaleCount;
  final double sessionCashTotal;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Cap the totals/footer so it scrolls internally on short windows
        // instead of crushing the cart items area to zero (overflow fix).
        final maxFooterHeight = constraints.maxHeight * 0.52;
        return Container(
          decoration: BoxDecoration(
            color: taj.paper,
            border: Border(left: BorderSide(color: taj.divider)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 18,
                      color: taj.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'الفاتورة',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: taj.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Trailing tools scale down on very tight widths instead of
                    // overflowing — the professional header carries several tools.
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerEnd,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ── Professional: low-stock indicator (one chip) ──
                              if (isProfessional && lowStockCount > 0) ...[
                                Tooltip(
                                  message: 'مخزون منخفض: $lowStockCount صنف',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: taj.warning.lighter,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.warning_rounded,
                                          size: 13,
                                          color: taj.warning.dark,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$lowStockCount',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: taj.warning.dark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],

                              // ── Professional: Customer link ──
                              if (isProfessional)
                                TextButton.icon(
                                  onPressed: onLinkCustomer,
                                  icon: Icon(
                                    linkedCustomer == null
                                        ? Icons.person_add_alt_1_rounded
                                        : Icons.person_rounded,
                                    size: 16,
                                    color:
                                        linkedCustomer == null
                                            ? taj.textSecondary
                                            : taj.primary.main,
                                  ),
                                  label: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 120,
                                    ),
                                    child: Text(
                                      linkedCustomer ?? 'ربط عميل',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color:
                                            linkedCustomer == null
                                                ? taj.textSecondary
                                                : taj.primary.main,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                              // ── Professional: Shift toggle ──
                              if (isProfessional)
                                IconButton(
                                  tooltip:
                                      shiftOpen
                                          ? 'إغلاق الوردية'
                                          : 'فتح الوردية',
                                  onPressed: onPressShift,
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(
                                    shiftOpen
                                        ? Icons.lock_open_rounded
                                        : Icons.lock_clock_rounded,
                                    size: 20,
                                    color:
                                        shiftOpen
                                            ? taj.accentFor(taj.success)
                                            : taj.textSecondary,
                                  ),
                                ),

                              if (cart.isNotEmpty) ...[
                                Text(
                                  '$itemCount منتج',
                                  style: TextStyle(
                                    color: taj.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: onClearCart,
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                  ),
                                  label: const Text('مسح'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: taj.error.main,
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: taj.divider),

              // Cart items
              Expanded(
                child:
                    cart.isEmpty
                        ? Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 44,
                                  color: taj.textDisabled,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'سلة فارغة',
                                  style: TextStyle(
                                    color: taj.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'اضغط على منتج لإضافته',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: taj.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: cart.length,
                          itemBuilder: (_, i) {
                            final entry = cart.entries.elementAt(i);
                            final product = products.firstWhere(
                              (p) => p.id == entry.key,
                            );
                            return _CartItem(
                              product: product,
                              quantity: entry.value,
                              canChangePrice: canChangePrice,
                              isEditing: isEditingLine == entry.key,
                              unitPrice: priceOverrides[entry.key],
                              onIncrement: () => onIncrement(entry.key),
                              onDecrement: () => onDecrement(entry.key),
                              onRemove: () => onRemove(entry.key),
                              onEditLine: isProfessional ? onEditLine : null,
                            );
                          },
                        ),
              ),

              // Professional: Held orders quick-preview
              if (isProfessional && heldOrders.isNotEmpty)
                _HeldOrdersBar(
                  heldOrders: heldOrders,
                  onRecallOrder: onRecallOrder,
                ),

              // Totals + Payment buttons (scrolls internally on short windows)
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxFooterHeight),
                child: SingleChildScrollView(
                  child: _CartTotals(
                    subtotal: subtotal,
                    itemCount: itemCount,
                    isProfessional: isProfessional,
                    discountPercent: discountPercent,
                    onDiscountChanged: onDiscountChanged,
                    orderNote: orderNote,
                    onOrderNoteChanged: onOrderNoteChanged,
                    sessionSaleCount: sessionSaleCount,
                    sessionCashTotal: sessionCashTotal,
                    onPayCash: onPayCash,
                    onPayCredit: onPayCredit,
                    onPayBank: onPayBank,
                    onPaySadad: onPaySadad,
                    onPayNumoQr: onPayNumoQr,
                    onPayMobicash: onPayMobicash,
                    onPayBankTransfer: onPayBankTransfer,
                    onPayBankTransferSadad: onPayBankTransferSadad,
                    onPayBankTransferMobCash: onPayBankTransferMobCash,
                    onHoldOrder: onHoldOrder,
                    onSplitPayment: onSplitPayment,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Cart Item ────────────────────────────────────────────────────────────────

class _CartItem extends StatelessWidget {
  const _CartItem({
    required this.product,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    this.canChangePrice = true,
    this.isEditing = false,
    this.onEditLine,
    this.unitPrice,
  });

  final _Product product;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final bool canChangePrice;
  final bool isEditing;
  final ValueChanged<String>? onEditLine;
  final double? unitPrice;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final effectiveUnit = unitPrice ?? product.price;
    final isOverridden = unitPrice != null && unitPrice != product.price;
    final lineTotal = effectiveUnit * quantity;

    return Container(
      padding: const EdgeInsetsDirectional.only(
        start: 12,
        end: 12,
        top: 6,
        bottom: 6,
      ),
      child: Row(
        children: [
          // Name + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: taj.textPrimary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onEditLine != null)
                      GestureDetector(
                        onTap: () => onEditLine!(product.id),
                        child: Icon(
                          Icons.more_vert_rounded,
                          size: 16,
                          color: taj.textSecondary,
                        ),
                      ),
                  ],
                ),
                Text(
                  canChangePrice
                      ? '${arNum(effectiveUnit)} د.ل × $quantity'
                      : '× $quantity',
                  style: TextStyle(
                    color: isOverridden ? taj.primary.main : taj.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // Quantity controls
          _QuantityCounter(
            quantity: quantity,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
          ),
          const SizedBox(width: 8),

          // Line total + remove
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                arDinar(lineTotal),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: taj.textPrimary,
                  fontSize: 13,
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: taj.error.main,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quantity Counter ─────────────────────────────────────────────────────────

class _QuantityCounter extends StatelessWidget {
  const _QuantityCounter({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;

    return Container(
      decoration: BoxDecoration(
        color: taj.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: taj.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyBtn(icon: Icons.remove_rounded, onTap: onDecrement),
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: taj.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
          _QtyBtn(icon: Icons.add_rounded, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(icon, size: 16, color: taj.textSecondary),
      ),
    );
  }
}

// ── Cart Totals ──────────────────────────────────────────────────────────────

class _CartTotals extends StatelessWidget {
  const _CartTotals({
    required this.subtotal,
    required this.itemCount,
    required this.isProfessional,
    required this.discountPercent,
    required this.onDiscountChanged,
    required this.orderNote,
    required this.onOrderNoteChanged,
    required this.sessionSaleCount,
    required this.sessionCashTotal,
    required this.onPayCash,
    required this.onPayCredit,
    required this.onPayBank,
    required this.onPaySadad,
    required this.onPayNumoQr,
    required this.onPayMobicash,
    required this.onPayBankTransfer,
    required this.onPayBankTransferSadad,
    required this.onPayBankTransferMobCash,
    required this.onHoldOrder,
    required this.onSplitPayment,
  });

  final double subtotal;
  final int itemCount;
  final bool isProfessional;
  final double discountPercent;
  final ValueChanged<double> onDiscountChanged;
  final String orderNote;
  final ValueChanged<String> onOrderNoteChanged;
  final int sessionSaleCount;
  final double sessionCashTotal;
  final VoidCallback onPayCash;
  final VoidCallback onPayCredit;
  final VoidCallback onPayBank;
  final VoidCallback onPaySadad;
  final VoidCallback onPayNumoQr;
  final VoidCallback onPayMobicash;
  final VoidCallback onPayBankTransfer;
  final VoidCallback onPayBankTransferSadad;
  final VoidCallback onPayBankTransferMobCash;
  final VoidCallback onHoldOrder;
  final VoidCallback onSplitPayment;

  double get _discountedTotal =>
      subtotal * (1 - discountPercent.clamp(0, 100) / 100);

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final hasDiscount = discountPercent > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: taj.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Professional: Session summary (Z-report mini) ──
          if (isProfessional) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: taj.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: taj.divider),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SessionStat(
                      icon: Icons.receipt_long_rounded,
                      label: 'مبيعات الجلسة',
                      value: '$sessionSaleCount',
                      valueColor: taj.textPrimary,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 26,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: taj.divider,
                  ),
                  Expanded(
                    child: _SessionStat(
                      icon: Icons.payments_rounded,
                      label: 'نقد اليوم',
                      value: arDinar(sessionCashTotal),
                      valueColor: taj.accentFor(taj.success),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Subtotal (+ discount row)
          _TotalRow(label: 'المجموع', value: arDinar(subtotal)),
          if (hasDiscount) ...[
            _TotalRow(
              label: 'خصم ${arNum(discountPercent.round())}%',
              value: '- ${arDinar(subtotal - _discountedTotal)}',
              valueColor: taj.error.main,
            ),
          ],
          const SizedBox(height: 12),

          // ── Primary: one-tap cash sale — shows the amount being charged ──
          _PrimaryChargeButton(
            amount: _discountedTotal,
            enabled: itemCount != 0,
            onPressed: onPayCash,
          ),
          const SizedBox(height: 10),

          // ── Professional: quick-action toolbar (discount / note / hold / split) ──
          if (isProfessional) ...[
            Row(
              children: [
                Expanded(
                  child: _ProActionTile(
                    icon: Icons.percent_rounded,
                    label:
                        hasDiscount
                            ? '${arNum(discountPercent.round())}%'
                            : 'خصم',
                    active: hasDiscount,
                    activeSwatch: taj.success,
                    onTap:
                        itemCount == 0 ? null : () => _promptDiscount(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ProActionTile(
                    icon: Icons.sticky_note_2_outlined,
                    label: 'ملاحظة',
                    active: orderNote.isNotEmpty,
                    activeSwatch: taj.primary,
                    onTap: () => _promptNote(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ProActionTile(
                    icon: Icons.pause_circle_outline_rounded,
                    label: 'حفظ',
                    active: false,
                    activeSwatch: taj.primary,
                    onTap: itemCount == 0 ? null : onHoldOrder,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ProActionTile(
                    icon: Icons.call_split_rounded,
                    label: 'تقسيم',
                    active: false,
                    activeSwatch: taj.primary,
                    onTap: itemCount == 0 ? null : onSplitPayment,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // ── Other payment methods — neutral soft buttons, grouped for scanning ──
          Row(
            children: [
              Expanded(
                child: _PayButton(
                  label: 'آجل',
                  icon: Icons.credit_card_outlined,
                  color: taj.neutral,
                  onPressed: itemCount == 0 ? null : onPayCredit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PayButton(
                  label: 'مصرفي',
                  icon: Icons.account_balance_outlined,
                  color: taj.neutral,
                  onPressed: itemCount == 0 ? null : onPayBank,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PayButton(
                  label: 'سداد',
                  icon: Icons.phone_android_rounded,
                  color: taj.neutral,
                  onPressed: itemCount == 0 ? null : onPaySadad,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PayButton(
                  label: 'NUMO QR',
                  icon: Icons.qr_code_rounded,
                  color: taj.neutral,
                  onPressed: itemCount == 0 ? null : onPayNumoQr,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _PaySectionLabel(label: 'تحويلات ومحافظ'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PayButton(
                  label: 'MobiCash',
                  icon: Icons.account_balance_wallet_rounded,
                  color: taj.neutral,
                  onPressed: itemCount == 0 ? null : onPayMobicash,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PayButton(
                  label: 'تحويل حساب',
                  icon: Icons.account_balance_rounded,
                  color: taj.neutral,
                  onPressed: itemCount == 0 ? null : onPayBankTransfer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _PayButton(
                  label: 'تحويل سداد',
                  icon: Icons.send_to_mobile_rounded,
                  color: taj.neutral,
                  onPressed: itemCount == 0 ? null : onPayBankTransferSadad,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PayButton(
                  label: 'تحويل MobiCash',
                  icon: Icons.phone_android_rounded,
                  color: taj.neutral,
                  onPressed: itemCount == 0 ? null : onPayBankTransferMobCash,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // More payment services link
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PaymentServicesPanel(),
                  ),
                );
              },
              icon: const Icon(Icons.info_outline, size: 16),
              label: const Text(
                'عرض جميع خدمات الدفع الإلكترونية',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _promptDiscount(BuildContext context) async {
    final controller = TextEditingController(
      text: discountPercent > 0 ? discountPercent.round().toString() : '',
    );
    final value = await showDialog<double>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('خصم على الفاتورة'),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'نسبة الخصم %',
                border: OutlineInputBorder(),
                hintText: 'مثال: 10',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.pop(
                      ctx,
                      double.tryParse(controller.text) ?? 0,
                    ),
                child: const Text('تطبيق'),
              ),
            ],
          ),
    );
    if (value != null) onDiscountChanged(value.clamp(0, 100).toDouble());
  }

  Future<void> _promptNote(BuildContext context) async {
    final controller = TextEditingController(text: orderNote);
    final value = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('ملاحظة الطلب'),
            content: TextField(
              controller: controller,
              maxLines: 3,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'تُطبع في إيصال الفاتورة',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, ''),
                child: const Text('مسح'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, controller.text),
                child: const Text('حفظ'),
              ),
            ],
          ),
    );
    if (value != null) onOrderNoteChanged(value);
  }
}

/// The big primary tender button. A full-width success bar that also shows the
/// amount being charged on the trailing side — the single most-used control on
/// the till, sized for fast, confident taps (spec §7.5 "huge pay buttons").
class _PrimaryChargeButton extends StatelessWidget {
  const _PrimaryChargeButton({
    required this.amount,
    required this.enabled,
    required this.onPressed,
  });

  final double amount;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: taj.success.main,
          foregroundColor: taj.success.contrastText,
          disabledBackgroundColor: taj.success.main.withValues(alpha: 0.35),
          disabledForegroundColor: taj.success.contrastText.withValues(
            alpha: 0.6,
          ),
          padding: const EdgeInsetsDirectional.only(start: 18, end: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.payments_rounded, size: 24),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'بيع نقداً',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              arDinar(amount),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

/// An equal-priority tender button — a neutral **soft** button (Minimals) with a
/// leading icon chip and label. Neutral grey by policy; methods are told apart
/// by their icon only (see [TajColors.neutralSwatch]).
class _PayButton extends StatelessWidget {
  const _PayButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final TajSwatch color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final enabled = onPressed != null;
    final iconColor = enabled ? taj.accentFor(color) : taj.textDisabled;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: taj.paper,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          hoverColor: taj.hover,
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: taj.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: taj.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 17, color: iconColor),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: enabled ? taj.textPrimary : taj.textDisabled,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A thin captioned divider that groups the alternate tenders (wallets /
/// transfers) so the till operator can scan them apart from the common methods.
class _PaySectionLabel extends StatelessWidget {
  const _PaySectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: taj.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(height: 1, color: taj.divider)),
      ],
    );
  }
}

/// A compact session KPI cell (label stacked over value) used by the
/// professional Z-report mini strip. Both label and value ellipsize so the pair
/// of cells stays inside a phone-width cart sheet.
class _SessionStat extends StatelessWidget {
  const _SessionStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Row(
      children: [
        Icon(icon, size: 15, color: taj.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: taj.textSecondary),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A compact professional-mode action tile (discount / note / hold / split).
/// Sits in a single 4-up toolbar and lights up with a semantic accent when its
/// feature is active (e.g. a discount is applied or a note is attached).
class _ProActionTile extends StatelessWidget {
  const _ProActionTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeSwatch,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final TajSwatch activeSwatch;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final enabled = onTap != null;
    final fg =
        !enabled
            ? taj.textDisabled
            : (active ? taj.accentFor(activeSwatch) : taj.textPrimary);
    final tint = activeSwatch.main.withValues(alpha: taj.isDark ? 0.20 : 0.10);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: taj.paper,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: taj.hover,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: active ? tint : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? activeSwatch.main : taj.divider,
                width: active ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19, color: fg),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Row(
      children: [
        Text(label, style: TextStyle(color: taj.textSecondary, fontSize: 14)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: valueColor ?? taj.accentText,
          ),
        ),
      ],
    );
  }
}

// ── Payment Dialog ───────────────────────────────────────────────────────────

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({
    required this.subtotal,
    required this.itemCount,
    required this.method,
    required this.onConfirm,
    this.isProfessional = false,
    this.onSplit,
  });

  final double subtotal;
  final int itemCount;
  final PaymentMethod method;
  final VoidCallback onConfirm;
  final bool isProfessional;
  final VoidCallback? onSplit;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.subtotal.toStringAsFixed(3);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final methodName = switch (widget.method) {
      PaymentMethod.cash => 'نقدي',
      PaymentMethod.credit => 'بيع آجل',
      PaymentMethod.bank => 'تحويل مصرفي',
      PaymentMethod.sadad => 'سداد',
      PaymentMethod.numoQr => 'NUMO QR',
      PaymentMethod.mobicash => 'MobiCash',
      PaymentMethod.bankTransfer => 'تحويل الى حساب',
      PaymentMethod.bankTransferSadad => 'تحويل عبر سداد',
      PaymentMethod.bankTransferMobCash => 'تحويل عبر MobiCash',
    };

    return AlertDialog(
      title: Text(methodName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Amount
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: taj.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text('الإجمالي', style: TextStyle(color: taj.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  arDinar(widget.subtotal),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: taj.accentText,
                  ),
                ),
                Text(
                  '${widget.itemCount} منتج',
                  style: TextStyle(color: taj.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),

          if (widget.method == PaymentMethod.cash) ...[
            const SizedBox(height: 16),
            Text(
              'المبلغ المدفوع',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                suffixText: 'د.ل',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],

          if (widget.method == PaymentMethod.credit) ...[
            const SizedBox(height: 16),
            Text('اسم العميل', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'أدخل اسم العميل',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],

          if (widget.method == PaymentMethod.bank) ...[
            const SizedBox(height: 16),
            Text('رقم المرجع', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'رقم عملية التحويل',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (widget.isProfessional && widget.onSplit != null)
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onSplit!();
            },
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
            label: const Text('تقسيم'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        SizedBox(
          width: 140,
          child: FilledButton.icon(
            onPressed: widget.onConfirm,
            icon: const Icon(Icons.check_rounded),
            label: const Text('تأكيد'),
          ),
        ),
      ],
    );
  }
}

// ── Held Orders Bar ─────────────────────────────────────────────────────────────

class _HeldOrdersBar extends StatelessWidget {
  const _HeldOrdersBar({required this.heldOrders, required this.onRecallOrder});
  final List<_HeldOrder> heldOrders;
  final ValueChanged<_HeldOrder> onRecallOrder;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: taj.background,
        border: Border(
          top: BorderSide(color: taj.divider),
          bottom: BorderSide(color: taj.divider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${heldOrders.length} طلب موقوف',
            style: TextStyle(
              color: taj.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final order in heldOrders)
                InkWell(
                  onTap: () => onRecallOrder(order),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: taj.neutral.lighter,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: taj.divider),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.restore_rounded,
                          size: 12,
                          color: taj.neutral.dark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order.name,
                          style: TextStyle(
                            color: taj.textPrimary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${order.itemCount} × ${arDinar(order.subtotal)}',
                          style: TextStyle(
                            color: taj.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Split Payment Sheet ────────────────────────────────────────────────────────

class _SplitPaymentSheet extends StatefulWidget {
  const _SplitPaymentSheet({required this.subtotal, required this.onConfirm});

  final double subtotal;
  final void Function(PaymentMethod method, List<double> amounts) onConfirm;

  @override
  State<_SplitPaymentSheet> createState() => _SplitPaymentSheetState();
}

class _SplitPaymentSheetState extends State<_SplitPaymentSheet> {
  final List<PaymentMethod> _methods = [
    PaymentMethod.cash,
    PaymentMethod.bank,
    PaymentMethod.sadad,
    PaymentMethod.numoQr,
  ];
  final Map<PaymentMethod, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final m in _methods) {
      _controllers[m] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _totalEntered {
    return _methods.fold(0, (sum, m) {
      final v = double.tryParse(_controllers[m]!.text) ?? 0;
      return sum + v;
    });
  }

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final remaining = widget.subtotal - _totalEntered;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        16,
        20,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تقسيم الدفع — ${arDinar(widget.subtotal)}',
            style: TextStyle(
              color: taj.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (final m in _methods) ...[
            Row(
              children: [
                Icon(_methodIcon(m), size: 18, color: taj.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _methodLabel(m),
                    style: TextStyle(color: taj.textPrimary, fontSize: 13),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _controllers[m],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: taj.divider)),
            ),
            child: Column(
              children: [
                Text(
                  'الباقي: ${arDinar(remaining)}',
                  style: TextStyle(
                    color:
                        remaining < 0
                            ? taj.accentFor(taj.success)
                            : taj.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              final amounts =
                  _methods
                      .map((m) => double.tryParse(_controllers[m]!.text) ?? 0)
                      .toList();
              widget.onConfirm(_methods.first, amounts);
            },
            style: FilledButton.styleFrom(
              backgroundColor: taj.primary.main,
              foregroundColor: taj.primary.contrastText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('تأكيد التقسيم'),
          ),
        ],
      ),
    );
  }

  IconData _methodIcon(PaymentMethod m) => switch (m) {
    PaymentMethod.cash => Icons.money_outlined,
    PaymentMethod.credit => Icons.credit_card_outlined,
    PaymentMethod.bank => Icons.account_balance_outlined,
    PaymentMethod.sadad => Icons.phone_android_rounded,
    _ => Icons.payment_outlined,
  };

  String _methodLabel(PaymentMethod m) => switch (m) {
    PaymentMethod.cash => 'نقدي',
    PaymentMethod.bank => 'تحويل مصرفي',
    PaymentMethod.sadad => 'سداد',
    PaymentMethod.numoQr => 'NUMO QR',
    _ => 'آخرى',
  };
}

// ── Shift Closed Sheet ─────────────────────────────────────────────────────────

class _ShiftClosedSheet extends StatelessWidget {
  const _ShiftClosedSheet({
    required this.totalSales,
    required this.transactionCount,
    required this.cashTotal,
    required this.itemCount,
  });

  final double totalSales;
  final int transactionCount;
  final double cashTotal;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        20,
        24,
        20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: taj.success.lighter,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.lock_clock_rounded,
              size: 32,
              color: taj.success.dark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'تم إغلاق الوردية',
            style: TextStyle(
              color: taj.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'مجموع المبيعات: ${arDinar(totalSales)}',
            style: TextStyle(color: taj.textSecondary, fontSize: 14),
          ),
          Text(
            '$transactionCount معاملة · $itemCount منتج',
            style: TextStyle(color: taj.textSecondary, fontSize: 14),
          ),
          Text(
            'نقد بالصندوق: ${arDinar(cashTotal)}',
            style: TextStyle(
              color: taj.accentFor(taj.success),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Session Report Sheet (Professional) ──────────────────────────────────────

class _ReportsSheet extends StatelessWidget {
  const _ReportsSheet({
    required this.sales,
    required this.totalSales,
    required this.cashTotal,
    required this.itemCount,
    required this.onCloseShift,
  });

  final List<_CompletedSale> sales;
  final double totalSales;
  final double cashTotal;
  final int itemCount;
  final VoidCallback onCloseShift;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;

    // Breakdown by payment method.
    final byMethod = <PaymentMethod, double>{};
    final methodCount = <PaymentMethod, int>{};
    for (final s in sales) {
      byMethod[s.method] = (byMethod[s.method] ?? 0) + s.total;
      methodCount[s.method] = (methodCount[s.method] ?? 0) + 1;
    }
    final methods =
        byMethod.keys.toList()
          ..sort((a, b) => (byMethod[b] ?? 0).compareTo(byMethod[a] ?? 0));

    String methodName(PaymentMethod m) => switch (m) {
      PaymentMethod.cash => 'نقدي',
      PaymentMethod.credit => 'آجل',
      PaymentMethod.bank => 'تحويل مصرفي',
      PaymentMethod.sadad => 'سداد',
      PaymentMethod.numoQr => 'NUMO QR',
      PaymentMethod.mobicash => 'MobiCash',
      PaymentMethod.bankTransfer => 'تحويل الى حساب',
      PaymentMethod.bankTransferSadad => 'تحويل عبر سداد',
      PaymentMethod.bankTransferMobCash => 'تحويل عبر MobiCash',
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تقرير الجلسة',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: taj.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ملخص مبيعات هذه الوردية',
              textAlign: TextAlign.center,
              style: TextStyle(color: taj.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // KPI cards
            Row(
              children: [
                Expanded(
                  child: _ReportKpi(
                    label: 'إجمالي المبيعات',
                    value: arDinar(totalSales),
                    color: taj.primary.main,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ReportKpi(
                    label: 'معاملات',
                    value: '${sales.length}',
                    color: taj.info.main,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ReportKpi(
                    label: 'منتجات',
                    value: '$itemCount',
                    color: taj.warning.main,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Cash drawer highlight
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: taj.success.lighter,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: taj.success.main),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.payments_rounded,
                    size: 18,
                    color: taj.success.dark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'نقد بالدرج',
                    style: TextStyle(
                      color: taj.success.dark,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    arDinar(cashTotal),
                    style: TextStyle(
                      color: taj.success.dark,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Breakdown by payment method
            if (methods.isNotEmpty) ...[
              Text(
                'توزيع طرق الدفع',
                style: TextStyle(
                  color: taj.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              for (final m in methods) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          methodName(m),
                          style: TextStyle(
                            color: taj.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        '${methodCount[m]} فاتورة',
                        style: TextStyle(
                          color: taj.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        arDinar(byMethod[m] ?? 0),
                        style: TextStyle(
                          color: taj.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: taj.divider),
              ],
              const SizedBox(height: 12),
            ],

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCloseShift,
                    icon: const Icon(Icons.lock_clock_rounded, size: 18),
                    label: const Text('إغلاق الوردية'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: taj.error.main,
                      side: BorderSide(color: taj.error.main),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('تم'),
                    style: FilledButton.styleFrom(
                      backgroundColor: taj.primary.main,
                      foregroundColor: taj.primary.contrastText,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportKpi extends StatelessWidget {
  const _ReportKpi({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: taj.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: taj.divider),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: taj.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ── Cart Line Edit Sheet ───────────────────────────────────────────────────────

class _CartLineEditSheet extends StatelessWidget {
  const _CartLineEditSheet({
    required this.product,
    required this.initialQuantity,
    required this.initialPrice,
    required this.canChangePrice,
    required this.onSave,
    required this.onRemove,
  });

  final _Product product;
  final int initialQuantity;
  final double initialPrice;
  final bool canChangePrice;
  final void Function(int quantity, double price) onSave;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    final qtyController = TextEditingController(
      text: initialQuantity.toString(),
    );
    final priceController = TextEditingController(
      text: initialPrice.toStringAsFixed(3),
    );

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        20,
        24,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            product.name,
            style: TextStyle(
              color: taj.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'الكمية',
                  style: TextStyle(color: taj.textSecondary, fontSize: 13),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: qtyController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (canChangePrice) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'السعر (د.ل)',
                    style: TextStyle(color: taj.textSecondary, fontSize: 13),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixText: '${arNum(product.price)} ← ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRemove();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: taj.error.main,
              side: BorderSide(color: taj.error.main),
            ),
            child: const Text('إزالة من السلة'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              final qty =
                  int.tryParse(qtyController.text.trim()) ?? initialQuantity;
              final price =
                  canChangePrice
                      ? double.tryParse(priceController.text.trim()) ??
                          initialPrice
                      : initialPrice;
              Navigator.of(context).pop();
              onSave(qty, price);
            },
            style: FilledButton.styleFrom(
              backgroundColor: taj.primary.main,
              foregroundColor: taj.primary.contrastText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

// ── Data ─────────────────────────────────────────────────────────────────────

class _HeldOrder {
  const _HeldOrder({
    required this.id,
    required this.name,
    required this.itemCount,
    required this.subtotal,
    required this.cart,
  });
  final String id;
  final String name;
  final int itemCount;
  final double subtotal;
  final Map<String, int> cart;
}

TajSwatch _tajCategoryColor(String category, TajColors taj) {
  switch (category) {
    case 'عطور':
    case 'قمصان':
      return taj.primary;
    case 'بخور':
    case 'جاكيتات':
      return taj.warning;
    case 'زيوت':
    case 'تنانير':
      return taj.success;
    case 'هدايا':
    case 'بناطيل':
    case 'حقائب':
      return taj.info;
    case 'فساتين':
    case 'إكسسوارات':
      return taj.secondary;
    case 'أحذية':
      return taj.error;
    default:
      return taj.primary;
  }
}

class _Product {
  const _Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.category,
    required this.price,
    this.stock = 999,
  });
  final String id;
  final String name;
  final String barcode;
  final String category;
  final double price;
  final int stock;
}

const _mockProducts = [
  _Product(
    id: 'p1',
    name: 'عود ملكي',
    barcode: '6224000111',
    category: 'عطور',
    price: 450,
    stock: 24,
  ),
  _Product(
    id: 'p2',
    name: 'عطر المسك',
    barcode: '6224000112',
    category: 'عطور',
    price: 320,
    stock: 3,
  ),
  _Product(
    id: 'p3',
    name: 'بخور فاخر',
    barcode: '6224000113',
    category: 'بخور',
    price: 180,
    stock: 57,
  ),
  _Product(
    id: 'p4',
    name: 'ماء الورد',
    barcode: '6224000114',
    category: 'زيوت',
    price: 60,
    stock: 0,
  ),
  _Product(
    id: 'p5',
    name: 'دهن العود',
    barcode: '6224000115',
    category: 'زيوت',
    price: 700,
    stock: 12,
  ),
  _Product(
    id: 'p6',
    name: 'عنبر',
    barcode: '6224000116',
    category: 'عطور',
    price: 540,
    stock: 2,
  ),
  _Product(
    id: 'p7',
    name: 'مبخرة نحاس',
    barcode: '6224000117',
    category: 'هدايا',
    price: 240,
    stock: 18,
  ),
  _Product(
    id: 'p8',
    name: 'بخور معمول',
    barcode: '6224000118',
    category: 'بخور',
    price: 150,
    stock: 40,
  ),
  _Product(
    id: 'p9',
    name: 'زيت الصندل',
    barcode: '6224000119',
    category: 'زيوت',
    price: 210,
    stock: 5,
  ),
  _Product(
    id: 'p10',
    name: 'طقم هدايا',
    barcode: '6224000120',
    category: 'هدايا',
    price: 380,
    stock: 9,
  ),
  _Product(
    id: 'p11',
    name: 'مسك أبيض',
    barcode: '6224000121',
    category: 'عطور',
    price: 260,
    stock: 33,
  ),
  _Product(
    id: 'p12',
    name: 'عود كمبودي',
    barcode: '6224000122',
    category: 'بخور',
    price: 820,
    stock: 0,
  ),
];

/// Products below this stock level trigger the Professional stock indicator.
const _lowStockThreshold = 5;
List<_Product> _lowStockProducts =
    _mockProducts.where((p) => p.stock <= _lowStockThreshold).toList();

// ── Completed Sale (session tracking) ────────────────────────────────────────

class _CompletedSale {
  const _CompletedSale({
    required this.method,
    required this.total,
    required this.itemCount,
    required this.time,
  });
  final PaymentMethod method;
  final double total;
  final int itemCount;
  final DateTime time;
}

// ── Mock Customers ───────────────────────────────────────────────────────────

const _mockCustomers = <String>[
  'أحمد الفيتوري',
  'فاطمة الزائدي',
  'محمد الترهوني',
  'سارة بنور',
  'خالد مخلوف',
  'نادية عبد السلام',
  'علي الطرابلسي',
  'هند القذافي',
  'عمر بوزيد',
  'آمال الشريف',
];

// ── Customer Picker Sheet ────────────────────────────────────────────────────

class _CustomerPickerSheet extends StatelessWidget {
  const _CustomerPickerSheet({
    required this.selected,
    required this.customers,
    required this.onSelect,
  });

  final String? selected;
  final List<String> customers;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final taj = context.taj;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ربط عميل',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: taj.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'اختر عميلاً لهذه الفاتورة',
              textAlign: TextAlign.center,
              style: TextStyle(color: taj.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: customers.length,
                separatorBuilder:
                    (_, _) => Divider(height: 1, color: taj.divider),
                itemBuilder: (_, i) {
                  final name = customers[i];
                  final isSelected = name == selected;
                  return ListTile(
                    dense: true,
                    title: Text(
                      name,
                      style: TextStyle(
                        color: taj.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    trailing:
                        isSelected
                            ? Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: taj.success.dark,
                            )
                            : null,
                    onTap: () => onSelect(name),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onSelect('');
              },
              child: Text(
                'إلغاء ربط العميل',
                style: TextStyle(color: taj.error.main, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
