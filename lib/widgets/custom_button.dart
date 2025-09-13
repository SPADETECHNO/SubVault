import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final IconData? icon;
  final Widget? leading;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.icon,
    this.leading,
    this.borderRadius,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final textScaler = mediaQuery.textScaler;
    
    final responsiveHeight = height ?? _getResponsiveHeight(screenHeight, textScaler);
    final responsiveBorderRadius = borderRadius ?? _getResponsiveBorderRadius(screenWidth);
    final responsiveFontSize = _getResponsiveFontSize(screenWidth, textScaler);
    final responsiveIconSize = _getResponsiveIconSize(screenWidth, textScaler);
    final responsivePadding = padding ?? _getResponsivePadding(screenWidth, screenHeight);

    return Container(
      width: width ?? double.infinity,
      height: responsiveHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined
              ? Colors.transparent
              : (backgroundColor ?? AppColors.primary),
          foregroundColor: isOutlined
              ? (textColor ?? AppColors.primary)
              : (textColor ?? Colors.white),
          elevation: isOutlined ? 0 : 2,
          shadowColor: AppColors.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsiveBorderRadius),
            side: isOutlined
                ? BorderSide(
                    color: backgroundColor ?? AppColors.primary,
                    width: 1.5,
                  )
                : BorderSide.none,
          ),
          padding: responsivePadding,
        ),
        child: isLoading
            ? SizedBox(
                height: responsiveIconSize,
                width: responsiveIconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    isOutlined ? AppColors.primary : Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[
                    leading!,
                    SizedBox(width: _getResponsiveSpacing(screenWidth)),
                  ] else if (icon != null) ...[
                    Icon(
                      icon,
                      size: responsiveIconSize,
                      color: isOutlined
                          ? (textColor ?? AppColors.primary)
                          : (textColor ?? Colors.white),
                    ),
                    SizedBox(width: _getResponsiveSpacing(screenWidth)),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: responsiveFontSize,
                        fontWeight: FontWeight.w600,
                        color: isOutlined
                            ? (textColor ?? AppColors.primary)
                            : (textColor ?? Colors.white),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  double _getResponsiveHeight(double screenHeight, TextScaler textScaler) {
    double baseHeight = screenHeight < 600 ? 48.0 : 56.0;
    return baseHeight * textScaler.scale(1.0).clamp(0.8, 1.3);
  }

  double _getResponsiveBorderRadius(double screenWidth) {
    return screenWidth < 400 ? 8.0 : 12.0;
  }

  double _getResponsiveFontSize(double screenWidth, TextScaler textScaler) {
    double baseFontSize = screenWidth < 400 ? 14.0 : 16.0;
    return baseFontSize * textScaler.scale(1.0).clamp(0.8, 1.2);
  }

  double _getResponsiveIconSize(double screenWidth, TextScaler textScaler) {
    double baseIconSize = screenWidth < 400 ? 18.0 : 20.0;
    return baseIconSize * textScaler.scale(1.0).clamp(0.8, 1.2);
  }

  EdgeInsetsGeometry _getResponsivePadding(double screenWidth, double screenHeight) {
    double horizontalPadding = screenWidth < 400 ? 16.0 : 24.0;
    double verticalPadding = screenHeight < 600 ? 12.0 : 16.0;
    return EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: verticalPadding,
    );
  }

  double _getResponsiveSpacing(double screenWidth) {
    return screenWidth < 400 ? 6.0 : 8.0;
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Widget? leading;
  final double? width;
  final double? height;
  final Color? backgroundColor;

  const PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.leading,
    this.width,
    this.backgroundColor,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      leading: leading,
      width: width,
      height: height,
      backgroundColor: backgroundColor ?? AppColors.primary,
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Widget? leading;
  final double? width;
  final double? height; 

  const SecondaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.leading,
    this.width,
    this.height, 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      leading: leading,
      width: width,
      height: height,
      isOutlined: true,
      backgroundColor: AppColors.primary,
    );
  }
}

class DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Widget? leading;
  final double? width;
  final double? height;

  const DangerButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.leading,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      leading: leading,
      width: width,
      height: height,
      backgroundColor: AppColors.error,
    );
  }
}

class SuccessButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Widget? leading;
  final double? width;
  final double? height;

  const SuccessButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.leading,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      leading: leading,
      width: width,
      height: height,
      backgroundColor: AppColors.success,
    );
  }
}
