import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/auth_service.dart';
import '../services/donation_service.dart';

class AddFood extends StatefulWidget {
  @override
  _AddFoodState createState() => _AddFoodState();
}

class _AddFoodState extends State<AddFood> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController locationController = TextEditingController();

  String name = '';
  int quantity = 1;
  String location = '';
  String status = 'Pending';
  String description = '';
  bool _isSubmitting = false;
  bool _isFetchingLocation = false;
  double? _latitude;
  double? _longitude;
  DateTime? _expiryTime;

  static const List<String> statusOptions = [
    'Pending',
    'Ready for Pickup',
    'Delivered',
  ];

  @override
  void dispose() {
    locationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);

    try {
      debugPrint('📍 [AddFood] Requesting location permission...');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ [AddFood] Location services are disabled');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled. Please enable them in settings.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isFetchingLocation = false);
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('📍 [AddFood] Location permission denied, requesting...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('❌ [AddFood] Location permissions are denied');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are denied. Please grant permission in settings.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isFetchingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('❌ [AddFood] Location permissions are permanently denied');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied. Please enable them in app settings.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isFetchingLocation = false);
        return;
      }

      // Get current position
      debugPrint('📍 [AddFood] Fetching current position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      debugPrint('✅ [AddFood] Position fetched: ${position.latitude}, ${position.longitude}');
      _latitude = position.latitude;
      _longitude = position.longitude;

      // Convert coordinates to address (skip on web - use coordinates directly)
      debugPrint('📍 [AddFood] Converting coordinates to address...');
      
      if (kIsWeb) {
        debugPrint('🌐 [AddFood] Running on web - using coordinates directly');
        final String addressOrCoordinates = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        setState(() {
          location = addressOrCoordinates;
          _isFetchingLocation = false;
        });
        locationController.text = addressOrCoordinates;
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }
      
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          
          // Build address with null safety
          List<String> addressParts = [];
          if (place.street?.isNotEmpty == true) addressParts.add(place.street!);
          if (place.locality?.isNotEmpty == true) addressParts.add(place.locality!);
          if (place.administrativeArea?.isNotEmpty == true) addressParts.add(place.administrativeArea!);
          if (place.country?.isNotEmpty == true) addressParts.add(place.country!);
          
          String address = addressParts.isNotEmpty ? addressParts.join(', ') : 'Unknown location';
          debugPrint('✅ [AddFood] Address: $address');
          
          // Update the location field
          setState(() {
            location = address;
            _isFetchingLocation = false;
          });
          locationController.text = address;

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location fetched: ${place.locality ?? 'Unknown'}, ${place.administrativeArea ?? 'Unknown'}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          debugPrint('⚠️ [AddFood] No address found for coordinates');
          setState(() => _isFetchingLocation = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not fetch address for current location.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ [AddFood] Geocoding error: $e');
        // Fallback: use coordinates as location
        final String addressOrCoordinates = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        setState(() {
          location = addressOrCoordinates;
          _isFetchingLocation = false;
        });
        locationController.text = addressOrCoordinates;
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using coordinates: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [AddFood] Error fetching location: $e');
      setState(() => _isFetchingLocation = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectExpiryDateTime() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );

    if (picked != null && mounted) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (timePicked != null && mounted) {
        setState(() {
          _expiryTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Add Food Donation',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFC9A227),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C1810), Color(0xFF4A3728), Color(0xFF6B4423)],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            MediaQuery.of(context).size.width * 0.05,
            16,
            MediaQuery.of(context).size.width * 0.05,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 700),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFD4A574), Color(0xFFC9A227)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFFFFF), Color(0xFFECFCCB)],
                          ),
                        ),
                        child: const Icon(
                          Icons.food_bank_outlined,
                          size: 36,
                          color: Color(0xFF8B4513),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Share your food now',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Fill the donation details and publish instantly to Firestore.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 40 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          _buildField(
                            label: 'Food Name',
                            icon: Icons.restaurant_rounded,
                            validator: (value) => value!.trim().isEmpty ? 'Enter food name' : null,
                            onSaved: (value) => name = value!.trim(),
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            label: 'Quantity (in kg/units)',
                            icon: Icons.scale_rounded,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Enter quantity';
                              return int.tryParse(value.trim()) == null ? 'Enter a valid number' : null;
                            },
                            onSaved: (value) => quantity = int.parse(value!.trim()),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildField(
                                label: 'Pickup / Delivery Location',
                                icon: Icons.location_on_rounded,
                                controller: locationController,
                                validator: (value) => value!.trim().isEmpty ? 'Enter location' : null,
                                onSaved: (value) => location = value!.trim(),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _isFetchingLocation ? null : _getCurrentLocation,
                                  icon: _isFetchingLocation
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC9A227)),
                                          ),
                                        )
                                      : const Icon(Icons.my_location, size: 18),
                                  label: Text(
                                    _isFetchingLocation ? 'Fetching location...' : 'Use Current Location',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFC9A227),
                                    side: const BorderSide(color: Color(0xFFC9A227)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: status,
                            decoration: _fieldDecoration('Status', Icons.flag_rounded),
                            items: statusOptions
                                .map(
                                  (option) => DropdownMenuItem(
                                    value: option,
                                    child: Text(option),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  status = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: _selectExpiryDateTime,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, color: Color(0xFFC9A227)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _expiryTime != null
                                          ? 'Expires: ${_formatDateTime(_expiryTime!)}'
                                          : 'Select Expiry Date & Time',
                                      style: TextStyle(
                                        color: _expiryTime != null ? Colors.black87 : Colors.grey.shade600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: _fieldDecoration('Additional notes', Icons.notes_rounded),
                            maxLines: 4,
                            onSaved: (value) => description = value?.trim() ?? '',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () async {
                    if (!_formKey.currentState!.validate()) return;
                    _formKey.currentState!.save();

                    setState(() => _isSubmitting = true);

                    try {
                      final user = AuthService.currentUser;
                      if (user == null) {
                        debugPrint('❌ [AddFood] No authenticated user found');
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sign in again to submit donation.')),
                        );
                        setState(() => _isSubmitting = false);
                        return;
                      }

                      debugPrint('✅ [AddFood] User authenticated: ${user.uid}, ${user.email}');
                      debugPrint('📝 [AddFood] Calling DonationService.addDonation...');

                      final String submittedLocation = locationController.text.trim();
                      await DonationService.addDonation(
                        donorId: user.uid,
                        donorEmail: user.email ?? '',
                        name: name,
                        quantity: quantity,
                        location: submittedLocation,
                        status: status,
                        description: description,
                        latitude: _latitude,
                        longitude: _longitude,
                        expiryTime: _expiryTime,
                      );

                      debugPrint('✅ [AddFood] DonationService.addDonation completed successfully');

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Donation saved successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context, true);
                    } catch (e) {
                      debugPrint('❌ [AddFood] Error submitting donation: $e');
                      if (!mounted) return;
                      setState(() => _isSubmitting = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error submitting donation: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC9A227),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Donation',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF475569)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFC9A227), width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      prefixIcon: Icon(icon, color: const Color(0xFFC9A227)),
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _fieldDecoration(label, icon),
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,
    );
  }
}
