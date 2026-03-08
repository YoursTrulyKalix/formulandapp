import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:formulandsocialapp/core/app_styles.dart';
import 'package:formulandsocialapp/features/creations/create_modal.dart';

class CreationsScreen extends StatelessWidget {
  const CreationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 24),
              _buildFilterChips(),
              const SizedBox(height: 20),
              Expanded(
                child: MasonryGridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  itemCount: 8,
                  itemBuilder: (context, i) => _buildCreationCard(i),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton(
          backgroundColor: AppStyles.accentRed,
          elevation: 8,
          onPressed: () => showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => const CreatePostModal(),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("GARAGE", style: AppStyles.label),
        const SizedBox(height: 4),
        Text("Creations", style: AppStyles.headingXL),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = ["All", "Photos", "Race Logs", "Polls", "Analysis"];
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, i) => Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: i == 0 ? AppStyles.accentRed : AppStyles.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: i == 0 ? AppStyles.accentRed : AppStyles.borderColor,
            ),
          ),
          child: Text(
            filters[i],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: i == 0 ? Colors.white : AppStyles.textSub,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreationCard(int i) {
    final gradients = [
      [const Color(0xFF1A0000), const Color(0xFF2D0000)],
      [const Color(0xFF0D0D0D), const Color(0xFF1A1A1A)],
      [const Color(0xFF00091A), const Color(0xFF001128)],
      [const Color(0xFF0A0A00), const Color(0xFF1A1800)],
    ];
    final g = gradients[i % gradients.length];

    return Container(
      height: (i % 3 == 0) ? 220 : (i % 3 == 1) ? 160 : 190,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: g,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.borderColor, width: 1),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 12,
            left: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: i % 4 == 0
                        ? AppStyles.accentRed.withOpacity(0.9)
                        : AppStyles.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    i % 3 == 0 ? "PHOTO" : i % 3 == 1 ? "LOG" : "POLL",
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}