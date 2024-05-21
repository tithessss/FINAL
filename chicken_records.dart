import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:LuckyEgg/color_provider.dart';
import 'dart:developer' as developer;

class ChickenRecordsPage extends StatefulWidget {
  const ChickenRecordsPage({Key? key}) : super(key: key);

  @override
  _ChickenRecordsPageState createState() => _ChickenRecordsPageState();
}

class _ChickenRecordsPageState extends State<ChickenRecordsPage> {
  List<ChickenRecord> chickenRecords = [];
  int? editingIndex; // Track the index of the row being edited
  Color textColor = Colors.black; // Text color variable

  // Load saved records when the page initializes
  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  // Load saved records from SharedPreferences
  void loadRecords() async {
    developer.log('Loading records from SharedPreferences...',
        name: 'ChickenRecords');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? recordsList = prefs.getStringList('chickenRecords');
    if (recordsList != null) {
      setState(() {
        chickenRecords = recordsList
            .map((recordString) => ChickenRecord.fromString(recordString))
            .toList();
      });
      developer.log('Loaded records: $chickenRecords', name: 'ChickenRecords');
    } else {
      developer.log('No records found', name: 'ChickenRecords');
    }
  }

  // Save records to SharedPreferences
  void saveRecords() async {
    developer.log('Saving records to SharedPreferences...',
        name: 'ChickenRecords');
    for (var record in chickenRecords) {
      // Sanitize the breed input to allow only characters from 'a' to 'z' (both lower and upper case)
      record.breed = record.breed.replaceAll(RegExp(r'[^a-zA-Z]'), '');

      // Check if counts is a valid integer
      if (!RegExp(r'^[0-9]+$').hasMatch(record.counts)) {
        record.counts = ''; // Clear the counts if invalid
      }

      if (record.breed.isEmpty) {
        record.breed = ''; // Clear the breed if it's empty after sanitization
      }
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> recordsList =
        chickenRecords.map((record) => record.toString()).toList();
    await prefs.setStringList('chickenRecords', recordsList);

    // Clear editingIndex after saving records
    setState(() {
      editingIndex = null;
    });
    developer.log('Saved records: $recordsList', name: 'ChickenRecords');
  }

  // Delete a record from the list and save the updated list
  void deleteRecord(int index) {
    setState(() {
      chickenRecords.removeAt(index);
      saveRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color selectedColor =
        Provider.of<ColorProvider>(context).selectedColor;
    final bool isDarkBackground = selectedColor.computeLuminance() < 0.5;
    textColor = isDarkBackground ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
        centerTitle: true,
        title: Text(
          'Chicken Records',
          style: TextStyle(
            color: textColor,
          ),
        ),
      ),
      backgroundColor: selectedColor,
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: DataTable(
            dividerThickness: 1.0,
            columns: [
              DataColumn(
                label: Text('Breed', style: TextStyle(color: textColor)),
              ),
              DataColumn(
                label: Text('Counts', style: TextStyle(color: textColor)),
              ),
              DataColumn(
                label: Text('Vaccinated', style: TextStyle(color: textColor)),
              ),
              DataColumn(
                label: Text('Actions', style: TextStyle(color: textColor)),
              ),
            ],
            rows: List.generate(
              chickenRecords.length,
              (index) => DataRow(
                cells: [
                  DataCell(
                    editingIndex == index
                        ? TextFormField(
                            initialValue: chickenRecords[index].breed,
                            style: TextStyle(color: textColor),
                            onChanged: (value) {
                              setState(() {
                                chickenRecords[index].breed = value;
                              });
                            },
                          )
                        : Text(chickenRecords[index].breed,
                            style: TextStyle(color: textColor)),
                  ),
                  DataCell(
                    editingIndex == index
                        ? TextFormField(
                            initialValue: chickenRecords[index].counts,
                            style: TextStyle(color: textColor),
                            onChanged: (value) {
                              setState(() {
                                chickenRecords[index].counts = value;
                              });
                            },
                          )
                        : Text(chickenRecords[index].counts,
                            style: TextStyle(color: textColor)),
                  ),
                  DataCell(
                    TextButton(
                      onPressed: () {
                        setState(() {
                          // Toggle the vaccination status
                          chickenRecords[index].vaccinations = chickenRecords[index].vaccinations == 'Vaccinated'
                          ? 'Not Vaccinated'
                          : 'Vaccinated';
                        });
                      },
                      child: Text(
                        chickenRecords[index].vaccinations,
                        style: TextStyle(color: textColor),
                      ),
                    ),
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  chickenRecords.add(ChickenRecord());
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

class ChickenRecord {
  String breed;
  String counts;
  String vaccinations;

  ChickenRecord({
    this.breed = '',
    this.counts = '',
    this.vaccinations = '',
  });

  // Create ChickenRecord object from string representation
  static ChickenRecord fromString(String recordString) {
    List<String> values = recordString.split(',');
    return ChickenRecord(
      breed: values[0],
      counts: values[1],
      vaccinations: values[2],
    );
  }

  // Convert ChickenRecord object to string representation
  @override
  String toString() {
    return '$breed,$counts,$vaccinations';
  }
}
