import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventory/addproduct.dart';
import 'package:inventory/result.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventory/settings.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:inventory/tabledata.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _textField1Controller = TextEditingController();
  final TextEditingController _textField2Controller = TextEditingController();
  final TextEditingController _textField3Controller = TextEditingController();
  final TextEditingController _textField4Controller = TextEditingController();
  String selectedOffice = "0";
  String selectedInverter = "0";
  bool inputWattError = false;
  bool inputUnitError = false;
  bool inputLoadError = false;
  bool inputEbError = false;
  bool inputWattSuccess = false;
  bool inputUnitSuccess = false;
  bool inputLoadSuccess = false;
  bool inputEbSuccess =false;
  File? _selectedImage;
  bool uploadImageSuccess = false;
  String _uploadStatusText = "";
  Color _uploadStatusColor = Colors.black;

  void _submitForm() async {
    if (selectedOffice == "0" || selectedInverter == "0") {
      setState(() {
        _textField1Controller.clear();
        _textField2Controller.clear();
        _textField3Controller.clear();
        _textField4Controller.clear();
        _uploadStatusText = "Office & Inverter need to selected";
        _uploadStatusColor = Colors.red;
      });
      return;
    }
    
    // if (selectedOffice != "0" || selectedInverter == "0") {
    //   setState(() {
    //     _textField2Controller.clear();
    //     _textField3Controller.clear();
    //     _textField4Controller.clear();
    //     _uploadStatusText = "Inverter need to selected";
    //     _uploadStatusColor = Colors.red;
    //   });
    //   return;
    // }

    // Unit Value
    String inputEb = _textField1Controller.text;
    String inputWatt = _textField2Controller.text;
    String inputUnit = _textField3Controller.text;
    String inputLoad = _textField4Controller.text;

    if (inputEb.isEmpty) {
      setState(() {
        inputEbError = true;
        inputEbSuccess = false;
      });
      return;
    }
    setState(() {
      inputEbError = false;
      inputEbSuccess = false;
    });
    if (inputWatt.isEmpty) {
      setState(() {
        inputWattError = true;
        inputWattSuccess = false;
      });
      return;
    }
    setState(() {
      inputWattError = false;
      inputWattSuccess = false;
    });
    if (inputUnit.isEmpty) {
      setState(() {
        inputUnitError = true;
        inputUnitSuccess = false;
      });
      return;
    }
    setState(() {
      inputUnitError = false;
      inputUnitSuccess = false;
    });
    if (inputLoad.isEmpty) {
      setState(() {
        inputLoadError = true;
        inputLoadSuccess = false;
      });
      return;
    }
    setState(() {
      inputLoadError = false;
      inputLoadSuccess = false;
    });

    final String uniqueFileName = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    int inputEBValue = int.parse(inputEb);
    int inputWattValue = int.parse(inputWatt);
    int inputUnitValue = int.parse(inputUnit);
    int inputLoadValue = int.parse(inputLoad);

    // EB Value Upload
    CollectionReference ebRef = FirebaseFirestore.instance.collection(
        'office_list/$selectedOffice/eb_list');
    try {
      await ebRef.doc(uniqueFileName).set({
        'EBValue': inputEBValue,
      });
      setState(() {
        inputEbSuccess = true;
        _textField1Controller.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding EB Reading : $e'),
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // Watt Value Upload
    CollectionReference wattRef = FirebaseFirestore.instance.collection(
        'office_list/$selectedOffice/inverter_list/$selectedInverter/watt');
    try {
      await wattRef.doc(uniqueFileName).set({
        'WattValue': inputWattValue,
      });
      setState(() {
        inputWattSuccess = true;
        _textField2Controller.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding Watt : $e'),
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // Unit Value Upload
    CollectionReference unitRef = FirebaseFirestore.instance.collection(
        'office_list/$selectedOffice/inverter_list/$selectedInverter/unit');
    try {
      await unitRef.doc(uniqueFileName).set({
        'UnitValue': inputUnitValue,
      });
      setState(() {
        inputUnitSuccess = true;
        _textField3Controller.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding unit : $e'),
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // Load Value Upload
    CollectionReference loadRef = FirebaseFirestore.instance.collection(
        'office_list/$selectedOffice/inverter_list/$selectedInverter/load');
    try {
      await loadRef.doc(uniqueFileName).set({
        'LoadValue': inputLoadValue,
      });
      setState(() {
        inputLoadSuccess = true;
        _textField4Controller.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error adding unit : $e'),
        duration: const Duration(seconds: 5),
      ));
    }
  }

  void _resetForm() {
    _textField1Controller.clear();
    _textField2Controller.clear();
    _textField3Controller.clear();
    _textField4Controller.clear();
    setState(() {
      selectedOffice = "0";
      selectedInverter = "0";
      inputEbError = false;
      inputEbSuccess = false;
      inputWattError =false;
      inputWattSuccess = false;
      inputUnitError = false;
      inputUnitSuccess = false;
      inputLoadError = false;
      inputLoadSuccess = false;
      _selectedImage = null;
      _uploadStatusText = "";
      _uploadStatusColor = Colors.black;
    });
  }

  Future<void> _uploadImage() async {
    if (selectedOffice == "0" || selectedInverter == "0") {
      setState(() {
        inputLoadError = true;
        inputUnitError = true;
        _textField3Controller.clear();
        _textField4Controller.clear();
        _selectedImage = null;
        _uploadStatusText = "Office & Inverter need to selected";
        _uploadStatusColor = Colors.red;
      });
      return;
    }
    if (_selectedImage == null) {
      setState(() {
        _uploadStatusText = "Image not found. Please capture image";
        _uploadStatusColor = Colors.red;
      });
      return;
    }

    final String uniqueFileName =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final Reference storageReference = FirebaseStorage.instance
        .ref()
        .child('Images')
        .child('$uniqueFileName.jpg');
    final UploadTask uploadTask = storageReference.putFile(_selectedImage!);

    try {
      await uploadTask.whenComplete(() async {
        // Image upload is complete
        final String imageUrl = await storageReference.getDownloadURL();
        await FirebaseFirestore.instance
            .collection(
                'office_list/$selectedOffice/inverter_list/$selectedInverter/image')
            .doc(uniqueFileName)
            .set({
          'ImageUrl': imageUrl,
        });
        setState(() {
          _uploadStatusText = "Image uploaded successfully!";
          _uploadStatusColor = Colors.green;
          uploadImageSuccess = true;
          _selectedImage = null;
        });
      });
    } catch (e) {
      setState(() {
        _uploadStatusText = "Image upload failed. Please try again.";
        _uploadStatusColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Electricity Reading'),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(FontAwesomeIcons.bars),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        // actions: [
        //   IconButton(
        //     onPressed: () {
        //       _ImageFromCamera();
        //     },
        //     icon: const Icon(Icons.camera_alt),
        //   ),
        // ],
      ),

      //Used for Drawer
      drawer: Drawer(
        backgroundColor: Colors.orange,
        child: ListView(
          children: <Widget>[
            const DrawerHeader(
              child: Text("QosteQ"),
            ),
            ListTile(
              title: const Text('Home'),
              leading: const Icon(FontAwesomeIcons.houseUser),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(
              height: 0.3,
            ),
            ListTile(
              title: const Text('Add'),
              leading: const Icon(FontAwesomeIcons.userPlus),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Addproduct()));
              },
            ),
            const Divider(
              height: 0.3,
            ),
            ListTile(
              title: const Text('Visualizer'),
              leading: const Icon(FontAwesomeIcons.squarePollVertical),
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => Result()));
              },
            ),
             const Divider(
              height: 0.3,
            ),
            ListTile(
              title: const Text('Data Table'),
              leading: const Icon(FontAwesomeIcons.table),
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => Tabledata()));
              },
            ),
            const Divider(
              height: 0.3,
            ),
            ListTile(
              title: const Text('Settings'),
              leading: const Icon(FontAwesomeIcons.gear),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => settings()));
              },
            ),
            const Divider(
              height: 0.3,
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[

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
                    return DropdownButtonFormField(
                      items: officeName,
                      onChanged: (clientValue) {
                        setState(() {
                          selectedOffice = clientValue;
                        });
                      },
                      value: selectedOffice,
                      validator: (value) =>
                          value == "0" ? 'field required' : null,
                      isExpanded: true,
                      padding: const EdgeInsets.all(16.0),
                    );
                  }),

                  const SizedBox(width: 16.0),

              // Type EB Reading Value
              Expanded(
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  controller: _textField1Controller,
                  decoration: InputDecoration(
                    labelText: 'EB Reading',
                    errorText:
                    inputWattError ? 'EB Reading cannot be empty' : null,
                    helperText:
                    inputWattSuccess ? 'EB Reading added successfully' : null,
                   ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
        
              // Select Inverter Type
              // StreamBuilder<QuerySnapshot>(
              //     stream: FirebaseFirestore.instance
              //         .collection('office_list/$selectedOffice/inverter_list')
              //         .snapshots(),
              //     builder: (context, snapshot) {
              //       List<DropdownMenuItem> inverterName = [];
              //       if (!snapshot.hasData) {
              //         const CircularProgressIndicator();
              //       } else {
              //         final company = snapshot.data?.docs.toList();
              //         inverterName.add(
              //           const DropdownMenuItem(
              //             value: "0",
              //             child: Text('Select Inverter'),
              //           ),
              //         );
              //         for (var companyName in company!) {
              //           inverterName.add(DropdownMenuItem(
              //               value: companyName.id,
              //               child: Text(companyName['InverterName'])));
              //         }
              //       }
              //       return DropdownButtonFormField(
              //         items: inverterName,
              //         onChanged: (clientValue) {
              //           setState(() {
              //             selectedInverter = clientValue;
              //           });
              //         },
              //         value: selectedInverter,
              //         validator: (value) =>
              //             value == "0" ? 'field required' : null,
              //         isExpanded: true,
              //         padding: const EdgeInsets.all(16.0),
              //       );
              //     }),

              // Type Watt Value
              Expanded(
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  controller: _textField2Controller,
                  decoration: InputDecoration(
                    labelText: 'Watt',
                    errorText:
                        inputWattError ? 'Watt value cannot be empty' : null,
                    helperText:
                        inputWattSuccess ? 'Watt added successfully' : null,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),

              // Type Unit Value
              Expanded(
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  controller: _textField3Controller,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    errorText:
                        inputUnitError ? 'Unit value cannot be empty' : null,
                    helperText:
                        inputUnitSuccess ? 'Unit added successfully' : null,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),

              //Type Load Value
              Expanded(
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  controller: _textField4Controller,
                  decoration: InputDecoration(
                    labelText: 'Load',
                    errorText:
                        inputLoadError ? 'Type value cannot be empty' : null,
                    helperText:
                        inputLoadSuccess ? 'Load added successfully' : null,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),

              // //Image Viewer
              // SizedBox(
              //   width: 150.0,
              //   height: 150.0,
              //   child:
              //       _selectedImage != null ? Image.file(_selectedImage!) : null,
              // ),

              // Text Alert
              Text(
                _uploadStatusText,
                style: TextStyle(
                  color: _uploadStatusColor,
                  fontSize: 16.0,
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomAppBar(
          color: Colors.orange,
          shape: const CircularNotchedRectangle(),
          child: MaterialButton(
              child: const Text('Submit',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  )),
              onPressed: () async {
                // if (_selectedImage != null) {
                //   _submitForm();
                //   _uploadImage();
                // } else {
                //   setState(() {
                //     _uploadStatusText = "Take a Picture";
                //     _uploadStatusColor = Colors.red;
                //   });
                // }
                _submitForm();
              })),

      floatingActionButton: FloatingActionButton(
          tooltip: 'Reset',
          onPressed: () {
            _resetForm();
          },
          child: const Icon(Icons.rotate_left)),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Future _ImageFromCamera() async {
    final returnedImage =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (returnedImage == null) return;
    setState(() {
      _selectedImage = File(returnedImage.path);
      _uploadStatusText = "Image Captured";
      _uploadStatusColor = Colors.black;
    });
  }

  @override
  void dispose() {
    _textField3Controller.dispose();
    _textField4Controller.dispose();
    super.dispose();
  }
}
