import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // User Info Section
          _buildSection(
            context,
            title: 'Account',
            children: [
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: const Text('user@example.com'),
                subtitle: const Text('Free Plan'),
                trailing: TextButton(
                  onPressed: () {
                    // TODO: Navigate to subscription
                  },
                  child: const Text('Upgrade'),
                ),
              ),
            ],
          ),
          
          const Divider(),
          
          // Correction Settings
          _buildSection(
            context,
            title: 'Correction',
            children: [
              ListTile(
                leading: const Icon(Icons.auto_fix_high),
                title: const Text('Default Correction Mode'),
                subtitle: const Text('Intermediate'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show mode selector
                },
              ),
            ],
          ),
          
          const Divider(),
          
          // Usage Section
          _buildSection(
            context,
            title: 'Today\'s Usage',
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Scans Used'),
                trailing: const Text('0 / 1'),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Free plan includes 1 scan per day. Upgrade to Premium for unlimited scans.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ],
          ),
          
          const Divider(),
          
          // App Settings
          _buildSection(
            context,
            title: 'App',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text('Dark Mode'),
                subtitle: const Text('Follow system'),
                value: false,
                onChanged: (value) {
                  // TODO: Implement theme switching
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                subtitle: const Text('English'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Show language selector
                },
              ),
            ],
          ),
          
          const Divider(),
          
          // About Section
          _buildSection(
            context,
            title: 'About',
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Version'),
                subtitle: const Text('1.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms of Service'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Open terms
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Open privacy policy
                },
              ),
            ],
          ),
          
          const Divider(),
          
          // Logout
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement logout
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Log Out'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Call Cognito signOut
                        },
                        child: const Text('Log Out'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}
