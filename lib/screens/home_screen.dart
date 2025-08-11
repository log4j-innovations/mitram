//lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mitram/screens/diagnose_screen.dart'; // Import DiagnoseScreen
import 'package:mitram/screens/mandi_screen.dart'; // Import MandiScreen
import 'package:mitram/screens/govt_schemes_screen.dart'; // Import GovtSchemesScreen
import 'package:mitram/screens/profile_screen.dart';
import 'package:mitram/services/mandi_service.dart'; // Import MandiService

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreenBody(onNavigate: _onItemTapped),
      const DiagnoseScreen(),
      const MandiScreen(),
      const GovtSchemesScreen(),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildResponsiveAppBar(context, BoxConstraints()),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar:
          _buildResponsiveBottomNav(context, BoxConstraints()),
    );
  }

  PreferredSizeWidget _buildResponsiveAppBar(
      BuildContext context, BoxConstraints constraints) {
    double screenWidth = MediaQuery.of(context).size.width;

    return AppBar(
      backgroundColor: const Color(0xFFA8D5A8),
      elevation: 0,
      toolbarHeight: screenWidth * 0.15, // Responsive app bar height
      title: Row(
        children: [
          Icon(
            Icons.agriculture,
            color: Colors.green.shade700,
            size: screenWidth * 0.06, // Responsive icon size
          ),
          SizedBox(width: screenWidth * 0.02),
          Text(
            'MITRAM',
            style: TextStyle(
              color: Colors.black,
              fontSize: screenWidth * 0.05, // Responsive font size
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.mic,
            color: Colors.green.shade700,
            size: screenWidth * 0.06, // Responsive icon size
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Voice feature coming soon!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildResponsiveBottomNav(
      BuildContext context, BoxConstraints constraints) {
    double screenWidth = MediaQuery.of(context).size.width;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFFA8D5A8),
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black54,
      currentIndex: _selectedIndex,
      selectedFontSize: screenWidth * 0.03, // Responsive font size
      unselectedFontSize: screenWidth * 0.025, // Responsive font size
      iconSize: screenWidth * 0.06, // Responsive icon size
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt), label: 'Diagnose'),
        BottomNavigationBarItem(
            icon: Icon(Icons.trending_up), label: 'Mandi'),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'Govt'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }


}

class HomeScreenBody extends StatefulWidget {
  final Function(int) onNavigate;
  const HomeScreenBody({super.key, required this.onNavigate});

  @override
  _HomeScreenBodyState createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<HomeScreenBody> {
  final MandiService _mandiService = MandiService();
  List<MandiPrice> _mandiPrices = [];
  bool _isLoadingMandi = false;

  @override
  void initState() {
    super.initState();
    _loadMandiData();
  }

  Future<void> _loadMandiData() async {
    setState(() {
      _isLoadingMandi = true;
    });

    try {
      final prices = await _mandiService.getMandiPrices(
        state: 'Uttar Pradesh', // Load UP data by default
        limit: 20,
      );
      if (mounted) {
        setState(() {
          _mandiPrices = prices;
          _isLoadingMandi = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMandi = false;
        });
      }
    }
  }

  Future<void> _refreshMandiData() async {
    await _loadMandiData();
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return LayoutBuilder(
          builder: (context, constraints) {
            bool isTablet = constraints.maxWidth > 600;
            bool isLandscape = orientation == Orientation.landscape;

            return SingleChildScrollView(
              child: _buildResponsiveBody(
                  context, constraints, isTablet, isLandscape),
            );
          },
        );
      },
    );
  }

  Widget _buildResponsiveBody(BuildContext context, BoxConstraints constraints,
      bool isTablet, bool isLandscape) {
    double screenWidth = constraints.maxWidth;
    double screenHeight = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Section
        Container(
          width: double.infinity,
          color: const Color(0xFFA8D5A8),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            children: [
              Text(
                'Welcome to MITRAM,',
                style: TextStyle(
                  fontSize: screenWidth * 0.06, // Responsive font size
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: screenHeight * 0.005),
              Text(
                'Your Smart Farming Ally',
                style: TextStyle(
                  fontSize: screenWidth * 0.04, // Responsive font size
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: screenHeight * 0.025),
              // Responsive main buttons layout
              _buildResponsiveMainButtons(
                  context, screenWidth, screenHeight, isTablet, isLandscape),
            ],
          ),
        ),

        // Content sections with responsive layout
        if (isLandscape && isTablet)
          _buildLandscapeTabletLayout(context, screenWidth, screenHeight)
        else
          _buildPortraitLayout(context, screenWidth, screenHeight),
      ],
    );
  }

  Widget _buildResponsiveMainButtons(BuildContext context, double screenWidth,
      double screenHeight, bool isTablet, bool isLandscape) {
    double buttonHeight = screenWidth * 0.22; // Responsive height based on width
    double spacing = screenWidth * 0.025; // 2.5% of screen width

    // For landscape tablets, use single row layout
    if (isLandscape && isTablet) {
      return Row(
        children: [
          Expanded(
              child: _buildMainButton(Icons.camera_alt, 'Diagnose', () {
            widget.onNavigate(1);
          }, screenWidth, buttonHeight)),
          SizedBox(width: spacing),
          Expanded(
              child: _buildMainButton(Icons.trending_up, 'Mandi', () {
            widget.onNavigate(2);
          }, screenWidth, buttonHeight)),
          SizedBox(width: spacing),
          Expanded(
              child: _buildMainButton(Icons.account_balance, 'Govt.', () {
            widget.onNavigate(3);
          }, screenWidth, buttonHeight)),
          SizedBox(width: spacing),
          Expanded(
              child: _buildMainButton(Icons.people, 'Ask', () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Farmer Community coming soon!')),
            );
          }, screenWidth, buttonHeight)),
        ],
      );
    }

    // Standard 2x2 grid layout using Column method to prevent overflow
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildMainButton(Icons.camera_alt, 'Diagnose', () {
              widget.onNavigate(1);
            }, screenWidth, buttonHeight)),
            SizedBox(width: spacing),
            Expanded(
                child: _buildMainButton(Icons.trending_up, 'Mandi', () {
              widget.onNavigate(2);
            }, screenWidth, buttonHeight)),
          ],
        ),
        SizedBox(height: spacing),
        Row(
          children: [
            Expanded(
                child: _buildMainButton(Icons.account_balance, 'Govt.', () {
              widget.onNavigate(3);
            }, screenWidth, buttonHeight)),
            SizedBox(width: spacing),
            Expanded(
                child: _buildMainButton(Icons.people, 'Ask', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Farmer Community coming soon!')),
              );
            }, screenWidth, buttonHeight)),
          ],
        ),
      ],
    );
  }

  Widget _buildMainButton(IconData icon, String label, VoidCallback onTap,
      double screenWidth, double buttonHeight) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: buttonHeight,
        decoration: BoxDecoration(
          color: Colors.green.shade600,
          borderRadius:
              BorderRadius.circular(buttonHeight * 0.5), // Responsive border radius
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: screenWidth * 0.07, // Responsive icon size
              ),
              SizedBox(height: screenWidth * 0.01),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.035, // Responsive font size
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeTabletLayout(
      BuildContext context, double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.03),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: _buildMandiCard(context, screenWidth, screenHeight),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            flex: 1,
            child: _buildSchemeCard(context, screenWidth, screenHeight),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout(
      BuildContext context, double screenWidth, double screenHeight) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: _buildMandiCard(context, screenWidth, screenHeight),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: _buildSchemeCard(context, screenWidth, screenHeight),
        ),
        SizedBox(height: screenHeight * 0.03),
      ],
    );
  }

  Widget _buildMandiCard(
      BuildContext context, double screenWidth, double screenHeight) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Smart Mandi',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05, // Responsive font size
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _isLoadingMandi ? null : _refreshMandiData,
                      icon: _isLoadingMandi
                          ? SizedBox(
                              width: screenWidth * 0.04,
                              height: screenWidth * 0.04,
                              child: CircularProgressIndicator(
                                color: Colors.green.shade600,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.refresh, color: Colors.green.shade600),
                      tooltip: 'Refresh prices',
                    ),
                    Icon(Icons.trending_up,
                        color: Colors.green, size: screenWidth * 0.06),
                  ],
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
            // Live Price Display
            if (_isLoadingMandi)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(screenHeight * 0.02),
                  child: CircularProgressIndicator(
                    color: Colors.green.shade600,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (_mandiPrices.isNotEmpty)
              Column(
                children: [
                  // Top 3 Prices
                  ..._mandiPrices.take(3).map((price) => Container(
                    margin: EdgeInsets.only(bottom: screenHeight * 0.01),
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                price.commodity,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                '${price.market}, ${price.district}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.03,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${price.modalPrice}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            Text(
                              'per ${price.unit}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.025,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
                  SizedBox(height: screenHeight * 0.01),
                  // View All Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => widget.onNavigate(2),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        ),
                      ),
                      child: Text(
                        'View All Prices',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: EdgeInsets.all(screenWidth * 0.03),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.grey.shade600, size: screenWidth * 0.05),
                    SizedBox(width: screenWidth * 0.02),
                    Expanded(
                      child: Text(
                        'Tap to view live mandi prices',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: screenHeight * 0.02),
            Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome,
                      color: Colors.blue.shade700, size: screenWidth * 0.05),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Market Data',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                        Text(
                          _mandiPrices.isNotEmpty 
                            ? '${_mandiPrices.length} commodities tracked'
                            : 'Real-time prices from across India',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: screenWidth * 0.03,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Container(
              height: screenHeight * 0.15,
              child: _mandiPrices.isNotEmpty
                ? LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(
                        show: true,
                        border: const Border(
                          left: BorderSide(color: Colors.black, width: 2),
                          bottom: BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      minX: 0,
                      maxX: (_mandiPrices.length - 1).toDouble(),
                      minY: 0,
                      maxY: _getMaxPrice(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _getChartData(),
                          isCurved: true,
                          color: Colors.green.shade600,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Text(
                      'Price trends will appear here',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchemeCard(
      BuildContext context, double screenWidth, double screenHeight) {
    return GestureDetector(
      onTap: () => widget.onNavigate(3),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
        ),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Govt Schemes',
                    style: TextStyle(
                      fontSize: screenWidth * 0.05, // Responsive font size
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Icon(Icons.auto_awesome,
                      color: Colors.blue.shade600, size: screenWidth * 0.06),
                ],
              ),
              SizedBox(height: screenHeight * 0.015),
              Text(
                '"What schemes apply to me?"',
                style: TextStyle(
                  fontSize: screenWidth * 0.035, // Responsive font size
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: screenWidth * 0.05,
                    ),
                    SizedBox(height: screenHeight * 0.008),
                    Text(
                      'AI-Powered Scheme Matching',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: screenWidth * 0.04, // Responsive font size
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      'Tap to find your eligible schemes',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: screenWidth * 0.03, // Responsive font size
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                        vertical: screenHeight * 0.005,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                      child: Text(
                        'Find Schemes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.03,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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

  List<FlSpot> _getChartData() {
    return _mandiPrices.asMap().entries.map((entry) {
      final index = entry.key;
      final price = entry.value;
      final modalPrice = double.tryParse(price.modalPrice) ?? 0.0;
      return FlSpot(index.toDouble(), modalPrice);
    }).toList();
  }

  double _getMaxPrice() {
    if (_mandiPrices.isEmpty) return 1000.0;
    final maxPrice = _mandiPrices.map((price) {
      return double.tryParse(price.modalPrice) ?? 0.0;
    }).reduce((a, b) => a > b ? a : b);
    return maxPrice * 1.1; // Add 10% padding
  }
}
