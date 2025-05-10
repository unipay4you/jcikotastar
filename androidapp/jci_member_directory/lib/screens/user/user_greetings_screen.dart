import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/api_config.dart';

class UserGreetingsScreen extends StatefulWidget {
  final List<dynamic> members;
  final String? userMobileBelongsTo;

  const UserGreetingsScreen({
    Key? key,
    required this.members,
    this.userMobileBelongsTo,
  }) : super(key: key);

  @override
  _UserGreetingsScreenState createState() => _UserGreetingsScreenState();
}

class _UserGreetingsScreenState extends State<UserGreetingsScreen> {
  List<Map<String, dynamic>> _todayEvents = [];
  Map<String, List<Map<String, dynamic>>> _monthlyEvents = {};
  Map<String, bool> _expandedMonths = {};
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _monthFormat = DateFormat('MMMM yyyy');

  @override
  void initState() {
    super.initState();
    _processUpcomingEvents();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    print('Comparing dates:');
    print('Current date: ${now.day}/${now.month}/${now.year}');
    print('Event date: ${date.day}/${date.month}/${date.year}');
    return date.day == now.day &&
        date.month == now.month &&
        date.year == now.year;
  }

  void _processUpcomingEvents() {
    final now = DateTime.now();
    print('Processing events for date: ${now.day}/${now.month}/${now.year}');
    final endDate =
        now.add(const Duration(days: 60)); // Changed to 60 days (2 months)
    final events = <Map<String, dynamic>>[];

    for (var member in widget.members) {
      print('\nProcessing member: ${member['jcName']}');

      // Process JC Birthday
      if (member['jcDob'] != null) {
        print('JC DOB: ${member['jcDob']}');
        final dob = DateTime.parse(member['jcDob']);
        final thisYearBirthday = DateTime(now.year, dob.month, dob.day);
        final nextYearBirthday = DateTime(now.year + 1, dob.month, dob.day);

        print(
            'This year birthday: ${thisYearBirthday.day}/${thisYearBirthday.month}/${thisYearBirthday.year}');
        print(
            'Next year birthday: ${nextYearBirthday.day}/${nextYearBirthday.month}/${nextYearBirthday.year}');

        if ((thisYearBirthday.isAfter(now.subtract(const Duration(days: 1))) &&
                thisYearBirthday.isBefore(endDate)) ||
            _isToday(thisYearBirthday)) {
          final isToday = _isToday(thisYearBirthday);
          print('Adding this year birthday. Is today: $isToday');
          events.add({
            'name': member['jcName'] ?? '',
            'event_type': 'JC Birthday',
            'date': thisYearBirthday.toIso8601String(),
            'is_today': isToday,
            'image_url': member['jcImage'] != null
                ? '${ApiConfig.baseUrl}${member['jcImage']}'
                : null,
          });
        } else if ((nextYearBirthday
                    .isAfter(now.subtract(const Duration(days: 1))) &&
                nextYearBirthday.isBefore(endDate)) ||
            _isToday(nextYearBirthday)) {
          final isToday = _isToday(nextYearBirthday);
          print('Adding next year birthday. Is today: $isToday');
          events.add({
            'name': member['jcName'] ?? '',
            'event_type': 'JC Birthday',
            'date': nextYearBirthday.toIso8601String(),
            'is_today': isToday,
            'image_url': member['jcImage'] != null
                ? '${ApiConfig.baseUrl}${member['jcImage']}'
                : null,
          });
        }
      }

      // Process JCRT Birthday
      if (member['jcrtDob'] != null) {
        print('JCRT DOB: ${member['jcrtDob']}');
        final dob = DateTime.parse(member['jcrtDob']);
        final thisYearBirthday = DateTime(now.year, dob.month, dob.day);
        final nextYearBirthday = DateTime(now.year + 1, dob.month, dob.day);

        print(
            'This year JCRT birthday: ${thisYearBirthday.day}/${thisYearBirthday.month}/${thisYearBirthday.year}');
        print(
            'Next year JCRT birthday: ${nextYearBirthday.day}/${nextYearBirthday.month}/${nextYearBirthday.year}');

        if ((thisYearBirthday.isAfter(now.subtract(const Duration(days: 1))) &&
                thisYearBirthday.isBefore(endDate)) ||
            _isToday(thisYearBirthday)) {
          final isToday = _isToday(thisYearBirthday);
          print('Adding this year JCRT birthday. Is today: $isToday');
          events.add({
            'name': member['jcrtName'] ?? '',
            'event_type': 'JCRT Birthday',
            'date': thisYearBirthday.toIso8601String(),
            'is_today': isToday,
            'image_url': member['jcrtImage'] != null
                ? '${ApiConfig.baseUrl}${member['jcrtImage']}'
                : null,
          });
        } else if ((nextYearBirthday
                    .isAfter(now.subtract(const Duration(days: 1))) &&
                nextYearBirthday.isBefore(endDate)) ||
            _isToday(nextYearBirthday)) {
          final isToday = _isToday(nextYearBirthday);
          print('Adding next year JCRT birthday. Is today: $isToday');
          events.add({
            'name': member['jcrtName'] ?? '',
            'event_type': 'JCRT Birthday',
            'date': nextYearBirthday.toIso8601String(),
            'is_today': isToday,
            'image_url': member['jcrtImage'] != null
                ? '${ApiConfig.baseUrl}${member['jcrtImage']}'
                : null,
          });
        }
      }

      // Process Anniversary
      if (member['anniversaryDate'] != null) {
        print('Anniversary: ${member['anniversaryDate']}');
        final anniversary = DateTime.parse(member['anniversaryDate']);
        final thisYearAnniversary =
            DateTime(now.year, anniversary.month, anniversary.day);
        final nextYearAnniversary =
            DateTime(now.year + 1, anniversary.month, anniversary.day);

        print(
            'This year anniversary: ${thisYearAnniversary.day}/${thisYearAnniversary.month}/${thisYearAnniversary.year}');
        print(
            'Next year anniversary: ${nextYearAnniversary.day}/${nextYearAnniversary.month}/${nextYearAnniversary.year}');

        if ((thisYearAnniversary
                    .isAfter(now.subtract(const Duration(days: 1))) &&
                thisYearAnniversary.isBefore(endDate)) ||
            _isToday(thisYearAnniversary)) {
          final isToday = _isToday(thisYearAnniversary);
          print('Adding this year anniversary. Is today: $isToday');
          events.add({
            'name': '${member['jcName'] ?? ''} & ${member['jcrtName'] ?? ''}',
            'event_type': 'Anniversary',
            'date': thisYearAnniversary.toIso8601String(),
            'is_today': isToday,
            'image_url': member['jcImage'] != null
                ? '${ApiConfig.baseUrl}${member['jcImage']}'
                : null,
          });
        } else if ((nextYearAnniversary
                    .isAfter(now.subtract(const Duration(days: 1))) &&
                nextYearAnniversary.isBefore(endDate)) ||
            _isToday(nextYearAnniversary)) {
          final isToday = _isToday(nextYearAnniversary);
          print('Adding next year anniversary. Is today: $isToday');
          events.add({
            'name': '${member['jcName'] ?? ''} & ${member['jcrtName'] ?? ''}',
            'event_type': 'Anniversary',
            'date': nextYearAnniversary.toIso8601String(),
            'is_today': isToday,
            'image_url': member['jcImage'] != null
                ? '${ApiConfig.baseUrl}${member['jcImage']}'
                : null,
          });
        }
      }
    }

    // Sort events by date
    events.sort((a, b) =>
        DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));

    // Separate today's events and group remaining events by month
    final todayEvents =
        events.where((event) => event['is_today'] == true).toList();
    final futureEvents =
        events.where((event) => event['is_today'] != true).toList();

    print('\nToday\'s events: ${todayEvents.length}');
    for (var event in todayEvents) {
      print('${event['name']} - ${event['event_type']} - ${event['date']}');
    }

    print('\nFuture events: ${futureEvents.length}');
    for (var event in futureEvents) {
      print('${event['name']} - ${event['event_type']} - ${event['date']}');
    }

    final monthlyEvents = <String, List<Map<String, dynamic>>>{};
    for (var event in futureEvents) {
      final date = DateTime.parse(event['date']);
      final monthKey = _monthFormat.format(date);
      monthlyEvents.putIfAbsent(monthKey, () => []).add(event);
      _expandedMonths[monthKey] = true; // Initialize all months as expanded
    }

    setState(() {
      _todayEvents = todayEvents;
      _monthlyEvents = monthlyEvents;
    });
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return _dateFormat.format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _launchWhatsApp(String? phoneNumber) async {
    print('\n=== WhatsApp Launch Process Started ===');
    print('Original phone number: $phoneNumber');

    if (phoneNumber == null || phoneNumber.isEmpty) {
      print('Error: Phone number is null or empty');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    String cleanNumber = '';
    try {
      // Clean the phone number - only remove non-digits
      cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      print('After removing non-digits: $cleanNumber');

      // Remove leading '0' if present
      if (cleanNumber.startsWith('0')) {
        cleanNumber = cleanNumber.substring(1);
        print('After removing leading 0: $cleanNumber');
      }

      // Try WhatsApp Business first
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: 'whatsapp://send?phone=$cleanNumber',
          package: 'com.whatsapp.w4b',
          flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
        );

        print('Attempting to launch WhatsApp Business');
        await intent.launch();
        print('Successfully launched WhatsApp Business');
        return;
      } catch (businessError) {
        print('WhatsApp Business not available, trying regular WhatsApp');
      }

      // Try regular WhatsApp
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: 'whatsapp://send?phone=$cleanNumber',
          package: 'com.whatsapp',
          flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
        );

        print('Attempting to launch regular WhatsApp');
        await intent.launch();
        print('Successfully launched regular WhatsApp');
        return;
      } catch (regularError) {
        print('Regular WhatsApp not available, trying web URL');
      }

      // Fallback to web URL if both apps fail
      final Uri webUrl =
          Uri.parse('https://api.whatsapp.com/send?phone=$cleanNumber');
      print('Attempting to launch WhatsApp via web URL: $webUrl');

      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        print('Successfully launched WhatsApp via web URL');
        return;
      }

      throw Exception('Could not launch WhatsApp through any method');
    } catch (e) {
      print('Error launching WhatsApp: $e');
      print('Error stack trace: ${StackTrace.current}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    print('=== WhatsApp Launch Process Ended ===\n');
  }

  Future<void> _launchPhoneCall(String? phoneNumber) async {
    print('\n=== Phone Call Launch Process Started ===');
    print('Original phone number: $phoneNumber');

    if (phoneNumber == null || phoneNumber.isEmpty) {
      print('Error: Phone number is null or empty');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Request phone call permission first
    final status = await Permission.phone.request();
    print('Phone permission status: $status');

    if (status.isDenied) {
      print('Phone permission denied');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone call permission is required to make calls'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Clean the phone number - only remove non-digits
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      print('After removing non-digits: $cleanNumber');

      // Create Android Intent for phone call
      final intent = AndroidIntent(
        action: 'android.intent.action.CALL',
        data: 'tel:$cleanNumber',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );

      print('Attempting to launch phone call with number: $cleanNumber');
      await intent.launch();
      print('Successfully launched phone call intent');
    } catch (e) {
      print('Error launching phone call: $e');
      print('Error stack trace: ${StackTrace.current}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching phone call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    print('=== Phone Call Launch Process Ended ===\n');
  }

  Widget _buildWhatsAppIcon() {
    return Image.asset(
      'assets/media/logo/whatsup.png',
      width: 24,
      height: 24,
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final bool isToday = event['is_today'] ?? false;
    final String eventType = event['event_type'] ?? '';
    final String name = event['name'] ?? '';
    final String date = _formatDate(event['date'] ?? '');
    final String? imageUrl = event['image_url'];
    final bool isJCRT = eventType == 'JCRT Birthday';
    final bool isAnniversary = eventType == 'Anniversary';

    // Find the member data for this event
    Map<String, dynamic>? memberData;
    try {
      memberData = widget.members.firstWhere(
        (m) =>
            (eventType == 'JC Birthday' && m['jcName'] == name) ||
            (eventType == 'JCRT Birthday' && m['jcrtName'] == name) ||
            (eventType == 'Anniversary' &&
                '${m['jcName']} & ${m['jcrtName']}' == name),
        orElse: () => <String, dynamic>{},
      ) as Map<String, dynamic>;
    } catch (e) {
      print('Error finding member data: $e');
      memberData = null;
    }

    String? phoneNumber;
    if (memberData != null) {
      if (eventType == 'JC Birthday') {
        // Extract only the first phone number if there are multiple
        String? rawNumber = memberData['jcMobile']?.toString();
        if (rawNumber != null) {
          // Split by any non-digit characters and take the first valid number
          List<String> numbers = rawNumber.split(RegExp(r'[^\d]'));
          phoneNumber = numbers.firstWhere(
            (n) => n.length >= 10,
            orElse: () => '',
          );
        }
        print('JC Phone number: $phoneNumber');
      } else if (eventType == 'JCRT Birthday') {
        // Extract only the first phone number if there are multiple
        String? rawNumber = memberData['jcrtMobile']?.toString();
        if (rawNumber != null) {
          // Split by any non-digit characters and take the first valid number
          List<String> numbers = rawNumber.split(RegExp(r'[^\d]'));
          phoneNumber = numbers.firstWhere(
            (n) => n.length >= 10,
            orElse: () => '',
          );
        }
        print('JCRT Phone number: $phoneNumber');
      } else if (eventType == 'Anniversary') {
        // For anniversary, use the phone number based on logged-in user's type
        if (widget.userMobileBelongsTo?.toLowerCase() == 'jc') {
          // Extract only the first phone number if there are multiple
          String? rawNumber = memberData['jcMobile']?.toString();
          if (rawNumber != null) {
            // Split by any non-digit characters and take the first valid number
            List<String> numbers = rawNumber.split(RegExp(r'[^\d]'));
            phoneNumber = numbers.firstWhere(
              (n) => n.length >= 10,
              orElse: () => '',
            );
          }
          print('Anniversary - Using JC phone number: $phoneNumber');
        } else if (widget.userMobileBelongsTo?.toLowerCase() == 'jcrt') {
          // Extract only the first phone number if there are multiple
          String? rawNumber = memberData['jcrtMobile']?.toString();
          if (rawNumber != null) {
            // Split by any non-digit characters and take the first valid number
            List<String> numbers = rawNumber.split(RegExp(r'[^\d]'));
            phoneNumber = numbers.firstWhere(
              (n) => n.length >= 10,
              orElse: () => '',
            );
          }
          print('Anniversary - Using JCRT phone number: $phoneNumber');
        }
      }
    }

    // Clean the phone number if it exists
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      // Remove any non-digit characters
      phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      // Remove leading '0' if present
      if (phoneNumber.startsWith('0')) {
        phoneNumber = phoneNumber.substring(1);
      }
      // Ensure the number starts with '91' for Indian numbers
      if (!phoneNumber.startsWith('91') && phoneNumber.length == 10) {
        phoneNumber = '91$phoneNumber';
      }
      print('Cleaned phone number: $phoneNumber');
    }

    // Get mobile_number_belongs_to value
    String? mobileBelongsTo =
        memberData?['mobile_number_belongs_to']?.toString().toLowerCase();
    print('Mobile number belongs to: $mobileBelongsTo');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isJCRT
          ? Colors.blue[50]
          : isAnniversary
              ? Colors.pink[50]
              : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: isJCRT
                  ? Colors.blue[100]
                  : isAnniversary
                      ? Colors.pink[100]
                      : Colors.grey[200],
              backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : null,
              child: imageUrl == null || imageUrl.isEmpty
                  ? Icon(
                      isAnniversary ? Icons.favorite : Icons.person,
                      size: 30,
                      color: isJCRT
                          ? Colors.blue[400]
                          : isAnniversary
                              ? Colors.pink[400]
                              : Colors.grey[600],
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isJCRT
                          ? Colors.blue[700]
                          : isAnniversary
                              ? Colors.pink[700]
                              : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    eventType,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isJCRT
                          ? Colors.blue[600]
                          : isAnniversary
                              ? Colors.pink[600]
                              : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isToday
                          ? Colors.green
                          : isJCRT
                              ? Colors.blue[600]
                              : isAnniversary
                                  ? Colors.pink[600]
                                  : Colors.blue,
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (mobileBelongsTo != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Mobile belongs to: ${mobileBelongsTo.toUpperCase()}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isToday && phoneNumber != null && phoneNumber.isNotEmpty) ...[
              IconButton(
                icon: Icon(Icons.phone, color: Colors.green[700]),
                onPressed: () => _launchPhoneCall(phoneNumber),
              ),
              IconButton(
                icon: _buildWhatsAppIcon(),
                onPressed: () => _launchWhatsApp(phoneNumber),
                tooltip: 'Open WhatsApp',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSection(String month, List<Map<String, dynamic>> events) {
    final bool isExpanded = _expandedMonths[month] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedMonths[month] = !isExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  month,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.blue[700],
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          ...events.map((event) => _buildEventCard(event)).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Upcoming Greetings',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _todayEvents.isEmpty && _monthlyEvents.isEmpty
          ? Center(
              child: Text(
                'No upcoming events',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                if (_todayEvents.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 16, 8),
                    child: Text(
                      'Today',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                  ..._todayEvents
                      .map((event) => _buildEventCard(event))
                      .toList(),
                  const Divider(height: 32),
                ],
                ..._monthlyEvents.entries
                    .map((entry) => _buildMonthSection(entry.key, entry.value))
                    .toList(),
              ],
            ),
    );
  }
}
