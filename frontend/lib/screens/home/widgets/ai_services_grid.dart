import 'package:flutter/material.dart';

import '../../crowd/crowd_monitor_screen.dart';
import '../../favorites/favorites_screen.dart';
import '../../guide/voice_guide_screen.dart';
import '../../places/places_screen.dart';
import '../../planner/trip_planner_screen.dart';
import '../../reconstruction/heritage_reconstruction_screen.dart';
import 'service_card.dart';

class AIServicesGrid extends StatelessWidget {
  const AIServicesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "AI Services",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 18),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          childAspectRatio: 0.80,
          children: [
            ServiceCard(
              title: "Explore Jordan",
              subtitle: "Browse Jordan's destinations",
              icon: Icons.map_rounded,
              imagePath: "assets/images/petra.jpg",
              iconBackgroundColor: const Color(0xFFE9E0D0),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PlacesScreen(),
                  ),
                );
              },
            ),

            ServiceCard(
              title: "AI Trip Planner",
              subtitle: "Generate your smart journey",
              icon: Icons.auto_awesome_rounded,
              imagePath: "assets/images/wadi_rum.jpg",
              iconBackgroundColor: const Color(0xFFDDE7D7),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TripPlannerScreen(),
                  ),
                );
              },
            ),

            ServiceCard(
              title: "Voice Guide",
              subtitle: "Talk with your AI guide",
              icon: Icons.mic_rounded,
              imagePath: "assets/images/amman_citadel.jpg",
              iconBackgroundColor: const Color(0xFFD9E7EC),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VoiceGuideScreen(),
                  ),
                );
              },
            ),

            ServiceCard(
              title: "Crowd Monitor",
              subtitle: "Check live crowd levels",
              icon: Icons.groups_rounded,
              imagePath: "assets/images/jerash.jpg",
              iconBackgroundColor: const Color(0xFFF1DDD5),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CrowdMonitorScreen(),
                  ),
                );
              },
            ),

            ServiceCard(
              title: "Heritage AI",
              subtitle: "Restore ancient landmarks",
              icon: Icons.castle_rounded,
              imagePath: "assets/images/ajloun_castle.jpg",
              iconBackgroundColor: const Color(0xFFE8E2D8),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const HeritageReconstructionScreen(),
                  ),
                );
              },
            ),

            ServiceCard(
              title: "Favorites",
              subtitle: "Your saved places",
              icon: Icons.favorite_rounded,
              imagePath: "assets/images/dead_sea.jpg",
              iconBackgroundColor: const Color(0xFFF3DCDD),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FavoritesScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}