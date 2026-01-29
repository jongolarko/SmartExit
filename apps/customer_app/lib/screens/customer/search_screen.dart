import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartexit_services/smartexit_services.dart';
import '../../providers/search_provider.dart';
import '../../providers/cart_provider.dart';
import '../../config/customer_theme.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchFocus.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: CustomerTheme.background,
      appBar: AppBar(
        backgroundColor: CustomerTheme.surface,
        elevation: 0,
        title: const Text(
          'Search Products',
          style: TextStyle(
            color: CustomerTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CustomerTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: CustomerTheme.surface,
            child: Column(
              children: [
                // Search input
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  decoration: InputDecoration(
                    hintText: 'Search for products...',
                    prefixIcon: const Icon(Icons.search, color: CustomerTheme.primaryBlue),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: CustomerTheme.textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchProvider.notifier).clearSearch();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: CustomerTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  onChanged: (query) {
                    ref.read(searchProvider.notifier).searchProducts(
                          query,
                          category: _selectedCategory,
                        );
                  },
                ),
                const SizedBox(height: 12),

                // Category filter chips
                categoriesAsync.when(
                  data: (categories) {
                    if (categories.isEmpty) return const SizedBox();

                    return SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // All categories chip
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: const Text('All'),
                              selected: _selectedCategory == null,
                              onSelected: (selected) {
                                setState(() => _selectedCategory = null);
                                if (_searchController.text.isNotEmpty) {
                                  ref.read(searchProvider.notifier).setCategory(null);
                                }
                              },
                              selectedColor: CustomerTheme.primaryBlue,
                              labelStyle: TextStyle(
                                color: _selectedCategory == null
                                    ? Colors.white
                                    : CustomerTheme.textSecondary,
                              ),
                            ),
                          ),

                          // Category chips
                          ...categories.map((cat) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(cat.name),
                                  selected: _selectedCategory == cat.name,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = selected ? cat.name : null;
                                    });
                                    if (_searchController.text.isNotEmpty) {
                                      ref.read(searchProvider.notifier).setCategory(
                                            selected ? cat.name : null,
                                          );
                                    }
                                  },
                                  selectedColor: CustomerTheme.accentGreen,
                                  labelStyle: TextStyle(
                                    color: _selectedCategory == cat.name
                                        ? Colors.white
                                        : CustomerTheme.textSecondary,
                                  ),
                                ),
                              )),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ],
            ),
          ),

          // Search results
          Expanded(
            child: searchState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : searchState.error != null
                    ? _buildError(searchState.error!)
                    : searchState.query.isEmpty
                        ? _buildEmptyState()
                        : searchState.results.isEmpty
                            ? _buildNoResults()
                            : _buildResults(searchState.results, searchState.fuzzyMatch),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final searchState = ref.watch(searchProvider);
    final popularAsync = ref.watch(popularProductsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches
          if (searchState.recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: CustomerTheme.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(searchProvider.notifier).clearRecentSearches();
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: searchState.recentSearches.map((search) {
                return ActionChip(
                  label: Text(search),
                  onPressed: () {
                    _searchController.text = search;
                    ref.read(searchProvider.notifier).searchImmediate(search);
                  },
                  avatar: const Icon(Icons.history, size: 18),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Popular products
          const Text(
            'Popular Products',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: CustomerTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          popularAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return const Center(child: Text('No popular products'));
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return _buildProductCard(products[index]);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Failed to load popular products')),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(List<ProductSearchResult> results, bool fuzzyMatch) {
    return Column(
      children: [
        // Fuzzy match indicator
        if (fuzzyMatch)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: CustomerTheme.accentGreenLight.withOpacity(0.2),
            child: Row(
              children: const [
                Icon(Icons.info_outline, size: 16, color: CustomerTheme.accentGreenDark),
                SizedBox(width: 8),
                Text(
                  'Showing similar results (typo correction)',
                  style: TextStyle(fontSize: 12, color: CustomerTheme.accentGreenDark),
                ),
              ],
            ),
          ),

        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              return _buildProductCard(results[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductSearchResult product) {
    final cartState = ref.watch(cartProvider);
    final isInCart = cartState.items.any((item) => item.productId == product.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CustomerTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product image placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: CustomerTheme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: product.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.shopping_bag, color: CustomerTheme.textSecondary),
            ),
            const SizedBox(width: 12),

            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: CustomerTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (product.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: CustomerTheme.primaryBlueLight.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.category!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: CustomerTheme.primaryBlueDark,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: CustomerTheme.accentGreen,
                    ),
                  ),
                  if (product.stock != null && product.stock! < 10)
                    Text(
                      'Only ${product.stock} left',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CustomerTheme.energeticOrange,
                      ),
                    ),
                ],
              ),
            ),

            // Add to cart button
            ElevatedButton(
              onPressed: isInCart
                  ? null
                  : () async {
                      final notifier = ref.read(cartProvider.notifier);
                      await notifier.addToCart(product.barcode);

                      // Track conversion
                      final searchState = ref.read(searchProvider);
                      if (searchState.query.isNotEmpty) {
                        await ApiService.trackSearchConversion(
                          productId: product.id,
                          query: searchState.query,
                          category: searchState.category,
                        );
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} added to cart'),
                            backgroundColor: CustomerTheme.accentGreen,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isInCart ? CustomerTheme.textSecondary : CustomerTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(isInCart ? 'In Cart' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: CustomerTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: CustomerTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try a different search term or category',
              style: TextStyle(
                fontSize: 14,
                color: CustomerTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: CustomerTheme.energeticOrange,
            ),
            const SizedBox(height: 16),
            const Text(
              'Search Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: CustomerTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontSize: 14,
                color: CustomerTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
