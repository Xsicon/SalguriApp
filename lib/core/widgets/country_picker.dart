import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class Country {
  final String name;
  final String flag;
  final String dialCode;
  final String code;

  const Country({
    required this.name,
    required this.flag,
    required this.dialCode,
    required this.code,
  });
}

const Country defaultCountry = Country(
  name: 'Somalia',
  flag: '\u{1F1F8}\u{1F1F4}',
  dialCode: '+252',
  code: 'SO',
);

Future<Country?> showCountryPicker(BuildContext context) {
  return showModalBottomSheet<Country>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CountryPickerSheet(),
  );
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet();

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  List<Country> _filtered = _countries;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = _countries.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.dialCode.contains(q) ||
            c.code.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final height = MediaQuery.of(context).size.height * 0.7;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'Select Country',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              style: TextStyle(fontSize: 16, color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Search country or code...',
                hintStyle: TextStyle(color: cs.outline, fontSize: 15),
                prefixIcon: Icon(Icons.search, color: cs.outline, size: 22),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: cs.surfaceContainerHighest),
          // List
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final country = _filtered[index];
                return ListTile(
                  onTap: () => Navigator.of(context).pop(country),
                  leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    country.name,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Text(
                    country.dialCode,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

const _countries = [
  Country(name: 'Afghanistan', flag: '\u{1F1E6}\u{1F1EB}', dialCode: '+93', code: 'AF'),
  Country(name: 'Albania', flag: '\u{1F1E6}\u{1F1F1}', dialCode: '+355', code: 'AL'),
  Country(name: 'Algeria', flag: '\u{1F1E9}\u{1F1FF}', dialCode: '+213', code: 'DZ'),
  Country(name: 'Argentina', flag: '\u{1F1E6}\u{1F1F7}', dialCode: '+54', code: 'AR'),
  Country(name: 'Australia', flag: '\u{1F1E6}\u{1F1FA}', dialCode: '+61', code: 'AU'),
  Country(name: 'Austria', flag: '\u{1F1E6}\u{1F1F9}', dialCode: '+43', code: 'AT'),
  Country(name: 'Bahrain', flag: '\u{1F1E7}\u{1F1ED}', dialCode: '+973', code: 'BH'),
  Country(name: 'Bangladesh', flag: '\u{1F1E7}\u{1F1E9}', dialCode: '+880', code: 'BD'),
  Country(name: 'Belgium', flag: '\u{1F1E7}\u{1F1EA}', dialCode: '+32', code: 'BE'),
  Country(name: 'Brazil', flag: '\u{1F1E7}\u{1F1F7}', dialCode: '+55', code: 'BR'),
  Country(name: 'Canada', flag: '\u{1F1E8}\u{1F1E6}', dialCode: '+1', code: 'CA'),
  Country(name: 'China', flag: '\u{1F1E8}\u{1F1F3}', dialCode: '+86', code: 'CN'),
  Country(name: 'Colombia', flag: '\u{1F1E8}\u{1F1F4}', dialCode: '+57', code: 'CO'),
  Country(name: 'Djibouti', flag: '\u{1F1E9}\u{1F1EF}', dialCode: '+253', code: 'DJ'),
  Country(name: 'Egypt', flag: '\u{1F1EA}\u{1F1EC}', dialCode: '+20', code: 'EG'),
  Country(name: 'Eritrea', flag: '\u{1F1EA}\u{1F1F7}', dialCode: '+291', code: 'ER'),
  Country(name: 'Ethiopia', flag: '\u{1F1EA}\u{1F1F9}', dialCode: '+251', code: 'ET'),
  Country(name: 'Finland', flag: '\u{1F1EB}\u{1F1EE}', dialCode: '+358', code: 'FI'),
  Country(name: 'France', flag: '\u{1F1EB}\u{1F1F7}', dialCode: '+33', code: 'FR'),
  Country(name: 'Germany', flag: '\u{1F1E9}\u{1F1EA}', dialCode: '+49', code: 'DE'),
  Country(name: 'Ghana', flag: '\u{1F1EC}\u{1F1ED}', dialCode: '+233', code: 'GH'),
  Country(name: 'India', flag: '\u{1F1EE}\u{1F1F3}', dialCode: '+91', code: 'IN'),
  Country(name: 'Indonesia', flag: '\u{1F1EE}\u{1F1E9}', dialCode: '+62', code: 'ID'),
  Country(name: 'Iran', flag: '\u{1F1EE}\u{1F1F7}', dialCode: '+98', code: 'IR'),
  Country(name: 'Iraq', flag: '\u{1F1EE}\u{1F1F6}', dialCode: '+964', code: 'IQ'),
  Country(name: 'Ireland', flag: '\u{1F1EE}\u{1F1EA}', dialCode: '+353', code: 'IE'),
  Country(name: 'Italy', flag: '\u{1F1EE}\u{1F1F9}', dialCode: '+39', code: 'IT'),
  Country(name: 'Japan', flag: '\u{1F1EF}\u{1F1F5}', dialCode: '+81', code: 'JP'),
  Country(name: 'Jordan', flag: '\u{1F1EF}\u{1F1F4}', dialCode: '+962', code: 'JO'),
  Country(name: 'Kenya', flag: '\u{1F1F0}\u{1F1EA}', dialCode: '+254', code: 'KE'),
  Country(name: 'Kuwait', flag: '\u{1F1F0}\u{1F1FC}', dialCode: '+965', code: 'KW'),
  Country(name: 'Laos', flag: '\u{1F1F1}\u{1F1E6}', dialCode: '+856', code: 'LA'),
  Country(name: 'Lebanon', flag: '\u{1F1F1}\u{1F1E7}', dialCode: '+961', code: 'LB'),
  Country(name: 'Libya', flag: '\u{1F1F1}\u{1F1FE}', dialCode: '+218', code: 'LY'),
  Country(name: 'Malaysia', flag: '\u{1F1F2}\u{1F1FE}', dialCode: '+60', code: 'MY'),
  Country(name: 'Mexico', flag: '\u{1F1F2}\u{1F1FD}', dialCode: '+52', code: 'MX'),
  Country(name: 'Morocco', flag: '\u{1F1F2}\u{1F1E6}', dialCode: '+212', code: 'MA'),
  Country(name: 'Netherlands', flag: '\u{1F1F3}\u{1F1F1}', dialCode: '+31', code: 'NL'),
  Country(name: 'Nigeria', flag: '\u{1F1F3}\u{1F1EC}', dialCode: '+234', code: 'NG'),
  Country(name: 'Norway', flag: '\u{1F1F3}\u{1F1F4}', dialCode: '+47', code: 'NO'),
  Country(name: 'Oman', flag: '\u{1F1F4}\u{1F1F2}', dialCode: '+968', code: 'OM'),
  Country(name: 'Pakistan', flag: '\u{1F1F5}\u{1F1F0}', dialCode: '+92', code: 'PK'),
  Country(name: 'Palestine', flag: '\u{1F1F5}\u{1F1F8}', dialCode: '+970', code: 'PS'),
  Country(name: 'Philippines', flag: '\u{1F1F5}\u{1F1ED}', dialCode: '+63', code: 'PH'),
  Country(name: 'Qatar', flag: '\u{1F1F6}\u{1F1E6}', dialCode: '+974', code: 'QA'),
  Country(name: 'Russia', flag: '\u{1F1F7}\u{1F1FA}', dialCode: '+7', code: 'RU'),
  Country(name: 'Saudi Arabia', flag: '\u{1F1F8}\u{1F1E6}', dialCode: '+966', code: 'SA'),
  Country(name: 'Senegal', flag: '\u{1F1F8}\u{1F1F3}', dialCode: '+221', code: 'SN'),
  Country(name: 'Somalia', flag: '\u{1F1F8}\u{1F1F4}', dialCode: '+252', code: 'SO'),
  Country(name: 'South Africa', flag: '\u{1F1FF}\u{1F1E6}', dialCode: '+27', code: 'ZA'),
  Country(name: 'South Korea', flag: '\u{1F1F0}\u{1F1F7}', dialCode: '+82', code: 'KR'),
  Country(name: 'Spain', flag: '\u{1F1EA}\u{1F1F8}', dialCode: '+34', code: 'ES'),
  Country(name: 'Sudan', flag: '\u{1F1F8}\u{1F1E9}', dialCode: '+249', code: 'SD'),
  Country(name: 'Sweden', flag: '\u{1F1F8}\u{1F1EA}', dialCode: '+46', code: 'SE'),
  Country(name: 'Switzerland', flag: '\u{1F1E8}\u{1F1ED}', dialCode: '+41', code: 'CH'),
  Country(name: 'Syria', flag: '\u{1F1F8}\u{1F1FE}', dialCode: '+963', code: 'SY'),
  Country(name: 'Tanzania', flag: '\u{1F1F9}\u{1F1FF}', dialCode: '+255', code: 'TZ'),
  Country(name: 'Thailand', flag: '\u{1F1F9}\u{1F1ED}', dialCode: '+66', code: 'TH'),
  Country(name: 'Tunisia', flag: '\u{1F1F9}\u{1F1F3}', dialCode: '+216', code: 'TN'),
  Country(name: 'Turkey', flag: '\u{1F1F9}\u{1F1F7}', dialCode: '+90', code: 'TR'),
  Country(name: 'Uganda', flag: '\u{1F1FA}\u{1F1EC}', dialCode: '+256', code: 'UG'),
  Country(name: 'United Arab Emirates', flag: '\u{1F1E6}\u{1F1EA}', dialCode: '+971', code: 'AE'),
  Country(name: 'United Kingdom', flag: '\u{1F1EC}\u{1F1E7}', dialCode: '+44', code: 'GB'),
  Country(name: 'United States', flag: '\u{1F1FA}\u{1F1F8}', dialCode: '+1', code: 'US'),
  Country(name: 'Yemen', flag: '\u{1F1FE}\u{1F1EA}', dialCode: '+967', code: 'YE'),
];
