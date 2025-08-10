import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context);
    final AppUser? currentUser = authService.currentUser;

    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Consistent background
      appBar: AppBar(
        backgroundColor: const Color(0xFFA8D5A8), // Consistent app bar color
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontSize: screenWidth * 0.05, // Responsive font size
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenHeight * 0.03),
              CircleAvatar(
                radius: screenWidth * 0.15,
                backgroundColor: Colors.green.shade700,
                child: Icon(
                  Icons.person,
                  size: screenWidth * 0.15,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                currentUser?.email ?? 'N/A',
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              // Text(
              //   'User ID: ${currentUser?.uid ?? 'N/A'}',
              //   style: TextStyle(
              //     fontSize: screenWidth * 0.035,
              //     color: Colors.black54,
              //   ),
              // ),
              SizedBox(height: screenHeight * 0.04),
              Divider(thickness: 1, color: Colors.grey[300]),
              SizedBox(height: screenHeight * 0.02),
              _buildProfileOption(
                context,
                icon: Icons.edit,
                title: 'Edit Profile',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit Profile coming soon!')), 
                  );
                },
                screenWidth: screenWidth,
              ),
              _buildProfileOption(
                context,
                icon: Icons.settings,
                title: 'Settings',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings coming soon!')),
                  );
                },
                screenWidth: screenWidth,
              ),
              _buildProfileOption(
                context,
                icon: Icons.logout,
                title: 'Logout',
                onTap: () async {
                  await authService.signOut();
                  // Navigate back to login/signup after logout
                  // This should be handled by AuthWrapper listening to authStateChanges
                },
                screenWidth: screenWidth,
                isLogout: true,
              ),
              SizedBox(height: screenHeight * 0.04),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required double screenWidth,
    bool isLogout = false,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon,
            color: isLogout ? Colors.red : Colors.green.shade700,
            size: screenWidth * 0.06),
        title: Text(
          title,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w500,
            color: isLogout ? Colors.red : Colors.black87,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios,
            size: screenWidth * 0.04, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }
}