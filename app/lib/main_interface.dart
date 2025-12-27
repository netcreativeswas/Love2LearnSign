import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:l2l_shared/auth/auth_provider.dart';
import 'home_page.dart';

class MainInterface extends StatefulWidget {
  final String? countryCode;
  final bool checkedLocation;

  const MainInterface({
    super.key,
    this.countryCode,
    this.checkedLocation = false,
  });

  @override
  State<MainInterface> createState() => _MainInterfaceState();
}

class _MainInterfaceState extends State<MainInterface> {
  @override
  Widget build(BuildContext context) {
    // All users are auto-approved with freeUser role - no pending check needed
    return HomePage(
      countryCode: widget.countryCode,
    );
  }
}
