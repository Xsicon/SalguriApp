import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/models/chat_message.dart';
import '../core/models/conversation.dart';
import '../core/models/maintenance_request.dart';
import '../core/models/agent.dart';
import '../core/models/property.dart';
import '../core/models/rental.dart';
import '../core/models/rental_document.dart';
import '../core/models/service_category.dart';
import '../core/models/service_item.dart';
import '../core/models/service_request.dart';

/// All data calls go through the .NET backend API.
/// Supabase is used only for Auth + Storage + Realtime.
class ApiService {
  // Change this to your deployed API URL in production.
  static const String _baseUrl = 'http://192.168.1.11:5000/api';

  static Future<String?> _freshToken() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return null;
    if (session.isExpired) {
      final res = await Supabase.instance.client.auth.refreshSession();
      return res.session?.accessToken;
    }
    return session.accessToken;
  }

  static Future<Map<String, String>> _freshHeaders() async {
    final token = await _freshToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }


  // ─── Helpers ───────────────────────────────────────────────────────────────

  static Future<dynamic> _get(String path) async {
    final headers = await _freshHeaders();
    final res = await http.get(Uri.parse('$_baseUrl$path'), headers: headers);
    _checkStatus(res);
    return jsonDecode(res.body);
  }

  static Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final headers = await _freshHeaders();
    final res = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    _checkStatus(res);
    if (res.statusCode == 204 || res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  static Future<dynamic> _patch(String path, Map<String, dynamic> body) async {
    final headers = await _freshHeaders();
    final res = await http.patch(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );
    _checkStatus(res);
    if (res.statusCode == 204 || res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  static void _checkStatus(http.Response res) {
    if (res.statusCode >= 400) {
      debugPrint('[ApiService] ${res.statusCode} ${res.request?.url}: ${res.body}');
      throw Exception('API error ${res.statusCode}: ${res.body}');
    }
  }

  // ─── Properties ────────────────────────────────────────────────────────────

  static Future<List<Property>> getProperties({int limit = 10}) async {
    final data = await _get('/properties') as List;
    final all = data.map((e) => Property.fromJson(e)).toList();
    return all.take(limit).toList();
  }

  static Future<List<Property>> getAllProperties() async {
    final data = await _get('/properties') as List;
    return data.map((e) => Property.fromJson(e)).toList();
  }

  static Future<List<Property>> filterProperties({
    String? search,
    List<String>? districts,
    String? propertyType,
    int? minBeds,
    int? minBaths,
    int? minSqft,
    int? maxSqft,
    List<String>? amenities,
  }) async {
    final data = await _post('/properties/filter', {
      if (search != null) 'search': search,
      if (districts != null) 'districts': districts,
      if (propertyType != null) 'property_type': propertyType,
      if (minBeds != null) 'min_beds': minBeds,
      if (minBaths != null) 'min_baths': minBaths,
      if (minSqft != null) 'min_sqft': minSqft,
      if (maxSqft != null) 'max_sqft': maxSqft,
      if (amenities != null) 'amenities': amenities,
    }) as List;
    return data.map((e) => Property.fromJson(e)).toList();
  }

  static Future<List<Property>> getMyProperties() async {
    final data = await _get('/properties/mine') as List;
    return data.map((e) => Property.fromJson(e)).toList();
  }

  static Future<Property> createProperty(Map<String, dynamic> body) async {
    final data = await _post('/properties', body);
    return Property.fromJson(data);
  }

  static Future<Property> updateProperty(String id, Map<String, dynamic> body) async {
    final data = await _patch('/properties/$id', body);
    return Property.fromJson(data);
  }

  static Future<List<Agent>> getTopAgents({int limit = 10}) async {
    final data = await _get('/agents/top?limit=$limit') as List;
    return data.map((e) => Agent.fromJson(e)).toList();
  }

  static Future<List<Agent>> getAllAgents() async {
    final data = await _get('/agents') as List;
    return data.map((e) => Agent.fromJson(e)).toList();
  }

  static Future<Agent?> getAgentById(String id) async {
    final data = await _get('/agents/$id');
    return Agent.fromJson(data);
  }

  static Future<Agent> createAgent(Map<String, dynamic> body) async {
    final data = await _post('/agents', body);
    return Agent.fromJson(data);
  }

  static Future<Map<String, dynamic>> getMarketStats() async {
    final data = await _get('/properties/stats');
    return Map<String, dynamic>.from(data);
  }

  // ─── Rentals ───────────────────────────────────────────────────────────────

  static Future<Rental> createRental({
    required String propertyId,
    required double monthlyRent,
    String leaseTerm = '12 Months (Fixed)',
    double securityDeposit = 0,
  }) async {
    final data = await _post('/rentals', {
      'property_id': propertyId,
      'monthly_rent': monthlyRent,
      'lease_term': leaseTerm,
      'security_deposit': securityDeposit,
    });
    return Rental.fromJson(data);
  }

  static Future<Rental?> getActiveRental() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/rentals/active'),
      headers: await _freshHeaders(),
    );
    if (res.statusCode == 204 || res.body.isEmpty) return null;
    _checkStatus(res);
    return Rental.fromJson(jsonDecode(res.body));
  }

  static Future<void> cancelRental(String rentalId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/rentals/$rentalId'),
      headers: await _freshHeaders(),
    );
    _checkStatus(res);
  }

  static Future<List<MaintenanceRequest>> getMaintenanceRequests(
      String rentalId) async {
    final data = await _get('/maintenance/rental/$rentalId') as List;
    return data.map((e) => MaintenanceRequest.fromJson(e)).toList();
  }

  static Future<List<RentalDocument>> getRentalDocuments(
      String rentalId) async {
    final data = await _get('/rentals/$rentalId/documents') as List;
    return data.map((e) => RentalDocument.fromJson(e)).toList();
  }

  static Future<List<RentalDocument>> seedRentalDocuments(
      String rentalId) async {
    final data = await _post('/rentals/$rentalId/documents/seed', {}) as List;
    return data.map((e) => RentalDocument.fromJson(e)).toList();
  }

  static Future<void> createRentPayment({
    required String rentalId,
    required double amount,
    required double platformFee,
    required String paymentMethod,
  }) async {
    await _post('/rentals/pay', {
      'rental_id': rentalId,
      'amount': amount,
      'platform_fee': platformFee,
      'payment_method': paymentMethod,
    });
  }

  static Future<List<Map<String, dynamic>>> getRentPayments(
      String rentalId) async {
    final data = await _get('/rentals/$rentalId/payments') as List;
    return List<Map<String, dynamic>>.from(data);
  }

  // ─── Service Requests ──────────────────────────────────────────────────────

  static Future<List<ServiceRequest>> getAllServiceRequests() async {
    final data = await _get('/servicerequests') as List;
    return data.map((e) => ServiceRequest.fromJson(e)).toList();
  }

  static Future<ServiceRequest> getServiceRequestById(String id) async {
    final data = await _get('/servicerequests/$id');
    return ServiceRequest.fromJson(data);
  }

  static Future<List<ServiceRequest>> getActiveServiceRequests() async {
    final data = await _get('/servicerequests/active') as List;
    return data.map((e) => ServiceRequest.fromJson(e)).toList();
  }

  static Future<ServiceRequest> createServiceRequest({
    required String category,
    required String description,
    required String urgency,
    required double totalAmount,
    required String paymentMethod,
    String? scheduledTime,
  }) async {
    final data = await _post('/servicerequests', {
      'category': category,
      'description': description,
      'urgency': urgency,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      if (scheduledTime != null) 'scheduled_time': scheduledTime,
    });
    return ServiceRequest.fromJson(data);
  }

  static Future<void> updateServiceRequestStatus(
    String id,
    String status, {
    String? statusMessage,
  }) async {
    await _patch('/servicerequests/$id/status', {
      'status': status,
      if (statusMessage != null) 'status_message': statusMessage,
    });
  }

  static Future<List<ServiceCategory>> getServiceCategories(
      {bool? popular}) async {
    final path =
        popular != null ? '/servicecategories?popular=$popular' : '/servicecategories';
    final data = await _get(path) as List;
    return data.map((e) => ServiceCategory.fromJson(e)).toList();
  }

  static Future<List<ServiceItem>> getServiceItems(String categoryId) async {
    final data = await _get('/servicecategories/$categoryId/items') as List;
    return data.map((e) => ServiceItem.fromJson(e)).toList();
  }

  // ─── Conversations ─────────────────────────────────────────────────────────

  static Future<List<Conversation>> getConversations() async {
    final data = await _get('/conversations') as List;
    return data.map((e) => _conversationFromApi(e)).toList();
  }

  static Future<Conversation> getOrCreateConversation({
    required String otherUserId,
    required String otherDisplayName,
    String? otherAvatarUrl,
    String otherRole = 'user',
  }) async {
    final data = await _post('/conversations', {
      'other_user_id': otherUserId,
      'other_display_name': otherDisplayName,
      if (otherAvatarUrl != null) 'other_avatar_url': otherAvatarUrl,
      'other_role': otherRole,
    });
    return _conversationFromApi(data);
  }

  static Future<List<ChatMessage>> getMessages(String conversationId,
      {int limit = 50}) async {
    final data =
        await _get('/conversations/$conversationId/messages?limit=$limit') as List;
    return data.map((e) => ChatMessage.fromJson(e)).toList();
  }

  static Future<ChatMessage> sendMessage({
    required String conversationId,
    required String content,
    String? imageUrl,
  }) async {
    final data = await _post('/conversations/$conversationId/messages', {
      'content': content,
      if (imageUrl != null) 'image_url': imageUrl,
    });
    return ChatMessage.fromJson(data);
  }

  static Future<void> markMessagesAsRead(String conversationId) async {
    await _post('/conversations/$conversationId/read', {});
  }

  static Future<List<Map<String, dynamic>>> getUsers() async {
    final data = await _get('/conversations/users') as List;
    return List<Map<String, dynamic>>.from(data);
  }

  // ─── Saved Items ──────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getSavedItems({String? collection}) async {
    final path = collection != null
        ? '/saveditems?collection=$collection'
        : '/saveditems';
    final data = await _get(path) as List;
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<String>> getSavedCollections() async {
    final data = await _get('/saveditems/collections') as List;
    return data.map((e) => e.toString()).toList();
  }

  static Future<Map<String, dynamic>> saveItem({
    required String propertyId,
    String? collection,
  }) async {
    final data = await _post('/saveditems', {
      'property_id': propertyId,
      if (collection != null) 'collection': collection,
    });
    return Map<String, dynamic>.from(data);
  }

  static Future<void> unsaveItem(String propertyId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/saveditems/$propertyId'),
      headers: await _freshHeaders(),
    );
    _checkStatus(res);
  }

  static Future<bool> isPropertySaved(String propertyId) async {
    final data = await _get('/saveditems/check/$propertyId');
    return data['saved'] as bool? ?? false;
  }

  // ─── Showings ───────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getShowings() async {
    final data = await _get('/showings') as List;
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> createShowing({
    required String propertyId,
    required DateTime requestedDate,
    required String requestedTime,
    int numberOfPeople = 1,
    String? notes,
    String confirmBy = 'phone',
  }) async {
    final data = await _post('/showings', {
      'property_id': propertyId,
      'requested_date': requestedDate.toIso8601String(),
      'requested_time': requestedTime,
      'number_of_people': numberOfPeople,
      if (notes != null) 'notes': notes,
      'confirm_by': confirmBy,
    });
    return Map<String, dynamic>.from(data);
  }

  static Future<void> cancelShowing(String showingId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/showings/$showingId'),
      headers: await _freshHeaders(),
    );
    _checkStatus(res);
  }

  // ─── Profile ────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getProfile() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/profile'),
      headers: await _freshHeaders(),
    );
    if (res.statusCode == 204 || res.body.isEmpty) return null;
    _checkStatus(res);
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  static Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? email,
    String? avatarUrl,
  }) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/profile'),
      headers: await _freshHeaders(),
      body: jsonEncode({
        if (fullName != null) 'full_name': fullName,
        if (email != null) 'email': email,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      }),
    );
    _checkStatus(res);
    return Map<String, dynamic>.from(jsonDecode(res.body));
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static Conversation _conversationFromApi(Map<String, dynamic> json) {
    final participants = (json['participants'] as List? ?? [])
        .map((p) => ConversationParticipant.fromJson(p))
        .toList();
    return Conversation.fromJson(
      json,
      participants: participants,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }
}
