import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// ==========================================
// DATA MODELS
// ==========================================

class DisasterCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<SafetyVideo> videos;

  const DisasterCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.videos,
  });
}

class SafetyVideo {
  final String title;
  final String duration;
  final String youtubeId;

  const SafetyVideo({
    required this.title,
    required this.duration,
    required this.youtubeId,
  });
}

// ==========================================
// VIDEO DATA (6 VIDEOS PER CATEGORY)
// ==========================================

final List<DisasterCategory> disasterCategories = [
  DisasterCategory(
    title: 'Flood',
    icon: Icons.house_siding_rounded,
    color: const Color(0xFF2196F3),
    videos: const [
      SafetyVideo(
        title: 'Flood Safety Rules & Preparation',
        duration: '2:15',
        youtubeId: '43M5mZuzHF8',
      ),
      SafetyVideo(
        title: 'How to Prepare for Urban Floods',
        duration: '3:10',
        youtubeId: 'k1ZInqB03rQ',
      ),
      SafetyVideo(
        title: 'Flash Flood Survival Guide',
        duration: '2:45',
        youtubeId: 'edC4pQeE03c',
      ),
      SafetyVideo(
        title: 'What to Do During & After Floods',
        duration: '4:12',
        youtubeId: '9hQZCiZ21fk',
      ),
      SafetyVideo(
        title: 'Home Flood Safety Protocol',
        duration: '3:05',
        youtubeId: 'PQV71INDaqY',
      ),
      SafetyVideo(
        title: 'Evacuation Safety During Severe Flooding',
        duration: '2:50',
        youtubeId: 'BLEPakj1YTY',
      ),
    ],
  ),
  DisasterCategory(
    title: 'Fire',
    icon: Icons.local_fire_department_rounded,
    color: const Color(0xFFFF5722),
    videos: const [
      SafetyVideo(
        title: 'How to Use a Fire Extinguisher (PASS Method)',
        duration: '2:15',
        youtubeId: 'PQV71INDaqY',
      ),
      SafetyVideo(
        title: 'Home Fire Safety Protocol',
        duration: '3:20',
        youtubeId: 'Kz9d28X0v-8',
      ),
      SafetyVideo(
        title: 'Kitchen Fire Safety & Emergency Handling',
        duration: '2:40',
        youtubeId: '43M5mZuzHF8',
      ),
      SafetyVideo(
        title: 'Electrical Fire Safety at Home',
        duration: '3:10',
        youtubeId: 'edC4pQeE03c',
      ),
      SafetyVideo(
        title: 'Smoke Detector & Escape Plan Essentials',
        duration: '2:25',
        youtubeId: 'k1ZInqB03rQ',
      ),
      SafetyVideo(
        title: 'Building Evacuation Drills for Fire Safety',
        duration: '3:45',
        youtubeId: 'BLEPakj1YTY',
      ),
    ],
  ),
  DisasterCategory(
    title: 'Earthquake',
    icon: Icons.terrain_rounded,
    color: const Color(0xFF795548),
    videos: const [
      SafetyVideo(
        title: 'Drop, Cover, and Hold On Protocol',
        duration: '2:05',
        youtubeId: 'BLEPakj1YTY',
      ),
      SafetyVideo(
        title: 'Earthquake Safety in High-Rise Buildings',
        duration: '3:15',
        youtubeId: '43M5mZuzHF8',
      ),
      SafetyVideo(
        title: 'What to Do Outdoors During an Earthquake',
        duration: '2:30',
        youtubeId: 'k1ZInqB03rQ',
      ),
      SafetyVideo(
        title: 'Emergency Kit Preparation for Earthquakes',
        duration: '4:10',
        youtubeId: 'PQV71INDaqY',
      ),
      SafetyVideo(
        title: 'Post-Earthquake Safety & Aftershock Steps',
        duration: '2:55',
        youtubeId: 'edC4pQeE03c',
      ),
      SafetyVideo(
        title: 'Structural Earthquake Defense Essentials',
        duration: '3:40',
        youtubeId: 'Kz9d28X0v-8',
      ),
    ],
  ),
  DisasterCategory(
    title: 'Cyclone / Storm',
    icon: Icons.air_rounded,
    color: const Color(0xFF00BCD4),
    videos: const [
      SafetyVideo(
        title: 'Cyclone Safety Precautions & Preparedness',
        duration: '2:50',
        youtubeId: 'k1ZInqB03rQ',
      ),
      SafetyVideo(
        title: 'Severe Storm Shelter Guidelines',
        duration: '3:12',
        youtubeId: '43M5mZuzHF8',
      ),
      SafetyVideo(
        title: 'High Wind and Hurricane Safety Rules',
        duration: '3:45',
        youtubeId: 'edC4pQeE03c',
      ),
      SafetyVideo(
        title: 'Thunderstorm & Lightning Safety Protocol',
        duration: '2:30',
        youtubeId: 'BLEPakj1YTY',
      ),
      SafetyVideo(
        title: 'Emergency Kit Setup for Cyclones',
        duration: '4:00',
        youtubeId: 'PQV71INDaqY',
      ),
      SafetyVideo(
        title: 'Coastal Evacuation Protocol During Storms',
        duration: '3:05',
        youtubeId: 'Kz9d28X0v-8',
      ),
    ],
  ),
  DisasterCategory(
    title: 'Building Collapse',
    icon: Icons.business_outlined,
    color: const Color(0xFF607D8B),
    videos: const [
      SafetyVideo(
        title: 'Structural Collapse Search & Survival Basics',
        duration: '3:30',
        youtubeId: 'BLEPakj1YTY',
      ),
      SafetyVideo(
        title: 'How to Survive Inside a Collapsed Building',
        duration: '4:10',
        youtubeId: '43M5mZuzHF8',
      ),
      SafetyVideo(
        title: 'Building Inspection & Cracks Warning Signs',
        duration: '3:15',
        youtubeId: 'k1ZInqB03rQ',
      ),
      SafetyVideo(
        title: 'Emergency Signals for Trapped Survival',
        duration: '2:45',
        youtubeId: 'PQV71INDaqY',
      ),
      SafetyVideo(
        title: 'Rescue Operations & Debris Safety',
        duration: '3:20',
        youtubeId: 'edC4pQeE03c',
      ),
      SafetyVideo(
        title: 'Emergency Shelters & Building Evacuation',
        duration: '3:50',
        youtubeId: 'Kz9d28X0v-8',
      ),
    ],
  ),
  DisasterCategory(
    title: 'Medical Emergency',
    icon: Icons.add_box_rounded,
    color: const Color(0xFFE91E63),
    videos: const [
      SafetyVideo(
        title: 'Basic First Aid & CPR Training Guide',
        duration: '4:20',
        youtubeId: 'PQV71INDaqY',
      ),
      SafetyVideo(
        title: 'How to Treat Severe Bleeding and Wounds',
        duration: '3:10',
        youtubeId: '43M5mZuzHF8',
      ),
      SafetyVideo(
        title: 'First Aid for Fractures and Sprains',
        duration: '2:55',
        youtubeId: 'k1ZInqB03rQ',
      ),
      SafetyVideo(
        title: 'Handling Unconsciousness & Fainting',
        duration: '2:35',
        youtubeId: 'BLEPakj1YTY',
      ),
      SafetyVideo(
        title: 'Choking First Aid for Adults & Children',
        duration: '3:40',
        youtubeId: 'edC4pQeE03c',
      ),
      SafetyVideo(
        title: 'Emergency Burn Relief & Treatment Protocol',
        duration: '3:00',
        youtubeId: 'Kz9d28X0v-8',
      ),
    ],
  ),
  DisasterCategory(
    title: 'Electrical Hazard',
    icon: Icons.power_rounded,
    color: const Color(0xFFFFC107),
    videos: const [
      SafetyVideo(
        title: 'Electrical Shock Safety & Prevention',
        duration: '3:05',
        youtubeId: 'edC4pQeE03c',
      ),
      SafetyVideo(
        title: 'What to Do in Case of Electrical Fire',
        duration: '2:40',
        youtubeId: 'PQV71INDaqY',
      ),
      SafetyVideo(
        title: 'Safe Use of Electrical Equipment at Home',
        duration: '3:30',
        youtubeId: '43M5mZuzHF8',
      ),
      SafetyVideo(
        title: 'Fallen Power Line Safety Precautions',
        duration: '2:15',
        youtubeId: 'k1ZInqB03rQ',
      ),
      SafetyVideo(
        title: 'Monsoon Electrical Safety Tips',
        duration: '2:50',
        youtubeId: 'BLEPakj1YTY',
      ),
      SafetyVideo(
        title: 'Breaker & Fuse Box Emergency Handling',
        duration: '3:15',
        youtubeId: 'Kz9d28X0v-8',
      ),
    ],
  ),
  DisasterCategory(
    title: 'Chemical Leak',
    icon: Icons.science_rounded,
    color: const Color(0xFF9C27B0),
    videos: const [
      SafetyVideo(
        title: 'Chemical Spill & Gas Leak Evacuation Tips',
        duration: '3:40',
        youtubeId: 'k1ZInqB03rQ',
      ),
      SafetyVideo(
        title: 'LPG Cylinder Gas Leakage Safety Protocol',
        duration: '2:30',
        youtubeId: 'PQV71INDaqY',
      ),
      SafetyVideo(
        title: 'Hazmat & Hazardous Material Safety',
        duration: '4:00',
        youtubeId: '43M5mZuzHF8',
      ),
      SafetyVideo(
        title: 'Shelter-in-Place for Toxic Gas Releases',
        duration: '3:15',
        youtubeId: 'edC4pQeE03c',
      ),
      SafetyVideo(
        title: 'Decontamination Steps After Chemical Exposure',
        duration: '3:50',
        youtubeId: 'BLEPakj1YTY',
      ),
      SafetyVideo(
        title: 'Industrial Chemical Leak Preparedness',
        duration: '3:25',
        youtubeId: 'Kz9d28X0v-8',
      ),
    ],
  ),
  DisasterCategory(
    title: 'General Safety',
    icon: Icons.shield_rounded,
    color: const Color(0xFF3F51B5),
    videos: const [
      SafetyVideo(
        title: 'Disaster Emergency Survival Kit Essentials',
        duration: '3:10',
        youtubeId: '43M5mZuzHF8',
      ),
      SafetyVideo(
        title: 'Family Disaster Action Plan Guide',
        duration: '4:15',
        youtubeId: 'k1ZInqB03rQ',
      ),
      SafetyVideo(
        title: 'Community Emergency Preparedness',
        duration: '3:35',
        youtubeId: 'BLEPakj1YTY',
      ),
      SafetyVideo(
        title: 'Emergency Helpline Numbers and Contacts',
        duration: '2:20',
        youtubeId: 'PQV71INDaqY',
      ),
      SafetyVideo(
        title: 'Psychological First Aid During Disasters',
        duration: '3:50',
        youtubeId: 'edC4pQeE03c',
      ),
      SafetyVideo(
        title: 'Evacuation Route Planning & Drills',
        duration: '3:00',
        youtubeId: 'Kz9d28X0v-8',
      ),
    ],
  ),
];

// ==========================================
// CATEGORY SELECTION SCREEN
// ==========================================

class SafetyTipsScreen extends StatelessWidget {
  const SafetyTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Safety Tips & Videos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFF5252),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a disaster or emergency',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: disasterCategories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.88,
              ),
              itemBuilder: (context, index) {
                final category = disasterCategories[index];
                return _CategoryCard(category: category);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final DisasterCategory category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CategoryVideoListScreen(category: category),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category.icon,
                  size: 38,
                  color: category.color,
                ),
                const SizedBox(height: 10),
                Text(
                  category.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// CATEGORY VIDEO LIST SCREEN
// ==========================================

class CategoryVideoListScreen extends StatelessWidget {
  final DisasterCategory category;

  const CategoryVideoListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          '${category.title} Safety Videos',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: category.color,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: category.videos.length,
        itemBuilder: (context, index) {
          final video = category.videos[index];
          final thumbnailUrl = 'https://img.youtube.com/vi/${video.youtubeId}/0.jpg';

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerScreen(
                      video: video,
                      categoryColor: category.color,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            thumbnailUrl,
                            width: 110,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              width: 110,
                              height: 70,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.play_circle_fill,
                                  color: Colors.red, size: 36),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                video.duration,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// NATIVE YOUTUBE PLAYER SCREEN
// ==========================================

class VideoPlayerScreen extends StatefulWidget {
  final SafetyVideo video;
  final Color categoryColor;

  const VideoPlayerScreen({
    super.key,
    required this.video,
    required this.categoryColor,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.youtubeId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openExternalYouTube() async {
    final Uri url = Uri.parse('https://www.youtube.com/watch?v=${widget.video.youtubeId}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch YouTube app')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: widget.categoryColor,
        progressColors: ProgressBarColors(
          playedColor: widget.categoryColor,
          handleColor: widget.categoryColor,
        ),
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            title: Text(
              widget.video.title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Column(
            children: [
              player,
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFF1E293B),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.video.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              color: widget.categoryColor, size: 18),
                          const SizedBox(width: 6),
                          const Text(
                            'Official Safety Guide',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 30),
                      const Text(
                        'This video provides essential steps to follow during a disaster emergency. Watch closely to learn safety protocols.',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openExternalYouTube,
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('Watch on YouTube App'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}