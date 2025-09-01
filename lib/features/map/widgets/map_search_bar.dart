import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/services/geocoding_service.dart';
import '../../../shared/services/haptic_feedback_service.dart';

class MapSearchBar extends StatefulWidget {
  final bool isVisible;
  final LatLng? userLocation;
  final Function(LatLng, {bool isCity}) onLocationSelected;

  const MapSearchBar({
    super.key,
    required this.isVisible,
    this.userLocation,
    required this.onLocationSelected,
  });

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<LocationSearchResult> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  Timer? _debounceTimer;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && widget.isVisible) {
        _animationController.forward();
      } else if (!_focusNode.hasFocus) {
        _animationController.reverse();
        setState(() {
          _showResults = false;
        });
      }
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _showResults = false;
        _isSearching = false;
      });
      return;
    }

    // Debounce the search
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
      _showResults = true;
    });

    try {
      final results = await GeocodingService.searchLocations(query, userLocation: widget.userLocation);
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults.clear();
          _isSearching = false;
        });
      }
    }
  }

  void _selectLocation(LocationSearchResult result) async {
    await HapticFeedbackService.selectionClick();
    
    _searchController.clear();
    _focusNode.unfocus();
    setState(() {
      _showResults = false;
      _searchResults.clear();
    });
    
    widget.onLocationSelected(result.location, isCity: result.isCity);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults.clear();
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search input field
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkCard
                      : AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: _focusNode.hasFocus 
                      ? Border.all(color: AppColors.trailGreen, width: 2)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Zoek locatie...',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: _focusNode.hasFocus ? AppColors.trailGreen : AppColors.textSecondary,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.clear, size: 20),
                            color: AppColors.textSecondary,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: const TextStyle(fontSize: 16),
                  textInputAction: TextInputAction.search,
                ),
              ),
              
              // Search results
              if (_showResults)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(top: 8),
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkCard
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildSearchResults(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.trailGreen),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Zoeken...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.search_off, color: AppColors.textSecondary, size: 16),
            const SizedBox(width: 12),
            Text(
              'Geen resultaten gevonden',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _selectLocation(result),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    result.isCity ? Icons.location_city : Icons.place,
                    color: result.isCity ? AppColors.trailGreen : AppColors.pathBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.shortName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        if (result.shortName != result.displayName)
                          Text(
                            result.displayName,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textSecondary,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}