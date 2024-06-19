import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  // Function to create a muted MaterialColor
  MaterialColor createMutedMaterialColor(Color color) {
    return MaterialColor(
      color.value,
      <int, Color>{
        50: adjustColor(color, 0.9),
        100: adjustColor(color, 0.8),
        200: adjustColor(color, 0.7),
        300: adjustColor(color, 0.6),
        400: adjustColor(color, 0.5),
        500: adjustColor(color, 0.4),
        600: adjustColor(color, 0.3),
        700: adjustColor(color, 0.2),
        800: adjustColor(color, 0.1),
        900: adjustColor(color, 0.05),
      },
    );
  }

// Function to adjust the brightness of a color
  Color adjustColor(Color color, double factor) {
    return Color.fromRGBO(
      (color.red * factor).toInt(),
      (color.green * factor).toInt(),
      (color.blue * factor).toInt(),
      1,
    );
  }

  List<MaterialColor> colors = [];


  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final bibleProvider = Provider.of<BibleProvider>(context);

    colors = [
      createMutedMaterialColor(Colors.red),
      createMutedMaterialColor(Colors.pink),
      createMutedMaterialColor(Colors.purple),
      createMutedMaterialColor(Colors.deepPurple),
      createMutedMaterialColor(Colors.indigo),
      createMutedMaterialColor(Colors.blue),
      createMutedMaterialColor(Colors.cyan),
      createMutedMaterialColor(Colors.teal),
      createMutedMaterialColor(Colors.green),
      createMutedMaterialColor(Colors.lightGreen),
      createMutedMaterialColor(Colors.yellow),
      createMutedMaterialColor(Colors.orange),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text('Bible Translation:', style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: settingsProvider.currentTranslationId == '' ? null : settingsProvider.currentTranslationId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Select Translation',
                ),
                isExpanded: true,
                items: bibleProvider.translations
                    .map<DropdownMenuItem<String>>((translation) {
                  String language = translation['language']['name'];
                  return DropdownMenuItem<String>(
                    value: translation['id'],
                    child: Text(
                      '${translation['name']} ($language)',
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    var selectedTranslation = bibleProvider.translations.firstWhere((t) => t['id'] == newValue);
                    settingsProvider.updateTranslation(newValue, selectedTranslation['name']);
                  }
                },
              ),
              if (settingsProvider.isLoggedIn)
                const SizedBox(height: 16),
              if (settingsProvider.isLoggedIn)
                SwitchListTile(
                  title: Text('Private Profile', style: Theme.of(context).textTheme.bodyMedium),
                  value: !settingsProvider.isPublicProfile,
                  onChanged: (bool value) {
                    settingsProvider.togglePublicProfile(!value);
                  },
                ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              if (settingsProvider.isLoggedIn)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text('App Color:', style: Theme.of(context).textTheme.bodyMedium),
                ),
              if (settingsProvider.isLoggedIn)
                const SizedBox(height: 16),
              if (settingsProvider.isLoggedIn)
                GridView.builder(
                  shrinkWrap: true,
                  itemCount: colors.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    var color = colors[index];
                    bool isSelected = settingsProvider.currentColor?.value == color.value;
                    return GestureDetector(
                      onTap: () {
                        settingsProvider.updateColor(color);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                        ),
                        child: isSelected
                            ? const Center(child: Icon(Icons.check, color: Colors.white))
                            : null,
                      ),
                    );
                  },
                ),
              if (settingsProvider.isLoggedIn)
                const SizedBox(height: 16),
              if (settingsProvider.isLoggedIn)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Text('Highlighter Color:', style: Theme.of(context).textTheme.bodyMedium),
                ),
              const SizedBox(height: 16),
              if (settingsProvider.isLoggedIn)
                GridView.builder(
                  shrinkWrap: true,
                  itemCount: colors.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    var color = colors[index];
                    bool isSelected = settingsProvider.highlightColor?.value == color.value;
                    return GestureDetector(
                      onTap: () {
                        settingsProvider.updateHighlightColor(color);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                        ),
                        child: isSelected
                            ? const Center(child: Icon(Icons.check, color: Colors.white))
                            : null,
                      ),
                    );
                  },
                ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text('Theme Mode:', style: Theme.of(context).textTheme.bodyMedium),
              ),
              ListTile(
                title: const Text('Light Mode'),
                leading: Radio<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: settingsProvider.currentThemeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      settingsProvider.updateThemeMode(value);
                    }
                  },
                ),
              ),
              ListTile(
                title: const Text('Dark Mode'),
                leading: Radio<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: settingsProvider.currentThemeMode,
                  onChanged: (ThemeMode? value) {
                    if (value != null) {
                      settingsProvider.updateThemeMode(value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (settingsProvider.isLoggedIn) ...[

                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await settingsProvider.updateUserSettingsOnBackend();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Settings synced successfully')),
                      );
                    },
                    child: const Text('Sync Settings'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
