import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/app_provider.dart';
import '../../models/antique_model.dart';
import 'collection_viewmodel.dart';

class CollectionView extends StatefulWidget {
  const CollectionView({super.key});

  @override
  State<CollectionView> createState() => _CollectionViewState();
}

class _CollectionViewState extends State<CollectionView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CollectionViewModel>(context, listen: false).loadCollection();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CollectionViewModel, AppProvider>(
      builder: (context, viewModel, appProvider, child) {
        if (appProvider.collectionScrollToTopRequested) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: Container(
            decoration: AppDecorations.antiqueBackground,
            child: SafeArea(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(viewModel),
                  ),
                  if (viewModel.collectionNames.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildCollectionTabs(viewModel),
                    ),
                  SliverToBoxAdapter(
                    child: _buildCollectionContent(viewModel),
                  ),
                ],
              ),
            ),
          ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(CollectionViewModel viewModel) {
    final displayCollections = viewModel.filteredCollections;
    final totalCollections = displayCollections.length;
    final totalItems = displayCollections.values.fold(0, (sum, list) => sum + list.length);

    return Container(
      padding: EdgeInsets.all(AppSizes.paddingM),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Collection',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (totalItems > 0)
                    Text(
                      'Your curated antique collection',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              if (viewModel.collections.isNotEmpty)
                GestureDetector(
                  onTap: () => viewModel.createNewCollection(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingM,
                      vertical: AppSizes.paddingS,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          color: AppColors.white,
                          size: 18.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Add Collection',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (totalItems > 0) ...[
            SizedBox(height: AppSizes.paddingM),
            Container(
              padding: EdgeInsets.all(AppSizes.paddingL),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          totalItems.toString(),
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Antiques',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1.w,
                    height: 40.h,
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          totalCollections.toString(),
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Collections',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollectionTabs(CollectionViewModel viewModel) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppSizes.paddingM),
      height: 50.h,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
        child: Row(
          children: [
            // All Collections Tab
            GestureDetector(
              onTap: () => viewModel.selectCollection(null),
              child: Container(
                margin: EdgeInsets.only(right: AppSizes.paddingS),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingL,
                  vertical: AppSizes.paddingS,
                ),
                decoration: BoxDecoration(
                  color: viewModel.selectedCollection == null
                      ? AppColors.primary
                      : AppColors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusL),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.apps,
                      size: 18.sp,
                      color: viewModel.selectedCollection == null
                          ? AppColors.white
                          : AppColors.textSecondary,
                    ),
                    SizedBox(width: AppSizes.paddingXS),
                    Text(
                      'All',
                      style: AppTextStyles.body2.copyWith(
                        color: viewModel.selectedCollection == null
                            ? AppColors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Individual Collection Tabs
            ...viewModel.collectionNames.map((collectionName) =>
              GestureDetector(
                onTap: () => viewModel.selectCollection(collectionName),
                child: Container(
                  margin: EdgeInsets.only(right: AppSizes.paddingS),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingL,
                    vertical: AppSizes.paddingS,
                  ),
                  decoration: BoxDecoration(
                    color: viewModel.selectedCollection == collectionName
                        ? AppColors.primary
                        : AppColors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusL),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.folder,
                        size: 18.sp,
                        color: viewModel.selectedCollection == collectionName
                            ? AppColors.white
                            : AppColors.textSecondary,
                      ),
                      SizedBox(width: AppSizes.paddingXS),
                      Text(
                        collectionName,
                        style: AppTextStyles.body2.copyWith(
                          color: viewModel.selectedCollection == collectionName
                              ? AppColors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionContent(CollectionViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (viewModel.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 48.sp,
            ),
            SizedBox(height: AppSizes.paddingM),
            Text(
              viewModel.error!,
              style: AppTextStyles.body1.copyWith(
                color: AppColors.error,
              ),
            ),
            SizedBox(height: AppSizes.paddingL),
            ElevatedButton(
              onPressed: () => viewModel.loadCollection(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
              ),
              child: Text(
                'Try Again',
                style: AppTextStyles.button,
              ),
            ),
          ],
        ),
      );
    }

    final displayCollections = viewModel.filteredCollections;

    if (displayCollections.isEmpty && !viewModel.collections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_off,
              color: AppColors.grey,
              size: 64.sp,
            ),
            SizedBox(height: AppSizes.paddingM),
            Text(
              'No items in this collection',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (viewModel.collections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_bookmark_outlined,
              color: AppColors.grey,
              size: 64.sp,
            ),
            SizedBox(height: AppSizes.paddingM),
            Text(
              'Your collection is empty',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSizes.paddingS),
            Text(
              'Tap here to add your first antique',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.grey,
              ),
            ),
            SizedBox(height: AppSizes.paddingL),
            ElevatedButton(
              onPressed: () => viewModel.createNewCollection(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingXL,
                  vertical: AppSizes.paddingM,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add,
                    color: AppColors.white,
                    size: 20.sp,
                  ),
                  SizedBox(width: AppSizes.paddingS),
                  Text(
                    'Add Collection',
                    style: AppTextStyles.button,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.paddingM),
      child: Column(
        children: displayCollections.keys.map((collectionName) {
          final items = displayCollections[collectionName]!;
          return _buildCollectionSection(context, collectionName, items, viewModel);
        }).toList(),
      ),
    );
  }

  Widget _buildCollectionSection(
    BuildContext context,
    String collectionName,
    List<AntiqueModel> items,
    CollectionViewModel viewModel,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: AppSizes.paddingS),
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.paddingM,
              vertical: AppSizes.paddingS,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(AppSizes.radiusS),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Icon(
                    Icons.folder,
                    color: AppColors.primary,
                    size: 16.sp,
                  ),
                ),
                SizedBox(width: AppSizes.paddingS),
                Expanded(
                  child: Text(
                    collectionName,
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${items.length}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: AppSizes.paddingS),
                GestureDetector(
                  onTap: () => _showRenameCollectionDialog(context, collectionName, viewModel),
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Icon(
                      Icons.edit,
                      color: AppColors.primary,
                      size: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSizes.paddingS),
          ...items.map((antique) => Container(
            margin: EdgeInsets.only(bottom: AppSizes.paddingS),
            child: _buildCollectionItem(context, antique, viewModel),
          )),
        ],
      ),
    );
  }

  Widget _buildCollectionItem(
    BuildContext context,
    AntiqueModel antique,
    CollectionViewModel viewModel,
  ) {
    return GestureDetector(
      onTap: () => viewModel.onItemTapped(context, antique),
      child: Container(
        margin: EdgeInsets.only(bottom: AppSizes.paddingM),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.1),
              blurRadius: 10.r,
              offset: Offset(0, 5.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 100.w,
              height: 100.h,
              decoration: BoxDecoration(
                color: AppColors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusL),
                  bottomLeft: Radius.circular(AppSizes.radiusL),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusL),
                  bottomLeft: Radius.circular(AppSizes.radiusL),
                ),
                child: antique.imageUrl.isNotEmpty
                    ? Image.network(
                        antique.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.image,
                              size: 40.sp,
                              color: AppColors.grey,
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.image,
                          size: 40.sp,
                          color: AppColors.grey,
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(AppSizes.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      antique.name,
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.error,
              ),
              onPressed: () => _showDeleteConfirmation(context, antique, viewModel),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    AntiqueModel antique,
    CollectionViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        title: Text(
          'Remove from Collection',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to remove "${antique.name}" from your collection?',
          style: AppTextStyles.body2.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await viewModel.removeFromCollection(antique.id);
            },
            child: Text(
              'Remove',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameCollectionDialog(
    BuildContext context,
    String currentName,
    CollectionViewModel viewModel,
  ) {
    final TextEditingController controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        title: Text(
          'Rename Collection',
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Collection Name...',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 16.sp,
            ),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          style: AppTextStyles.body1.copyWith(
            color: AppColors.textPrimary,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty && controller.text.trim() != currentName) {
                try {
                  await viewModel.renameCollection(currentName, controller.text.trim());
                  Navigator.pop(context);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Collection renamed to "${controller.text.trim()}"'),
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to rename collection: ${e.toString()}'),
                        backgroundColor: AppColors.error,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              } else {
                Navigator.pop(context);
              }
            },
            child: Text(
              'Rename',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}