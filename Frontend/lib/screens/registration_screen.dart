import 'package:flutter/material.dart';
import 'package:TheWord/screens/login_screen.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../providers/settings_provider.dart';
import 'main_app.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _privacyPolicyAgreed = false;

  Future<bool> _login() async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': _emailController.text,
        'password': _passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final token = body['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setInt('tokenExpiry',
          DateTime.now().add(Duration(days: 30)).millisecondsSinceEpoch);
      await Provider.of<SettingsProvider>(context, listen: false)
          .loadSettings();
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed')),
      );
    }
    return false;
  }

  Future<void> _register() async {
    if (!_privacyPolicyAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must agree to the privacy policy.')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': _emailController.text,
        'password': _passwordController.text,
        'username': _usernameController.text,
      }),
    );

    if (response.statusCode == 200) {
      bool loginSuccessful = await _login();

      if (loginSuccessful) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MainAppScreen()),
        );
      } else {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => LoginScreen()));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed')),
      );
    }
  }

  void _showPrivacyPolicyModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Privacy Policy'),
          content: const SingleChildScrollView(
            child: Text(
              '''
Privacy Policy

Effective Date: June 16th, 2024

1. Introduction

Welcome to The Word. We value your privacy and are committed to protecting your personal data. This privacy policy explains how we collect, use, and share your information. We comply with the Children's Online Privacy Protection Act (COPPA) and take special care to protect the privacy of children under 13.

2. Data Collection

2.1 User-Provided Data

- Prompts to Google Gemini API: We send user-provided prompts to the Google Gemini API. We do not save this data.
- Email Address: We collect email addresses for account registration and login purposes. These are used solely for user verification and not for any other form of communication.
- Saved Data: Users can save verses, notes, and comments. Saved data is stored on our servers and tied to user profiles for persistence. Users can access and delete their notes.

2.2 Automatically Collected Data

We may collect certain information automatically when you use our app, such as your IP address, browser type, and device information. This data is used to improve our services.

2.3 Children's Data

We do not knowingly collect personal information from children under 13 without parental consent. If we become aware that we have collected personal information from a child under 13 without parental consent, we will take steps to remove that information promptly.

3. Data Use

We use your data for the following purposes:

- Account Management: To manage user accounts and provide login functionality.
- Service Improvement: To enhance our services and user experience.
- User Interaction: To allow users to save and share verses, notes, and comments.

4. Data Sharing

- Public Profiles: If users set their profiles to public, other users can see their notes, comments, and username.
- Friends Feature: Users can add friends and interact through comments on notes. Comments are saved and visible to other users.
- Third-Party Services: We use Google Gemini API for prompt processing. We do not store the data sent to this service.

5. Children’s Privacy (COPPA Compliance)

- Parental Consent: We do not collect personal information from children under 13 without obtaining parental consent. Parents can consent to our collection and use of their child's information but prohibit disclosure to third parties.
- Parental Rights: Parents have the right to review, delete, and manage their child's personal information at any time. They can contact us at [Your Contact Information] to exercise these rights.
- Data Minimization: We only collect the information necessary to provide our services and do not condition the participation in activities on the collection of more information than is necessary.
- Data Security: We implement reasonable security measures to protect the data of children.

6. User Rights

- Access and Control: Users can view and delete their notes and comments. They can also set their profile visibility to public or private.
- Data Deletion: Users have the right to delete their accounts and associated data.

7. Data Security

We implement reasonable security measures to protect your data. However, no method of transmission over the internet or electronic storage is 100% secure.

8. No Moderation Policy

We do not moderate user activity within the app. Users are responsible for their interactions and content.

9. Changes to This Privacy Policy

We may update this privacy policy from time to time. Any changes will be posted on this page with an updated effective date.

10. Contact Us

If you have any questions about this privacy policy or if you need to exercise any parental rights under COPPA, please contact us at [Your Contact Information].
              ''',
              style: const TextStyle(fontSize: 14.0),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _privacyPolicyAgreed = true;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Agree'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Disagree'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: _privacyPolicyAgreed,
                  onChanged: (bool? value) {
                    if (value == true) {
                      _showPrivacyPolicyModal();
                    } else {
                      setState(() {
                        _privacyPolicyAgreed = false;
                      });
                    }
                  },
                ),
                GestureDetector(
                  onTap: _showPrivacyPolicyModal,
                  child: const Text(
                    'I agree to the Privacy Policy',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _register,
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
