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
  List<Map<String, dynamic>> ebReadingsList = [];
  List<Map<String, dynamic>> combinedValues = [];
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

  String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  String formatDateTime(DateTime dateTime) {
  return DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
}


  Future<void> fetchData() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('office_list').get();
    officeList.clear();
    invertersByOffice.clear();
    for (var office in snapshot.docs) {
      officeList.add(office['OfficeName'] as String);
    }
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
      final List<Map<String, dynamic>> ebReadingsData =
          await searchForEBReadings(officeId, fromDate, toDate);
      final List<Map<String, dynamic>> combinedData =
          await searchForCombinedValues(fromDate, toDate, officeId, inverterId);
      setState(() {
        loadList = loaddata;
        unitList = unitdata;
        ebReadingsList = ebReadingsData;
        combinedValues = combinedData;
      });
    } catch (e) {
      // ignore: use_build_context_synchronously
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
    double ebAvg = 0.0;
    double diffAvg = 0.0;
    double solarAvg = 0.0;
    int loadCount = 0;
    int unitCount = 0;
    int ebCount = 0;
    int diffCount = 0;
    int solarCount = 0;

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
                padding: const EdgeInsets.only(top: 5.0),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Date & Time')),
                    DataColumn(label: Text('EB Reading')),
                  ],
                  rows: ebReadingsList.map(
                    (ebReading) {
                      ebAvg = ebAvg + ebReading['value'];
                      ebCount = ebCount + 1;
                      return DataRow(
                        cells: [
                          DataCell(
                              Text(formatDateTime(ebReading['timestamp']).toString())),
                          DataCell(Text(ebReading['value'].toString())),
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
            const SizedBox(height: 20),
            Text('Average EB : ${ebCount > 0 ? (ebAvg / ebCount).toStringAsFixed(2) : "N/A"}   |   Total EB : ${ebCount > 0 ? ebAvg.toStringAsFixed(2) : "N/A"}',
            ),
            const SizedBox(height: 20),
            const Divider(
              height: 0.3,
            ),

            Center(
              child: Container(
                padding: const EdgeInsets.only(top: 5.0),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('From')),
                    DataColumn(label: Text('To')),
                    DataColumn(label: Text('Solar')),
                  ],
                  rows: calculateEBDifferences(ebReadingsList).map(
                    (difference) {
                      solarAvg = solarAvg + difference['difference'];
                      solarCount = solarCount + 1;
                      return DataRow(
                        cells: [
                          DataCell(Text(formatDateTime(difference['currenttimestamp']).toString())),
                          DataCell(Text(formatTime(difference['nexttimestamp']).toString())),
                          DataCell(Text(difference['difference'].toString())),
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
            const SizedBox(height: 20),
            Text('Solar Average : ${solarCount > 0 ? (solarAvg / solarCount).toStringAsFixed(2) : "N/A"}   |   Solar Total : ${solarCount > 0 ? solarAvg.toStringAsFixed(2) : "N/A"}',
            ),
            const SizedBox(height: 20),
            const Divider(
              height: 0.3,
            ),

             Center(
              child: Container(
                padding: const EdgeInsets.only(top: 5.0),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('From Date')),
                    DataColumn(label: Text('To Date')),
                    DataColumn(label: Text('EB')),
                  ],
                  rows: calculateDayDifferences(ebReadingsList).map(
                    (daydifference) {
                      diffAvg = diffAvg + daydifference['difference'];
                      diffCount = diffCount + 1;
                      return DataRow(
                        cells: [
                          DataCell(Text(formatDate(daydifference['currenttimestamp']).toString())),
                          DataCell(Text(formatDate(daydifference['nexttimestamp']).toString())),
                          DataCell(Text(daydifference['difference'].toString())),
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
            const SizedBox(height: 20),
            Text('EB Average : ${diffCount > 0 ? (diffAvg / diffCount).toStringAsFixed(2) : "N/A"}   |   EB Total : ${diffCount > 0 ? diffAvg.toStringAsFixed(2) : "N/A"}',
            ),
            const SizedBox(height: 20),
            const Divider(
              height: 0.3,
            ),

            Center(
              child: Container(
                padding: const EdgeInsets.only(top: 5.0),
                child: DataTable(
                  columnSpacing: 25,
                  columns: const [
                    DataColumn(label: Text('Inverter')),
                    DataColumn(label: Text('Date/Time')),
                    DataColumn(label: Text('Load')),
                    DataColumn(label: Text('Unit')),
                  ],
                  rows: combinedValues.map(
                    (comb) {
                      loadAvg = loadAvg + comb['loadValue'];
                      loadCount = loadCount + 1;
                      unitAvg = unitAvg + comb['unitValue'];
                      unitCount = unitCount + 1;
                      return DataRow(
                        cells: [
                          DataCell(Text(comb['inv'].toString())),
                          DataCell(
                              Text(formatDateTime(comb['timestamp']).toString())),
                          DataCell(Text(comb['loadValue'].toString())),
                          DataCell(Text(comb['unitValue'].toString())),
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
            const SizedBox(height: 20),
            Text('Average Unit : ${unitCount > 0 ? (unitAvg / unitCount).toStringAsFixed(2) : "N/A"}   |   Total Unit : ${loadCount > 0 ? unitAvg.toStringAsFixed(2) : "N/A"}',
            ),
            const SizedBox(height: 20),
            const Divider(
              height: 0.3,
            ),
            const SizedBox(height: 20),
             Text('Average Load : ${loadCount > 0 ? (loadAvg / loadCount).toStringAsFixed(2) : "N/A"}   |   Total Load : ${loadCount > 0 ? loadAvg.toStringAsFixed(2) : "N/A"}',
            ),
            const SizedBox(height: 20),
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
      for (var doc in querySnapshot.docs) {
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
      }
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
        for (var doc in querySnapshot.docs) {
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
        }
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
      for (var doc in querySnapshot.docs) {
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
      }
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
        for (var doc in querySnapshot.docs) {
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
        }
      }
    }
  }
  return unitValues;
}

Future<List<Map<String, dynamic>>> searchForEBReadings(
    String officeId, DateTime fromDate, DateTime toDate) async {
  final List<Map<String, dynamic>> ebReadings = [];

  if (officeId != "0") {
    final QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await FirebaseFirestore.instance
            .collection('office_list/$officeId/EB_Readings')
            .get();
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final ebtimestamp = int.parse(doc.id);
      final timestamp = DateTime.fromMillisecondsSinceEpoch(ebtimestamp * 1000);
      if (timestamp.isAfter(fromDate) && timestamp.isBefore(toDate)) {
        final ebValue = data['EBValue'] as num;
        ebReadings.add({'value': ebValue, 'timestamp': timestamp});
      }
    }
  }
  return ebReadings;
}

Future<List<Map<String, dynamic>>> searchForCombinedValues(
    DateTime fromDate,
    DateTime toDate,
    String officeId,
    String inverterId,
) async {
  final List<Map<String, dynamic>> combinedValues = [];
  final List<Map<String, dynamic>> loadValues =
      await searchForLoadValues(fromDate, toDate, officeId, inverterId);
  final List<Map<String, dynamic>> unitValues =
      await searchForUnitValues(fromDate, toDate, officeId, inverterId);

  for (var loadValue in loadValues) {
    var combinedValue = {
      'timestamp': loadValue['timestamp'],
      'inv': loadValue['inv'],
      'loadValue': loadValue['value'],
      'unitValue': null,
    };
    var matchingUnitValue = unitValues.firstWhere(
      (unitValue) =>
          unitValue['timestamp'] == loadValue['timestamp'] &&
          unitValue['inv'] == loadValue['inv'],
      orElse: () =>{
        'timestamp': loadValue['timestamp'],
        'inv': loadValue['inv'],
        'value': null,
      }
    );
    combinedValue['unitValue'] = matchingUnitValue['value'];
    combinedValues.add(combinedValue);
  }
  return combinedValues;
}

List<Map<String, dynamic>> calculateEBDifferences(List<Map<String, dynamic>> ebReadings) {
  final List<Map<String, dynamic>> differences = [];
  ebReadings.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

  for (var i = 0; i < ebReadings.length - 1; i++) {
    final currentReading = ebReadings[i];
    final nextReading = ebReadings[i + 1];

    final currentTimestamp  = currentReading['timestamp'];
    final nextTimestamp = nextReading['timestamp'];

    final currentDate = DateTime(currentTimestamp.year, currentTimestamp.month, currentTimestamp.day);
    final nextDate = DateTime(nextTimestamp.year, nextTimestamp.month, nextTimestamp.day);

    if (currentDate  == nextDate) {
      final difference = nextReading['value'] - currentReading['value'];
      differences.add({'currenttimestamp':currentTimestamp ,'nexttimestamp': nextTimestamp, 'difference': difference});
    }
  }
  return differences;
}

List<Map<String, dynamic>> calculateDayDifferences(List<Map<String, dynamic>> ebReadings) {
  final List<Map<String, dynamic>> daydifferences = [];
  ebReadings.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

  for (var i = 0; i < ebReadings.length - 1; i++) {
    final currentReading = ebReadings[i];
    final nextReading = ebReadings[i + 1];

    final currentTimestamp  = currentReading['timestamp'];
    final nextTimestamp = nextReading['timestamp'];

    final currentDate = DateTime(currentTimestamp.year, currentTimestamp.month, currentTimestamp.day);
    final nextDate = DateTime(nextTimestamp.year, nextTimestamp.month, nextTimestamp.day);

    if (currentDate  != nextDate) {
      final difference = nextReading['value'] - currentReading['value'];
      daydifferences.add({'currenttimestamp':currentTimestamp ,'nexttimestamp': nextTimestamp, 'difference': difference});
    }
  }
  return daydifferences;
}