import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/categories_provider.dart';
import '../../../providers/products_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../services/customer_auth_service.dart';
import '../../../utils/firebase_image_helper.dart';
import '../products/game_category_screen.dart';

class GameHomeScreen extends StatefulWidget {
  const GameHomeScreen({Key? key}) : super(key: key);

  @override
  State<GameHomeScreen> createState() => _GameHomeScreenState();
}

class _GameHomeScreenState extends State<GameHomeScreen> {
  int _currentBannerIndex = 0;
  final List<String> _bannerImages = [
    'https://firebasestorage.googleapis.com/v0/b/walalka-store-a06ef.appspot.com/o/banners%2Fpubg_banner.jpg?alt=media',
    'https://firebasestorage.googleapis.com/v0/b/walalka-store-a06ef.appspot.com/o/banners%2Ffree_fire_banner.jpg?alt=media',
  ];

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'PUBG KR',
      'subtitle': 'Special offers on game credits',
      'image': 'https://firebasestorage.googleapis.com/v0/b/walalka-store-a06ef.appspot.com/o/banners%2Fpubg_banner.jpg?alt=media',
      'action': 'Shop Now'
    },
    {
      'title': 'Free Fire',
      'subtitle': 'Best deals on diamonds',
      'image': 'https://firebasestorage.googleapis.com/v0/b/walalka-store-a06ef.appspot.com/o/banners%2Ffree_fire_banner.jpg?alt=media',
      'action': 'Buy Now'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriesProvider>().fetchCategories();
    });
  }
  
  // Build a fallback banner image when the network image fails to load
  Widget _buildBannerFallbackImage(String title) {
    // Generate a color based on the title
    final int hash = title.hashCode;
    final double hue = (hash % 360).toDouble();
    final Color baseColor = HSLColor.fromAHSL(1.0, hue, 0.6, 0.4).toColor();
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor,
            baseColor.withOpacity(0.7),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          CustomPaint(
            painter: BannerPatternPainter(
              color: Colors.white.withOpacity(0.1),
            ),
            size: Size.infinite,
          ),
          // Game icon
          Center(
            child: Icon(
              Icons.sports_esports,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          // Walalka logo or text
          Positioned(
            top: 20,
            right: 20,
            child: Text(
              'WALALKA GAMES',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Build a fallback category image with decorative pattern and icon
  Widget _buildCategoryFallbackImage(String categoryName) {
    final int hash = categoryName.hashCode;
    final double hue = (hash % 360).toDouble();
    final Color baseColor = HSLColor.fromAHSL(1.0, hue, 0.6, 0.4).toColor();
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor,
            baseColor.withOpacity(0.7),
          ],
        ),
      ),
      child: Stack(
        children: [
          CustomPaint(
            painter: BannerPatternPainter(color: Colors.white.withOpacity(0.1)),
            size: Size.infinite,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getCategoryIcon(categoryName),
                  size: 40,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(height: 8),
                Text(
                  categoryName,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Get an appropriate icon based on category name
  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    
    if (name.contains('game') || name.contains('play')) {
      return Icons.sports_esports;
    } else if (name.contains('food') || name.contains('meal')) {
      return Icons.restaurant;
    } else if (name.contains('drink') || name.contains('beverage')) {
      return Icons.local_drink;
    } else if (name.contains('sport')) {
      return Icons.sports_basketball;
    } else if (name.contains('tech') || name.contains('electronic')) {
      return Icons.devices;
    } else if (name.contains('fashion') || name.contains('cloth')) {
      return Icons.shopping_bag;
    } else if (name.contains('beauty') || name.contains('cosmetic')) {
      return Icons.spa;
    } else if (name.contains('home') || name.contains('furniture')) {
      return Icons.home;
    } else {
      return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesProvider = context.watch<CategoriesProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/new_logo.png',
              height: 32,
              width: 32,
            ),
            const SizedBox(width: 8),
            const Text('Walalka Store'),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Consumer<CartProvider>(
                    builder: (context, cart, child) {
                      return cart.items.isEmpty
                          ? const SizedBox()
                          : Container(
                              padding: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 12,
                                minHeight: 12,
                              ),
                              child: Text(
                                '${cart.items.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                    },
                  ),
                )
              ],
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              final authService = context.read<CustomerAuthService>();
              if (authService.isLoggedIn) {
                Navigator.pushNamed(context, '/profile');
              } else {
                Navigator.pushNamed(context, '/login');
              }
            },
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: const Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              ],
            ),
            onPressed: () {},
          ),
        ],
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed section - Search bar (stays at the top)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search games, credits...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  // Search functionality will be implemented here
                },
              ),
            ),
          ),
          
          // Scrollable content (everything below search)
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Game banners
                  SizedBox(
                    height: 180.0,
                    child: PageView.builder(
                      controller: PageController(viewportFraction: 0.92),
                      itemCount: _banners.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentBannerIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final banner = _banners[index];
                        return Container(
                          height: 180,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Banner image
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: FirebaseImageWidget(
                                    imageUrl: banner['image'],
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    borderRadius: BorderRadius.circular(16),
                                    placeholder: Stack(
                                      children: [
                                        _buildBannerFallbackImage(banner['title']),
                                        const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    errorWidget: _buildBannerFallbackImage(banner['title']),
                                  ),
                                ),
                              ),
                              // Gradient overlay for better text readability
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      banner['title'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                    Text(
                                      banner['subtitle'],
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        // Navigate to the relevant product category
                                      },
                                      icon: const Icon(Icons.shopping_cart),
                                      label: Text(banner['action']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.blue.shade800,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Banner dots indicator
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_banners.length, (index) {
                        return Container(
                          width: 8.0,
                          height: 8.0,
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentBannerIndex == index
                                ? Colors.blue.shade800
                                : Colors.grey.shade400,
                          ),
                        );
                      }),
                    ),
                  ),
                  
                  // Game Categories header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Game Categories',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _loadCategories,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Refresh'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Game Categories grid
                  categoriesProvider.isLoading
                      ? const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : categoriesProvider.error != null
                          ? SizedBox(
                              height: 200,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Error: ${categoriesProvider.error}'),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _loadCategories,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : categoriesProvider.categories.isEmpty
                              ? const SizedBox(
                                  height: 200,
                                  child: Center(child: Text('No categories found')),
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.all(16.0),
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.3,
                                  ),
                                  itemCount: categoriesProvider.categories.length,
                                  itemBuilder: (context, index) {
                                    final category = categoriesProvider.categories[index];
                                    return InkWell(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => GameCategoryScreen(category: category),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey.withOpacity(0.1),
                                              spreadRadius: 1,
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: AspectRatio(
                                                aspectRatio: 16/9,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade900,
                                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                                    child: category.imageUrl != null && category.imageUrl!.isNotEmpty
                                                      ? FirebaseImageWidget(
                                                          imageUrl: category.imageUrl,
                                                          width: double.infinity,
                                                          height: double.infinity,
                                                          fit: BoxFit.cover,
                                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                                          placeholder: Center(
                                                            child: CircularProgressIndicator(
                                                              color: Colors.white,
                                                              strokeWidth: 2,
                                                            ),
                                                          ),
                                                          errorWidget: _buildCategoryFallbackImage(category.name),
                                                        )
                                                      : _buildCategoryFallbackImage(category.name),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Center(
                                                child: Text(
                                                  category.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                  // Add some padding at the bottom for better scrolling experience
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue.shade800,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Dalabyadi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Akoonkayga',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              Navigator.pushNamed(context, '/cart');
              break;
            case 2:
              Navigator.pushNamed(context, '/orders');
              break;
            case 3:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
      ),
    );
  }
}

/// Custom painter for banner patterns
class BannerPatternPainter extends CustomPainter {
  final Color color;
  
  BannerPatternPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
      
    // Draw diagonal lines pattern
    final spacing = 40.0;
    for (double i = -size.width; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
    
    // Draw circles
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.2), 10, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.8), 15, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.9), 8, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
