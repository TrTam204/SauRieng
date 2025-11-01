import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PestCard extends StatelessWidget {
  final String title;
  final String code;
  final String? thumbUrl;
  final VoidCallback onTap;

  const PestCard({
    super.key,
    required this.title,
    required this.code,
    required this.onTap,
    this.thumbUrl,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: thumbUrl == null
                    ? const Center(child: Icon(Icons.image_not_supported, size: 48))
                    : CachedNetworkImage(
                        imageUrl: thumbUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (_, __, ___) =>
                            const Center(child: Icon(Icons.broken_image)),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
