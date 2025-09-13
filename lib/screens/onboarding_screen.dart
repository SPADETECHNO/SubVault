import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../utils/constants.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentIndex = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      phoneImage: 'assets/images/mobile_1.png',
      manImage: 'assets/images/boy_1.png',
      title: AppStrings.onboarding1Title,
      subtitle: AppStrings.onboarding1Subtitle,
    ),
    OnboardingData(
      phoneImage: 'assets/images/mobile_2.png',
      manImage: 'assets/images/boy_2.png',
      title: AppStrings.onboarding2Title,
      subtitle: AppStrings.onboarding2Subtitle,
    ),
    OnboardingData(
      phoneImage: 'assets/images/notifications.png',
      manImage: 'assets/images/boy_3.png',
      title: AppStrings.onboarding3Title,
      subtitle: AppStrings.onboarding3Subtitle,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _nextPage() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _skipToLogin() {
    _navigateToLogin();
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(),
        transitionDuration: Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(
                begin: Offset(1.0, 0.0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final textScaler = mediaQuery.textScaler;
    
    final responsiveHorizontalPadding = _getResponsiveHorizontalPadding(screenWidth);
    final responsiveVerticalPadding = _getResponsiveVerticalPadding(screenHeight);
    final responsiveNavigationFontSize = _getResponsiveNavigationFontSize(screenWidth, textScaler);
    final responsiveIndicatorSpacing = _getResponsiveIndicatorSpacing(screenHeight);
    final responsiveBottomPadding = _getResponsiveBottomPadding(screenHeight);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsiveHorizontalPadding,
                  vertical: responsiveVerticalPadding,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button (only show after first page)
                    _currentIndex > 0
                        ? TextButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Text(
                              'Back',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: responsiveNavigationFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : SizedBox(width: screenWidth * 0.15),

                    // Skip Button
                    TextButton(
                      onPressed: _skipToLogin,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: responsiveNavigationFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return OnboardingPage(
                      data: _pages[index],
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                      textScaler: textScaler,
                    );
                  },
                ),
              ),

              Padding(
                padding: EdgeInsets.all(responsiveBottomPadding),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          width: _currentIndex == index 
                              ? _getResponsiveIndicatorWidth(screenWidth, true)
                              : _getResponsiveIndicatorWidth(screenWidth, false),
                          height: _getResponsiveIndicatorHeight(screenHeight),
                          decoration: BoxDecoration(
                            color: _currentIndex == index
                                ? AppColors.primary
                                : AppColors.textSecondary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: responsiveIndicatorSpacing),

                    PrimaryButton(
                      text: _currentIndex == _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                      onPressed: _nextPage,
                      icon: _currentIndex == _pages.length - 1
                          ? Icons.rocket_launch
                          : Icons.arrow_forward,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getResponsiveHorizontalPadding(double screenWidth) {
    if (screenWidth < 400) return 16.0;
    if (screenWidth < 600) return 20.0;
    return 24.0;
  }

  double _getResponsiveVerticalPadding(double screenHeight) {
    if (screenHeight < 600) return 12.0;
    if (screenHeight < 800) return 16.0;
    return 20.0;
  }

  double _getResponsiveNavigationFontSize(double screenWidth, TextScaler textScaler) {
    double baseFontSize = screenWidth < 400 ? 14.0 : 16.0;
    return baseFontSize * textScaler.scale(1.0).clamp(0.8, 1.2);
  }

  double _getResponsiveIndicatorWidth(double screenWidth, bool isActive) {
    double baseWidth = screenWidth < 400 ? (isActive ? 20.0 : 6.0) : (isActive ? 24.0 : 8.0);
    return baseWidth;
  }

  double _getResponsiveIndicatorHeight(double screenHeight) {
    return screenHeight < 600 ? 6.0 : 8.0;
  }

  double _getResponsiveIndicatorSpacing(double screenHeight) {
    if (screenHeight < 600) return 24.0;
    if (screenHeight < 800) return 32.0;
    return 40.0;
  }

  double _getResponsiveBottomPadding(double screenHeight) {
    if (screenHeight < 600) return 16.0;
    if (screenHeight < 800) return 24.0;
    return 32.0;
  }
}

class OnboardingData {
  final String phoneImage;
  final String manImage;
  final String title;
  final String subtitle;

  const OnboardingData({
    required this.phoneImage,
    required this.manImage,
    required this.title,
    required this.subtitle,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  final double screenWidth;
  final double screenHeight;
  final TextScaler textScaler;

  const OnboardingPage({
    Key? key,
    required this.data,
    required this.screenWidth,
    required this.screenHeight,
    required this.textScaler,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsivePhoneImageHeight = _getResponsivePhoneImageHeight(screenHeight);
    final responsivePersonImageHeight = _getResponsivePersonImageHeight(screenHeight);
    final responsiveTitleFontSize = _getResponsiveTitleFontSize(screenWidth, textScaler);
    final responsiveSubtitleFontSize = _getResponsiveSubtitleFontSize(screenWidth, textScaler);
    final responsiveIconSize = _getResponsiveIconSize(screenWidth);
    
    final phoneAlignment = _getPhoneAlignment(screenWidth, screenHeight);
    final personAlignment = _getPersonAlignment(screenWidth, screenHeight);
    final titleAlignment = _getTitleAlignment(screenWidth, screenHeight);
    final subtitleAlignment = _getSubtitleAlignment(screenWidth, screenHeight);

    return SafeArea(
      child: Stack(
        children: [
          Align(
            alignment: phoneAlignment,
            child: Image.asset(
              data.phoneImage,
              height: responsivePhoneImageHeight,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: responsivePhoneImageHeight * 0.8,
                  width: responsivePhoneImageHeight * 0.5,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.phone_android,
                    size: responsiveIconSize,
                    color: AppColors.primary,
                  ),
                );
              },
            ),
          ),

          Align(
            alignment: personAlignment,
            child: Image.asset(
              data.manImage,
              height: responsivePersonImageHeight,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: responsivePersonImageHeight * 0.8,
                  width: responsivePersonImageHeight * 0.5,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.person,
                    size: responsiveIconSize,
                    color: AppColors.secondary,
                  ),
                );
              },
            ),
          ),

          Align(
            alignment: titleAlignment,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: _getResponsiveTextPadding(screenWidth)),
              child: Text(
                data.title,
                style: TextStyle(
                  fontSize: responsiveTitleFontSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  height: 1.2,
                ),
                textAlign: _getTextAlign(screenWidth),
                overflow: TextOverflow.visible,
              ),
            ),
          ),

          Align(
            alignment: subtitleAlignment,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: _getResponsiveTextPadding(screenWidth)),
              child: Text(
                data.subtitle,
                style: TextStyle(
                  fontSize: responsiveSubtitleFontSize,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: _getTextAlign(screenWidth),
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getResponsivePhoneImageHeight(double screenHeight) {
    if (screenHeight < 600) return 280.0;
    if (screenHeight < 700) return 320.0;
    if (screenHeight < 800) return 360.0;
    return 380.0;
  }

  double _getResponsivePersonImageHeight(double screenHeight) {
    if (screenHeight < 600) return 300.0;
    if (screenHeight < 700) return 340.0;
    if (screenHeight < 800) return 380.0;
    return 405.0;
  }

  double _getResponsiveTitleFontSize(double screenWidth, TextScaler textScaler) {
    double baseFontSize;
    if (screenWidth < 400) {
      baseFontSize = 24.0;
    } else if (screenWidth < 600) {
      baseFontSize = 28.0;
    } else {
      baseFontSize = 32.0;
    }
    return baseFontSize * textScaler.scale(1.0).clamp(0.8, 1.3);
  }

  double _getResponsiveSubtitleFontSize(double screenWidth, TextScaler textScaler) {
    double baseFontSize;
    if (screenWidth < 400) {
      baseFontSize = 14.0;
    } else if (screenWidth < 600) {
      baseFontSize = 16.0;
    } else {
      baseFontSize = 17.0;
    }
    return baseFontSize * textScaler.scale(1.0).clamp(0.8, 1.2);
  }

  double _getResponsiveIconSize(double screenWidth) {
    if (screenWidth < 400) return 60.0;
    if (screenWidth < 600) return 70.0;
    return 80.0;
  }

  double _getResponsiveTextPadding(double screenWidth) {
    if (screenWidth < 400) return 20.0;
    if (screenWidth < 600) return 24.0;
    return 32.0;
  }

  Alignment _getPhoneAlignment(double screenWidth, double screenHeight) {
    if (screenWidth < 400) {
      return Alignment(-0.5, -0.7);
    } else if (screenHeight < 600) {
      return Alignment(-0.6, -0.75);
    }
    return Alignment(-0.7, -0.8);
  }

  Alignment _getPersonAlignment(double screenWidth, double screenHeight) {
    if (screenWidth < 400) {
      return Alignment(-0.7, 0.15);
    } else if (screenHeight < 600) {
      return Alignment(-0.8, 0.2);
    }
    return Alignment(-0.9, 0.25);
  }

  Alignment _getTitleAlignment(double screenWidth, double screenHeight) {
    if (screenWidth < 400) {
      return Alignment(-0.5, 0.45);
    } else if (screenHeight < 600) {
      return Alignment(-0.6, 0.5);
    }
    return Alignment(-0.7, 0.55);
  }

  Alignment _getSubtitleAlignment(double screenWidth, double screenHeight) {
    if (screenWidth < 400) {
      return Alignment(-0.5, 0.75);
    } else if (screenHeight < 600) {
      return Alignment(-0.6, 0.8);
    }
    return Alignment(-0.7, 0.9);
  }

  TextAlign _getTextAlign(double screenWidth) {
    return screenWidth < 400 ? TextAlign.center : TextAlign.left;
  }
}
