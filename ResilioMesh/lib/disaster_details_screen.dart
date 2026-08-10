import 'package:flutter/material.dart';

// ==========================================
// DATA MODELS
// ==========================================
class DisasterInfo {
  final String title;
  final IconData icon;
  final Color color;
  final String overview;
  final List<String> dos;
  final List<String> donts;
  final String beforeText;
  final String duringText;
  final String afterText;

  const DisasterInfo({
    required this.title,
    required this.icon,
    required this.color,
    required this.overview,
    required this.dos,
    required this.donts,
    required this.beforeText,
    required this.duringText,
    required this.afterText,
  });
}

// ==========================================
// SAMPLE DATA REPOSITORY
// ==========================================
final List<DisasterInfo> allDisasters = [
  DisasterInfo(
    title: 'Flood',
    icon: Icons.house_siding_rounded,
    color: Color(0xFF2196F3),
    overview: 'Flooding occurs when heavy rainfall, overflowing rivers, or storm surges overwhelm drainage systems, inundating low-lying land and threatening human life and infrastructure.',
    dos: [
      'Move to higher ground or upper floors immediately.',
      'Switch off electricity, main breakers, and gas valves safely.',
      'Store clean drinking water, dry rations, and critical medications.',
      'Keep battery-powered or emergency radios tuned for official alerts.',
      'Wear sturdy footwear and avoid contact with stagnant flood waters.',
    ],
    donts: [
      'Do not walk, swim, or wade through fast-moving flash flood currents.',
      'Do not touch submerged electrical appliances, wires, or power poles.',
      'Do not drive vehicles through flooded roadways or underpasses.',
      'Do not consume food items that have come in direct contact with flood waters.',
      'Do not return to evacuated zones until local authorities give explicit clearance.',
    ],
    beforeText: 'Identify local flood evacuation routes, compile emergency kits with documents in waterproof bags, and clear home drainage pathways.',
    duringText: 'Monitor emergency broadcast channels, secure outdoor furniture, keep mobile communication devices charged, and assist vulnerable neighbors.',
    afterText: 'Inspect your property carefully for structural cracks or gas leaks, discard contaminated water, and disinfect living spaces.',
  ),
  DisasterInfo(
    title: 'Fire',
    icon: Icons.local_fire_department_rounded,
    color: Color(0xFFFF5722),
    overview: 'Uncontrolled fires spread rapidly, generating toxic smoke and extreme heat that can trap occupants inside homes or buildings within minutes.',
    dos: [
      'Stay low to the ground beneath smoke levels during evacuation.',
      'Feel closed doors with the back of your hand before opening them.',
      'Use the PASS method if operating an approved fire extinguisher.',
      'Cover your nose and mouth with a damp cloth if smoke is present.',
    ],
    donts: [
      'Do not use elevators during a building fire emergency.',
      'Do not open doors that feel hot or allow smoke to seep through cracks.',
      'Do not stop to collect personal belongings or valuables.',
      'Never throw water on oil, grease, or electrical fires.',
    ],
    beforeText: 'Install smoke detectors on every floor, test batteries monthly, and establish a clear family fire escape plan.',
    duringText: 'Sound the alarm immediately, alert others, drop low, and evacuate through the nearest safe designated exit.',
    afterText: 'Remain outside at your assembly point, check in with rescue personnel, and never re-enter the building until declared safe.',
  ),
  DisasterInfo(
    title: 'Earthquake',
    icon: Icons.terrain_rounded,
    color: Color(0xFF795548),
    overview: 'Earthquakes cause sudden, violent ground shaking capable of collapsing structures, rupturing utility lines, and triggering landslides.',
    dos: [
      'Drop to your hands and knees so you are not knocked down.',
      'Cover your head and neck under a sturdy table or desk.',
      'Hold on to your shelter and stay clear of glass or falling objects.',
      'Stay inside until shaking stops and it is safe to exit.',
    ],
    donts: [
      'Do not run outside or rush down stairwells while the ground is shaking.',
      'Do not stand near exterior walls, brick chimneys, or hanging light fixtures.',
      'Do not use elevators during or immediately after the event.',
    ],
    beforeText: 'Secure heavy bookshelves and wall units to studs, store heavy items on lower shelves, and identify safe spots in each room.',
    duringText: 'Execute Drop, Cover, and Hold On immediately. Protect your vital organs and stay away from windows.',
    afterText: 'Expect aftershocks, check for gas leaks or electrical short circuits, and listen to battery-operated radios for instructions.',
  ),
  DisasterInfo(
    title: 'Cyclone / Storm',
    icon: Icons.air_rounded,
    color: Color(0xFF00BCD4),
    overview: 'Severe cyclonic storms bring destructive winds, torrential rainfall, and coastal storm surges that disrupt power and tear down infrastructure.',
    dos: [
      'Board up glass windows or secure storm shutters tightly.',
      'Move all loose outdoor objects, patio furniture, and garden tools indoors.',
      'Stock up on adequate non-perishable food supplies and drinking water.',
    ],
    donts: [
      'Do not venture outdoors during the calm eye of the storm, as winds will return suddenly.',
      'Do not ignore evacuation orders issued by local meteorological departments.',
      'Do not touch downed power lines or damaged utility poles.',
    ],
    beforeText: 'Trim weak tree branches near your house, inspect roof tiles, and pack an emergency grab-bag with documents.',
    duringText: 'Stay away from windows and glass doors, move to a small interior room on the lower floor, and stay informed.',
    afterText: 'Beware of fallen trees, contaminated water sources, and live wires hanging loosely on streets.',
  ),
  DisasterInfo(
    title: 'Building Collapse',
    icon: Icons.business_outlined,
    color: Color(0xFF607D8B),
    overview: 'Structural failures can happen due to natural calamities or weak construction, trapping individuals under heavy debris and rubble.',
    dos: [
      'Protect your head and face using arms, clothing, or a sturdy barrier.',
      'Tap on pipes or walls so rescuers can hear your acoustic location signals.',
      'Cover your nose and mouth with fabric to minimize dust inhalation.',
    ],
    donts: [
      'Do not light matches or lighters, as gas lines might be leaking nearby.',
      'Do not shout continuously; conserve your breath and energy for when rescuers are close.',
      'Do not panic or move heavy debris blindly that could trigger secondary collapses.',
    ],
    beforeText: 'Be aware of visible structural cracks, sagging ceilings, or unauthorized modifications in older buildings.',
    duringText: 'Seek immediate cover under strong architectural elements like doorframes, heavy tables, or support columns.',
    afterText: 'Remain calm, stay still if trapped, signal using a whistle or tapping tool, and wait for professional extraction teams.',
  ),
  DisasterInfo(
    title: 'Medical Emergency',
    icon: Icons.add_box_rounded,
    color: Color(0xFFE91E63),
    overview: 'Critical medical situations require immediate, calm intervention and first-aid application before professional paramedics arrive.',
    dos: [
      'Call local emergency response lines or medical helplines instantly.',
      'Apply direct pressure with clean fabric to stop severe bleeding.',
      'Keep the injured person calm, comfortable, and warm.',
    ],
    donts: [
      'Do not move an injured person with suspected spinal trauma unless absolutely necessary.',
      'Do not give food or water to an unconscious or semi-conscious individual.',
      'Do not panic; assess the airway, breathing, and circulation (ABC) calmly.',
    ],
    beforeText: 'Keep a well-stocked first aid kit at home and learn basic CPR and wound management procedures.',
    duringText: 'Evaluate the scene for safety hazards, ensure professional help is called, and administer basic life support steps.',
    afterText: 'Hand over patient history and notes to medical professionals upon arrival.',
  ),
  DisasterInfo(
    title: 'Electrical Hazard',
    icon: Icons.power_rounded,
    color: Color(0xFFFFC107),
    overview: 'Faulty wiring, wet switches, and downed power lines present severe electrocution and burn risks.',
    dos: [
      'Turn off the main circuit breaker box immediately in case of an electrical fault.',
      'Use non-conductive wooden or plastic items to separate victims from live circuits.',
      'Wear rubber-soled shoes when dealing with wet electrical setups.',
    ],
    donts: [
      'Do not touch a person connected to a live electrical source with bare hands.',
      'Do not use water to extinguish electrical equipment fires.',
      'Do not overload multi-plug adapters or run wires under heavy carpets.',
    ],
    beforeText: 'Inspect frayed cords regularly, keep appliances away from water sources, and use surge protectors.',
    duringText: 'Cut power supply instantly via mains before attempting any rescue or inspection.',
    afterText: 'Call a certified electrician to inspect wiring before turning power back on.',
  ),
  DisasterInfo(
    title: 'Chemical Leak',
    icon: Icons.science_rounded,
    color: Color(0xFF9C27B0),
    overview: 'Hazardous material spills or gas cylinder leaks release toxic fumes that endanger respiratory tracts and public safety.',
    dos: [
      'Evacuate perpendicular to the wind direction immediately.',
      'Seal doors, windows, and ventilation gaps with wet towels if sheltering in place.',
      'Wash exposed skin thoroughly with clean running water if contaminated.',
    ],
    donts: [
      'Do not inhale vapors or inspect chemical containers without proper PPE.',
      'Do not use open flames or switch on electrical lights if a gas leak is suspected.',
      'Do not consume open food items exposed to chemical fumes.',
    ],
    beforeText: 'Know the location of gas shut-off valves and identify local industrial hazard zones.',
    duringText: 'Cover face with a damp respirator mask, move uphill or upwind, and follow civil defense advisories.',
    afterText: 'Seek medical evaluation immediately if experiencing dizziness, coughing, or skin irritation.',
  ),
  DisasterInfo(
    title: 'General Safety',
    icon: Icons.shield_rounded,
    color: Color(0xFF3F51B5),
    overview: 'General preparedness, maintaining emergency kits, and situational awareness protect communities across all hazard types.',
    dos: [
      'Maintain an updated emergency bag containing documents, flashlights, and water.',
      'Identify family meeting points and keep emergency contact numbers saved.',
      'Stay tuned to verified government notification channels.',
    ],
    donts: [
      'Do not spread unverified rumors or panic messages on social media.',
      'Do not ignore official weather or disaster warning advisories.',
      'Do not travel into unknown or cordoned-off disaster zones.',
    ],
    beforeText: 'Conduct periodic family evacuation drills and maintain your home emergency inventory.',
    duringText: 'Stay calm, follow official instructions, and help vulnerable members of your community.',
    afterText: 'Review your emergency preparedness plan and restock depleted supplies.',
  ),
];

// ==========================================
// MAIN SELECTION SCREEN (GRID VIEW)
// ==========================================
class DosDontsScreen extends StatelessWidget {
  const DosDontsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Do's & Don'ts",
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
              itemCount: allDisasters.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.88,
              ),
              itemBuilder: (context, index) {
                final disaster = allDisasters[index];
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
                            builder: (context) => DisasterDetailScreen(disaster: disaster),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              disaster.icon,
                              size: 38,
                              color: disaster.color,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              disaster.title,
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
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// DISASTER DETAIL SCREEN WITH TABS
// ==========================================
class DisasterDetailScreen extends StatefulWidget {
  final DisasterInfo disaster;

  const DisasterDetailScreen({super.key, required this.disaster});

  @override
  State<DisasterDetailScreen> createState() => _DisasterDetailScreenState();
}

class _DisasterDetailScreenState extends State<DisasterDetailScreen> {
  int _selectedTab = 0; // 0: Overview, 1: Do's, 2: Don'ts, 3: Before/During/After

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.disaster.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFF5252),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Banner Image Container matching your screenshots
          Container(
            height: 180,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1547683905-f686c993aae5?q=80&w=800&auto=format&fit=crop',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Navigation Tabs Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Expanded(child: _buildTabButton('Overview', 0)),
                const SizedBox(width: 4),
                Expanded(child: _buildTabButton("Do's", 1)),
                const SizedBox(width: 4),
                Expanded(child: _buildTabButton("Don'ts", 2)),
                const SizedBox(width: 4),
                Expanded(child: _buildTabButton('Before/During/After', 3)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
         

          // Tab Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF334155),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0: // Overview
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: Text(
            widget.disaster.overview,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF334155),
              height: 1.5,
            ),
          ),
        );

      case 1: // Do's
        return Column(
          children: [
            ...widget.disaster.dos.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF166534),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(14),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFBBF7D0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF16A34A), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Be prepared. Be safe.',
                    style: TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        );

      case 2: // Don'ts
        return Column(
          children: [
            ...widget.disaster.donts.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cancel, color: Color(0xFFDC2626), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF991B1B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(14),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFFECACA)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Your safety is more important.',
                    style: TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        );

      case 3: // Before / During / After
        return Column(
          children: [
            _buildPhaseCard('BEFORE', widget.disaster.beforeText, const Color(0xFF0284C7), const Color(0xFFE0F2FE)),
            const SizedBox(height: 14),
            _buildPhaseCard('DURING', widget.disaster.duringText, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
            const SizedBox(height: 14),
            _buildPhaseCard('AFTER', widget.disaster.afterText, const Color(0xFF7C3AED), const Color(0xFFF3E8FF)),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPhaseCard(String phaseTitle, String description, Color themeColor, Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: themeColor, width: 5)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                phaseTitle == 'BEFORE'
                    ? Icons.timer_outlined
                    : phaseTitle == 'DURING'
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                color: themeColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                phaseTitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF334155),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}