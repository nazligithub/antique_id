import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import '../../constants/app_constants.dart';
import '../../providers/app_provider.dart';
import '../antique_home/home_view.dart';
import '../antique_scan/scan_view.dart';
import '../antique_collection/collection_view.dart';
import 'maintab_viewmodel.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MainTabViewModel, AppProvider>(
      builder: (context, viewModel, appProvider, child) {
        return Scaffold(
          body: IndexedStack(
            index: viewModel.currentIndex,
            children: const [
              HomeView(),
              CollectionView(),
            ],
          ),
          floatingActionButton: _buildFloatingActionButton(viewModel, appProvider),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: _buildAnimatedBottomBar(viewModel, appProvider),
        );
      },
    );
  }

  Widget _buildAnimatedBottomBar(MainTabViewModel viewModel, AppProvider appProvider) {
    return AnimatedBottomNavigationBar.builder(
      itemCount: 2,
      tabBuilder: (int index, bool isActive) {
        IconData iconData;
        String label;

        if (index == 0) {
          iconData = Icons.home_outlined;
          label = 'tab_home'.tr();
        } else {
          iconData = Icons.bookmark_outline;
          label = 'tab_collection'.tr();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: 24.sp,
              color: isActive ? AppColors.primary : AppColors.tabBarUnselected,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.tabBarUnselected,
                fontSize: 12.sp,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        );
      },
      activeIndex: viewModel.currentIndex,
      onTap: (index) {
        viewModel.setIndex(index);
        appProvider.setTabIndex(index);

        if (index == 0 && viewModel.currentIndex == 0) {
          appProvider.homeScrollToTopRequested = true;
          viewModel.onHomeTabDoubleTap();
        } else if (index == 1 && viewModel.currentIndex == 1) {
          appProvider.collectionScrollToTopRequested = true;
          viewModel.onCollectionTabDoubleTap();
        }
      },
      gapLocation: GapLocation.center,
      notchSmoothness: NotchSmoothness.defaultEdge,
      leftCornerRadius: 0,
      rightCornerRadius: 0,
      backgroundColor: AppColors.white,
      height: 70.h,
      splashColor: Colors.transparent,
      splashRadius: 0,
    );
  }

  Widget _buildFloatingActionButton(MainTabViewModel viewModel, AppProvider appProvider) {
    return SizedBox(
      width: 70.w,
      height: 70.h,
      child: FloatingActionButton(
        onPressed: () => ScanSheet.open(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: const CircleBorder(),
        child: Container(
          width: 70.w,
          height: 70.h,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/antique_float.png'),
              fit: BoxFit.cover,
            ),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}