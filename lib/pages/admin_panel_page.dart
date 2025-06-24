import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  Future<void> _approveRequest(
    String requestId,
    String userId,
    int points,
    int amount,
    String upiId,
  ) async {
    final requestRef = FirebaseFirestore.instance
        .collection('redeem_requests')
        .doc(requestId);
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    // Update request status
    await requestRef.update({
      'status': 'approved',
      'processed_at': FieldValue.serverTimestamp(),
      'admin_message': 'Redeem approved',
    });

    // Add to user's redeem_history
    await userRef.collection('redeem_history').doc(requestId).update({
      'status': 'approved',
      'processed_at': FieldValue.serverTimestamp(),
      'admin_message': 'Redeem approved',
    });

    // Deduct points from user
    await userRef.update({'points': FieldValue.increment(-points)});
  }

  Future<void> _rejectRequest(
    BuildContext context,
    String requestId,
    String userId, {
    String reason = "Rejected by admin",
  }) async {
    final requestRef = FirebaseFirestore.instance
        .collection('redeem_requests')
        .doc(requestId);
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    // Update request status
    await requestRef.update({
      'status': 'rejected',
      'processed_at': FieldValue.serverTimestamp(),
      'admin_message': reason,
    });

    // Add to user's redeem_history
    await userRef.collection('redeem_history').doc(requestId).update({
      'status': 'rejected',
      'processed_at': FieldValue.serverTimestamp(),
      'admin_message': reason,
    });
  }

  void _showUserDetailsDialog(BuildContext context, String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    final userData = userDoc.data() as Map<String, dynamic>?;

    showDialog(
      context: context,
      builder: (context) {
        if (userData == null) {
          return AlertDialog(
            title: Text('User Details'),
            content: Text('User data not found.'),
            actions: [
              TextButton(
                child: Text('Close'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        }
        return AlertDialog(
          title: Text('User Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (userData['photoUrl'] != null)
                Center(
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(userData['photoUrl']),
                    radius: 30,
                  ),
                ),
              SizedBox(height: 8),
              Text('Name: ${userData['name'] ?? ''}'),
              Text('Email: ${userData['email'] ?? ''}'),
              Text('Points: ${userData['points'] ?? 0}'),
              if (userData['upi_id'] != null)
                Text('UPI ID: ${userData['upi_id']}'),
              // Add more fields as needed
            ],
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  void _showRejectDialog(
    BuildContext context,
    String requestId,
    String userId,
  ) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Redeem Request'),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(labelText: 'Reason (optional)'),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('Reject'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _rejectRequest(
                context,
                requestId,
                userId,
                reason: reasonController.text.isNotEmpty
                    ? reasonController.text
                    : "Rejected by admin",
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Panel')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('redeem_requests')
            .orderBy('requested_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return Center(child: Text('No redeem requests.'));
          return ListView(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final userId = data['userId'] ?? '';
              final amount = data['amount'] ?? 0;
              final points = data['points'] ?? 0;
              final upiId = data['upi_id'] ?? '';
              final name = data['name'] ?? '';
              final email = data['email'] ?? '';
              final status = data['status'] ?? 'pending';
              final requestedAt = data['requested_at'] as Timestamp?;
              final dateStr = requestedAt != null
                  ? DateFormat('yyyy-MM-dd').format(requestedAt.toDate())
                  : '';
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: InkWell(
                  onTap: () => _showUserDetailsDialog(context, userId),
                  child: ListTile(
                    title: Text('$name ($email)'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User ID: $userId'),
                        Text('UPI: $upiId'),
                        Text('Points: $points, Amount: ₹$amount'),
                        Text('Requested: $dateStr'),
                        Text('Status: $status'),
                      ],
                    ),
                    trailing: status == 'pending'
                        ? PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'approve') {
                                await _approveRequest(
                                  doc.id,
                                  userId,
                                  points,
                                  amount,
                                  upiId,
                                );
                              } else if (value == 'reject') {
                                _showRejectDialog(context, doc.id, userId);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'approve',
                                child: Text('Approve'),
                              ),
                              PopupMenuItem(
                                value: 'reject',
                                child: Text('Reject'),
                              ),
                            ],
                            icon: Icon(Icons.more_vert),
                          )
                        : Icon(
                            status == 'approved'
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: status == 'approved'
                                ? Colors.green
                                : Colors.red,
                          ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
