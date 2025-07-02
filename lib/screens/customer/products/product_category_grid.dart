import 'package:flutter/material.dart';
import '../../../models/category.dart';
import 'category_products_screen.dart';

class ProductCategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final int? maxItems;

  const ProductCategoryGrid({
    Key? key,
    required this.categories,
    this.maxItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayCategories = maxItems != null && categories.length > maxItems!
        ? categories.sublist(0, maxItems)
        : categories;

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final category = displayCategories[index];
          return CategoryCard(category: category);
        },
        childCount: displayCategories.length,
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final Category category;

  const CategoryCard({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryProductsScreen(category: category),
          ),
        );
      },
      child: Card(
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: category.imageUrl != null && category.imageUrl!.isNotEmpty
                  ? Image.network(
                      category.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, __) => const Center(
                        child: Icon(
                          Icons.category,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.category,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).primaryColor,
              child: Text(
                category.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
