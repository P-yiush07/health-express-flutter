import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/ai_service.dart';

class StoredValuesDialog extends StatefulWidget {
  final List<Map<String, dynamic>> storedValues;

  const StoredValuesDialog({Key? key, required this.storedValues}) : super(key: key);

  @override
  State<StoredValuesDialog> createState() => _StoredValuesDialogState();
}

class _StoredValuesDialogState extends State<StoredValuesDialog> {
  late List<Map<String, dynamic>> values;

  @override
  void initState() {
    super.initState();
    values = List.from(widget.storedValues);
  }

  Future<void> _deleteValue(int index) async {
    await AIService.deleteStoredValue(index);
    if (mounted) {
      Navigator.of(context).pop(); // Close the dialog
    }
  }

  Future<void> _deleteAllValues() async {
    await AIService.deleteAllStoredValues();
    if (mounted) {
      Navigator.of(context).pop(); // Close the dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report History'),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6, // Set maximum height
        child: values.isEmpty
            ? const Center(
                child: Text('No reports available'),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: values.length,
                itemBuilder: (context, index) {
                  final entry = values[index];
                  final timestamp = DateTime.parse(entry['timestamp']);
                  final entryValues = List<Map<String, dynamic>>.from(entry['values']);
                  final type = entry['type'] ?? 'metrics';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ExpansionTile(
                      leading: Icon(
                        type == 'comparison' 
                            ? Icons.compare_arrows 
                            : Icons.medical_information,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat('MMM dd, yyyy HH:mm').format(timestamp),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, 
                              size: 20, 
                              color: Colors.red,
                            ),
                            onPressed: () => _deleteValue(index),
                            tooltip: 'Delete Report',
                          ),
                        ],
                      ),
                      children: [
                        ...entryValues.map((value) => ListTile(
                          title: Text(
                            value['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${value['value']} ${value['unit']}',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                          ),
                          dense: true,
                        )).toList(),
                        const Divider(),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Close'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
