import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore List',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF2962FF)),
      home: const ItemListApp(),
    );
  }
}

class ItemListApp extends StatefulWidget {
  const ItemListApp({super.key});

  @override
  State<ItemListApp> createState() => _ItemListAppState();
}

class _ItemListAppState extends State<ItemListApp> {
  // Controller for the input field
  final TextEditingController _newItemTextField = TextEditingController();

  // Local list of items (Phase 1: local; Phase 2: Firestore stream replaces this).
  //final List<String> _itemList = <String>[];
  late final CollectionReference<Map<String, dynamic>> items;

  void initState() {
    super.initState();
    items = FirebaseFirestore.instance.collection('ITEMS');
  }

  // ACTION: add one item from the TextField to the local list.
  void _addItem() {
    final newItem = _newItemTextField.text.trim();
    if (newItem.isEmpty) return;
    setState(() {
      //_itemList.add(newItem);
      items.add(
          {
            'item_name': newItem,
            'createdAt': FieldValue.serverTimestamp(),
          });
      _newItemTextField.clear();
    });
  }

  // ACTION: remove the item with the given FireStore ID.
  void _removeItemAt(String  id) {
    setState(() {
      //_itemList.removeAt(i); // remove item from list
      items.doc(id).delete(); // remove item from Firestore
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firestore List Demo')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Column(
          children: [
            // ====== Item Input  ======
            NewItemWidget(),
            // ====== Spacer for formating ======
            const SizedBox(height: 24),
            Expanded(
              // ====== Item List ======
              child: ItemListWidget(),
            ),
          ],
        ),
      ),
    );
  }

  StreamBuilder<QuerySnapshot<Map<String, dynamic>>> ItemListWidget() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: items.snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snap) {
        if (snap.hasError) {
          return Text('Firebase Snapshot Error: ${snap.error}');
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Text('Loading...');
        }
        if (snap.data == null || snap.data!.docs.isEmpty) {
          return const Text('No Items Yet...');
        }
        return ListView.builder(
                  itemCount: snap.data!.docs.length,
                  itemBuilder: (context, i) {
                    final doc = snap.data!.docs[i];
                    final String itemId = doc.id;
                    final String itemName = (doc.data()['item_name']);
                    return Dismissible(
                      key: ValueKey(itemId),
                      background: Container(color: Colors.red),
                      onDismissed: (_) => _removeItemAt(itemId),
                      // ====== Item Tile ======
                      child: ListTile(
                        leading: const Icon(Icons.check_box),
                        title: Text(itemName),
                        onTap: () => _removeItemAt(itemId),
                      ),
                    );
                  },
                );
      }
    );
  }

  Widget NewItemWidget() {
    return Row(
            children: [
              // ====== Item Name TextField ======
              Expanded(
                child: TextField(
                  controller: _newItemTextField,
                  onSubmitted: (_) => _addItem(),
                  decoration: const InputDecoration(
                    labelText: 'New Item Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              // ====== Spacer for formating ======
              const SizedBox(width: 12),
              // ====== Add Item Button ======
              FilledButton(onPressed: _addItem, child: const Text('Add')),
            ],
          );
  }
}
