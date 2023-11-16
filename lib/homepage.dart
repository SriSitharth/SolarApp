import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventory/addproduct.dart';
import 'package:inventory/result.dart';
import 'package:inventory/settings.dart';
import 'package:inventory/tabledata.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  String selectedOffice = "0";
  List<String> officeNameList = [];
  late TextEditingController EbController;
  Map<String, TextEditingController> unitControllers = {};
  Map<String, TextEditingController> loadControllers = {};
  String _uploadStatusText = "";
  Color _uploadStatusColor = Colors.black;

  Future<List<String>> fetchOfficeNames() async {
    CollectionReference office =
        FirebaseFirestore.instance.collection('office_list');
    QuerySnapshot snapshot = await office.get();
    List<DocumentSnapshot> documents = snapshot.docs;
    List<String> officeNames = [];
    for (var element in documents) {
      String officeName = element.get('OfficeName');
      officeNames.add(officeName);
      //Function Only for OfficeNameList and adding controller
      officeNameList.add(officeName);
    }
    return officeNames;
  }

  Future<void> _submitForm() async {
    if (selectedOffice != "0") {
      final String uniqueFileName =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      CollectionReference ebRef = FirebaseFirestore.instance
          .collection('office_list/$selectedOffice/EB_Readings');
      String ebInput = EbController.text;
      // Setting State for EB Input
      if (ebInput.isEmpty) {
        setState(() {
          _uploadStatusText = "EB Reading cannot be empty";
          _uploadStatusColor = Colors.red;
        });
        return;
      }
      // Unit & Load Upload
      CollectionReference invRef = FirebaseFirestore.instance
          .collection('office_list/$selectedOffice/inverter_list');
      QuerySnapshot invSnapshot = await invRef.get();
      List<DocumentSnapshot> documents = invSnapshot.docs;
      for (var element in documents) {
        String invDoc = element.id;
        String inverterName = element.get('InverterName');
        String unitInput = unitControllers[inverterName]!.text;
        String loadInput = loadControllers[inverterName]!.text;
        // Setting State for Unit & Load Input
        if (unitInput.isEmpty && loadInput.isEmpty) {
          setState(() {
            _uploadStatusText = "Unit & Load Reading cannot be empty";
            _uploadStatusColor = Colors.red;
          });
          return;
        }

        try {
          await invRef.doc(invDoc).collection('unit').doc(uniqueFileName).set({
            'UnitValue': int.parse(unitInput),
          });
          await invRef.doc(invDoc).collection('load').doc(uniqueFileName).set({
            'LoadValue': int.parse(loadInput),
          });
        } catch (e) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding Unit/Load Reading : $e'),
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }
        // EB Reading Upload
        try {
          await ebRef.doc(uniqueFileName).set({
            'EBValue': int.parse(ebInput),
          });
          setState(() {
            _uploadStatusText = "EB Reading added successfully";
            EbController.clear();
          });
        } catch (e) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding EB Reading : $e'),
              duration: const Duration(seconds: 5),
            ),
          );
          return;
        }
      }
    }
  }

  void _resetForm() {
    setState(() {
      selectedOffice = "0";
      _uploadStatusText = "";
    });
  }

  @override
  void initState() {
    super.initState();
    fetchOfficeNames();
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
      ),
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
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Tabledata()));
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
            children: <Widget>[
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
                    for (var office in offices!) {
                      officeItems.add(DropdownMenuItem(
                          value: office.id, child: Text(office['OfficeName'])));
                    }
                    return DropdownButton(
                      items: officeItems,
                      onChanged: (clientValue) {
                        setState(() {
                          selectedOffice = clientValue;
                        });
                      },
                      value: selectedOffice,
                      isExpanded: true,
                      padding: const EdgeInsets.all(16.0),
                    );
                  }
                },
              ),
              if (selectedOffice != "0")
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      buildOfficeRow(selectedOffice),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      buildInvertersList(selectedOffice),
                    ],
                  ),
                ),
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
          child: const Text(
            'Submit',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
            ),
          ),
          onPressed: () async {
            if (selectedOffice != "0") {
              _submitForm();
            } else {
              setState(() {
                _uploadStatusText = "Select a Office";
                _uploadStatusColor = Colors.red;
              });
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Reset',
        onPressed: () {
          _resetForm();
        },
        child: const Icon(Icons.rotate_left),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Widget buildOfficeRow(String selectedOffice) {
    EbController = TextEditingController();
    return Row(
      children: [
        Text(
          officeNameList[int.parse(selectedOffice) - 1],
          style: const TextStyle(fontSize: 16),
        ),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 26)),
        Expanded(
          child: TextFormField(
            controller: EbController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'EB Reading',
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
      ],
    );
  }

  Widget buildInvertersList(String selectedOffice) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('office_list')
          .doc(selectedOffice)
          .collection('inverter_list')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        } else {
          List inverterNames =
              snapshot.data!.docs.map((doc) => doc['InverterName']).toList();
          return ListView.builder(
            shrinkWrap: true,
            itemCount: inverterNames.length,
            itemBuilder: (context, inverterIndex) {
              String unitCont = inverterNames[inverterIndex];
              String loadCont = inverterNames[inverterIndex];
              unitControllers[unitCont] = TextEditingController();
              loadControllers[loadCont] = TextEditingController();
              return Row(
                children: [
                  Text(
                    inverterNames[inverterIndex],
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 35, vertical: 30),
                  ),

                  // Unit Textbox
                  Expanded(
                    child: TextFormField(
                      controller: unitControllers[unitCont],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Unit',
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 15, vertical: 45)),

                  // Load Textbox
                  Expanded(
                    child: TextFormField(
                      controller: loadControllers[loadCont],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Load',
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              );
            },
          );
        }
      },
    );
  }
}
