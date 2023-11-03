import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Addproduct extends StatefulWidget {
  const Addproduct({super.key});
  @override
  State<Addproduct> createState() => _AddproductState();
}

class _AddproductState extends State<Addproduct> {
  final TextEditingController _textField1 = TextEditingController();
  final TextEditingController _textField2 = TextEditingController();
  String selectedOffice = "0";
  bool showOfficeNameError = false;
  bool showOfficeNameSuccess = false;
  bool showOfficeNameDuplicate = false;
  bool showOfficeNameFailure = false;
  bool showInverterNameError = false;
  bool showInverterNameSuccess = false;
  bool showInverterNameDuplicate = false;
  bool showInverterNameFailure = false;

  // Function to Add Office
  void _addOffice() async {
    String inputOfficeName = _textField1.text.trim();
    if (inputOfficeName.isEmpty) {
      setState(() {
        showOfficeNameError = true;
        showOfficeNameSuccess = false;
        showOfficeNameDuplicate = false;
        showOfficeNameFailure = false;
      });
      return;
    }
    // Reset the error state
    setState(() {
      showOfficeNameError = false;
      showOfficeNameSuccess = false;
      showOfficeNameDuplicate = false;
      showOfficeNameFailure = false;
    });
    CollectionReference collRef =
        FirebaseFirestore.instance.collection('office_list');
    try {
      // Check if the office name already exists
      QuerySnapshot querySnapshot =
          await collRef.where('OfficeName', isEqualTo: inputOfficeName).get();
      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
        showOfficeNameDuplicate = true;
      });
       return;
      }
      QuerySnapshot docCountSnapshot = await collRef.get();
      int docCount = docCountSnapshot.docs.length;
      await collRef.doc((docCount + 1).toString()).set({
        'OfficeName': inputOfficeName,
      });
      // show the success message
      setState(() {
        showOfficeNameSuccess = true;
        _textField1.clear();
      });
    } catch (e) {
      setState(() {
        showOfficeNameFailure = true;
        _textField1.clear();
      });
    }
  }

  // Function to Add Inverter
  void _addInverter() async {
    // Not selected the office
    if(selectedOffice == "0"){
      setState(() {
        showInverterNameFailure = true;
        _textField2.clear();
      });
      return;
    }
    String inputInverterName = _textField2.text.trim();
     if (inputInverterName.isEmpty) {
      setState(() {
        showInverterNameError = true;
        showInverterNameSuccess = false;
        showInverterNameDuplicate = false;
        showInverterNameFailure = false;
      });
      return;
    }
    
    // Reset the error state
    setState(() {
      showInverterNameError = false;
      showInverterNameSuccess = false;
      showInverterNameDuplicate = false;
      showInverterNameFailure = false;
    });
    CollectionReference invRef = FirebaseFirestore.instance
        .collection('office_list/$selectedOffice/inverter_list');
    try {
      // Check if the inverter name already exists
      QuerySnapshot querySnapshot =
          await invRef.where('InverterName', isEqualTo: inputInverterName).get();
      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
        showInverterNameDuplicate = true;
      });
       return;
      }
      QuerySnapshot invCountSnapshot = await invRef.get();
      int invCount = invCountSnapshot.docs.length;
      await invRef.doc((invCount + 1).toString()).set({
        'InverterName': inputInverterName,
      });
       // show the success message
      setState(() {
        showInverterNameSuccess = true;
        _textField2.clear();
      });
    } catch (e) {
       setState(() {
        showInverterNameFailure = true;
        _textField2.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Add Inventory")),
        body: SingleChildScrollView(
          child: Column(children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _textField1,
                decoration: InputDecoration(
                  labelText: 'Office Name',
                  errorText: showOfficeNameError ? 'Office name cannot be empty' : showOfficeNameFailure ? 'Error Adding Office Name' : null,
                  helperText: showOfficeNameSuccess ? 'Office added successfully' : showOfficeNameDuplicate ? 'Office name already exists' : null,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: _addOffice,
              child: const Text('Add Office Name'),
            ),

            // Select Office Name
            StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('office_list')
                    .snapshots(),
                builder: (context, snapshot) {
                  List<DropdownMenuItem> officeName = [];
                  if (!snapshot.hasData) {
                    const CircularProgressIndicator();
                  } else {
                    final company = snapshot.data?.docs.toList();
                    officeName.add(
                      const DropdownMenuItem(
                        value: "0",
                        child: Text('Select Office'),
                      ),
                    );
                    for (var companyName in company!) {
                      officeName.add(DropdownMenuItem(
                          value: companyName.id,
                          child: Text(companyName['OfficeName'])));
                    }
                  }
                  return DropdownButton(
                    items: officeName,
                    onChanged: (clientValue) {
                      setState(() {
                        selectedOffice = clientValue;
                      });
                    },
                    value: selectedOffice,
                    isExpanded: true,
                    padding: const EdgeInsets.all(16.0),
                  );
                }),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _textField2,
                decoration: InputDecoration(labelText: 'Inverter Name',
                errorText: showInverterNameError ? 'Inverter name cannot be empty' : showInverterNameFailure ? 'Error Adding Inverter Name' : null,
                helperText: showInverterNameSuccess ? 'Inverter added successfully' : showInverterNameDuplicate ? 'Inverter name already exists' : null,
                  ),
              ),
            ),

            ElevatedButton(
              onPressed: _addInverter,
              child: const Text('Add Inverter Name'),
            ),
          ]),
        ));
  }

  @override
  void dispose() {
    _textField1.dispose();
    _textField2.dispose();
    super.dispose();
  }
}
