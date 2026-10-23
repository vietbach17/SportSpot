import 'package:flutter/material.dart';
import '../../data/sportspot_mock_data.dart';
import '../../data/sportspot_models.dart';

class VenueDetailScreen extends StatefulWidget {
  final dynamic venue;

  const VenueDetailScreen({
    super.key,
    required this.venue,
  });

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  String selectedSport = 'Badminton';
  String selectedDay = '24';
  String selectedCourt = 'Court 1 - Premium Wood';
  final Set<int> selectedSlots = {3, 4}; // 18:00 & 19:00 default
  bool isSplitEnabled = true;

  final days = [
    {'day': '24', 'name': 'TODAY'},
    {'day': '25', 'name': 'FRI'},
    {'day': '26', 'name': 'SAT'},
    {'day': '27', 'name': 'SUN'},
    {'day': '28', 'name': 'MON'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int totalAmount = 0;
    for (var id in selectedSlots) {
      final slot = SportSpotMockData.timeSlots.firstWhere((s) => s.id == id);
      totalAmount += slot.price;
    }
    final int splitAmount = isSplitEnabled ? (totalAmount ~/ 4) : totalAmount;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181A22) : const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Venue Detail & Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép link sân! 📋')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã lưu vào danh sách yêu thích! ❤️')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image Card
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Image.network(
                        SportSpotMockData.cauGiayDetailHero,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 220,
                          color: const Color(0xFF1E212B),
                          child: const Center(
                            child: Icon(Icons.sports_tennis_rounded, color: Color(0xFF2563EB), size: 48),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified, size: 14, color: Color(0xFF2563EB)),
                              SizedBox(width: 4),
                              Text('Verified Spot', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.85),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: const Text('Open until 23:00', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: const Text('🏸 6 Pro Courts', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Title & Address
                Text(widget.venue.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${widget.venue.address} • ${widget.venue.distance}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),

                // Quick Hotline & Directions Actions
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Hotline: 0903123456')),
                        );
                      },
                      icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                      label: const Text('Hotline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đang mở bản đồ chỉ đường Google Maps...')),
                        );
                      },
                      icon: const Icon(Icons.directions_rounded, size: 16),
                      label: const Text('Chỉ đường', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Discipline Selector
                Row(
                  children: [
                    _buildDisciplineChip('🏸 Badminton', selectedSport == 'Badminton', () => setState(() => selectedSport = 'Badminton')),
                    const SizedBox(width: 8),
                    _buildDisciplineChip('🏓 Pickleball', selectedSport == 'Pickleball', () => setState(() => selectedSport = 'Pickleball')),
                  ],
                ),
                const SizedBox(height: 16),

                // Date Selector
                SizedBox(
                  height: 70,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: days.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = days[index];
                      final isSelected = selectedDay == item['day'];
                      return GestureDetector(
                        onTap: () => setState(() => selectedDay = item['day']!),
                        child: Container(
                          width: 65,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF2563EB) : (isDark ? const Color(0xFF242834) : Colors.white),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(item['name']!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white70 : Colors.grey)),
                              Text(item['day']!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Court & Slot Picker
                const Text('Pick Court & Slot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // Court Schematic Mini Diagram
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF20232E) : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.blue.shade200),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 14,
                              backgroundColor: Color(0x332563EB),
                              child: Text('C1', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.venue.name,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  const Text(
                                    'Premium Maple Wood • BWF Level 2',
                                    style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('LIVE CLEAR', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Time Slot Matrix Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.2,
                  children: SportSpotMockData.timeSlots.map((slot) {
                    final isSelected = selectedSlots.contains(slot.id);
                    if (slot.isBooked) {
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(slot.time, style: const TextStyle(fontSize: 11, decoration: TextDecoration.lineThrough, color: Colors.grey)),
                            const Text('Reserved', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selectedSlots.contains(slot.id)) {
                            selectedSlots.remove(slot.id);
                          } else {
                            selectedSlots.add(slot.id);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2563EB) : (isDark ? const Color(0xFF242834) : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? Colors.transparent : (isDark ? Colors.white12 : Colors.black12)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    slot.time,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : null),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white)
                                else
                                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                              ],
                            ),
                            Text(
                              '${slot.price ~/ 1000}k VND',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF2563EB)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Split Payment Switch
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF242834) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.group_add_rounded, color: Color(0xFF2563EB)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Split-Payment (Squad)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                  Text('Tự động chia tiền với 4 người trong đội', style: TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: isSplitEnabled,
                        onChanged: (val) => setState(() => isSplitEnabled = val),
                        activeColor: const Color(0xFF2563EB),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Booking Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF242834) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -4))],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total (${selectedSlots.length} Hours)', style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
                          Text('${totalAmount.toString()} VND', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                          if (isSplitEnabled)
                            Text('or ${splitAmount.toString()} VND / each', style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: selectedSlots.isEmpty
                          ? null
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🎉 Đặt sân thành công! Vé QR đã được tạo trong mục "Vé của tôi".'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                      ),
                      child: const Text('Đặt Sân Ngay', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisciplineChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}
