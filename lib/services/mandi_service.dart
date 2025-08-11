import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';

class MandiPrice {
  final String state;
  final String district;
  final String market;
  final String commodity;
  final String variety;
  final String arrivalDate;
  final String minPrice;
  final String maxPrice;
  final String modalPrice;
  final String unit;

  MandiPrice({
    required this.state,
    required this.district,
    required this.market,
    required this.commodity,
    required this.variety,
    required this.arrivalDate,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
    required this.unit,
  });

  factory MandiPrice.fromJson(Map<String, dynamic> json) {
    return MandiPrice(
      state: json['State'] ?? '',
      district: json['District'] ?? '',
      market: json['Market'] ?? '',
      commodity: json['Commodity'] ?? '',
      variety: json['Variety'] ?? '',
      arrivalDate: json['Arrival_Date'] ?? '',
      minPrice: json['Min_Price']?.toString() ?? '',
      maxPrice: json['Max_Price']?.toString() ?? '',
      modalPrice: json['Modal_Price']?.toString() ?? '',
      unit: json['Unit'] ?? 'Quintal', // Default unit if not provided
    );
  }
}

class MandiService {
  static const String _baseUrl = Constants.mandiApiUrl;
  static const String _apiKey = Constants.mandiApiKey;

  Future<List<MandiPrice>> getMandiPrices({
    String? state,
    String? commodity,
    int limit = 100,
  }) async {
    // Set default state to Uttar Pradesh if not specified
    final selectedState = state ?? 'Uttar Pradesh';
    try {
      final queryParameters = {
        'api-key': _apiKey,
        'format': 'json',
        'limit': limit.toString(),
      };

      // Always set state filter, default to Uttar Pradesh
      queryParameters['filters[state]'] = selectedState;
      if (commodity != null && commodity.isNotEmpty) {
        queryParameters['filters[commodity]'] = commodity;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParameters);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final records = data['records'] as List<dynamic>;
        
        List<MandiPrice> prices = records.map((record) => MandiPrice.fromJson(record)).toList();
        
        // If no data found for Uttar Pradesh, add some sample data for famous UP crops
        if (selectedState == 'Uttar Pradesh' && prices.isEmpty) {
          prices = _getUPCropSampleData();
        }
        
        return prices;
      } else {
        throw Exception('Failed to load mandi prices: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching mandi prices: $e');
    }
  }

  List<MandiPrice> _getUPCropSampleData() {
    return [
      MandiPrice(
        state: 'Uttar Pradesh',
        district: 'Lucknow',
        market: 'Lucknow Mandi',
        commodity: 'Sugarcane',
        variety: 'Co-0238',
        arrivalDate: DateTime.now().toString().split(' ')[0],
        minPrice: '320',
        maxPrice: '350',
        modalPrice: '335',
        unit: 'Quintal',
      ),
      MandiPrice(
        state: 'Uttar Pradesh',
        district: 'Meerut',
        market: 'Meerut Mandi',
        commodity: 'Wheat',
        variety: 'HD-2967',
        arrivalDate: DateTime.now().toString().split(' ')[0],
        minPrice: '2100',
        maxPrice: '2250',
        modalPrice: '2175',
        unit: 'Quintal',
      ),
      MandiPrice(
        state: 'Uttar Pradesh',
        district: 'Kanpur',
        market: 'Kanpur Mandi',
        commodity: 'Rice',
        variety: 'Pusa Basmati',
        arrivalDate: DateTime.now().toString().split(' ')[0],
        minPrice: '2800',
        maxPrice: '3200',
        modalPrice: '3000',
        unit: 'Quintal',
      ),
      MandiPrice(
        state: 'Uttar Pradesh',
        district: 'Varanasi',
        market: 'Varanasi Mandi',
        commodity: 'Potato',
        variety: 'Kufri Jyoti',
        arrivalDate: DateTime.now().toString().split(' ')[0],
        minPrice: '800',
        maxPrice: '950',
        modalPrice: '875',
        unit: 'Quintal',
      ),
      MandiPrice(
        state: 'Uttar Pradesh',
        district: 'Gorakhpur',
        market: 'Gorakhpur Mandi',
        commodity: 'Maize',
        variety: 'Hybrid',
        arrivalDate: DateTime.now().toString().split(' ')[0],
        minPrice: '1400',
        maxPrice: '1600',
        modalPrice: '1500',
        unit: 'Quintal',
      ),
      MandiPrice(
        state: 'Uttar Pradesh',
        district: 'Prayagraj',
        market: 'Prayagraj Mandi',
        commodity: 'Pulses',
        variety: 'Arhar',
        arrivalDate: DateTime.now().toString().split(' ')[0],
        minPrice: '6500',
        maxPrice: '7200',
        modalPrice: '6850',
        unit: 'Quintal',
      ),
      MandiPrice(
        state: 'Uttar Pradesh',
        district: 'Bareilly',
        market: 'Bareilly Mandi',
        commodity: 'Mustard',
        variety: 'Pusa Bold',
        arrivalDate: DateTime.now().toString().split(' ')[0],
        minPrice: '5200',
        maxPrice: '5800',
        modalPrice: '5500',
        unit: 'Quintal',
      ),
      MandiPrice(
        state: 'Uttar Pradesh',
        district: 'Agra',
        market: 'Agra Mandi',
        commodity: 'Onion',
        variety: 'Red',
        arrivalDate: DateTime.now().toString().split(' ')[0],
        minPrice: '1200',
        maxPrice: '1400',
        modalPrice: '1300',
        unit: 'Quintal',
      ),
    ];
  }

  Future<List<String>> getStates() async {
    try {
      final prices = await getMandiPrices(limit: 1000);
      final states = prices.map((price) => price.state).toSet().toList();
      states.sort();
      return states;
    } catch (e) {
      throw Exception('Error fetching states: $e');
    }
  }

  Future<List<String>> getCommodities() async {
    try {
      final prices = await getMandiPrices(limit: 1000);
      final commodities = prices.map((price) => price.commodity).toSet().toList();
      commodities.sort();
      return commodities;
    } catch (e) {
      throw Exception('Error fetching commodities: $e');
    }
  }

  Future<List<MandiPrice>> getPricesByState(String state) async {
    return await getMandiPrices(state: state);
  }

  Future<List<MandiPrice>> getPricesByCommodity(String commodity) async {
    return await getMandiPrices(commodity: commodity);
  }

  Future<List<MandiPrice>> getPricesByStateAndCommodity(String state, String commodity) async {
    return await getMandiPrices(state: state, commodity: commodity);
  }
}
