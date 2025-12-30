import 'package:flutter/material.dart';
import 'package:renthouse/models/house_model.dart';
import 'package:renthouse/utils/helpers.dart';
import 'package:renthouse/core/constants.dart';

class HouseCard extends StatelessWidget {
  final HouseModel house;
  final VoidCallback onTap;

  const HouseCard({
    super.key,
    required this.house,
    required this.onTap,
  });

  Widget _buildRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star
              : index < rating
              ? Icons.star_half
              : Icons.star_border,
          size: 14,
          color: Colors.amber,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // IMAGE SECTION (fixed ratio)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: house.imageUrl.isNotEmpty
                  ? Image.network(
                house.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Image.asset(
                    AppConstants.defaultHouseImage,
                    fit: BoxFit.cover,
                  );
                },
              )
                  : Image.asset(
                AppConstants.defaultHouseImage,
                fit: BoxFit.cover,
              ),
            ),

            // CONTENT SECTION (height controlled)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            house.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          Helpers.formatCurrency(house.price),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    _buildRating(4.5),

                    Text(
                      house.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),

                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            house.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
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
