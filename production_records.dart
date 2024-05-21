import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:LuckyEgg/color_provider.dart';
import 'dart:developer' as developer;

class EggProductionPage extends StatefulWidget {
  const EggProductionPage({Key? key}) : super(key: key);

  @override
  _EggProductionPageState createState() => _EggProductionPageState();
}

class _EggProductionPageState extends State<EggProductionPage> {
  List<EggProductionRecord> eggProductionRecords = [];
  int? editingIndex; // Track the index of the row being edited
  Color textColor = Colors.black; // Text color variable

  // Load saved records when the page initializes
  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  // Load saved records from SharedPreferences
  Future<void> loadRecords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? recordsList = prefs.getStringList('eggProductionRecords');
    if (recordsList != null) {
      setState(() {
        eggProductionRecords = recordsList
        .map((recordString) => EggProductionRecord.fromString(recordString))
        .toList();
      });
      developer.log('Loaded records: $recordsList'); // Log loaded records
    }
  }

  // Save records to SharedPreferences
  Future<void> saveRecords() async {
    for (var record in eggProductionRecords) {
      // Sanitize the breed input to allow only characters from 'a' to 'z' (both lower and upper case)
      record.breed = record.breed.replaceAll(RegExp(r'[^a-zA-Z]'), '');

      // Check if good and bad are valid integers
      if (!RegExp(r'^[0-9]+$').hasMatch(record.good)) {
        record.good = ''; // Clear the good if invalid
      }
      if (!RegExp(r'^[0-9]+$').hasMatch(record.bad)) {
        record.bad = ''; // Clear the bad if invalid
      }

      if (record.breed.isEmpty) {
        record.breed = ''; // Clear the breed if it's empty after sanitization
      }

      if (record.size.isEmpty) {
        record.size = ''; // Clear the size if it's empty after sanitization
      }
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> recordsList = eggProductionRecords.map((record) => record.toString()).toList();
    await prefs.setStringList('eggProductionRecords', recordsList);
    developer.log('Saved records: $recordsList'); // Log saved records

    // Clear editingIndex after saving records
    setState(() {
      editingIndex = null;
    });
  }

  // Delete a record from the list and save the updated list
  Future<void> deleteRecord(int index) async {
    setState(() {
      eggProductionRecords.removeAt(index);
    });
    await saveRecords();
  }

  @override
  Widget build(BuildContext context) {
    final Color selectedColor =
        Provider.of<ColorProvider>(context).selectedColor;
    final bool isDarkBackground = selectedColor.computeLuminance() < 0.5;
    textColor = isDarkBackground ? Colors.white : Colors.black;

    // Calculate sum of "good" values
    int sumOfGoods = 0;
    for (var record in eggProductionRecords) {
      if (record.good.isNotEmpty) {
        sumOfGoods += int.parse(record.good);
      }
    }

  // Calculate sum of "bad" values
  int sumOfBads = 0;
  for (var record in eggProductionRecords) {
    if (record.bad.isNotEmpty) {
      sumOfBads += int.parse(record.bad);
    }
  }


    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
        centerTitle: true,
        title: Text(
          'Egg Production Records',
          style: TextStyle(
            color: textColor,
          ),
        ),
      ),
      backgroundColor: selectedColor,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  dividerThickness: 1.0,
                  columns: [
                    DataColumn(
                      label: Text('Date', style: TextStyle(color: textColor)),
                    ),
                    DataColumn(
                      label: Text('Breed', style: TextStyle(color: textColor)),
                    ),
                    DataColumn(
                      label: Text('Size', style: TextStyle(color: textColor)),
                    ),
                    DataColumn(
                      label: Text('Good', style: TextStyle(color: textColor)),
                    ),
                    DataColumn(
                      label: Text('Bad', style: TextStyle(color: textColor)),
                    ),
                    DataColumn(
                      label: Text('Actions', style: TextStyle(color: textColor)),
                    ),
                  ],
                  rows: List.generate(
                    eggProductionRecords.length,
                    (index) => DataRow(
                      cells: [
                        DataCell(
                          editingIndex == index
                              ? GestureDetector(
                                  onTap: () async {
                                    final DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (pickedDate != null) {
                                      setState(() {
                                        // Extract the date part without the time
                                        eggProductionRecords[index].date = "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
                                      });
                                      await saveRecords();
                                    }
                                  },
                                  child: TextFormField(
                                    enabled: false,
                                    controller: TextEditingController(text: eggProductionRecords[index].date),
                                    style: TextStyle(color: textColor),
                                    decoration: InputDecoration(border: InputBorder.none),
                                  ),
                                )
                              : Text(eggProductionRecords[index].date, style: TextStyle(color: textColor)),
                        ),
                        DataCell(
                          editingIndex == index
                              ? TextFormField(
                                  initialValue: eggProductionRecords[index].breed,
                                  style: TextStyle(color: textColor),
                                  onChanged: (value) {
                                    setState(() {
                                      eggProductionRecords[index].breed = value.replaceAll(RegExp(r'[^a-zA-Z]'), '');
                                    });
                                  },
                                  onFieldSubmitted: (value) {
                                    setState(() {
                                      editingIndex = null;
                                    });
                                  },
                                )
                              : Text(eggProductionRecords[index].breed, style: TextStyle(color: textColor)),
                        ),
                        DataCell(
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                editingIndex = index;
                                if (eggProductionRecords[index].size == 'Small') {
                                  eggProductionRecords[index].size = 'Medium';
                                } else if (eggProductionRecords[index].size == 'Medium') {
                                  eggProductionRecords[index].size = 'Large';
                                } else {
                                  eggProductionRecords[index].size = 'Small';
                                }
                                saveRecords();
                              });
                            },
                            child: Row(
                              children: [
                                Text(
                                  eggProductionRecords[index].size.isNotEmpty ? eggProductionRecords[index].size : 'tap',
                                  style: TextStyle(color: textColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          editingIndex == index
                              ? TextFormField(
                                  initialValue: eggProductionRecords[index].good,
                                  style: TextStyle(color: textColor),
                                  onChanged: (value) {
                                    setState(() {
                                      eggProductionRecords[index].good = RegExp(r'^[0-9]+$').hasMatch(value) ? value : '';
                                    });
                                  },
                                  onFieldSubmitted: (value) {
                                    setState(() {
                                      editingIndex = null;
                                    });
                                  },
                                )
                              : Text(eggProductionRecords[index].good, style: TextStyle(color: textColor)),
                        ),
                        DataCell(
                          editingIndex == index
                              ? TextFormField(
                                  initialValue: eggProductionRecords[index].bad,
                                  style: TextStyle(color: textColor),
                                  onChanged: (value) {
                                    setState(() {
                                      eggProductionRecords[index].bad = RegExp(r'^[0-9]+$').hasMatch(value) ? value : '';
                                    });
                                  },
                                  onFieldSubmitted: (value) {
                                    setState(() {
                                      editingIndex = null;
                                    });
                                  },
                                )
                              : Text(eggProductionRecords[index].bad, style: TextStyle(color: textColor)),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  setState(() {
                                    editingIndex = index;
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  deleteRecord(index);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Replace SizedBox with ExpansionTile
ExpansionTile(
  leading: Icon(Icons.calculate), // Icon indicating that it can be tapped to expand
  title: Text(
    'Totals', // Title of the ExpansionTile
    style: TextStyle(
      color: textColor,
      fontWeight: FontWeight.bold,
    ),
  ),
  children: [
    // DataTable for Good values
    DataTable(
      columns: [
        DataColumn(
          label: Text(
            'Good', 
            style: TextStyle(
              color: Colors.green, 
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
      rows: [
        DataRow(
          cells: [
            DataCell(
              Text(
                'Total: $sumOfGoods', 
                textAlign: TextAlign.end, 
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
    // DataTable for Bad values
    DataTable(
      columns: [
        DataColumn(
          label: Text(
            'Bad', 
            style: TextStyle(
              color: Colors.red, 
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
      rows: [
        DataRow(
          cells: [
            DataCell(
              Text(
                'Total: $sumOfBads', 
                textAlign: TextAlign.end, 
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
),

        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  eggProductionRecords.add(EggProductionRecord(date: ''));
                });
              },
              child: const Text('Add Row'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                saveRecords();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class EggProductionRecord {
  String date;
  String breed;
  String size;
  String good;
  String bad;

  EggProductionRecord({
    required this.date,
    this.breed = '',
    this.size = '',
    this.good = '',
    this.bad = '',
  });

  // Create EggProductionRecord object from string representation
  static EggProductionRecord fromString(String recordString) {
    List<String> values = recordString.split(',');
    return EggProductionRecord(
      date: values[0],
      breed: values[1],
      size: values[2],
      good: values[3],
      bad: values[4],
    );
  }

  // Convert EggProductionRecord object to string representation
  @override
  String toString() {
    return '$date,$breed,$size,$good,$bad';
  }
}

