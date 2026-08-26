import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/collection_service.dart';

class CollectionSelectionBottomSheet extends StatefulWidget {
  final Function(String collectionName) onCollectionSelected;

  const CollectionSelectionBottomSheet({
    super.key,
    required this.onCollectionSelected,
  });

  @override
  State<CollectionSelectionBottomSheet> createState() =>
      _CollectionSelectionBottomSheetState();
}

class _CollectionSelectionBottomSheetState
    extends State<CollectionSelectionBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  List<String> collections = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingCollections();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadExistingCollections() async {
    try {
      final collectionNames = await CollectionService().getCollectionNames();
      if (mounted) {
        setState(() {
          collections = collectionNames;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      debugPrint('Error loading collections: $e');
    }
  }

  void _showNewCollectionDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'New Collection',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D1810),
                ),
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Collection Name...',
                  hintStyle: GoogleFonts.lora(
                    color: Colors.grey[400],
                    fontSize: 16.sp,
                  ),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF8B4513)),
                  ),
                ),
                style: GoogleFonts.lora(
                  fontSize: 16.sp,
                  color: const Color(0xFF2D1810),
                ),
                autofocus: true,
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        _controller.clear();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.lora(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_controller.text.trim().isNotEmpty) {
                          final collectionName = _controller.text.trim();
                          _controller.clear();
                          Navigator.pop(context); // Dialog'u kapat
                          widget.onCollectionSelected(collectionName);
                          Navigator.pop(context); // Bottom sheet'i kapat
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B4513),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.lora(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(top: 12.h),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    color: const Color(0xFF2D1810),
                    size: 24.sp,
                  ),
                ),
                Text(
                  'Collection',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D1810),
                  ),
                ),
                SizedBox(width: 24.w),
              ],
            ),
          ),
          Flexible(
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    child: ElevatedButton(
                      onPressed: _showNewCollectionDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8D5C4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        minimumSize: Size(double.infinity, 50.h),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add,
                            color: const Color(0xFF8B4513),
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Add Collection',
                            style: GoogleFonts.lora(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8B4513),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  if (isLoading)
                    Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: const Color(0xFF8B4513),
                        ),
                      ),
                    )
                  else if (collections.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.collections_outlined,
                              size: 64.sp,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'No collections yet',
                              style: GoogleFonts.lora(
                                fontSize: 16.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Create your first collection to\norganize your antiques',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lora(
                                fontSize: 14.sp,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: collections.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            onTap: () {
                              widget.onCollectionSelected(collections[index]);
                              Navigator.pop(context);
                            },
                            leading: Container(
                              width: 40.w,
                              height: 40.w,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B4513).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.folder_outlined,
                                color: const Color(0xFF8B4513),
                                size: 20.sp,
                              ),
                            ),
                            title: Text(
                              collections[index],
                              style: GoogleFonts.lora(
                                fontSize: 16.sp,
                                color: const Color(0xFF2D1810),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}