import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:inventory/addproduct.dart';
import 'package:inventory/result.dart';
import 'package:inventory/settings.dart';
import 'package:inventory/tabledata.dart';
import 'package:inventory/edit.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  String selectedOffice = "0";
  List<String> officeNameList = [];
  // ignore: non_constant_identifier_names
  late TextEditingController EbController;
  Map<String, TextEditingController> unitControllers = {};
  Map<String, TextEditingController> loadControllers = {};
  Map<String, TextEditingController> etodayControllers = {};

  Future<void> _submitForm() async {
    if (selectedOffice != "0") {
      final String uniqueFileName =
          (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      CollectionReference ebRef = FirebaseFirestore.instance
          .collection('office_list/$selectedOffice/EB_Readings');
      String ebInput = EbController.text;

      // Unit & Load Upload
      CollectionReference invRef = FirebaseFirestore.instance
          .collection('office_list/$selectedOffice/inverter_list');
      QuerySnapshot invSnapshot = await invRef.where('isInverterDeleted', isEqualTo: false).get();
      List<DocumentSnapshot> documents = invSnapshot.docs;

      for (var element in documents) {
        String invDoc = element.id;
        String inverterName = element.get('InverterName');
        String unitInput = unitControllers[inverterName]!.text;
        String loadInput = loadControllers[inverterName]!.text;
        String etodayInput = etodayControllers[inverterName]!.text;
        try {
          await invRef.doc(invDoc).collection('unit').doc(uniqueFileName).set({
            'UnitValue': double.parse(unitInput),
          });
          await invRef.doc(invDoc).collection('load').doc(uniqueFileName).set({
            'LoadValue': double.parse(loadInput),
          });
          await invRef
              .doc(invDoc)
              .collection('eToday')
              .doc(uniqueFileName)
              .set({
            'eTodayValue': double.parse(etodayInput),
          });
        } catch (e) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding Unit/Load/E-Today Reading : $e'),
              duration: const Duration(seconds: 5),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // EB Reading Upload
      try {
        await ebRef.doc(uniqueFileName).set({
          'EBValue': double.parse(ebInput),
        });
        setState(() {
          EbController.clear();
        });
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Readings Added Successfully'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.green,
          ),
        );
        return;
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding EB Reading : $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
  }

  void _resetForm() {
    setState(() {
      selectedOffice = "0";
    });
  }

  @override
  void initState() {
    super.initState();
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
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const Addproduct()));
              },
            ),
            const Divider(
              height: 0.3,
            ),
            ListTile(
              title: const Text('Edit'),
              leading: const Icon(FontAwesomeIcons.userPen),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const Edit()));
              },
            ),
            const Divider(
              height: 0.3,
            ),
            ListTile(
              title: const Text('Visualizer'),
              leading: const Icon(FontAwesomeIcons.squarePollVertical),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const Result()));
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
                    MaterialPageRoute(builder: (context) => const Tabledata()));
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
                    MaterialPageRoute(builder: (context) => const settings()));
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
                    officeNameList.clear();
                    for (var office in offices!) {
                      officeNameList.add(office['OfficeName'] as String);
                      if (office['isOfficeDeleted'] == false) {
                        officeItems.add(DropdownMenuItem(
                            value: office.id,
                            child: Text(office['OfficeName'])));
                      }
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
                        padding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      buildInvertersList(selectedOffice),
                    ],
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
            if (_formKey.currentState!.validate()) {
              _submitForm();
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'EB Reading',
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
              LengthLimitingTextInputFormatter(6)
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '* All Readings are required';
              }
              return null;
            },
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
          .where('isInverterDeleted', isEqualTo: false)
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
              String etodayCont = inverterNames[inverterIndex];
              unitControllers[unitCont] = TextEditingController();
              loadControllers[loadCont] = TextEditingController();
              etodayControllers[etodayCont] = TextEditingController();
              return Row(
                children: [
                  Text(
                    inverterNames[inverterIndex],
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 30),
                  ),

                  // Load Textbox
                  Expanded(
                    child: TextFormField(
                      controller: loadControllers[loadCont],
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Load',
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                        LengthLimitingTextInputFormatter(6)
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '* Required Field';
                        }
                        return null;
                      },
                    ),
                  ),

                  const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 5, vertical: 45)),

                  // E-Today Textbox
                  Expanded(
                    child: TextFormField(
                      controller: etodayControllers[etodayCont],
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'E-Today',
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                        LengthLimitingTextInputFormatter(6)
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '* Required Field';
                        }
                        return null;
                      },
                    ),
                  ),

                  const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 5, vertical: 45)),

                  // Unit Textbox
                  Expanded(
                    child: TextFormField(
                      controller: unitControllers[unitCont],
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Unit',
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                        LengthLimitingTextInputFormatter(6)
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '* Required Field';
                        }
                        return null;
                      },
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
