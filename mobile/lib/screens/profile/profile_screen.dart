import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/theme_provider.dart';
import '../../widgets/neumorphic_container.dart';
import '../../widgets/neumorphic_button.dart';
import '../../widgets/neumorphic_text_field.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Hierarchical data
  final Map<String, Map<String, String>> countryData = {
    'USA': {'continent': 'North America', 'cities': 'New York, Los Angeles, Chicago'},
    'UK': {'continent': 'Europe', 'cities': 'London, Manchester, Birmingham'},
    'Bangladesh': {'continent': 'Asia', 'cities': 'Dhaka, Chittagong, Sylhet'},
    'Germany': {'continent': 'Europe', 'cities': 'Berlin, Munich, Frankfurt'},
    'Canada': {'continent': 'North America', 'cities': 'Toronto, Vancouver, Montreal'},
  };

  String? _selectedCountry = 'USA';
  String? _selectedCity = 'New York';
  String _continent = 'North America';

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDark = themeMode == ThemeMode.dark || 
                  (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppConstants.spaceM),
            child: _buildThemeToggle(isDark),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spaceL),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: AppConstants.spaceXL),
            _buildUserInfoSection(),
            const SizedBox(height: AppConstants.spaceXL),
            _buildLocationSection(),
            const SizedBox(height: AppConstants.spaceXL),
            _buildPasswordSection(),
            const SizedBox(height: AppConstants.spaceXXXL),
            NeumorphicButton(
              isPrimary: true,
              onPressed: () {},
              child: const Text(
                'Save Changes',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: AppConstants.spaceXL),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle(bool isDark) {
    return GestureDetector(
      onTap: () => ref.read(themeNotifierProvider.notifier).toggleTheme(),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.8),
              offset: const Offset(-2, -2),
              blurRadius: 4,
            ),
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.2) : AppColors.darkShadow.withOpacity(0.5),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: NeumorphicContainer(
          width: 44,
          height: 44,
          shape: BoxShape.circle,
          child: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: AppColors.primaryGreen,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            const NeumorphicContainer(
              width: 120,
              height: 120,
              shape: BoxShape.circle,
              child: Icon(Icons.person, size: 60, color: AppColors.primaryGreen),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: NeumorphicContainer(
                width: 36,
                height: 36,
                shape: BoxShape.circle,
                child: const Icon(Icons.camera_alt, size: 16, color: AppColors.primaryGreen),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spaceM),
        Text(
          'Muhammad Minhaz',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          '@muhammad_minhaz',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryGreen),
        ),
      ],
    );
  }

  Widget _buildUserInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Basic Information'),
        const SizedBox(height: AppConstants.spaceM),
        const NeumorphicTextField(
          hintText: 'First Name',
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: AppConstants.spaceM),
        const NeumorphicTextField(
          hintText: 'Last Name',
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: AppConstants.spaceM),
        const NeumorphicTextField(
          hintText: 'Email',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Location'),
        const SizedBox(height: AppConstants.spaceM),
        _buildDropdown(
          label: 'Country',
          value: _selectedCountry,
          items: countryData.keys.toList(),
          onChanged: (val) {
            setState(() {
              _selectedCountry = val;
              _continent = countryData[val]!['continent']!;
              _selectedCity = countryData[val]!['cities']!.split(', ').first;
            });
          },
        ),
        const SizedBox(height: AppConstants.spaceM),
        _buildDropdown(
          label: 'City',
          value: _selectedCity,
          items: countryData[_selectedCountry]!['cities']!.split(', '),
          onChanged: (val) {
            setState(() {
              _selectedCity = val;
            });
          },
        ),
        const SizedBox(height: AppConstants.spaceM),
        _buildReadOnlyField(
          label: 'Continent',
          value: _continent,
          icon: Icons.public,
        ),
      ],
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Security'),
        const SizedBox(height: AppConstants.spaceM),
        const NeumorphicTextField(
          hintText: 'Current Password',
          prefixIcon: Icons.lock_outline,
          obscureText: true,
        ),
        const SizedBox(height: AppConstants.spaceM),
        const NeumorphicTextField(
          hintText: 'New Password',
          prefixIcon: Icons.lock_reset,
          obscureText: true,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGreen,
          ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return NeumorphicContainer(
      isInset: true,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceM),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(label),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return NeumorphicContainer(
      isInset: true,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceM, vertical: AppConstants.spaceM),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: AppConstants.spaceM),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
