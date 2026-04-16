import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class DestinationsFirestoreScreen extends StatelessWidget {
  const DestinationsFirestoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Destinations (Firestore)'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getDestinations(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No destinations found'),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return ListTile(
                leading: data['imageUrl'] != null
                    ? Image.network(
                        data['imageUrl'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.image_not_supported);
                        },
                      )
                    : const Icon(Icons.place),
                title: Text(data['name'] ?? 'Unknown'),
                subtitle: Text(data['category'] ?? ''),
                trailing: Text('⭐ ${data['rating'] ?? 0}'),
                onTap: () {
                  // Navigate to detail screen
                },
              );
            },
          );
        },
      ),
    );
  }
}
