import 'package:flutter/material.dart';

import '../../core/api/repositories.dart';
import '../../core/app_scope.dart';
import '../../core/currency_formatter.dart';
import '../../core/shop_keys.dart';
import '../../data/shop_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/widgets.dart';
import 'checkout_screen.dart';
import 'order_detail_screen.dart';

class ShopModuleScreen extends StatefulWidget {
  const ShopModuleScreen({super.key});

  @override
  State<ShopModuleScreen> createState() => _ShopModuleScreenState();
}

class _ShopModuleScreenState extends State<ShopModuleScreen> {
  List<ShopProduct> _products = [];
  List<ShopProduct> _favoriteProducts = [];
  CartData? _cart;
  List<ShopOrder> _orders = [];
  final _favoriteIds = <String>{};
  int _tab = 0;
  ShopCategory? _category;

  bool _loadingProducts = true;
  bool _loadingFavorites = true;
  bool _loadingCart = true;
  bool _loadingOrders = true;
  String? _errorProducts;
  String? _errorFavorites;
  String? _errorCart;
  String? _errorOrders;

  ShopRepository get _repo => AppScope.of(context).shop;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadProducts(), _loadFavorites(), _loadCart(), _loadOrders()]);
  }

  Future<void> _loadProducts() async {
    setState(() { _loadingProducts = true; _errorProducts = null; });
    try {
      final products = await _repo.getProducts();
      if (mounted) setState(() { _products = products; _loadingProducts = false; });
    } catch (e) {
      if (mounted) setState(() { _errorProducts = '$e'; _loadingProducts = false; });
    }
  }

  Future<void> _loadFavorites() async {
    setState(() { _loadingFavorites = true; _errorFavorites = null; });
    try {
      final fav = await _repo.getFavorites();
      if (mounted) {
        setState(() {
          _favoriteProducts = fav;
          _favoriteIds.clear();
          _favoriteIds.addAll(fav.map((p) => p.id));
          _loadingFavorites = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _errorFavorites = '$e'; _loadingFavorites = false; });
    }
  }

  Future<void> _loadCart() async {
    setState(() { _loadingCart = true; _errorCart = null; });
    try {
      final cart = await _repo.getCart();
      if (mounted) setState(() { _cart = cart; _loadingCart = false; });
    } catch (e) {
      if (mounted) setState(() { _errorCart = '$e'; _loadingCart = false; });
    }
  }

  Future<void> _loadOrders() async {
    setState(() { _loadingOrders = true; _errorOrders = null; });
    try {
      final orders = await _repo.getOrders();
      if (mounted) setState(() { _orders = orders; _loadingOrders = false; });
    } catch (e) {
      if (mounted) setState(() { _errorOrders = '$e'; _loadingOrders = false; });
    }
  }

  List<ShopProduct> get _filteredProducts => _products
      .where((product) => _category == null || product.category == _category)
      .toList();

  Future<void> _openProduct(ShopProduct product) async {
    try {
      final detail = await _repo.getProduct(product.id);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => _ProductDetailScreen(
            product: detail,
            isFavorite: _favoriteIds.contains(detail.id),
            onFavorite: () => _toggleFavorite(detail.id),
            onAddToCart: (quantity) => _addToCart(detail, quantity),
          ),
        ),
      );
      if (mounted) _loadProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _toggleFavorite(String slug) async {
    try {
      if (_favoriteIds.contains(slug)) {
        await _repo.removeFavorite(slug);
        if (mounted) {
          setState(() {
            _favoriteIds.remove(slug);
            _favoriteProducts.removeWhere((p) => p.id == slug);
          });
        }
      } else {
        await _repo.addFavorite(slug);
        if (mounted) {
          setState(() => _favoriteIds.add(slug));
          _loadFavorites();
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _addToCart(ShopProduct product, [int quantity = 1]) async {
    try {
      final cart = await _repo.addToCart(product.id, quantity);
      if (mounted) {
        setState(() => _cart = cart);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} ajouté au panier')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _updateCartQuantity(String slug, int newQuantity) async {
    try {
      CartData cart;
      if (newQuantity <= 0) {
        cart = await _repo.removeCartItem(slug);
      } else {
        cart = await _repo.updateCartItem(slug, newQuantity);
      }
      if (mounted) setState(() => _cart = cart);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _openCheckout() async {
    if (_cart == null || _cart!.items.isEmpty) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          cart: _cart!,
          onOrderCreated: (order) {
            if (mounted) {
              setState(() => _tab = 3);
              _loadCart();
              _loadOrders();
            }
          },
        ),
      ),
    );
  }

  Future<void> _openOrderDetail(ShopOrder order) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderNumber: order.orderNumber,
          onOrderChanged: () {
            if (mounted) _loadOrders();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const tabs = ['Catalogue', 'Favoris', 'Panier', 'Commandes'];
    final cartCount = _cart?.itemCount ?? 0;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, AppSpacing.md,
              ),
              child: Row(
                children: [
                  ApexIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Boutique', style: text.labelSmall?.copyWith(color: AppColors.coral)),
                        Text('Équipement sportif', style: text.headlineMedium),
                      ],
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ApexIconButton(
                        icon: Icons.shopping_bag_outlined,
                        onPressed: () => setState(() => _tab = 2),
                      ),
                      if (cartCount > 0)
                        Positioned(
                          right: -3, top: -4,
                          child: _CountBadge(count: cartCount),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              child: _ShopTabs(
                tabs: tabs, selected: _tab,
                onSelected: (index) => setState(() => _tab = index),
              ),
            ),
            Expanded(
              child: switch (_tab) {
                0 => _buildCatalog(text),
                1 => _buildFavorites(text),
                2 => _buildCart(text),
                _ => _buildOrders(text),
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Catalog tab ────────────────────────────────────────────────────

  Widget _buildCatalog(TextTheme text) {
    if (_loadingProducts) return const Center(child: CircularProgressIndicator());
    if (_errorProducts != null) return _errorState(text, _errorProducts!, _loadProducts);
    final products = _filteredProducts;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.lg, AppSpacing.screenH, AppSpacing.sm),
          sliver: SliverToBoxAdapter(
            child: ApexCard(
              tone: ApexCardTone.glow, accent: AppColors.coral,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PRÊT À BOUGER ?', style: text.labelSmall?.copyWith(color: AppColors.coral)),
                        const SizedBox(height: 6),
                        Text('Le bon équipement\npour votre prochaine séance.', style: text.headlineSmall),
                        const SizedBox(height: 8),
                        Text('Livraison offerte dès 250,000 DT', style: text.bodySmall),
                      ],
                    ),
                  ),
                  Icon(Icons.local_mall_rounded, size: 58, color: AppColors.coral.withValues(alpha: 0.9)),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: AppSpacing.sm),
          sliver: SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryChip(label: 'Tout', icon: Icons.grid_view_rounded, selected: _category == null, onTap: () => setState(() => _category = null)),
                  for (final category in ShopCategory.values)
                    _CategoryChip(label: category.label, icon: category.icon, accent: category.accent, selected: _category == category, onTap: () => setState(() => _category = category)),
                ],
              ),
            ),
          ),
        ),
        if (products.isEmpty)
          SliverFillRemaining(child: _emptyState(text, 'Aucun produit trouvé', 'Essayez une autre catégorie.', Icons.search_off_rounded))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.sm, AppSpacing.screenH, AppSpacing.xxxl),
            sliver: SliverList.builder(
              itemCount: products.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ProductTile(
                  product: products[index],
                  isFavorite: _favoriteIds.contains(products[index].id),
                  onTap: () => _openProduct(products[index]),
                  onFavorite: () => _toggleFavorite(products[index].id),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Favorites tab ──────────────────────────────────────────────────

  Widget _buildFavorites(TextTheme text) {
    if (_loadingFavorites) return const Center(child: CircularProgressIndicator());
    if (_errorFavorites != null) return _errorState(text, _errorFavorites!, _loadFavorites);
    if (_favoriteProducts.isEmpty) {
      return _emptyState(text, 'Aucun favori pour le moment', 'Gardez vos essentiels sous la main.', Icons.favorite_border_rounded);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.lg, AppSpacing.screenH, AppSpacing.xxxl),
      itemCount: _favoriteProducts.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, index) => _ProductTile(
        product: _favoriteProducts[index],
        isFavorite: true,
        onTap: () => _openProduct(_favoriteProducts[index]),
        onFavorite: () => _toggleFavorite(_favoriteProducts[index].id),
      ),
    );
  }

  // ─── Cart tab ───────────────────────────────────────────────────────

  Widget _buildCart(TextTheme text) {
    if (_loadingCart) return const Center(child: CircularProgressIndicator());
    if (_errorCart != null) return _errorState(text, _errorCart!, _loadCart);
    final cart = _cart;
    if (cart == null || cart.items.isEmpty) {
      return _emptyState(text, 'Votre panier est vide', 'Ajoutez un équipement depuis le catalogue.', Icons.shopping_bag_outlined);
    }
    final shippingCost = cart.subtotal >= 250 ? 0.0 : 8.0;
    final total = cart.subtotal + shippingCost;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.lg, AppSpacing.screenH, AppSpacing.xxxl),
      children: [
        Text('${cart.itemCount} article${cart.itemCount > 1 ? 's' : ''}', style: text.labelSmall),
        const SizedBox(height: AppSpacing.sm),
        for (final item in cart.items) ...[
          _CartLine(
            item: item,
            onDecrease: () => _updateCartQuantity(item.product.id, item.quantity - 1),
            onIncrease: () => _updateCartQuantity(item.product.id, item.quantity + 1),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.md),
        ApexCard(
          tone: ApexCardTone.muted,
          child: Column(
            children: [
              _SummaryRow(label: 'Sous-total', value: formatDinar(cart.subtotal)),
              const SizedBox(height: 8),
              _SummaryRow(
                label: 'Livraison',
                value: shippingCost == 0 ? 'Offerte' : formatDinar(shippingCost),
                valueColor: AppColors.mint,
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
              _SummaryRow(label: 'Total', value: formatDinar(total), large: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ApexButton(
          label: 'Commander',
          icon: Icons.lock_outline_rounded,
          onPressed: _openCheckout,
        ),
        const SizedBox(height: 8),
        Text('Paiement à la livraison · retours sous 30 jours', textAlign: TextAlign.center, style: text.labelSmall),
      ],
    );
  }

  // ─── Orders tab ─────────────────────────────────────────────────────

  Widget _buildOrders(TextTheme text) {
    if (_loadingOrders) return const Center(child: CircularProgressIndicator());
    if (_errorOrders != null) return _errorState(text, _errorOrders!, _loadOrders);
    if (_orders.isEmpty) {
      return _emptyState(text, 'Aucune commande', 'Vos commandes apparaîtront ici.', Icons.receipt_long_outlined);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.lg, AppSpacing.screenH, AppSpacing.xxxl),
      itemCount: _orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, index) {
        final order = _orders[index];
        return ApexCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          onTap: () => _openOrderDetail(order),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Commande ${order.orderNumber}', style: text.titleMedium)),
                  _StatusPill(label: orderStatusLabel(order.status), color: orderStatusColor(order.status)),
                ],
              ),
              const SizedBox(height: 6),
              Text(order.date, style: text.bodySmall),
              const SizedBox(height: AppSpacing.md),
              Text(order.items.map((i) => i.productName).join('  ·  '), style: text.bodyMedium),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(formatDinar(order.total), style: text.titleMedium),
                  const Spacer(),
                  Flexible(
                    child: Text('Voir le détail', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: text.labelLarge?.copyWith(color: AppColors.volt)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Shared states ──────────────────────────────────────────────────

  Widget _emptyState(TextTheme text, String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: text.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: text.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _errorState(TextTheme text, String error, VoidCallback retry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 44, color: AppColors.coral),
            const SizedBox(height: AppSpacing.md),
            Text(error, textAlign: TextAlign.center, style: text.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            ApexButton(label: 'Réessayer', onPressed: retry),
          ],
        ),
      ),
    );
  }
}

// ─── Product Detail Screen ────────────────────────────────────────────

class _ProductDetailScreen extends StatefulWidget {
  const _ProductDetailScreen({
    required this.product,
    required this.isFavorite,
    required this.onFavorite,
    required this.onAddToCart,
  });

  final ShopProduct product;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final void Function(int quantity) onAddToCart;

  @override
  State<_ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<_ProductDetailScreen> {
  late ShopProduct _product;
  late bool _favorite;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _favorite = widget.isFavorite;
  }

  Future<void> _openAddReviewDialog() async {
    double selectedRating = 5;
    final commentCtrl = TextEditingController();
    bool submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.lg,
            AppSpacing.screenH,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Donner votre avis', style: Theme.of(ctx).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(_product.name, style: Theme.of(ctx).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return IconButton(
                    icon: Icon(
                      star <= selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: AppColors.amber,
                      size: 32,
                    ),
                    onPressed: () => setModalState(() => selectedRating = star.toDouble()),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                style: Theme.of(ctx).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Partagez votre expérience avec ce produit...',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: AppRadii.mdAll, borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: AppRadii.mdAll, borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: AppRadii.mdAll, borderSide: const BorderSide(color: AppColors.volt)),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ApexButton(
                label: submitting ? 'Envoi en cours...' : 'Publier mon avis',
                onPressed: submitting
                    ? null
                    : () async {
                        final comment = commentCtrl.text.trim();
                        if (comment.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Veuillez saisir un commentaire')),
                          );
                          return;
                        }
                        final repo = AppScope.of(context).shop;
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(ctx);
                        setModalState(() => submitting = true);
                        try {
                          final updated = await repo.submitReview(
                            _product.id,
                            selectedRating,
                            comment,
                          );
                          if (!mounted) return;
                          setState(() => _product = updated);
                          navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Merci pour votre avis !')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          setModalState(() => submitting = false);
                          messenger.showSnackBar(SnackBar(content: Text('$e')));
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final reviews = _product.reviews;
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, AppSpacing.md, AppSpacing.screenH, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    ApexIconButton(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.of(context).pop()),
                    const Spacer(),
                    ApexIconButton(
                      icon: _favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      onPressed: () {
                        setState(() => _favorite = !_favorite);
                        widget.onFavorite();
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenH),
                child: _ProductHero(product: _product),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(_product.brand.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: text.labelSmall?.copyWith(color: _product.color)),
                      ),
                      const SizedBox(width: 8),
                      Text('${_product.rating}', style: text.labelLarge),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded, color: AppColors.amber, size: 18),
                      Text('  (${_product.reviewCount})', style: text.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_product.name, style: text.displaySmall),
                  const SizedBox(height: 8),
                  Text(formatDinar(_product.price), style: text.headlineMedium?.copyWith(color: AppColors.volt)),
                  const SizedBox(height: AppSpacing.lg),
                  Text(_product.description, style: text.bodyLarge),
                  const SizedBox(height: AppSpacing.md),
                  for (final feature in _product.features)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: _product.color, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(feature, style: text.bodyMedium)),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(child: Text('Avis clients', style: text.headlineSmall)),
                      TextButton.icon(
                        icon: const Icon(Icons.rate_review_outlined, size: 18),
                        label: const Text('Donner un avis'),
                        onPressed: _openAddReviewDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (reviews.isEmpty) Text('Les premiers avis arrivent bientôt.', style: text.bodyMedium),
                  for (final review in reviews)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _ReviewCard(review: review),
                    ),
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 10, AppSpacing.screenH, AppSpacing.md),
          child: Row(
            children: [
              ApexIconButton(icon: Icons.remove_rounded, onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$_quantity', style: text.titleLarge),
              ),
              ApexIconButton(icon: Icons.add_rounded, onPressed: () => setState(() => _quantity++)),
              const SizedBox(width: 12),
              Expanded(
                child: ApexButton(
                  label: 'Ajouter · ${formatDinar(_product.price * _quantity)}',
                  icon: Icons.shopping_bag_outlined,
                  onPressed: () {
                    widget.onAddToCart(_quantity);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Small Widgets ────────────────────────────────────────────────────

class _ProductHero extends StatelessWidget {
  const _ProductHero({required this.product});
  final ShopProduct product;
  @override
  Widget build(BuildContext context) => Container(
    height: 220,
    decoration: BoxDecoration(
      borderRadius: AppRadii.xlAll,
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
        product.color.withValues(alpha: 0.8), AppColors.surfaceElevated,
      ]),
      border: Border.all(color: product.color.withValues(alpha: 0.35)),
    ),
    child: Stack(
      children: [
        Positioned(
          right: 24, bottom: 20,
          child: Icon(product.icon, size: 140, color: Colors.white.withValues(alpha: 0.92)),
        ),
        if (product.badgeLabel != null)
          Positioned(
            left: 18, top: 18,
            child: _StatusPill(label: product.badgeLabel!, color: product.color),
          ),
      ],
    ),
  );
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.isFavorite, required this.onTap, required this.onFavorite});
  final ShopProduct product;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ApexCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 108,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadii.lg)),
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
                  product.color.withValues(alpha: 0.75), AppColors.surfaceElevated,
                ]),
              ),
              child: Center(
                child: Icon(product.icon, size: 54, color: Colors.white.withValues(alpha: 0.9)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, 10, AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(product.brand.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: text.labelSmall?.copyWith(color: product.color))),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onFavorite,
                          icon: Icon(
                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFavorite ? AppColors.coral : AppColors.textTertiary, size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.amber, size: 16),
                        const SizedBox(width: 4),
                        Expanded(child: Text('${product.rating} · ${product.reviewCount} avis', maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(formatDinar(product.price), style: text.titleMedium?.copyWith(color: AppColors.volt)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({required this.item, required this.onDecrease, required this.onIncrease});
  final CartItem item;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  @override
  Widget build(BuildContext context) => ApexCard(
    padding: const EdgeInsets.all(10),
    child: Row(
      children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: item.product.color.withValues(alpha: 0.22),
            borderRadius: AppRadii.mdAll,
          ),
          child: Icon(item.product.icon, color: item.product.color, size: 28),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(formatDinar(item.product.price), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppRadii.smAll,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: onDecrease,
                      borderRadius: AppRadii.smAll,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Icon(Icons.remove_rounded, size: 16, color: AppColors.textPrimary),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text('${item.quantity}', style: Theme.of(context).textTheme.labelMedium),
                    ),
                    InkWell(
                      onTap: onIncrease,
                      borderRadius: AppRadii.smAll,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Icon(Icons.add_rounded, size: 16, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(formatDinar(item.lineTotal), style: Theme.of(context).textTheme.labelLarge),
      ],
    ),
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final ShopReview review;
  @override
  Widget build(BuildContext context) => ApexCard(
    tone: ApexCardTone.muted,
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ApexAvatar(initials: review.initials, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.author, style: Theme.of(context).textTheme.titleSmall),
                  Text(review.date, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            ...List.generate(5, (index) => Icon(
              index < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
              color: AppColors.amber, size: 15,
            )),
          ],
        ),
        const SizedBox(height: 10),
        Text(review.comment, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.icon, required this.selected, required this.onTap, this.accent});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color? accent;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ActionChip(
      avatar: Icon(icon, size: 16, color: selected ? AppColors.textOnVolt : accent ?? AppColors.textSecondary),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: selected ? (accent ?? AppColors.volt) : AppColors.surface,
      side: BorderSide(color: selected ? (accent ?? AppColors.volt) : AppColors.border),
      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: selected ? AppColors.textOnVolt : AppColors.textSecondary,
      ),
    ),
  );
}

class _ShopTabs extends StatelessWidget {
  const _ShopTabs({required this.tabs, required this.selected, required this.onSelected});
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadii.mdAll, border: Border.all(color: AppColors.border)),
    child: Row(
      children: [
        for (var i = 0; i < tabs.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () => onSelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected == i ? AppColors.coral : Colors.transparent,
                  borderRadius: AppRadii.smAll,
                ),
                alignment: Alignment.center,
                child: Text(tabs[i], maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected == i ? Colors.white : AppColors.textSecondary,
                  )),
              ),
            ),
          ),
      ],
    ),
  );
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
    width: 18, height: 18, alignment: Alignment.center,
    decoration: const BoxDecoration(color: AppColors.coral, shape: BoxShape.circle),
    child: Text('$count', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontSize: 10)),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, this.color = AppColors.mint});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(AppRadii.pill),
    ),
    child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.valueColor, this.large = false});
  final String label;
  final String value;
  final Color? valueColor;
  final bool large;
  @override
  Widget build(BuildContext context) {
    final labelStyle = large ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.bodyMedium;
    final valueStyle = labelStyle?.copyWith(color: valueColor ?? AppColors.textPrimary, fontWeight: large ? FontWeight.w700 : null);
    return Row(children: [Expanded(child: Text(label, style: labelStyle)), Text(value, style: valueStyle)]);
  }
}
