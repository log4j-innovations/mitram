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
    int limit = 50,
  }) async {
    try {
      final queryParameters = {
        'api-key': _apiKey,
        'format': 'json',
        'limit': limit.toString(),
      };

      if (state != null && state.isNotEmpty) {
        queryParameters['filters[state]'] = state;
      }
      if (commodity != null && commodity.isNotEmpty) {
        queryParameters['filters[commodity]'] = commodity;
      }

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParameters);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final records = data['records'] as List<dynamic>;
        
        return records.map((record) => MandiPrice.fromJson(record)).toList();
      } else {
        throw Exception('Failed to load mandi prices: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching mandi prices: $e');
    }
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
