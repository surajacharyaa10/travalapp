import 'package:flutter/material.dart';
import '../screens/home/category_places_screen.dart';

class CategorySelector extends StatelessWidget {
  final String selectedCategory;
  final Function() onBookmarkRefreshed;

  CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onBookmarkRefreshed,
  });

  final Map<String, String> _categoryMapping = {
    'Dining': 'restaurant',
    'Hotels': 'lodging',
    'Museums': 'museum',
    'Cafes': 'cafe',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildCategoryItem(context, 'Dining', Icons.restaurant, Colors.orange),
        _buildCategoryItem(context, 'Hotels', Icons.hotel, Colors.blue),
        _buildCategoryItem(context, 'Museums', Icons.museum, Colors.purple),
        _buildCategoryItem(context, 'Cafes', Icons.local_cafe, Colors.brown),
      ],
    );
  }

  Widget _buildCategoryItem(BuildContext context, String label, IconData icon, Color color) {
    final categoryCode = _categoryMapping[label] ?? 'restaurant';
    final isSelected = selectedCategory == categoryCode;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryPlacesScreen(
              categoryName: label,
              categoryType: categoryCode,
            ),
          ),
        ).then((_) => onBookmarkRefreshed()); // Refresh bookmarks in home screen
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.3) : color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: color, width: 2) : null,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.black87 : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
