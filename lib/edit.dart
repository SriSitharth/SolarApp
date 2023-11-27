import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Edit extends StatefulWidget {
  const Edit({Key? key}) : super(key: key);

  @override
  State<Edit> createState() => _EditState();
}

class _EditState extends State<Edit> {
  String selectedOffice = "0";
  String selectedInverter = "0";
  List<String> officeNameList = [];
  List<String> inverterNameList = [];

  final TextEditingController _officeNameController = TextEditingController();
  final TextEditingController _inverterNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _officeNameController.dispose();
    _inverterNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // Office Dropdown
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('office_list')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                } else {
                  List<DropdownMenuItem> officeItems = [];
                  final offices = snapshot.data?.docs.toList();
                  officeItems.add(
                    const DropdownMenuItem(
                      value: "0",
                      child: Text('Select Office'),
                    ),
                  );
                  officeNameList.clear();
                  for (var office in offices!) {
                    officeNameList.add(office['OfficeName'] as String);
                    if (office['isOfficeDeleted'] == false) {
                      officeItems.add(DropdownMenuItem(
                          value: office.id, child: Text(office['OfficeName'])));
                    }
                  }
                  return DropdownButton(
                    items: officeItems,
                    onChanged: (clientValue) {
                      setState(() {
                        selectedOffice = clientValue;
                        _officeNameController.text = selectedOffice == "0"
                            ? ""
                            : officeNameList[int.parse(selectedOffice) - 1];
                      });
                    },
                    value: officeNameList.contains(_officeNameController.text)
                        ? selectedOffice
                        : "0",
                    isExpanded: true,
                    padding: const EdgeInsets.all(16.0),
                  );
                }
              },
            ),
            // Office Textbox
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _officeNameController,
                decoration: const InputDecoration(
                  hintText: 'Office Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            // Office Related Buttons
            Row(
              children: [
                const Spacer(),
                ElevatedButton(
                  onPressed: updateOfficeName,
                  child: const Text('Update Office'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Are you sure?'),
                        content: const Text(
                            'This action will permanently delete this data'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (result == null || !result) {
                      return;
                    }
                    deleteOffice();
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.red),
                  ),
                  child: const Text('Delete Office'),
                ),
                const Spacer(),
              ],
            ),
            // Inverter Dropdown
            StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('office_list/$selectedOffice/inverter_list')
                    .snapshots(),
                builder: (context, snapshot) {
                  List<DropdownMenuItem> inverterName = [];
                  if (!snapshot.hasData) {
                    const CircularProgressIndicator();
                  } else {
                    final inverters = snapshot.data?.docs.toList();
                    inverterName.add(
                      const DropdownMenuItem(
                        value: "0",
                        child: Text('Select Inverter'),
                      ),
                    );
                    inverterNameList.clear();
                    for (var inv in inverters!) {
                      inverterNameList.add(inv['InverterName'] as String);
                      if (inv['isInverterDeleted'] == false) {
                        inverterName.add(DropdownMenuItem(
                            value: inv.id, child: Text(inv['InverterName'])));
                      }
                    }
                  }
                  return DropdownButton(
                    items: inverterName,
                    onChanged: (clientValue) {
                      setState(() {
                        selectedInverter = clientValue;
                        _inverterNameController.text = selectedInverter == "0"
                            ? ""
                            : inverterNameList[int.parse(selectedInverter) - 1];
                      });
                    },
                    value:
                        inverterNameList.contains(_inverterNameController.text)
                            ? selectedInverter
                            : "0",
                    isExpanded: true,
                    padding: const EdgeInsets.all(16.0),
                  );
                }),
            // Inverter Textbox
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _inverterNameController,
                decoration: const InputDecoration(
                  hintText: 'Inverter Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            // Inverter Related Buttons
            Row(
              children: [
                const Spacer(),
                ElevatedButton(
                  onPressed: updateInverterName,
                  child: const Text('Update Inverter'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Are you sure?'),
                        content: const Text(
                            'This action will permanently delete this data'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (result == null || !result) {
                      return;
                    }
                    deleteInverter();
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.red),
                  ),
                  child: const Text('Delete Inverter'),
                ),
                const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> updateInverterName() async {
    String editedInverterData = _inverterNameController.text;
    if (editedInverterData.isNotEmpty && selectedOffice != "0") {
      try {
        CollectionReference inverterCollection =
            FirebaseFirestore.instance.collection('office_list');
        await inverterCollection
            .doc(selectedOffice)
            .collection('inverter_list')
            .doc(selectedInverter)
            .update({
          'InverterName': editedInverterData,
        });
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inverter name updated successfully!'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update inverter name!'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> deleteInverter() async {
    if (selectedOffice != "0" && selectedInverter != "0") {
      try {
        String tempSelectedInverter = selectedInverter;
        setState(() {
          _inverterNameController.clear();
          selectedInverter = "0";
        });
        CollectionReference inverterCollection =
            FirebaseFirestore.instance.collection('office_list');
        await inverterCollection
            .doc(selectedOffice)
            .collection('inverter_list')
            .doc(tempSelectedInverter)
            .update({
          'isInverterDeleted': true,
        });

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inverter deleted successfully!'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete inverter!'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> updateOfficeName() async {
    String editedData = _officeNameController.text;
    if (editedData.isNotEmpty && selectedOffice != "0") {
      try {
        CollectionReference officeCollection =
            FirebaseFirestore.instance.collection('office_list');
        await officeCollection.doc(selectedOffice).update({
          'OfficeName': editedData,
        });
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Office name updated successfully!'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update office name!'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> deleteOffice() async {
    if (selectedOffice != "0") {
      try {
        String tempSelectedOffice = selectedOffice;
        setState(() {
          _officeNameController.clear();
          selectedOffice = "0";
        });
        CollectionReference officeCollection =
            FirebaseFirestore.instance.collection('office_list');
        await officeCollection.doc(tempSelectedOffice).update({
          'isOfficeDeleted': true,
        });
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Office deleted successfully!'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete office!'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
