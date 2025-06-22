import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/location_service.dart';
import '../../data/models/location_model.dart';

/// Screen for sharing location
class LocationShareScreen extends StatefulWidget {
  final Function(LocationModel location) onLocationSelected;

  const LocationShareScreen({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<LocationShareScreen> createState() => _LocationShareScreenState();
}

class _LocationShareScreenState extends State<LocationShareScreen> {
  final LocationService _locationService = LocationService();
  
  LocationModel? _currentLocation;
  bool _isLoadingLocation = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      final location = await _locationService.getCurrentLocation();
      
      if (location != null) {
        setState(() {
          _currentLocation = location;
        });
      } else {
        setState(() {
          _errorMessage = 'Unable to get current location';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _shareCurrentLocation() {
    if (_currentLocation != null) {
      widget.onLocationSelected(_currentLocation!);
      Navigator.of(context).pop();
    }
  }

  void _copyLocationToClipboard() {
    if (_currentLocation != null) {
      final locationText = _locationService.generateLocationMessage(_currentLocation!);
      Clipboard.setData(ClipboardData(text: locationText));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location copied to clipboard')),
      );
    }
  }

  void _openInMaps() {
    if (_currentLocation != null) {
      final mapsUrl = _locationService.generateMapsUrl(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        label: 'My Location',
      );
      
      // In a real app, you would use url_launcher to open the URL
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maps URL: $mapsUrl')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Location'),
        actions: [
          if (_currentLocation != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _getCurrentLocation,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Share your location',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Your current location will be shared with the recipient',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Location Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildLocationContent(theme),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Action Buttons
            if (_currentLocation != null) ...[
              ElevatedButton.icon(
                onPressed: _shareCurrentLocation,
                icon: const Icon(Icons.send),
                label: const Text('Share This Location'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyLocationToClipboard,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openInMaps,
                      icon: const Icon(Icons.map),
                      label: const Text('Open Maps'),
                    ),
                  ),
                ],
              ),
            ],
            
            if (_isLoadingLocation) ...[
              ElevatedButton.icon(
                onPressed: null,
                icon: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                label: const Text('Getting Location...'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
            
            if (_errorMessage != null) ...[
              ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Privacy Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.privacy_tip_outlined,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Privacy Notice',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your location is shared directly with the recipient via P2P connection. No location data is stored on external servers.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationContent(ThemeData theme) {
    if (_isLoadingLocation) {
      return const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Getting your location...'),
        ],
      );
    }

    if (_errorMessage != null) {
      return Column(
        children: [
          Icon(
            Icons.location_off,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Location Error',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (_currentLocation == null) {
      return Column(
        children: [
          Icon(
            Icons.location_searching,
            size: 48,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No location available',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location Icon and Title
        Row(
          children: [
            Icon(
              Icons.location_on,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Current Location',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Address
        if (_currentLocation!.address != null) ...[
          Text(
            _currentLocation!.address!,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // Coordinates
        _buildInfoRow(
          icon: Icons.my_location,
          label: 'Coordinates',
          value: _currentLocation!.coordinatesString,
          theme: theme,
        ),
        
        const SizedBox(height: 8),
        
        // Accuracy
        if (_currentLocation!.accuracy != null)
          _buildInfoRow(
            icon: Icons.gps_fixed,
            label: 'Accuracy',
            value: _currentLocation!.accuracyString,
            theme: theme,
          ),
        
        const SizedBox(height: 8),
        
        // Timestamp
        _buildInfoRow(
          icon: Icons.access_time,
          label: 'Updated',
          value: _formatTimestamp(_currentLocation!.timestamp),
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
