import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:l2l_shared/add_word/add_word_page.dart';
import 'package:l2l_shared/auth/auth_provider.dart';

class EditorPortalPage extends StatefulWidget {
  const EditorPortalPage({super.key});

  @override
  State<EditorPortalPage> createState() => _EditorPortalPageState();
}

class _EditorPortalPageState extends State<EditorPortalPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final isEditor = authProvider.isEditor || authProvider.isAdmin;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Editor Portal',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome to the Editor Portal',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Use the options below to manage and add new sign language entries.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                if (isEditor)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Word'),
                    style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddWordPage()),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
