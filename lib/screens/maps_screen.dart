import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'login_screen.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _HighEndAppState();
}

class _HighEndAppState extends State<MapsScreen> with TickerProviderStateMixin {
  // Google Maps controller
  GoogleMapController? _mapController;
  final LatLng _center = const LatLng(28.6139, 77.2090);
  final Set<Marker> _markers = {};
  
  // Search controller
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredLocations = [];

  // Carousel controller
  late PageController _carouselController;

  final List<Map<String, dynamic>> _locations = [
    {
      "id": "doc1",
      "title": "Dr. Priya Sharma",
      "subtitle": "Clinical Psychologist",
      "position": LatLng(28.6145, 77.2100),
      "icon": "assets/icons/doctor.png",
      "photo": "https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=400&h=400&fit=crop&crop=face",
      "experience": "15 years",
      "specialization": "Anxiety, Depression, PTSD",
      "rating": 4.9,
      "reviews": 234,
      "fees": "₹1,500",
      "availability": "Mon-Sat 10AM-6PM",
      "phone": "+91 98765 43210",
      "description": "Specialized in cognitive behavioral therapy with expertise in treating anxiety disorders and depression."
    },
    {
      "id": "yoga1",
      "title": "Calm Space Yoga",
      "subtitle": "Yoga & Meditation Studio",
      "position": LatLng(28.6120, 77.2080),
      "icon": "assets/icons/yoga.png",
      "photo": "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400&h=400&fit=crop",
      "experience": "8 years",
      "specialization": "Hatha Yoga, Meditation, Pranayama",
      "rating": 4.7,
      "reviews": 156,
      "fees": "₹800/session",
      "availability": "Daily 6AM-8PM",
      "phone": "+91 98765 43211",
      "description": "Peaceful environment for yoga practice and meditation with certified instructors."
    },
    {
      "id": "ther1",
      "title": "Mind Healers Center",
      "subtitle": "Therapy & Counseling",
      "position": LatLng(28.6160, 77.2125),
      "icon": "assets/icons/therapy.png",
      "photo": "https://images.unsplash.com/photo-1582750433449-648ed127bb54?w=400&h=400&fit=crop",
      "experience": "12 years",
      "specialization": "Family Therapy, Couples Counseling",
      "rating": 4.8,
      "reviews": 189,
      "fees": "₹2,000",
      "availability": "Mon-Fri 9AM-7PM",
      "phone": "+91 98765 43212",
      "description": "Comprehensive mental health services with team of experienced therapists and counselors."
    },
    {
      "id": "doc2",
      "title": "Dr. Rajesh Mehra",
      "subtitle": "Psychiatrist",
      "position": LatLng(28.6170, 77.2110),
      "icon": "assets/icons/doctor.png",
      "photo": "https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=400&h=400&fit=crop&crop=face",
      "experience": "20 years",
      "specialization": "Bipolar Disorder, Schizophrenia, OCD",
      "rating": 4.9,
      "reviews": 312,
      "fees": "₹2,500",
      "availability": "Tue-Sun 11AM-5PM",
      "phone": "+91 98765 43213",
      "description": "Senior psychiatrist with extensive experience in treating complex mental health conditions."
    },
    {
      "id": "yoga2",
      "title": "Zen Yoga Studio",
      "subtitle": "Therapeutic Yoga",
      "position": LatLng(28.6100, 77.2095),
      "icon": "assets/icons/yoga.png",
      "photo": "https://images.unsplash.com/photo-1506629905543-2f181773b3d8?w=400&h=400&fit=crop",
      "experience": "10 years",
      "specialization": "Therapeutic Yoga, Stress Relief",
      "rating": 4.6,
      "reviews": 98,
      "fees": "₹1,000/session",
      "availability": "Daily 7AM-9PM",
      "phone": "+91 98765 43214",
      "description": "Specialized in therapeutic yoga practices for mental wellness and stress management."
    },
    {
      "id": "doc3",
      "title": "Dr. Anita Gupta",
      "subtitle": "Child Psychologist",
      "position": LatLng(28.6180, 77.2140),
      "icon": "assets/icons/doctor.png",
      "photo": "https://images.unsplash.com/photo-1594824919066-1e75e0b1a1bf?w=400&h=400&fit=crop&crop=face",
      "experience": "12 years",
      "specialization": "Child Psychology, ADHD, Autism",
      "rating": 4.8,
      "reviews": 167,
      "fees": "₹1,800",
      "availability": "Mon-Sat 2PM-8PM",
      "phone": "+91 98765 43215",
      "description": "Dedicated child psychologist specializing in developmental disorders and behavioral issues."
    },
  ];

  int _selectedIndex = 0;
  late AnimationController _particleController;
  final List<FloatingParticle> _particles = [];
  bool _showSearchResults = false;

  // Animation controllers for fancy UI
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _filteredLocations = List.from(_locations);
    _initializeMarkers();
    _initializeParticles();
    _particleController =
        AnimationController(duration: const Duration(seconds: 10), vsync: this)
          ..repeat();

    _fadeController =
        AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
    
    // Initialize the carousel controller
    _carouselController = PageController(viewportFraction: 0.8);
  }

  void _initializeMarkers() {
    _markers.clear();
    for (var loc in _locations) {
      _markers.add(Marker(
          markerId: MarkerId(loc['id']),
          position: loc['position'],
          infoWindow: InfoWindow(
            title: loc['title'], 
            snippet: '${loc['subtitle']} • Rating: ${loc['rating']}'
          ),
          onTap: () => _showLocationDetails(loc)));
    }
  }

  void _initializeParticles() {
    for (int i = 0; i < 25; i++) {
      _particles.add(FloatingParticle());
    }
  }

  void _goToLocation(LatLng target) {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 15));
  }

  void _searchLocations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLocations = List.from(_locations);
        _showSearchResults = false;
      } else {
        _filteredLocations = _locations.where((location) {
          return location['title'].toLowerCase().contains(query.toLowerCase()) ||
                 location['subtitle'].toLowerCase().contains(query.toLowerCase()) ||
                 location['specialization'].toLowerCase().contains(query.toLowerCase());
        }).toList();
        _showSearchResults = true;
      }
    });
  }

  void _showLocationDetails(Map<String, dynamic> location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildLocationDetailSheet(location),
    );
  }

  // Helper method for glassmorphism effect
  Widget _glassContainer({
    required Widget child,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    double opacity = 0.15,
    double blur = 10.0,
    Border? border,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: border ?? Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(opacity),
              borderRadius: borderRadius ?? BorderRadius.circular(12),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  // Helper method to get background images based on provider type
  String _getBackgroundImage(String id) {
    if (id.startsWith('doc')) {
      // Medical/doctor backgrounds
      final doctorBgs = [
        'https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?w=800&h=400&fit=crop', // Medical office
        'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800&h=400&fit=crop', // Hospital corridor
        'https://images.unsplash.com/photo-1516549655169-df83a0774514?w=800&h=400&fit=crop', // Medical equipment
      ];
      return doctorBgs[Random().nextInt(doctorBgs.length)];
    } else if (id.startsWith('yoga')) {
      // Yoga/wellness backgrounds
      final yogaBgs = [
        'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=400&fit=crop', // Yoga studio
        'https://images.unsplash.com/photo-1545389336-cf090694435e?w=800&h=400&fit=crop', // Meditation space
        'https://images.unsplash.com/photo-1588286840104-8957b019727f?w=800&h=400&fit=crop', // Peaceful yoga
      ];
      return yogaBgs[Random().nextInt(yogaBgs.length)];
    } else if (id.startsWith('ther')) {
      // Therapy/counseling backgrounds
      final therapyBgs = [
        'https://images.unsplash.com/photo-1559757175-0eb30cd8c063?w=800&h=400&fit=crop', // Comfortable office
        'https://images.unsplash.com/photo-1586105251261-72a756497a11?w=800&h=400&fit=crop', // Therapy room
        'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=800&h=400&fit=crop', // Calming space
      ];
      return therapyBgs[Random().nextInt(therapyBgs.length)];
    }
    
    // Default background
    return 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?w=800&h=400&fit=crop';
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _particleController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 13),
            markers: _markers,
            onMapCreated: (c) => _mapController = c,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),

          // Animated particles overlay
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return Stack(
                  children: _particles
                      .map((p) => Positioned(
                            left: p.x +
                                sin(_particleController.value * 2 * pi + p.phase) *
                                    p.amplitude,
                            top: p.y +
                                cos(_particleController.value * 2 * pi + p.phase) *
                                    p.amplitude,
                            child: Opacity(
                              opacity: (sin(_particleController.value * 2 * pi + p.phase) +
                                      1) /
                                  2 *
                                  0.5,
                              child: Container(
                                width: p.size,
                                height: p.size,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.white.withOpacity(0.5),
                                          blurRadius: 4)
                                    ]),
                              ),
                            ),
                          ))
                      .toList());
            },
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.purple.withOpacity(0.2),
                  Colors.blue.withOpacity(0.1),
                  Colors.black.withOpacity(0.3)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Animated top search bar
          FadeTransition(
            opacity: _fadeAnimation,
            child: Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: _buildSearchBar(),
            ),
          ),

          // Search results overlay
          if (_showSearchResults)
            Positioned(
              top: 110,
              left: 20,
              right: 20,
              child: _buildSearchResults(),
            ),

          // Floating action buttons
          Positioned(
            right: 16,
            bottom: 200,
            child: Column(
              children: [
                _buildFab(Icons.gps_fixed, () => _goToLocation(_center)),
                const SizedBox(height: 12),
                _buildFab(Icons.layers, () {
                  // Toggle map type functionality can be added here
                }),
              ],
            ),
          ),

          // Bottom carousel - COMPLETELY ISOLATED FROM MAP
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 200,
              // IMPORTANT: Prevent any interaction with the map behind
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: _buildBottomCarousel(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: _glassContainer(
        opacity: 0.25,
        blur: 15.0,
        borderRadius: BorderRadius.zero,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Text(
                  "User Menu",
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white),
              title: const Text("Profile", style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text("Settings", style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text("Logout", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.blue.withOpacity(0.05),
            Colors.purple.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.purple.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.cyan.withOpacity(0.08),
                  Colors.indigo.withOpacity(0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _searchLocations,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
              decoration: InputDecoration(
                hintText: "Find your wellness companion...",
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                prefixIcon: Container(
                  margin: const EdgeInsets.only(left: 4, right: 8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow effect
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.cyan.withOpacity(0.3),
                              Colors.transparent,
                            ],
                            stops: const [0.3, 1.0],
                          ),
                        ),
                      ),
                      // Main icon
                      Icon(
                        Icons.psychology_outlined,
                        color: Colors.white.withOpacity(0.9),
                        size: 20,
                      ),
                    ],
                  ),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? Container(
                        margin: const EdgeInsets.only(right: 4),
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.red.withOpacity(0.3),
                                  Colors.pink.withOpacity(0.2),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.clear,
                              color: Colors.white.withOpacity(0.9),
                              size: 14,
                            ),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _searchLocations('');
                          },
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Animated pulse for wellness theme
                            AnimatedBuilder(
                              animation: _particleController,
                              builder: (context, child) {
                                return Container(
                                  width: 20 + sin(_particleController.value * 2 * pi) * 4,
                                  height: 20 + sin(_particleController.value * 2 * pi) * 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.green.withOpacity(0.2),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.3, 1.0],
                                    ),
                                  ),
                                );
                              },
                            ),
                            // Heart icon for wellness
                            Icon(
                              Icons.favorite_outline,
                              color: Colors.white.withOpacity(0.6),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return _glassContainer(
      opacity: 0.25,
      blur: 15.0,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _filteredLocations.length,
          itemBuilder: (context, index) {
            final location = _filteredLocations[index];
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(location['photo']),
                  backgroundColor: Colors.grey[700],
                ),
                title: Text(location['title'], style: const TextStyle(color: Colors.white)),
                subtitle: Text(location['subtitle'], style: TextStyle(color: Colors.white70)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 16),
                    Text(' ${location['rating']}', style: const TextStyle(color: Colors.white)),
                  ],
                ),
                onTap: () {
                  _searchController.clear();
                  _searchLocations('');
                  _goToLocation(location['position']);
                  _showLocationDetails(location);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLocationDetailSheet(Map<String, dynamic> location) {
    return _glassContainer(
      height: MediaQuery.of(context).size.height * 0.8,
      opacity: 0.25,
      blur: 20.0,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile section
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(location['photo']),
                        backgroundColor: Colors.grey[700],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              location['title'],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              location['subtitle'],
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.orange, size: 20),
                                Text(
                                  ' ${location['rating']} (${location['reviews']} reviews)',
                                  style: const TextStyle(fontSize: 14, color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Details cards
                  _buildDetailCard('Experience', location['experience'], Icons.work),
                  _buildDetailCard('Specialization', location['specialization'], Icons.psychology),
                  _buildDetailCard('Consultation Fees', location['fees'], Icons.currency_rupee),
                  _buildDetailCard('Availability', location['availability'], Icons.access_time),
                  _buildDetailCard('Phone', location['phone'], Icons.phone),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    location['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Implement call functionality
                            },
                            icon: const Icon(Icons.phone),
                            label: const Text('Call'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Implement booking functionality
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Book Appointment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
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
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon) {
    return _glassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      opacity: 0.15,
      blur: 10.0,
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[300], size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCarousel() {
    return Container(
      height: 200,
      child: Stack(
        children: [
          // Main carousel
          PageView.builder(
            controller: _carouselController,
            itemCount: _locations.length,
            itemBuilder: (context, index) {
              final loc = _locations[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
                child: _glassContainer(
                  opacity: 0.2,
                  blur: 15.0,
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Background image with overlay
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              // Background image
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  image: DecorationImage(
                                    image: NetworkImage(_getBackgroundImage(loc['id'])),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              // Gradient overlay for better text readability
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withOpacity(0.7),
                                      Colors.black.withOpacity(0.3),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Content
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          _goToLocation(loc['position']);
                          _showLocationDetails(loc);
                        },
                        child: Row(
                          children: [
                            Container(
                              margin: const EdgeInsets.all(12),
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                image: DecorationImage(
                                  image: NetworkImage(loc['photo']),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc['title'],
                                      style: const TextStyle(
                                        fontSize: 16, 
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black,
                                            offset: Offset(1, 1),
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      loc['subtitle'],
                                      style: TextStyle(
                                        fontSize: 12, 
                                        color: Colors.white.withOpacity(0.9),
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black,
                                            offset: Offset(1, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      loc['specialization'],
                                      style: TextStyle(
                                        fontSize: 11, 
                                        color: Colors.white.withOpacity(0.8),
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black,
                                            offset: Offset(1, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.orange, size: 16),
                                        const SizedBox(width: 2),
                                        Text(
                                          "${loc['rating']}", 
                                          style: const TextStyle(
                                            fontSize: 12, 
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          loc['fees'], 
                                          style: TextStyle(
                                            fontSize: 11, 
                                            color: Colors.green[300],
                                            fontWeight: FontWeight.w600,
                                            shadows: const [
                                              Shadow(
                                                color: Colors.black,
                                                offset: Offset(1, 1),
                                                blurRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.8),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Text(
                                            "View", 
                                            style: TextStyle(
                                              color: Colors.white, 
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Left navigation arrow
          Positioned(
            left: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: _glassContainer(
                width: 45,
                height: 45,
                opacity: 0.25,
                blur: 10.0,
                borderRadius: BorderRadius.circular(22.5),
                child: IconButton(
                  onPressed: () {
                    if (_carouselController.hasClients) {
                      _carouselController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          
          // Right navigation arrow
          Positioned(
            right: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: _glassContainer(
                width: 45,
                height: 45,
                opacity: 0.25,
                blur: 10.0,
                borderRadius: BorderRadius.circular(22.5),
                child: IconButton(
                  onPressed: () {
                    if (_carouselController.hasClients) {
                      _carouselController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          
          // Page indicator dots
          Positioned(
            bottom: 5,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _locations.length,
                (index) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.7),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(IconData icon, VoidCallback onPressed) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: _glassContainer(
        width: 40,
        height: 40,
        opacity: 0.15,
        blur: 10.0,
        borderRadius: BorderRadius.circular(20),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 20),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

// Floating particles class
class FloatingParticle {
  late double x;
  late double y;
  late double size;
  late double phase;
  late double amplitude;

  FloatingParticle() {
    final random = Random();
    x = random.nextDouble() * 400;
    y = random.nextDouble() * 800;
    size = random.nextDouble() * 4 + 2;
    phase = random.nextDouble() * 2 * pi;
    amplitude = random.nextDouble() * 50 + 25;
  }
}