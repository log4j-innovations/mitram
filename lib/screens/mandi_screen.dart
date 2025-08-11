import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../services/mandi_service.dart';
import '../utils/constants.dart';

class MandiScreen extends StatefulWidget {
  static const routeName = '/mandi';
  const MandiScreen({super.key});

  @override
  _MandiScreenState createState() => _MandiScreenState();
}

class _MandiScreenState extends State<MandiScreen> {
  final MandiService _mandiService = MandiService();
  late GenerativeModel _model;
  
  List<MandiPrice> _prices = [];
  List<String> _states = [];
  List<String> _commodities = [];
  String? _selectedState;
  String? _selectedCommodity;
  bool _isLoading = false;
  String? _aiPrediction;
  bool _isGeneratingPrediction = false;

  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _loadInitialData();
  }

  void _initializeGemini() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: Constants.geminiApiKey,
    );
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load Uttar Pradesh data by default
      final prices = await _mandiService.getMandiPrices(
        state: 'Uttar Pradesh',
        limit: 100,
      );
      final states = await _mandiService.getStates();
      final commodities = await _mandiService.getCommodities();

      if (mounted) {
        setState(() {
          _prices = prices;
          _states = states;
          _commodities = commodities;
          _selectedState = 'Uttar Pradesh'; // Set UP as default
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load mandi data: $e');
      }
    }
  }

  Future<void> _filterPrices() async {
    if (_selectedState == null && _selectedCommodity == null) {
      await _loadInitialData();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<MandiPrice> prices;
      if (_selectedState != null && _selectedCommodity != null) {
        prices = await _mandiService.getPricesByStateAndCommodity(_selectedState!, _selectedCommodity!);
      } else if (_selectedState != null) {
        prices = await _mandiService.getPricesByState(_selectedState!);
      } else {
        prices = await _mandiService.getPricesByCommodity(_selectedCommodity!);
      }

      if (mounted) {
        setState(() {
          _prices = prices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to filter prices: $e');
      }
    }
  }

  Future<void> _generateAIPrediction() async {
    if (_prices.isEmpty) return;

    setState(() {
      _isGeneratingPrediction = true;
    });

    try {
      // Create a summary of current prices for AI analysis
      final priceSummary = _prices.take(10).map((price) => 
        '${price.commodity} in ${price.state}: Min ₹${price.minPrice}, Max ₹${price.maxPrice}, Modal ₹${price.modalPrice} per ${price.unit}'
      ).join('\n');

      final prompt = '''
You are an expert agricultural economist helping Indian farmers. Analyze this mandi price data and provide:

1. **Price Trend Analysis**: What are the current price trends?
2. **Best Selling Time**: When is the best time to sell in the next 2-3 weeks?
3. **Price Prediction**: What might happen to prices in the coming days?
4. **Farmer Advice**: What should farmers do right now?
5. **Commodity Analysis**: What is the current demand and supply of the commodity?
Current Price Data:
$priceSummary

Provide your response in simple Hindi-English mixed language that Indian farmers can easily understand. Focus on practical, actionable advice.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (mounted) {
        setState(() {
          _aiPrediction = response.text;
          _isGeneratingPrediction = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingPrediction = false;
        });
        _showErrorSnackBar('Failed to generate AI prediction: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isTablet = constraints.maxWidth > 600;
      final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
      
      return SingleChildScrollView(
        child: _buildResponsiveBody(context, constraints, isTablet, isLandscape),
      );
    });
  }

  Widget _buildResponsiveBody(BuildContext context, BoxConstraints constraints, bool isTablet, bool isLandscape) {
    double screenWidth = constraints.maxWidth;
    double screenHeight = MediaQuery.of(context).size.height;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Container(
          width: double.infinity,
          color: const Color(0xFFA8D5A8),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            children: [
              Icon(
                Icons.trending_up,
                color: Colors.green.shade700,
                size: screenWidth * 0.08,
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                'Live Mandi Prices',
                style: TextStyle(
                  fontSize: screenWidth * 0.06,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.005),
              Text(
                'Get real-time prices and AI predictions',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        // Filter Section
        Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: _buildFilterSection(screenWidth, screenHeight),
        ),
        
        // AI Prediction Section
        if (_aiPrediction != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            child: _buildAIPredictionCard(screenWidth, screenHeight),
          ),
        
        // Price Chart Section
        Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: _buildPriceChartCard(screenWidth, screenHeight),
        ),
        
        // Price List Section
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
          child: _buildPriceListCard(screenWidth, screenHeight),
        ),
      ],
    );
  }

  Widget _buildFilterSection(double screenWidth, double screenHeight) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
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
                  'Filter Prices',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: _isLoading ? null : _loadInitialData,
                  icon: _isLoading
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
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
            
            // State Dropdown
            DropdownButtonFormField<String>(
              value: _selectedState,
              decoration: InputDecoration(
                labelText: 'Select State',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
                prefixIcon: Icon(Icons.location_on, color: Colors.green.shade600),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All States'),
                ),
                ..._states.map((state) => DropdownMenuItem<String>(
                  value: state,
                  child: Text(state),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedState = value;
                });
                _filterPrices();
              },
            ),
            
            SizedBox(height: screenHeight * 0.02),
            
            // Commodity Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCommodity,
              decoration: InputDecoration(
                labelText: 'Select Commodity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
                prefixIcon: Icon(Icons.agriculture, color: Colors.green.shade600),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Commodities'),
                ),
                ..._commodities.map((commodity) => DropdownMenuItem<String>(
                  value: commodity,
                  child: Text(commodity),
                )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCommodity = value;
                });
                _filterPrices();
              },
            ),
            
            SizedBox(height: screenHeight * 0.02),
            
            // AI Prediction Button
            SizedBox(
              width: double.infinity,
              height: screenHeight * 0.06,
              child: ElevatedButton.icon(
                onPressed: _isGeneratingPrediction ? null : _generateAIPrediction,
                icon: _isGeneratingPrediction
                    ? SizedBox(
                        width: screenWidth * 0.05,
                        height: screenWidth * 0.05,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.auto_awesome, color: Colors.white),
                label: Text(
                  _isGeneratingPrediction ? 'Generating AI Prediction...' : 'Get AI Price Prediction',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIPredictionCard(double screenWidth, double screenHeight) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.blue.shade600,
                  size: screenWidth * 0.06,
                ),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  'AI Price Prediction',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                _aiPrediction!,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Colors.blue.shade800,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceChartCard(double screenWidth, double screenHeight) {
    if (_prices.isEmpty) return const SizedBox.shrink();

    // Prepare chart data
    final chartData = _prices.take(10).map((price) {
      final modalPrice = double.tryParse(price.modalPrice) ?? 0.0;
      return FlSpot(_prices.indexOf(price).toDouble(), modalPrice);
    }).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Trends',
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            SizedBox(
              height: screenHeight * 0.3,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData,
                      isCurved: true,
                      color: Colors.green.shade600,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceListCard(double screenWidth, double screenHeight) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
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
                  'Latest Prices',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (_isLoading)
                  SizedBox(
                    width: screenWidth * 0.05,
                    height: screenWidth * 0.05,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
            
            if (_prices.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(screenHeight * 0.05),
                  child: Text(
                    'No price data available',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _prices.length,
                itemBuilder: (context, index) {
                  final price = _prices[index];
                  return _buildPriceItem(price, screenWidth, screenHeight);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceItem(MandiPrice price, double screenWidth, double screenHeight) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  price.commodity,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.02,
                  vertical: screenHeight * 0.005,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Text(
                  '₹${price.modalPrice}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            '${price.market}, ${price.district}, ${price.state}',
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: screenHeight * 0.005),
          Row(
            children: [
              Text(
                'Min: ₹${price.minPrice}',
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                  color: Colors.red.shade600,
                ),
              ),
              SizedBox(width: screenWidth * 0.05),
              Text(
                'Max: ₹${price.maxPrice}',
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                  color: Colors.green.shade600,
                ),
              ),
              const Spacer(),
              Text(
                'per ${price.unit}',
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
      ),
    );
  }
}
