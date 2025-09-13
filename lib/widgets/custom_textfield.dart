import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final bool isPassword;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final bool readOnly;
  final int maxLines;
  final String? errorText;
  final bool enabled;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  const CustomTextField({
    Key? key,
    required this.label,
    this.hintText,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.errorText,
    this.enabled = true,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
  }) : super(key: key);

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final textScaler = mediaQuery.textScaler;
    
    final responsiveLabelFontSize = _getResponsiveLabelFontSize(screenWidth, textScaler);
    final responsiveTextFontSize = _getResponsiveTextFontSize(screenWidth, textScaler);
    final responsiveBorderRadius = _getResponsiveBorderRadius(screenWidth);
    final responsiveIconSize = _getResponsiveIconSize(screenWidth, textScaler);
    final responsivePadding = _getResponsivePadding(screenWidth, screenHeight, widget.maxLines);
    final responsiveSpacing = _getResponsiveSpacing(screenHeight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with responsive font size
        if (widget.label.isNotEmpty)
          Text(
            widget.label,
            style: TextStyle(
              fontSize: responsiveLabelFontSize,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        if (widget.label.isNotEmpty) SizedBox(height: responsiveSpacing),
        
        // Text Field Container
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(responsiveBorderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.isPassword ? _obscureText : false,
            keyboardType: widget.keyboardType,
            inputFormatters: widget.inputFormatters,
            validator: widget.validator,
            onChanged: widget.onChanged,
            onTap: widget.onTap,
            readOnly: widget.readOnly,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            textCapitalization: widget.textCapitalization,
            style: TextStyle(
              fontSize: responsiveTextFontSize,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: responsiveTextFontSize,
              ),
              // Responsive prefix icon
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused ? AppColors.primary : AppColors.textSecondary,
                      size: responsiveIconSize,
                    )
                  : null,
              // Responsive suffix icon
              suffixIcon: _buildResponsiveSuffixIcon(responsiveIconSize),
              // Responsive border styling
              filled: true,
              fillColor: widget.enabled ? AppColors.surface : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsiveBorderRadius),
                borderSide: BorderSide(color: AppColors.divider, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsiveBorderRadius),
                borderSide: BorderSide(
                  color: widget.errorText != null ? AppColors.error : AppColors.divider,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsiveBorderRadius),
                borderSide: BorderSide(
                  color: widget.errorText != null ? AppColors.error : AppColors.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsiveBorderRadius),
                borderSide: BorderSide(color: AppColors.error, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsiveBorderRadius),
                borderSide: BorderSide(color: AppColors.error, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsiveBorderRadius),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              contentPadding: responsivePadding,
              errorText: widget.errorText,
              errorStyle: TextStyle(
                color: AppColors.error,
                fontSize: responsiveTextFontSize * 0.85,
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _getResponsiveLabelFontSize(double screenWidth, TextScaler textScaler) {
    double baseFontSize = screenWidth < 400 ? 12.0 : 14.0;
    return baseFontSize * textScaler.scale(1.0).clamp(0.8, 1.2);
  }

  double _getResponsiveTextFontSize(double screenWidth, TextScaler textScaler) {
    double baseFontSize = screenWidth < 400 ? 14.0 : 16.0;
    return baseFontSize * textScaler.scale(1.0).clamp(0.8, 1.3);
  }

  double _getResponsiveBorderRadius(double screenWidth) {
    return screenWidth < 400 ? 8.0 : 12.0;
  }

  double _getResponsiveIconSize(double screenWidth, TextScaler textScaler) {
    double baseIconSize = screenWidth < 400 ? 18.0 : 20.0;
    return baseIconSize * textScaler.scale(1.0).clamp(0.8, 1.2);
  }

  EdgeInsetsGeometry _getResponsivePadding(double screenWidth, double screenHeight, int maxLines) {
    double horizontalPadding = screenWidth < 400 ? 12.0 : 16.0;
    double verticalPadding;
    
    if (maxLines > 1) {
      verticalPadding = screenHeight < 600 ? 12.0 : 16.0;
    } else {
      verticalPadding = screenHeight < 600 ? 14.0 : 18.0;
    }
    
    return EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: verticalPadding,
    );
  }

  double _getResponsiveSpacing(double screenHeight) {
    return screenHeight < 600 ? 6.0 : 8.0;
  }

  Widget? _buildResponsiveSuffixIcon(double iconSize) {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: AppColors.textSecondary,
          size: iconSize,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    } else if (widget.suffixIcon != null) {
      return IconButton(
        icon: Icon(
          widget.suffixIcon,
          color: AppColors.textSecondary,
          size: iconSize,
        ),
        onPressed: widget.onSuffixIconPressed,
      );
    }
    return null;
  }
}


class EmailTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final String? errorText;

  const EmailTextField({
    Key? key,
    this.controller,
    this.validator,
    this.onChanged,
    this.errorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: 'Email',
      hintText: 'Enter your email address',
      controller: controller,
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: validator,
      onChanged: onChanged,
      errorText: errorText,
    );
  }
}

class PasswordTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final String? errorText;
  final String label;

  const PasswordTextField({
    Key? key,
    this.controller,
    this.validator,
    this.onChanged,
    this.errorText,
    this.label = 'Password',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: label,
      hintText: 'Enter your password',
      controller: controller,
      prefixIcon: Icons.lock_outline,
      isPassword: true,
      validator: validator,
      onChanged: onChanged,
      errorText: errorText,
    );
  }
}

class PriceTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final String? errorText;
  final String prefixText;

  const PriceTextField({
    Key? key,
    this.controller,
    this.validator,
    this.onChanged,
    this.errorText,
    this.prefixText = '\$',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final textScaler = mediaQuery.textScaler;
    
    final responsiveLabelFontSize = _getResponsiveLabelFontSize(screenWidth, textScaler);
    final responsiveTextFontSize = _getResponsiveTextFontSize(screenWidth, textScaler);
    final responsiveBorderRadius = _getResponsiveBorderRadius(screenWidth);
    final responsivePadding = _getResponsivePadding(screenWidth, screenHeight);
    final responsiveSpacing = _getResponsiveSpacing(screenHeight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price',
          style: TextStyle(
            fontSize: responsiveLabelFontSize,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsiveSpacing),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(responsiveBorderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: validator,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: responsiveTextFontSize,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: responsiveTextFontSize,
              ),
              prefixText: '$prefixText ',
              prefixStyle: TextStyle(
                fontSize: responsiveTextFontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsiveBorderRadius),
                borderSide: BorderSide(color: AppColors.divider, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsiveBorderRadius),
                borderSide: BorderSide(color: AppColors.divider, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsiveBorderRadius),
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: responsivePadding,
              errorText: errorText,
              errorStyle: TextStyle(
                color: AppColors.error,
                fontSize: responsiveTextFontSize * 0.85,
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _getResponsiveLabelFontSize(double screenWidth, TextScaler textScaler) {
    double baseFontSize = screenWidth < 400 ? 12.0 : 14.0;
    return baseFontSize * textScaler.scale(1.0).clamp(0.8, 1.2);
  }

  double _getResponsiveTextFontSize(double screenWidth, TextScaler textScaler) {
    double baseFontSize = screenWidth < 400 ? 14.0 : 16.0;
    return baseFontSize * textScaler.scale(1.0).clamp(0.8, 1.3);
  }

  double _getResponsiveBorderRadius(double screenWidth) {
    return screenWidth < 400 ? 8.0 : 12.0;
  }

  EdgeInsetsGeometry _getResponsivePadding(double screenWidth, double screenHeight) {
    double horizontalPadding = screenWidth < 400 ? 12.0 : 16.0;
    double verticalPadding = screenHeight < 600 ? 14.0 : 18.0;
    return EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding);
  }

  double _getResponsiveSpacing(double screenHeight) {
    return screenHeight < 600 ? 6.0 : 8.0;
  }
}

class SearchTextField extends StatelessWidget {
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final String? hintText;
  final VoidCallback? onClear;

  const SearchTextField({
    Key? key,
    this.controller,
    this.onChanged,
    this.hintText,
    this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: '',
      hintText: hintText ?? 'Search subscriptions...',
      controller: controller,
      prefixIcon: Icons.search,
      suffixIcon: controller?.text.isNotEmpty == true ? Icons.clear : null,
      onSuffixIconPressed: onClear,
      onChanged: onChanged,
    );
  }
}
