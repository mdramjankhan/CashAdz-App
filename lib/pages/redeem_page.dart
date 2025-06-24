import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RedeemPage extends StatefulWidget {
  const RedeemPage({super.key});

  @override
  State<RedeemPage> createState() => _RedeemPageState();
}

class _RedeemPageState extends State<RedeemPage> {
  final _formKey = GlobalKey<FormState>();
  final _upiController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  int _selectedPoints = 1000; // default minimum
  bool _isLoading = false;

  @override
  void dispose() {
    _upiController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _showRedeemDialog(int userPoints) async {
    _upiController.clear();
    _nameController.clear();
    _emailController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Redeem Points'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'You are redeeming $_selectedPoints points for ₹${_selectedPoints ~/ 20}',
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _upiController,
                  decoration: InputDecoration(labelText: 'UPI ID'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter UPI ID' : null,
                ),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter your name' : null,
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter your email'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        if (userPoints < _selectedPoints) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Not enough points!')),
                          );
                          return;
                        }
                        setState(() => _isLoading = true);
                        await _submitRedeemRequest();
                        setState(() => _isLoading = false);
                        Navigator.pop(context);
                      }
                    },
              child: _isLoading ? CircularProgressIndicator() : Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitRedeemRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    final redeemData = {
      'userId': user.uid,
      'amount': _selectedPoints ~/ 20,
      'points': _selectedPoints,
      'upi_id': _upiController.text.trim(),
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'status': 'pending',
      'requested_at': FieldValue.serverTimestamp(),
    };

    // Add to global redeem_requests
    final redeemRef = await FirebaseFirestore.instance
        .collection('redeem_requests')
        .add(redeemData);

    // Add to user's redeem_history
    await userDoc
        .collection('redeem_history')
        .doc(redeemRef.id)
        .set(redeemData);

    // Deduct points from user (optional: only after admin approves, or lock points here)
    // await userDoc.update({'points': FieldValue.increment(-_selectedPoints)});

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Redeem request submitted!')));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return SizedBox();

    return Scaffold(
      appBar: AppBar(title: Text('Redeem Points')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final points = data['points'] ?? 0;

          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: Text('Your Points'),
                  trailing: Text(
                    '$points pts',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Conversion Rates:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(title: Text('100 points = ₹5')),
                    ListTile(title: Text('500 points = ₹25')),
                    ListTile(title: Text('1000 points = ₹50 (Minimum redeem)')),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Select Redeem Amount:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ChoiceChip(
                    label: Text('₹50 (1000 pts)'),
                    selected: _selectedPoints == 1000,
                    onSelected: (selected) {
                      setState(() => _selectedPoints = 1000);
                    },
                  ),
                  ChoiceChip(
                    label: Text('₹100 (2000 pts)'),
                    selected: _selectedPoints == 2000,
                    onSelected: (selected) {
                      setState(() => _selectedPoints = 2000);
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ChoiceChip(
                    label: Text('₹25 (500 pts)'),
                    selected: _selectedPoints == 500,
                    onSelected: (selected) {
                      setState(() => _selectedPoints = 500);
                    },
                  ),
                  ChoiceChip(
                    label: Text('₹200 (4000 pts)'),
                    selected: _selectedPoints == 4000,
                    onSelected: (selected) {
                      setState(() => _selectedPoints = 4000);
                    },
                  ),
                ],
              ),

              SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.redeem),
                label: Text('Redeem Now'),
                onPressed: points >= 1000
                    ? () => _showRedeemDialog(points)
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
              SizedBox(height: 32),
              Text(
                'Redeem History',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('redeem_history')
                    .orderBy('requested_at', descending: true)
                    .snapshots(),
                builder: (context, historySnapshot) {
                  if (!historySnapshot.hasData)
                    return Center(child: CircularProgressIndicator());
                  final docs = historySnapshot.data!.docs;
                  if (docs.isEmpty) {
                    return Text('No redeem history yet.');
                  }
                  return Column(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final amount = data['amount'] ?? 0;
                      final upi = data['upi_id'] ?? '';
                      final status = data['status'] ?? 'pending';
                      final requestedAt = data['requested_at'] as Timestamp?;
                      final processedAt = data['processed_at'] as Timestamp?;
                      final dateStr = requestedAt != null
                          ? DateFormat(
                              'yyyy-MM-dd',
                            ).format(requestedAt.toDate())
                          : '';
                      String statusText = '';
                      Color statusColor = Colors.orange;
                      if (status == 'approved') {
                        statusText = '+₹$amount sent to $upi';
                        statusColor = Colors.green;
                      } else if (status == 'rejected') {
                        statusText = 'Rejected';
                        statusColor = Colors.red;
                      } else {
                        statusText = 'Pending';
                        statusColor = Colors.orange;
                      }
                      return ListTile(
                        leading: Icon(
                          Icons.account_balance_wallet,
                          color: statusColor,
                        ),
                        title: Text(
                          statusText,
                          style: TextStyle(color: statusColor),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Requested on $dateStr'),
                            if (status == 'rejected' &&
                                data['admin_message'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Reason: ${data['admin_message']}',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            if (status == 'approved' &&
                                data['admin_message'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Note: ${data['admin_message']}',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: Text('₹$amount'),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
