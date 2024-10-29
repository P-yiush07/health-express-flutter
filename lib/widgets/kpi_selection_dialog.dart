import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class KPISelectionDialog extends StatefulWidget {
  final String pdfContent;
  final Function(List<Map<String, dynamic>>) onKPIsSelected;

  const KPISelectionDialog({
    Key? key,
    required this.pdfContent,
    required this.onKPIsSelected,
  }) : super(key: key);

  @override
  _KPISelectionDialogState createState() => _KPISelectionDialogState();
}

class _KPISelectionDialogState extends State<KPISelectionDialog> {
  List<Map<String, dynamic>> kpis = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _extractKPIs();
  }

  Future<void> _extractKPIs() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final extractedKPIs = await AIService.generateMedicalTerms(widget.pdfContent);
      setState(() {
        kpis = extractedKPIs.map((kpi) => {...kpi, 'selected': false}).toList();
        if (kpis.isEmpty) {
          errorMessage = "No KPIs found in the document. Try manual entry.";
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error extracting KPIs: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select KPIs to add to Dashboard',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            if (isLoading)
              CircularProgressIndicator()
            else if (errorMessage.isNotEmpty)
              Text(errorMessage, style: TextStyle(color: Colors.red))
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: kpis.length,
                  itemBuilder: (context, index) {
                    return CheckboxListTile(
                      title: Text(kpis[index]['title']),
                      subtitle: Text('${kpis[index]['value']} ${kpis[index]['unit']}'),
                      value: kpis[index]['selected'],
                      onChanged: (bool? value) {
                        setState(() {
                          kpis[index]['selected'] = value;
                        });
                      },
                    );
                  },
                ),
              ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final selectedKPIs = kpis.where((kpi) => kpi['selected']).toList();
                    widget.onKPIsSelected(selectedKPIs);
                    Navigator.of(context).pop();
                  },
                  child: Text('Add to Dashboard'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
