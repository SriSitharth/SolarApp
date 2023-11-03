import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Tabledata extends StatefulWidget {
  const Tabledata({Key? key}) : super(key: key);

  @override
  State<Tabledata> createState() => _TabledataState();
}

class _TabledataState extends State<Tabledata> {
  DateTime fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime toDate = DateTime.now();
  List<String> officeList = [];
  Map<String, List<String>> invertersByOffice = {};
  List<Map<String, dynamic>> loadList = [];
  List<Map<String, dynamic>> unitList = [];
  String selectedOffice = "0";
  String selectedInverter = "0";

  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fromDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != fromDate) {
      setState(() {
        fromDate = picked;
      });
      fetchFirestoreData(selectedOffice, selectedInverter);
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: toDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != toDate) {
      setState(() {
        toDate = picked;
      });
      fetchFirestoreData(selectedOffice, selectedInverter);
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('dd-MM-yyyy').format(date);
  }

  String formatDateTime(DateTime dateTime) {
  return DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
}


  Future<void> fetchData() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('office_list').get();
    officeList.clear();
    invertersByOffice.clear();
    snapshot.docs.forEach((office) {
      officeList.add(office['OfficeName'] as String);
    });
    for (var i = 0; i < officeList.length; i++) {
      int docid = i + 1;
      final QuerySnapshot<Map<String, dynamic>> invertersnapshot =
          await FirebaseFirestore.instance
              .collection('office_list/$docid/inverter_list')
              .get();
      final inverterList = invertersnapshot.docs
          .map((inverter) => inverter['InverterName'] as String)
          .toList();
      invertersByOffice[officeList[i]] = inverterList;
    }
    setState(() {});
  }

  Future<void> fetchFirestoreData(String officeId, String inverterId) async {
    try {
      final List<Map<String, dynamic>> loaddata =
          await searchForLoadValues(fromDate, toDate, officeId, inverterId);
      final List<Map<String, dynamic>> unitdata =
          await searchForUnitValues(fromDate, toDate, officeId, inverterId);
      setState(() {
        loadList = loaddata;
        unitList = unitdata;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error fetching data : $e'),
        duration: const Duration(seconds: 5),
      ));
    }
  }

  @override
  void initState() {
    fetchData();
    super.initState();
    fetchFirestoreData(selectedOffice, selectedInverter);
  }

  @override
  Widget build(BuildContext context) {
    double loadAvg = 0.0;
    double unitAvg = 0.0;
    int loadCount = 0;
    int unitCount = 0;
    return Scaffold(
      appBar: AppBar(title: const Text("Data Table")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Date selection row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                const Text(
                  '  From :',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  formatDate(fromDate),
                  style: const TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.calendar_today,
                    size: 24,
                  ),
                  onPressed: () => _selectFromDate(context),
                ),
                const Text(
                  'To :',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  formatDate(toDate),
                  style: const TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.calendar_today,
                    size: 24,
                  ),
                  onPressed: () => _selectToDate(context),
                ),
              ],
            ),
            const Divider(
              height: 0.3,
            ),

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
                        fetchFirestoreData(selectedOffice, selectedInverter);
                      });
                    },
                    value: selectedOffice,
                    validator: (value) =>
                        value == "0" ? 'field required' : null,
                    isExpanded: true,
                    padding: const EdgeInsets.all(14.0),
                  );
                }),

            // Select Inverter Type
            StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('office_list/$selectedOffice/inverter_list')
                    .snapshots(),
                builder: (context, snapshot) {
                  List<DropdownMenuItem> inverterName = [];
                  if (!snapshot.hasData) {
                    const CircularProgressIndicator();
                  } else {
                    final company = snapshot.data?.docs.toList();
                    inverterName.add(
                      const DropdownMenuItem(
                        value: "0",
                        child: Text('Select Inverter'),
                      ),
                    );
                    for (var companyName in company!) {
                      inverterName.add(DropdownMenuItem(
                          value: companyName.id,
                          child: Text(companyName['InverterName'])));
                    }
                  }
                  return DropdownButtonFormField(
                    items: inverterName,
                    onChanged: (clientValue) {
                      setState(() {
                        selectedInverter = clientValue;
                        fetchFirestoreData(selectedOffice, selectedInverter);
                      });
                    },
                    value: selectedInverter,
                    validator: (value) =>
                        value == "0" ? 'field required' : null,
                    isExpanded: true,
                    padding: const EdgeInsets.all(14.0),
                  );
                }),

            const Divider(
              height: 0.3,
            ),

            Center(
              child: Container(
                padding: const EdgeInsets.only(top: 20.0),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Inverter')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Load')),
                    
                  ],
                  
                  rows: loadList.map(
                    (load) {
                      loadAvg = loadAvg + load['value'];
                      loadCount = loadCount + 1;
                      return DataRow(
                        cells: [
                          DataCell(Text(load['inv'].toString())),
                          DataCell(
                              Text(formatDateTime(load['timestamp']).toString())),
                          DataCell(Text(load['value'].toString())),
                        ],
                      );
                    },
                  ).toList(),
                ),
              ),
            ),
            const Divider(
              height: 0.3,
            ),
            Text('Average Load : ${loadCount > 0 ? (loadAvg / loadCount).toStringAsFixed(2) : "N/A"}',
                style: const TextStyle(fontSize: 16)),

            const Divider(
              height: 0.3,
            ),

            Center(
              child: Container(
                padding: const EdgeInsets.only(top: 20.0),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Inverter')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Unit')),
                  ],
                  rows: unitList.map(
                    (unit) {
                      unitAvg = unitAvg + unit['value'];
                      unitCount = unitCount + 1;
                      return DataRow(
                        cells: [
                          DataCell(Text(unit['inv'].toString())),
                          DataCell(
                              Text(formatDateTime(unit['timestamp']).toString())),
                          DataCell(Text(unit['value'].toString())),
                        ],
                      );
                    },
                  ).toList(),
                ),
              ),
            ),
            const Divider(
              height: 0.3,
            ),
            Text('Average Unit : ${unitCount > 0 ? (unitAvg / unitCount).toStringAsFixed(2) : "N/A"}',
                style: const TextStyle(fontSize: 16)),
            const Divider(
              height: 0.3,
            ),
          ],
        ),
      ),
    );
  }
}

Future<List<Map<String, dynamic>>> searchForLoadValues(DateTime fromDate,
    DateTime toDate, String officeId, String inverterId) async {
  final List<Map<String, dynamic>> loadValues = [];
  final List<String> inverterList = [];

  if (officeId != "0") {
    if (inverterId != "0") {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('office_list/$officeId/inverter_list/$inverterId/load')
          .get();

      final QuerySnapshot<Map<String, dynamic>> invertersnapshot =
          await FirebaseFirestore.instance
              .collection('office_list/$officeId/inverter_list')
              .get();
      inverterList.addAll(invertersnapshot.docs
          .map((inverter) => inverter['InverterName'] as String));

      querySnapshot.docs.forEach((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('LoadValue')) {
          final loadtimestamp = int.parse(doc.id);
          final timestamp =
              DateTime.fromMillisecondsSinceEpoch(loadtimestamp * 1000);
          if (timestamp.isAfter(fromDate) && timestamp.isBefore(toDate)) {
            final loadValue = data['LoadValue'] as num;
            int reqId = int.parse(inverterId);
            final invName = inverterList[reqId - 1];
            loadValues.add(
                {'value': loadValue, 'timestamp': timestamp, 'inv': invName});
          }
        }
      });
    } else {
      final QuerySnapshot<Map<String, dynamic>> invertersnapshot =
          await FirebaseFirestore.instance
              .collection('office_list/$officeId/inverter_list')
              .get();
      inverterList.addAll(invertersnapshot.docs
          .map((inverter) => inverter['InverterName'] as String));

      int inverterCount = invertersnapshot.docs.length;

      for (int i = 1; i <= inverterCount; i++) {
        final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('office_list/$officeId/inverter_list/$i/load')
            .get();
        querySnapshot.docs.forEach((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('LoadValue')) {
            final loadtimestamp = int.parse(doc.id);
            final timestamp =
                DateTime.fromMillisecondsSinceEpoch(loadtimestamp * 1000);
            if (timestamp.isAfter(fromDate) && timestamp.isBefore(toDate)) {
              final loadValue = data['LoadValue'] as num;
              final invName = inverterList[i - 1];
              loadValues.add(
                  {'value': loadValue, 'timestamp': timestamp, 'inv': invName});
            }
          }
        });
      }
    }
  }

  return loadValues;
}

Future<List<Map<String, dynamic>>> searchForUnitValues(DateTime fromDate,
    DateTime toDate, String officeId, String inverterId) async {
  final List<Map<String, dynamic>> unitValues = [];
  final List<String> inverterList = [];

  if (officeId != "0") {
    if (inverterId != "0") {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('office_list/$officeId/inverter_list/$inverterId/unit')
          .get();
      final QuerySnapshot<Map<String, dynamic>> invertersnapshot =
          await FirebaseFirestore.instance
              .collection('office_list/$officeId/inverter_list')
              .get();
      inverterList.addAll(invertersnapshot.docs
          .map((inverter) => inverter['InverterName'] as String));

      querySnapshot.docs.forEach((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('UnitValue')) {
          final loadtimestamp = int.parse(doc.id);
          final timestamp =
              DateTime.fromMillisecondsSinceEpoch(loadtimestamp * 1000);
          if (timestamp.isAfter(fromDate) && timestamp.isBefore(toDate)) {
            final unitValue = data['UnitValue'] as num;
            int reqId = int.parse(inverterId);
            final invName = inverterList[reqId - 1];
            unitValues.add(
                {'value': unitValue, 'timestamp': timestamp, 'inv': invName});
          }
        }
      });
    } else {
      final QuerySnapshot<Map<String, dynamic>> invertersnapshot =
          await FirebaseFirestore.instance
              .collection('office_list/$officeId/inverter_list')
              .get();
      inverterList.addAll(invertersnapshot.docs
          .map((inverter) => inverter['InverterName'] as String));

      int inverterCount = invertersnapshot.docs.length;
      for (int i = 1; i <= inverterCount; i++) {
        final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('office_list/$officeId/inverter_list/$i/unit')
            .get();
        querySnapshot.docs.forEach((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data.containsKey('UnitValue')) {
            final loadtimestamp = int.parse(doc.id);
            final timestamp =
                DateTime.fromMillisecondsSinceEpoch(loadtimestamp * 1000);
            if (timestamp.isAfter(fromDate) && timestamp.isBefore(toDate)) {
              final unitValue = data['UnitValue'] as num;
              final invName = inverterList[i - 1];
              unitValues.add(
                  {'value': unitValue, 'timestamp': timestamp, 'inv': invName});
            }
          }
        });
      }
    }
  }
  return unitValues;
}
