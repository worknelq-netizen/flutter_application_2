import 'package:flutter/material.dart';

class TwoLineSelector extends StatefulWidget {
  final TextEditingController timeController;
  const TwoLineSelector({super.key, required this.timeController});

  @override
  State<TwoLineSelector> createState() => _TwoLineSelectorState();
}

class _TwoLineSelectorState extends State<TwoLineSelector> {
  String? selected;
  
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      RadioListTile(title: const Text('9:00'), value: '9:00', groupValue: selected, onChanged: (v) {
        setState(() => selected = widget.timeController.text = v!);
        Navigator.pop(context);
      }),
      RadioListTile(title: const Text('14:00'), value: '14:00', groupValue: selected, onChanged: (v) {
        setState(() => selected = widget.timeController.text = v!);
        Navigator.pop(context);
      }),
    ]);
  }
}