import '../../data/onboarding_models.dart';
import '../../data/mock_profile.dart';
import '../../data/mock_shop.dart';
import '../../data/mock_training.dart';
import '../../data/profile_models.dart';
import '../../data/shop_models.dart';
import '../../data/training_models.dart';
import 'auth_repository.dart';
import 'repositories.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository() : _profile = buildInitialProfileBundle();
  final ProfileBundle _profile;
  bool _authenticated = false;

  @override
  Future<AuthSession> login(String email, String password) async {
    _authenticated = true;
    return AuthSession(token: 'mock-token', user: _profile.profile.toJson());
  }

  @override
  Future<AuthSession> register({required String firstName, required String lastName, required String email, required String password, required String passwordConfirmation}) async {
    _authenticated = true;
    return AuthSession(token: 'mock-token', user: _profile.profile.toJson());
  }

  @override
  Future<void> logout() async => _authenticated = false;

  @override
  Future<bool> hasToken() async => _authenticated;

  @override
  Future<void> verifyEmail({required String email, required String code}) async {}

  @override
  Future<void> resendCode(String email) async {}

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  Future<void> resetPassword({required String email, required String code, required String password, required String passwordConfirmation}) async {}

  @override
  Future<void> changePassword({required String currentPassword, required String password, required String passwordConfirmation}) async {}
}

class MockProfileRepository implements ProfileRepository {
  MockProfileRepository() : _bundle = buildInitialProfileBundle();
  ProfileBundle _bundle;

  @override
  Future<ProfileBundle> loadProfile() async => _bundle;

  @override
  Future<SportProfile> updateProfile(SportProfile profile) async {
    _bundle = _bundle.copyWith(profile: profile);
    return profile;
  }

  @override
  Future<List<SportGoal>> loadGoals() async => _bundle.goals;

  @override
  Future<SportGoal> createGoal(SportGoal goal) async {
    final nextId = (_bundle.goals.map((item) => item.id ?? 0).fold<int>(0, (max, id) => id > max ? id : max)) + 1;
    final saved = SportGoal(id: nextId, kind: goal.kind, detail: goal.detail, target: goal.target, deadline: goal.deadline, progress: goal.progress, active: goal.active, primary: goal.primary);
    _bundle = _bundle.copyWith(goals: [..._bundle.goals, saved]);
    return saved;
  }

  @override
  Future<SportGoal> updateGoal(SportGoal goal) async {
    _bundle = _bundle.copyWith(goals: _bundle.goals.map((item) => item.id == goal.id ? goal : item).toList());
    return goal;
  }

  @override
  Future<void> deleteGoal(int goalId) async => _bundle = _bundle.copyWith(goals: _bundle.goals.where((item) => item.id != goalId).toList());

  @override
  Future<List<BodySnapshot>> loadMeasurements() async => _bundle.measurements;

  @override
  Future<BodySnapshot> addMeasurement(BodySnapshot measurement) async {
    _bundle = _bundle.copyWith(measurements: [measurement, ..._bundle.measurements]);
    return measurement;
  }

  @override
  Future<DashboardData> loadDashboard() async => const DashboardData(firstName: 'Lina', readiness: 84, streakDays: 5, weeklySessions: 4);

  final List<RecommendedProgramItem> _mockRecommendations = [
    const RecommendedProgramItem(
      id: 'hyrox-foundations',
      title: 'Hyrox Foundations',
      subtitle: 'Conditionnement hybride, puissance et endurance de force.',
      weeks: 8,
      daysPerWeek: 4,
      level: 'intermediate',
      score: 96,
      reasons: [
        'Correspond à ton objectif de force et conditionnement',
        'Fréquence idéale de 4 séances par semaine',
        'Accessible avec équipement en salle',
      ],
      equipment: 'gym',
      goalTags: ['Hyrox', 'Force', 'Cardio'],
    ),
    const RecommendedProgramItem(
      id: 'force-athletique-lineaire',
      title: 'Force Athlétique Linéaire',
      subtitle: 'Progression méthodique sur squat, développé couché et soulevé de terre.',
      weeks: 12,
      daysPerWeek: 3,
      level: 'beginner',
      score: 88,
      reasons: [
        'Parfait pour bâtir des fondations solides',
        'Volume maîtrisé avec récupération optimisée',
        'Explications claires pour chaque mouvement',
      ],
      equipment: 'gym',
      goalTags: ['Force', 'Musculation'],
    ),
    const RecommendedProgramItem(
      id: 'remise-en-forme-hybride',
      title: 'Remise en Forme Hybride',
      subtitle: 'Brûler les graisses et booster le métabolisme au quotidien.',
      weeks: 6,
      daysPerWeek: 3,
      level: 'beginner',
      score: 82,
      reasons: [
        'Séances dynamiques et modulables',
        'Idéal pour retrouver endurance et tonus musculaire',
        'Adapté maison ou salle de sport',
      ],
      equipment: 'home',
      goalTags: ['Fitness', 'Cardio'],
    ),
  ];

  final List<Map<String, dynamic>> _userPrograms = [
    {
      'id': 1,
      'status': 'active',
      'startedAt': '2026-09-01T08:00:00Z',
      'program': {
        'id': 'hyrox-foundations',
        'title': 'Hyrox Foundations',
        'subtitle': 'Conditionnement hybride, puissance et endurance de force.',
        'weeks': 8,
        'daysPerWeek': 4,
        'level': 'intermediate',
      },
    }
  ];

  @override
  Future<List<RecommendedProgramItem>> submitOnboarding(OnboardingPayload payload) async {
    _bundle = _bundle.copyWith(
      profile: _bundle.profile.copyWith(
        age: payload.age,
        heightCm: payload.heightCm,
        sex: payload.sex.name,
        mainGoal: payload.mainGoal.wireValue,
        experienceLevel: payload.experienceLevel.wireValue,
        daysPerWeek: payload.daysPerWeek,
        equipment: payload.equipment.wireValue,
        onboardingCompleted: true,
      ),
    );
    return _mockRecommendations;
  }

  @override
  Future<List<RecommendedProgramItem>> loadRecommendations() async => _mockRecommendations;

  @override
  Future<void> startProgram(String slug) async {
    final prog = _mockRecommendations.firstWhere(
      (p) => p.id == slug,
      orElse: () => _mockRecommendations.first,
    );
    _userPrograms.clear();
    _userPrograms.add({
      'id': DateTime.now().millisecondsSinceEpoch,
      'status': 'active',
      'startedAt': DateTime.now().toUtc().toIso8601String(),
      'program': {
        'id': prog.id,
        'title': prog.title,
        'subtitle': prog.subtitle,
        'weeks': prog.weeks,
        'daysPerWeek': prog.daysPerWeek,
        'level': prog.level,
      },
    });
  }

  @override
  Future<List<Map<String, dynamic>>> loadUserPrograms() async => _userPrograms;
}

class MockTrainingRepository implements TrainingRepository {
  TrainingCatalog _catalog = buildInitialTrainingCatalog();

  @override
  Future<TrainingCatalog> loadCatalog() async => _catalog;

  @override
  Future<SessionLog> createSessionLog({required String sessionId, required String programId, required DateTime completedAt, required int durationMin, required String highlight, required List<Map<String, dynamic>> sets}) async {
    final log = SessionLog(date: completedAt, sessionTitle: _catalog.sessionById(sessionId).title, programTitle: programId, durationMin: durationMin, volumeKg: sets.where((set) => set['kind'] == 'load').fold<int>(0, (total, set) => total + (((set['reps'] as num) * (set['loadKg'] as num)).round())), highlight: highlight);
    _catalog = _catalog.copyWith(logs: [log, ..._catalog.logs]);
    return log;
  }
}

// ─── Mock Shop Repository ─────────────────────────────────────────────

class MockShopRepository implements ShopRepository {
  final _products = [...mockShopProducts];
  final _favorites = <String>{'aero-runner-x'};
  final _cart = <String, int>{'recovery-roll': 1};
  final _orders = [...mockShopOrders];
  final _reviews = <String, List<ShopReview>>{
    for (final entry in mockShopReviews.entries) entry.key: [...entry.value],
  };

  @override
  Future<List<ShopProduct>> getProducts({String? category, String? search}) async {
    var result = _products.toList();
    if (category != null) result = result.where((p) => p.category.wireValue == category).toList();
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      result = result.where((p) => p.name.toLowerCase().contains(q) || p.brand.toLowerCase().contains(q)).toList();
    }
    return result;
  }

  @override
  Future<ShopProduct> getProduct(String slug) async {
    final product = _products.firstWhere((p) => p.id == slug);
    final reviews = _reviews[slug] ?? const [];
    return ShopProduct(
      id: product.id, name: product.name, brand: product.brand,
      category: product.category, price: product.price, description: product.description,
      features: product.features, rating: product.rating, reviewCount: reviews.length,
      colorKey: product.colorKey, iconKey: product.iconKey, badgeKey: product.badgeKey,
      stockQuantity: product.stockQuantity, reviews: reviews,
    );
  }

  @override
  Future<List<ShopProduct>> getFavorites() async =>
      _products.where((p) => _favorites.contains(p.id)).toList();

  @override
  Future<void> addFavorite(String slug) async => _favorites.add(slug);

  @override
  Future<void> removeFavorite(String slug) async => _favorites.remove(slug);

  CartData _buildCart() {
    final items = <CartItem>[];
    double subtotal = 0;
    int count = 0;
    for (final entry in _cart.entries) {
      final product = _products.firstWhere((p) => p.id == entry.key);
      final lineTotal = product.price * entry.value;
      subtotal += lineTotal;
      count += entry.value;
      items.add(CartItem(product: product, quantity: entry.value, lineTotal: lineTotal));
    }
    return CartData(items: items, currency: 'TND', subtotal: subtotal, itemCount: count);
  }

  @override
  Future<CartData> getCart() async => _buildCart();

  @override
  Future<CartData> addToCart(String productSlug, int quantity) async {
    _cart[productSlug] = (_cart[productSlug] ?? 0) + quantity;
    return _buildCart();
  }

  @override
  Future<CartData> updateCartItem(String slug, int quantity) async {
    if (quantity <= 0) {
      _cart.remove(slug);
    } else {
      _cart[slug] = quantity;
    }
    return _buildCart();
  }

  @override
  Future<CartData> removeCartItem(String slug) async {
    _cart.remove(slug);
    return _buildCart();
  }

  @override
  Future<List<String>> getGovernorates() async => kFallbackGovernorates;

  @override
  Future<ShopOrder> createOrder(Map<String, dynamic> data) async {
    final items = _cart.entries.map((e) {
      final p = _products.firstWhere((p) => p.id == e.key);
      return OrderItem(productId: p.id, productName: p.name, quantity: e.value, unitPrice: p.price, lineTotal: p.price * e.value);
    }).toList();
    final subtotal = items.fold<double>(0, (s, i) => s + i.lineTotal);
    final shipping = subtotal >= 250 ? 0.0 : 8.0;
    final order = ShopOrder(
      orderNumber: 'APX-${20500 + _orders.length}',
      date: DateTime.now().toString().substring(0, 10),
      createdAt: DateTime.now(),
      status: 'pending',
      paymentStatus: 'unpaid',
      paymentMethod: 'cash_on_delivery',
      currency: 'TND',
      subtotal: subtotal,
      shippingCost: shipping,
      total: subtotal + shipping,
      notes: data['notes']?.toString(),
      shippingAddress: ShippingAddress(
        fullName: data['fullName']?.toString() ?? '',
        phone: data['phone']?.toString() ?? '',
        addressLine1: data['addressLine1']?.toString() ?? '',
        addressLine2: data['addressLine2']?.toString(),
        city: data['city']?.toString() ?? '',
        governorate: data['governorate']?.toString() ?? '',
        postalCode: data['postalCode']?.toString() ?? '',
      ),
      items: items,
      statusHistory: [StatusHistoryEntry(toStatus: 'pending', comment: 'Order placed by customer.', createdAt: DateTime.now())],
    );
    _orders.insert(0, order);
    _cart.clear();
    return order;
  }

  @override
  Future<List<ShopOrder>> getOrders() async => _orders;

  @override
  Future<ShopOrder> getOrder(String orderNumber) async =>
      _orders.firstWhere((o) => o.orderNumber == orderNumber);

  @override
  Future<ShopOrder> cancelOrder(String orderNumber) async {
    final idx = _orders.indexWhere((o) => o.orderNumber == orderNumber);
    final old = _orders[idx];
    final cancelled = ShopOrder(
      orderNumber: old.orderNumber, date: old.date, createdAt: old.createdAt,
      status: 'cancelled', paymentStatus: old.paymentStatus, paymentMethod: old.paymentMethod,
      currency: old.currency, subtotal: old.subtotal, shippingCost: old.shippingCost,
      total: old.total, notes: old.notes, shippingAddress: old.shippingAddress,
      items: old.items,
      statusHistory: [...old.statusHistory, StatusHistoryEntry(fromStatus: 'pending', toStatus: 'cancelled', comment: 'Order cancelled by customer.', createdAt: DateTime.now())],
    );
    _orders[idx] = cancelled;
    return cancelled;
  }

  @override
  Future<ShopProduct> submitReview(String slug, double rating, String comment) async {
    final review = ShopReview(author: 'Lina M.', date: DateTime.now().toString().substring(0, 10), rating: rating, comment: comment, initials: 'LM');
    _reviews.putIfAbsent(slug, () => []);
    _reviews[slug]!.add(review);
    return getProduct(slug);
  }
}
