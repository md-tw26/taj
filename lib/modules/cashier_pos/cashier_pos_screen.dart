import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/taj_colors.dart';
import '../../core/responsive.dart';
import '../../core/format.dart';
import '../../core/sale_sound.dart';
import '../../core/user_role.dart';
import '../../core/demo/demo_models.dart';
import '../../core/demo/demo_provider.dart';
import 'pos_layouts.dart';
import 'pos_models.dart';
import 'pos_payments.dart';
import 'pos_reports_sheets.dart';
import 'pos_top_bar.dart';

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
  final List<PosHeldOrder> _heldOrders = [];
  bool _shiftOpen = false;
  String? _linkedCustomer;
  String? _editingLineId;

  // Professional: per-line price overrides + order-level discount + note.
  final Map<String, double> _priceOverrides = {};
  double _discountPercent = 0;
  String _orderNote = '';

  // Completed sales this session (order history / Z-report data).
  final List<PosCompletedSale> _completedSales = [];

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
      PosCompletedSale(
        method: PaymentMethod.cash,
        total: 250,
        itemCount: 3,
        time: now,
      ),
      PosCompletedSale(
        method: PaymentMethod.cash,
        total: 90,
        itemCount: 1,
        time: now,
      ),
      PosCompletedSale(
        method: PaymentMethod.sadad,
        total: 150,
        itemCount: 2,
        time: now,
      ),
      PosCompletedSale(
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

  List<PosProduct> get _products =>
      DemoStoreProvider.of(context).products
          .map(
            (p) => PosProduct(
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

  List<PosProduct> get _filteredProducts {
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

  void _recallOrder(PosHeldOrder order) {
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
          (_) => PosCustomerPickerSheet(
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
        PosHeldOrder(
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
          (_) => PosSplitPaymentSheet(
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
          (_) => PosShiftClosedSheet(
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
          (_) => PosReportsSheet(
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
          (_) => PosCartLineEditSheet(
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
          (ctx) => PosPaymentDialog(
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
    if (!mounted) return;
    setState(() {
      _completedSales.add(
        PosCompletedSale(
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
            PosTopBar(
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
                      ? PosWideLayout(
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
                      : PosNarrowLayout(
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













