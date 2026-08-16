import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../places/places_screen.dart';
import 'destination_card.dart';

class FeaturedDestinations extends StatelessWidget {
  const FeaturedDestinations({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Popular Destinations",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PlacesScreen(),
                  ),
                );
              },
              child: const Text(
                "See all",
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        SizedBox(
          height: 245,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              DestinationCard(
                name: "Petra",
                location: "Ma'an",
                imagePath: "assets_new/images_copy/petra.jpg",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PlacesScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(width: 18),

              DestinationCard(
                name: "Wadi Rum",
                location: "Aqaba",
                imagePath: "assets_new/images_copy/wadi_rum.jpg",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PlacesScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(width: 18),

              DestinationCard(
                name: "Jerash",
                location: "Jerash",
                imagePath: "assets_new/images_copy/jerash.jpg",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PlacesScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(width: 18),

              DestinationCard(
                name: "Dead Sea",
                location: "Balqa",
                imagePath: "assets_new/images_copy/dead_sea.jpg",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PlacesScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}