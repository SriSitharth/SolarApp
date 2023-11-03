import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class Result extends StatefulWidget {
  Result({Key? key}) : super(key: key);
  @override
  State<Result> createState() => _ResultState();
}

class _ResultState extends State<Result> {
  DateTime fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime toDate = DateTime.now();
  List<Map<String, dynamic>> loadValues = [];
  List<Map<String, dynamic>> unitValues = [];
  String selectedOffice = "0";
  String selectedInverter = "0";
  List<Map<String, dynamic>> selectedOfficeValues = [];
  List<Map<String, dynamic>> selectedInverterValues = [];

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

  @override
  void initState() {
    super.initState();
    fetchFirestoreData(selectedOffice, selectedInverter);
  }

  Future<void> fetchFirestoreData(String officeId, String inverterId) async {
    try {
      final List<Map<String, dynamic>> listdata =
          await searchForLoadValues(fromDate, toDate, officeId, inverterId);
      final List<Map<String, dynamic>> unitdata =
          await searchForUnitValues(fromDate, toDate, officeId, inverterId);
      setState(() {
        loadValues = listdata;
        unitValues = unitdata;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error fetching data : $e'),
        duration: const Duration(seconds: 5),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size.width;

    // DateTime maxDate = DateTime.now();
    // DateTime minDate = DateTime.now();

    // if (unitValues.isNotEmpty) {
    //   maxDate = unitValues.reduce((a, b) =>
    //       a['timestamp'].compareTo(b['timestamp']) > 0 ? a : b)['timestamp'];
    // }
    // if (unitValues.isNotEmpty) {
    //   minDate = unitValues.reduce((a, b) =>
    //       a['timestamp'].compareTo(b['timestamp']) < 0 ? a : b)['timestamp'];
    // }

    return Scaffold(
      appBar: AppBar(title: const Text("Visualizer")),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[

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
                const Divider(
                  height: 0.3,
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
                        selectedOfficeValues.clear();
                        print("office selected");
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
                        selectedInverterValues.clear();
                        print("Inverter selected");
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
            
            const Padding(
              padding: EdgeInsets.all(9.0),
              child: Text(
                'Load Value',
                style: TextStyle(fontSize: 15),
              ),
            ),
            //const SizedBox(height: 20),
            SizedBox(
              width: screenSize * 0.8,
              height: 230,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(
                      show: true,
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false))),
                  borderData: FlBorderData(
                      show: true,
                      border: const Border(
                          bottom: BorderSide(color: Colors.black, width: 2),
                          left: BorderSide(color: Colors.black, width: 2))),
                  minX: 0,
                  maxX: loadValues.length.toDouble() - 1,
                  minY: 0,
                  maxY: loadValues.isNotEmpty
                      ? (loadValues.reduce((a, b) =>
                                  a['value'] > b['value'] ? a : b)['value'] +
                              10.0)
                          .toDouble()
                      : 100.0,
                  lineBarsData: [
                    LineChartBarData(
                      spots: loadValues.asMap().entries.map((entry) {
                        //final timestamp = entry.value['timestamp'] as DateTime;
                        final value = entry.value['value'] as num;
                        return FlSpot(entry.key.toDouble(), value.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.orange,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(
              height: 0.3,
            ),
            const Padding(
              padding: EdgeInsets.all(9.0),
              child: Text(
                'Unit Value',
                style: TextStyle(fontSize: 15),
              ),
            ),
            SizedBox(
              width: screenSize * 0.8,
              height: 230,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(
                      show: true,
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false))),
                  borderData: FlBorderData(
                      show: true,
                      border: const Border(
                          bottom: BorderSide(color: Colors.black, width: 2),
                          left: BorderSide(color: Colors.black, width: 2))),
                  minX: 0,
                  maxX: loadValues.length.toDouble() - 1,
                  minY: 0,
                  maxY: unitValues.isNotEmpty
                      ? (unitValues.reduce((a, b) =>
                                  a['value'] > b['value'] ? a : b)['value'] +
                              10)
                          .toDouble()
                      : 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: unitValues.asMap().entries.map((entry) {
                        //final timestamp = entry.value['timestamp'] as DateTime;
                        final plotvalue = entry.value['value'] as num;
                        return FlSpot(
                            entry.key.toDouble(), plotvalue.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: Colors.orange,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<List<Map<String, dynamic>>> searchForLoadValues(DateTime fromDate,
    DateTime toDate, String officeId, String inverterId) async {
  String firestorePath = 'load';
  if (officeId != "0") {
    firestorePath = 'office_list/$officeId/inverter_list';
    if (inverterId != "0") {
      firestorePath = 'office_list/$officeId/inverter_list/$inverterId/load';
    }
  }
  final QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection(firestorePath).get();
  final List<Map<String, dynamic>> loadValues = [];
  querySnapshot.docs.forEach((doc) {
    final data = doc.data() as Map<String, dynamic>;
    if (data.containsKey('LoadValue')) {
      final loadtimestamp = int.parse(doc.id);
      final timestamp =
          DateTime.fromMillisecondsSinceEpoch(loadtimestamp * 1000);
      if (timestamp.isAfter(fromDate) && timestamp.isBefore(toDate)) {
        final loadValue = data['LoadValue'] as num;
        loadValues.add({'value': loadValue, 'timestamp': timestamp});
      }
    }
  });
  return loadValues;
}

Future<List<Map<String, dynamic>>> searchForUnitValues(DateTime fromDate,
    DateTime toDate, String officeId, String inverterId) async {
  String firestorePath = 'unit';
  if (officeId != "0") {
    firestorePath = 'office_list/$officeId/inverter_list';
    if (inverterId != "0") {
      firestorePath = 'office_list/$officeId/inverter_list/$inverterId/unit';
    }
  }
  final QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection(firestorePath).get();
  final List<Map<String, dynamic>> unitValues = [];
  querySnapshot.docs.forEach((doc) {
    final data = doc.data() as Map<String, dynamic>;
    if (data.containsKey('UnitValue')) {
      final loadtimestamp = int.parse(doc.id);
      final timestamp =
          DateTime.fromMillisecondsSinceEpoch(loadtimestamp * 1000);
      if (timestamp.isAfter(fromDate) && timestamp.isBefore(toDate)) {
        final unitValue = data['UnitValue'] as num;
        unitValues.add({'value': unitValue, 'timestamp': timestamp});
      }
    }
  });
  return unitValues;
}
