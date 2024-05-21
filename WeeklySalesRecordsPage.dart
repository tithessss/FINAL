import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:LuckyEgg/color_provider.dart';
import 'dart:developer' as developer;

class JanuarySalesScreen extends StatefulWidget {
  const JanuarySalesScreen({Key? key}) : super(key: key);

  @override
  _JanuarySalesScreenState createState() => _JanuarySalesScreenState();
}

class _JanuarySalesScreenState extends State<JanuarySalesScreen> {
  late List<List<List<String>>> weeklySalesList = [];
  int? editingTableIndex;
  int? editingRowIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final Color selectedColor =
        Provider.of<ColorProvider>(context).selectedColor;
    final bool isDarkBackground = selectedColor.computeLuminance() < 0.5;
    final Color textColor = isDarkBackground ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
        centerTitle: true,
        title: const Text('Weekly Sales Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Sales Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklySalesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(weeklySalesList[index], textColor, index),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteConfirmationDialog(index);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addTable,
              child: const Text('Add Table'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(
      List<List<String>> weeklySales, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklySales);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Quantity', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklySales.asMap().entries.map(
                (entry) => DataRow(
                  cells: [
                    DataCell(Text(_getDayName(entry.key),
                        style: TextStyle(color: textColor))),
                    DataCell(
                      InkWell(
                        onTap: () {
                          _selectDate(context, tableIndex, entry.key);
                        },
                        child: Text(
                          entry.value[1].isEmpty
                              ? 'select date'
                              : entry.value[1],
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[2],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][2] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[3],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][3] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (editingRowIndex != entry.key)
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _editRow(tableIndex, entry.key);
                              },
                            ),
                          if (editingRowIndex == entry.key)
                            IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () async {
                                bool saved =
                                    await _saveRow(tableIndex, entry.key);
                                if (saved) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Saved')),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          DataRow(
            cells: [
              DataCell(Text('Total',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
              DataCell(Text('')),
              DataCell(Text(totalAmount.toStringAsFixed(2),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCell(
      bool enabled, String value, Function(String) onChanged, Color textColor) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));
    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: value,
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            style: TextStyle(color: textColor),
          )
        : Text(value, style: TextStyle(color: textColor));
  }

  String _getDayName(int index) {
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[index];
  }

  void _addTable() {
    setState(() {
      weeklySalesList.add(_initializeWeeklySales());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklySales() {
    List<List<String>> initialData = [];
    // Add initial row for each day of the week
    for (int i = 0; i < 7; i++) {
      initialData.add(['', '', '', '']);
    }
    return initialData;
  }

  void _editRow(int tableIndex, int rowIndex) {
    setState(() {
      editingTableIndex = tableIndex;
      editingRowIndex = rowIndex;
    });
  }

  Future<bool> _saveRow(int tableIndex, int rowIndex) async {
    setState(() {
      editingTableIndex = null;
      editingRowIndex = null;
    });
    List<List<String>> weeklySales = weeklySalesList[tableIndex];
    bool valid = _validateInputs(weeklySales[rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the modified row
      if (double.tryParse(weeklySales[rowIndex][2]) == null) {
        // Clear quantity if invalid
        weeklySales[rowIndex][2] = '';
      }
      if (double.tryParse(weeklySales[rowIndex][3]) == null) {
        // Clear amount if invalid
        weeklySales[rowIndex][3] = '';
      }
      await _saveData(); // Save modified row after clearing invalid inputs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid inputs cleared.'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return false;
    }
  }

  bool _validateInputs(List<String> inputs) {
    // Validate if the "Quantity" field contains only numbers
    bool isQuantityValid = double.tryParse(inputs[2]) != null;
    // Validate if the "Amount" field contains only numbers
    bool isAmountValid = double.tryParse(inputs[3]) != null;
    return isQuantityValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklySalesList.length;
    await prefs.setInt(
        'JanuarynumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklySalesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('JanuaryweeklySales$i', dataToSave);
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('JanuarynumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData = prefs.getStringList('JanuaryweeklySales$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
        developer.log('Saved table $i: $savedData');
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklySalesList = loadedData;
      });
    } else {
      setState(() {
        weeklySalesList = [_initializeWeeklySales()];
      });
    }
  }

  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Table'),
          content: Text('Are you sure you want to delete this table?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed != null && confirmed) {
        _deleteTable(index);
      }
    });
  }

  void _deleteTable(int index) {
    setState(() {
      weeklySalesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklySales) {
    return weeklySales.fold<double>(0, (total, entry) => total + (double.tryParse(entry[3]) ?? 0));
  }

  Future<void> _selectDate(
      BuildContext context, int tableIndex, int rowIndex) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        weeklySalesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class FebuarySalesScreen extends StatefulWidget {
  const FebuarySalesScreen({Key? key}) : super(key: key);

  @override
  _FebuarySalesScreenState createState() => _FebuarySalesScreenState();
}

class _FebuarySalesScreenState extends State<FebuarySalesScreen> {
  late List<List<List<String>>> weeklySalesList = [];
  int? editingTableIndex;
  int? editingRowIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final Color selectedColor =
        Provider.of<ColorProvider>(context).selectedColor;
    final bool isDarkBackground = selectedColor.computeLuminance() < 0.5;
    final Color textColor = isDarkBackground ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
        centerTitle: true,
        title: const Text('Weekly Sales Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Sales Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklySalesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(weeklySalesList[index], textColor, index),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteConfirmationDialog(index);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addTable,
              child: const Text('Add Table'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(
      List<List<String>> weeklySales, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklySales);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Quantity', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklySales.asMap().entries.map(
                (entry) => DataRow(
                  cells: [
                    DataCell(Text(_getDayName(entry.key),
                        style: TextStyle(color: textColor))),
                    DataCell(
                      InkWell(
                        onTap: () {
                          _selectDate(context, tableIndex, entry.key);
                        },
                        child: Text(
                          entry.value[1].isEmpty
                              ? 'select date'
                              : entry.value[1],
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[2],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][2] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[3],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][3] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (editingRowIndex != entry.key)
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _editRow(tableIndex, entry.key);
                              },
                            ),
                          if (editingRowIndex == entry.key)
                            IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () async {
                                bool saved =
                                    await _saveRow(tableIndex, entry.key);
                                if (saved) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Saved')),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          DataRow(
            cells: [
              DataCell(Text('Total',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
              DataCell(Text('')),
              DataCell(Text(totalAmount.toStringAsFixed(2),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCell(
      bool enabled, String value, Function(String) onChanged, Color textColor) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));
    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: value,
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            style: TextStyle(color: textColor),
          )
        : Text(value, style: TextStyle(color: textColor));
  }

  String _getDayName(int index) {
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[index];
  }

  void _addTable() {
    setState(() {
      weeklySalesList.add(_initializeWeeklySales());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklySales() {
    List<List<String>> initialData = [];
    // Add initial row for each day of the week
    for (int i = 0; i < 7; i++) {
      initialData.add(['', '', '', '']);
    }
    return initialData;
  }

  void _editRow(int tableIndex, int rowIndex) {
    setState(() {
      editingTableIndex = tableIndex;
      editingRowIndex = rowIndex;
    });
  }

  Future<bool> _saveRow(int tableIndex, int rowIndex) async {
    setState(() {
      editingTableIndex = null;
      editingRowIndex = null;
    });
    List<List<String>> weeklySales = weeklySalesList[tableIndex];
    bool valid = _validateInputs(weeklySales[rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the modified row
      if (double.tryParse(weeklySales[rowIndex][2]) == null) {
        // Clear quantity if invalid
        weeklySales[rowIndex][2] = '';
      }
      if (double.tryParse(weeklySales[rowIndex][3]) == null) {
        // Clear amount if invalid
        weeklySales[rowIndex][3] = '';
      }
      await _saveData(); // Save modified row after clearing invalid inputs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid inputs cleared.'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return false;
    }
  }

  bool _validateInputs(List<String> inputs) {
    // Validate if the "Quantity" field contains only numbers
    bool isQuantityValid = double.tryParse(inputs[2]) != null;
    // Validate if the "Amount" field contains only numbers
    bool isAmountValid = double.tryParse(inputs[3]) != null;
    return isQuantityValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklySalesList.length;
    await prefs.setInt(
        'FebuarynumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklySalesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('FebuaryweeklySales$i', dataToSave);
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('FebuarynumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData = prefs.getStringList('FebuaryweeklySales$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
        developer.log('Saved table $i: $savedData');
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklySalesList = loadedData;
      });
    } else {
      setState(() {
        weeklySalesList = [_initializeWeeklySales()];
      });
    }
  }

  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Table'),
          content: Text('Are you sure you want to delete this table?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed != null && confirmed) {
        _deleteTable(index);
      }
    });
  }

  void _deleteTable(int index) {
    setState(() {
      weeklySalesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklySales) {
    return weeklySales.fold<double>(
        0, (total, entry) => total + (double.tryParse(entry[3]) ?? 0));
  }

  Future<void> _selectDate(
      BuildContext context, int tableIndex, int rowIndex) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        weeklySalesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class MarchSalesScreen extends StatefulWidget {
  const MarchSalesScreen({Key? key}) : super(key: key);

  @override
  _MarchSalesScreenState createState() => _MarchSalesScreenState();
}

class _MarchSalesScreenState extends State<MarchSalesScreen> {
  late List<List<List<String>>> weeklySalesList = [];
  int? editingTableIndex;
  int? editingRowIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final Color selectedColor =
        Provider.of<ColorProvider>(context).selectedColor;
    final bool isDarkBackground = selectedColor.computeLuminance() < 0.5;
    final Color textColor = isDarkBackground ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
        centerTitle: true,
        title: const Text('Weekly Sales Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Sales Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklySalesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(weeklySalesList[index], textColor, index),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteConfirmationDialog(index);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addTable,
              child: const Text('Add Table'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(
      List<List<String>> weeklySales, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklySales);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Quantity', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklySales.asMap().entries.map(
                (entry) => DataRow(
                  cells: [
                    DataCell(Text(_getDayName(entry.key),
                        style: TextStyle(color: textColor))),
                    DataCell(
                      InkWell(
                        onTap: () {
                          _selectDate(context, tableIndex, entry.key);
                        },
                        child: Text(
                          entry.value[1].isEmpty
                              ? 'select date'
                              : entry.value[1],
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[2],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][2] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[3],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][3] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (editingRowIndex != entry.key)
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _editRow(tableIndex, entry.key);
                              },
                            ),
                          if (editingRowIndex == entry.key)
                            IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () async {
                                bool saved =
                                    await _saveRow(tableIndex, entry.key);
                                if (saved) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Saved')),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          DataRow(
            cells: [
              DataCell(Text('Total',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
              DataCell(Text('')),
              DataCell(Text(totalAmount.toStringAsFixed(2),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCell(
      bool enabled, String value, Function(String) onChanged, Color textColor) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));
    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: value,
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            style: TextStyle(color: textColor),
          )
        : Text(value, style: TextStyle(color: textColor));
  }

  String _getDayName(int index) {
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[index];
  }

  void _addTable() {
    setState(() {
      weeklySalesList.add(_initializeWeeklySales());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklySales() {
    List<List<String>> initialData = [];
    // Add initial row for each day of the week
    for (int i = 0; i < 7; i++) {
      initialData.add(['', '', '', '']);
    }
    return initialData;
  }

  void _editRow(int tableIndex, int rowIndex) {
    setState(() {
      editingTableIndex = tableIndex;
      editingRowIndex = rowIndex;
    });
  }

  Future<bool> _saveRow(int tableIndex, int rowIndex) async {
    setState(() {
      editingTableIndex = null;
      editingRowIndex = null;
    });
    List<List<String>> weeklySales = weeklySalesList[tableIndex];
    bool valid = _validateInputs(weeklySales[rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the modified row
      if (double.tryParse(weeklySales[rowIndex][2]) == null) {
        // Clear quantity if invalid
        weeklySales[rowIndex][2] = '';
      }
      if (double.tryParse(weeklySales[rowIndex][3]) == null) {
        // Clear amount if invalid
        weeklySales[rowIndex][3] = '';
      }
      await _saveData(); // Save modified row after clearing invalid inputs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid inputs cleared.'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return false;
    }
  }

  bool _validateInputs(List<String> inputs) {
    // Validate if the "Quantity" field contains only numbers
    bool isQuantityValid = double.tryParse(inputs[2]) != null;
    // Validate if the "Amount" field contains only numbers
    bool isAmountValid = double.tryParse(inputs[3]) != null;
    return isQuantityValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklySalesList.length;
    await prefs.setInt(
        'MarchnumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklySalesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('MarchweeklySales$i', dataToSave);
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('MarchnumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData = prefs.getStringList('MarchweeklySales$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
        developer.log('Saved table $i: $savedData');
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklySalesList = loadedData;
      });
    } else {
      setState(() {
        weeklySalesList = [_initializeWeeklySales()];
      });
    }
  }

  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Table'),
          content: Text('Are you sure you want to delete this table?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed != null && confirmed) {
        _deleteTable(index);
      }
    });
  }

  void _deleteTable(int index) {
    setState(() {
      weeklySalesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklySales) {
    return weeklySales.fold<double>(
        0, (total, entry) => total + (double.tryParse(entry[3]) ?? 0));
  }

  Future<void> _selectDate(
      BuildContext context, int tableIndex, int rowIndex) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        weeklySalesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class AprilSalesScreen extends StatefulWidget {
  const AprilSalesScreen({Key? key}) : super(key: key);

  @override
  _AprilSalesScreenState createState() => _AprilSalesScreenState();
}

class _AprilSalesScreenState extends State<AprilSalesScreen> {
  late List<List<List<String>>> weeklySalesList = [];
  int? editingTableIndex;
  int? editingRowIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final Color selectedColor =
        Provider.of<ColorProvider>(context).selectedColor;
    final bool isDarkBackground = selectedColor.computeLuminance() < 0.5;
    final Color textColor = isDarkBackground ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
        centerTitle: true,
        title: const Text('Weekly Sales Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Sales Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklySalesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(weeklySalesList[index], textColor, index),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteConfirmationDialog(index);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addTable,
              child: const Text('Add Table'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(
      List<List<String>> weeklySales, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklySales);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Quantity', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklySales.asMap().entries.map(
                (entry) => DataRow(
                  cells: [
                    DataCell(Text(_getDayName(entry.key),
                        style: TextStyle(color: textColor))),
                    DataCell(
                      InkWell(
                        onTap: () {
                          _selectDate(context, tableIndex, entry.key);
                        },
                        child: Text(
                          entry.value[1].isEmpty
                              ? 'select date'
                              : entry.value[1],
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[2],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][2] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[3],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][3] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (editingRowIndex != entry.key)
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _editRow(tableIndex, entry.key);
                              },
                            ),
                          if (editingRowIndex == entry.key)
                            IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () async {
                                bool saved =
                                    await _saveRow(tableIndex, entry.key);
                                if (saved) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Saved')),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          DataRow(
            cells: [
              DataCell(Text('Total',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
              DataCell(Text('')),
              DataCell(Text(totalAmount.toStringAsFixed(2),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCell(
      bool enabled, String value, Function(String) onChanged, Color textColor) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));
    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: value,
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            style: TextStyle(color: textColor),
          )
        : Text(value, style: TextStyle(color: textColor));
  }

  String _getDayName(int index) {
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[index];
  }

  void _addTable() {
    setState(() {
      weeklySalesList.add(_initializeWeeklySales());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklySales() {
    List<List<String>> initialData = [];
    // Add initial row for each day of the week
    for (int i = 0; i < 7; i++) {
      initialData.add(['', '', '', '']);
    }
    return initialData;
  }

  void _editRow(int tableIndex, int rowIndex) {
    setState(() {
      editingTableIndex = tableIndex;
      editingRowIndex = rowIndex;
    });
  }

  Future<bool> _saveRow(int tableIndex, int rowIndex) async {
    setState(() {
      editingTableIndex = null;
      editingRowIndex = null;
    });
    List<List<String>> weeklySales = weeklySalesList[tableIndex];
    bool valid = _validateInputs(weeklySales[rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the modified row
      if (double.tryParse(weeklySales[rowIndex][2]) == null) {
        // Clear quantity if invalid
        weeklySales[rowIndex][2] = '';
      }
      if (double.tryParse(weeklySales[rowIndex][3]) == null) {
        // Clear amount if invalid
        weeklySales[rowIndex][3] = '';
      }
      await _saveData(); // Save modified row after clearing invalid inputs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid inputs cleared.'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return false;
    }
  }

  bool _validateInputs(List<String> inputs) {
    // Validate if the "Quantity" field contains only numbers
    bool isQuantityValid = double.tryParse(inputs[2]) != null;
    // Validate if the "Amount" field contains only numbers
    bool isAmountValid = double.tryParse(inputs[3]) != null;
    return isQuantityValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklySalesList.length;
    await prefs.setInt(
        'AprilnumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklySalesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('AprilweeklySales$i', dataToSave);
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('AprilnumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData = prefs.getStringList('AprilweeklySales$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
        developer.log('Saved table $i: $savedData');
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklySalesList = loadedData;
      });
    } else {
      setState(() {
        weeklySalesList = [_initializeWeeklySales()];
      });
    }
  }

  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Table'),
          content: Text('Are you sure you want to delete this table?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed != null && confirmed) {
        _deleteTable(index);
      }
    });
  }

  void _deleteTable(int index) {
    setState(() {
      weeklySalesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklySales) {
    return weeklySales.fold<double>(
        0, (total, entry) => total + (double.tryParse(entry[3]) ?? 0));
  }

  Future<void> _selectDate(
      BuildContext context, int tableIndex, int rowIndex) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        weeklySalesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class MaySalesScreen extends StatefulWidget {
  const MaySalesScreen({Key? key}) : super(key: key);

  @override
  _MaySalesScreenState createState() => _MaySalesScreenState();
}

class _MaySalesScreenState extends State<MaySalesScreen> {
  late List<List<List<String>>> weeklySalesList = [];
  int? editingTableIndex;
  int? editingRowIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final Color selectedColor =
        Provider.of<ColorProvider>(context).selectedColor;
    final bool isDarkBackground = selectedColor.computeLuminance() < 0.5;
    final Color textColor = isDarkBackground ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
        centerTitle: true,
        title: const Text('Weekly Sales Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Sales Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklySalesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(weeklySalesList[index], textColor, index),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteConfirmationDialog(index);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addTable,
              child: const Text('Add Table'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(
      List<List<String>> weeklySales, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklySales);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Quantity', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklySales.asMap().entries.map(
                (entry) => DataRow(
                  cells: [
                    DataCell(Text(_getDayName(entry.key),
                        style: TextStyle(color: textColor))),
                    DataCell(
                      InkWell(
                        onTap: () {
                          _selectDate(context, tableIndex, entry.key);
                        },
                        child: Text(
                          entry.value[1].isEmpty
                              ? 'select date'
                              : entry.value[1],
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[2],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][2] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[3],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][3] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (editingRowIndex != entry.key)
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _editRow(tableIndex, entry.key);
                              },
                            ),
                          if (editingRowIndex == entry.key)
                            IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () async {
                                bool saved =
                                    await _saveRow(tableIndex, entry.key);
                                if (saved) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Saved')),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          DataRow(
            cells: [
              DataCell(Text('Total',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
              DataCell(Text('')),
              DataCell(Text(totalAmount.toStringAsFixed(2),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCell(
      bool enabled, String value, Function(String) onChanged, Color textColor) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));
    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: value,
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            style: TextStyle(color: textColor),
          )
        : Text(value, style: TextStyle(color: textColor));
  }

  String _getDayName(int index) {
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[index];
  }

  void _addTable() {
    setState(() {
      weeklySalesList.add(_initializeWeeklySales());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklySales() {
    List<List<String>> initialData = [];
    // Add initial row for each day of the week
    for (int i = 0; i < 7; i++) {
      initialData.add(['', '', '', '']);
    }
    return initialData;
  }

  void _editRow(int tableIndex, int rowIndex) {
    setState(() {
      editingTableIndex = tableIndex;
      editingRowIndex = rowIndex;
    });
  }

  Future<bool> _saveRow(int tableIndex, int rowIndex) async {
    setState(() {
      editingTableIndex = null;
      editingRowIndex = null;
    });
    List<List<String>> weeklySales = weeklySalesList[tableIndex];
    bool valid = _validateInputs(weeklySales[rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the modified row
      if (double.tryParse(weeklySales[rowIndex][2]) == null) {
        // Clear quantity if invalid
        weeklySales[rowIndex][2] = '';
      }
      if (double.tryParse(weeklySales[rowIndex][3]) == null) {
        // Clear amount if invalid
        weeklySales[rowIndex][3] = '';
      }
      await _saveData(); // Save modified row after clearing invalid inputs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid inputs cleared.'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return false;
    }
  }

  bool _validateInputs(List<String> inputs) {
    // Validate if the "Quantity" field contains only numbers
    bool isQuantityValid = double.tryParse(inputs[2]) != null;
    // Validate if the "Amount" field contains only numbers
    bool isAmountValid = double.tryParse(inputs[3]) != null;
    return isQuantityValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklySalesList.length;
    await prefs.setInt(
        'MaynumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklySalesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('MayweeklySales$i', dataToSave);
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('MaynumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData = prefs.getStringList('MayweeklySales$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
        developer.log('Saved table $i: $savedData');
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklySalesList = loadedData;
      });
    } else {
      setState(() {
        weeklySalesList = [_initializeWeeklySales()];
      });
    }
  }

  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Table'),
          content: Text('Are you sure you want to delete this table?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed != null && confirmed) {
        _deleteTable(index);
      }
    });
  }

  void _deleteTable(int index) {
    setState(() {
      weeklySalesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklySales) {
    return weeklySales.fold<double>(
        0, (total, entry) => total + (double.tryParse(entry[3]) ?? 0));
  }

  Future<void> _selectDate(
      BuildContext context, int tableIndex, int rowIndex) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        weeklySalesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class JuneSalesScreen extends StatefulWidget {
  const JuneSalesScreen({Key? key}) : super(key: key);

  @override
  _JuneSalesScreenState createState() => _JuneSalesScreenState();
}

class _JuneSalesScreenState extends State<JuneSalesScreen> {
  late List<List<List<String>>> weeklySalesList = [];
  int? editingTableIndex;
  int? editingRowIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final Color selectedColor =
        Provider.of<ColorProvider>(context).selectedColor;
    final bool isDarkBackground = selectedColor.computeLuminance() < 0.5;
    final Color textColor = isDarkBackground ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
        centerTitle: true,
        title: const Text('Weekly Sales Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Sales Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklySalesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(weeklySalesList[index], textColor, index),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteConfirmationDialog(index);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addTable,
              child: const Text('Add Table'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(
      List<List<String>> weeklySales, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklySales);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Quantity', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklySales.asMap().entries.map(
                (entry) => DataRow(
                  cells: [
                    DataCell(Text(_getDayName(entry.key),
                        style: TextStyle(color: textColor))),
                    DataCell(
                      InkWell(
                        onTap: () {
                          _selectDate(context, tableIndex, entry.key);
                        },
                        child: Text(
                          entry.value[1].isEmpty
                              ? 'select date'
                              : entry.value[1],
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[2],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][2] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[3],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][3] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (editingRowIndex != entry.key)
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _editRow(tableIndex, entry.key);
                              },
                            ),
                          if (editingRowIndex == entry.key)
                            IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () async {
                                bool saved =
                                    await _saveRow(tableIndex, entry.key);
                                if (saved) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Saved')),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          DataRow(
            cells: [
              DataCell(Text('Total',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
              DataCell(Text('')),
              DataCell(Text(totalAmount.toStringAsFixed(2),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCell(
      bool enabled, String value, Function(String) onChanged, Color textColor) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));
    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: value,
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            style: TextStyle(color: textColor),
          )
        : Text(value, style: TextStyle(color: textColor));
  }

  String _getDayName(int index) {
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[index];
  }

  void _addTable() {
    setState(() {
      weeklySalesList.add(_initializeWeeklySales());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklySales() {
    List<List<String>> initialData = [];
    // Add initial row for each day of the week
    for (int i = 0; i < 7; i++) {
      initialData.add(['', '', '', '']);
    }
    return initialData;
  }

  void _editRow(int tableIndex, int rowIndex) {
    setState(() {
      editingTableIndex = tableIndex;
      editingRowIndex = rowIndex;
    });
  }

  Future<bool> _saveRow(int tableIndex, int rowIndex) async {
    setState(() {
      editingTableIndex = null;
      editingRowIndex = null;
    });
    List<List<String>> weeklySales = weeklySalesList[tableIndex];
    bool valid = _validateInputs(weeklySales[rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the modified row
      if (double.tryParse(weeklySales[rowIndex][2]) == null) {
        // Clear quantity if invalid
        weeklySales[rowIndex][2] = '';
      }
      if (double.tryParse(weeklySales[rowIndex][3]) == null) {
        // Clear amount if invalid
        weeklySales[rowIndex][3] = '';
      }
      await _saveData(); // Save modified row after clearing invalid inputs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid inputs cleared.'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return false;
    }
  }

  bool _validateInputs(List<String> inputs) {
    // Validate if the "Quantity" field contains only numbers
    bool isQuantityValid = double.tryParse(inputs[2]) != null;
    // Validate if the "Amount" field contains only numbers
    bool isAmountValid = double.tryParse(inputs[3]) != null;
    return isQuantityValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklySalesList.length;
    await prefs.setInt(
        'JunenumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklySalesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('JuneweeklySales$i', dataToSave);
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('JunenumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData = prefs.getStringList('JuneweeklySales$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
        developer.log('Saved table $i: $savedData');
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklySalesList = loadedData;
      });
    } else {
      setState(() {
        weeklySalesList = [_initializeWeeklySales()];
      });
    }
  }

  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Table'),
          content: Text('Are you sure you want to delete this table?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed != null && confirmed) {
        _deleteTable(index);
      }
    });
  }

  void _deleteTable(int index) {
    setState(() {
      weeklySalesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklySales) {
    return weeklySales.fold<double>(
        0, (total, entry) => total + (double.tryParse(entry[3]) ?? 0));
  }

  Future<void> _selectDate(
      BuildContext context, int tableIndex, int rowIndex) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        weeklySalesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class JulySalesScreen extends StatefulWidget {
  const JulySalesScreen({Key? key}) : super(key: key);

  @override
  _JulySalesScreenState createState() => _JulySalesScreenState();
}

class _JulySalesScreenState extends State<JulySalesScreen> {
  late List<List<List<String>>> weeklySalesList = [];
  int? editingTableIndex;
  int? editingRowIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final Color selectedColor =
        Provider.of<ColorProvider>(context).selectedColor;
    final bool isDarkBackground = selectedColor.computeLuminance() < 0.5;
    final Color textColor = isDarkBackground ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
        centerTitle: true,
        title: const Text('Weekly Sales Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Sales Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklySalesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(weeklySalesList[index], textColor, index),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteConfirmationDialog(index);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addTable,
              child: const Text('Add Table'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(
      List<List<String>> weeklySales, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklySales);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Quantity', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklySales.asMap().entries.map(
                (entry) => DataRow(
                  cells: [
                    DataCell(Text(_getDayName(entry.key),
                        style: TextStyle(color: textColor))),
                    DataCell(
                      InkWell(
                        onTap: () {
                          _selectDate(context, tableIndex, entry.key);
                        },
                        child: Text(
                          entry.value[1].isEmpty
                              ? 'select date'
                              : entry.value[1],
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[2],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][2] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[3],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][3] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (editingRowIndex != entry.key)
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _editRow(tableIndex, entry.key);
                              },
                            ),
                          if (editingRowIndex == entry.key)
                            IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () async {
                                bool saved =
                                    await _saveRow(tableIndex, entry.key);
                                if (saved) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Saved')),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          DataRow(
            cells: [
              DataCell(Text('Total',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
              DataCell(Text('')),
              DataCell(Text(totalAmount.toStringAsFixed(2),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCell(
      bool enabled, String value, Function(String) onChanged, Color textColor) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));
    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: value,
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            style: TextStyle(color: textColor),
          )
        : Text(value, style: TextStyle(color: textColor));
  }

  String _getDayName(int index) {
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[index];
  }

  void _addTable() {
    setState(() {
      weeklySalesList.add(_initializeWeeklySales());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklySales() {
    List<List<String>> initialData = [];
    // Add initial row for each day of the week
    for (int i = 0; i < 7; i++) {
      initialData.add(['', '', '', '']);
    }
    return initialData;
  }

  void _editRow(int tableIndex, int rowIndex) {
    setState(() {
      editingTableIndex = tableIndex;
      editingRowIndex = rowIndex;
    });
  }

  Future<bool> _saveRow(int tableIndex, int rowIndex) async {
    setState(() {
      editingTableIndex = null;
      editingRowIndex = null;
    });
    List<List<String>> weeklySales = weeklySalesList[tableIndex];
    bool valid = _validateInputs(weeklySales[rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the modified row
      if (double.tryParse(weeklySales[rowIndex][2]) == null) {
        // Clear quantity if invalid
        weeklySales[rowIndex][2] = '';
      }
      if (double.tryParse(weeklySales[rowIndex][3]) == null) {
        // Clear amount if invalid
        weeklySales[rowIndex][3] = '';
      }
      await _saveData(); // Save modified row after clearing invalid inputs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid inputs cleared.'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return false;
    }
  }

  bool _validateInputs(List<String> inputs) {
    // Validate if the "Quantity" field contains only numbers
    bool isQuantityValid = double.tryParse(inputs[2]) != null;
    // Validate if the "Amount" field contains only numbers
    bool isAmountValid = double.tryParse(inputs[3]) != null;
    return isQuantityValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklySalesList.length;
    await prefs.setInt(
        'JulynumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklySalesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('JulyweeklySales$i', dataToSave);
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('JulynumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData = prefs.getStringList('JulyweeklySales$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
        developer.log('Saved table $i: $savedData');
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklySalesList = loadedData;
      });
    } else {
      setState(() {
        weeklySalesList = [_initializeWeeklySales()];
      });
    }
  }

  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Table'),
          content: Text('Are you sure you want to delete this table?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed != null && confirmed) {
        _deleteTable(index);
      }
    });
  }

  void _deleteTable(int index) {
    setState(() {
      weeklySalesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklySales) {
    return weeklySales.fold<double>(
        0, (total, entry) => total + (double.tryParse(entry[3]) ?? 0));
  }

  Future<void> _selectDate(
      BuildContext context, int tableIndex, int rowIndex) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        weeklySalesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class AugustSalesScreen extends StatefulWidget {
  const AugustSalesScreen({Key? key}) : super(key: key);

  @override
  _AugustSalesScreenState createState() => _AugustSalesScreenState();
}

class _AugustSalesScreenState extends State<AugustSalesScreen> {
  late List<List<List<String>>> weeklySalesList = [];
  int? editingTableIndex;
  int? editingRowIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final Color selectedColor =
        Provider.of<ColorProvider>(context).selectedColor;
    final bool isDarkBackground = selectedColor.computeLuminance() < 0.5;
    final Color textColor = isDarkBackground ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
        centerTitle: true,
        title: const Text('Weekly Sales Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Sales Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklySalesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(weeklySalesList[index], textColor, index),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteConfirmationDialog(index);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addTable,
              child: const Text('Add Table'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(
      List<List<String>> weeklySales, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklySales);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Quantity', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklySales.asMap().entries.map(
                (entry) => DataRow(
                  cells: [
                    DataCell(Text(_getDayName(entry.key),
                        style: TextStyle(color: textColor))),
                    DataCell(
                      InkWell(
                        onTap: () {
                          _selectDate(context, tableIndex, entry.key);
                        },
                        child: Text(
                          entry.value[1].isEmpty
                              ? 'select date'
                              : entry.value[1],
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[2],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][2] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[3],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][3] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (editingRowIndex != entry.key)
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _editRow(tableIndex, entry.key);
                              },
                            ),
                          if (editingRowIndex == entry.key)
                            IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () async {
                                bool saved =
                                    await _saveRow(tableIndex, entry.key);
                                if (saved) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Saved')),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          DataRow(
            cells: [
              DataCell(Text('Total',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
              DataCell(Text('')),
              DataCell(Text(totalAmount.toStringAsFixed(2),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCell(
      bool enabled, String value, Function(String) onChanged, Color textColor) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));
    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: value,
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            style: TextStyle(color: textColor),
          )
        : Text(value, style: TextStyle(color: textColor));
  }

  String _getDayName(int index) {
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[index];
  }

  void _addTable() {
    setState(() {
      weeklySalesList.add(_initializeWeeklySales());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklySales() {
    List<List<String>> initialData = [];
    // Add initial row for each day of the week
    for (int i = 0; i < 7; i++) {
      initialData.add(['', '', '', '']);
    }
    return initialData;
  }

  void _editRow(int tableIndex, int rowIndex) {
    setState(() {
      editingTableIndex = tableIndex;
      editingRowIndex = rowIndex;
    });
  }

  Future<bool> _saveRow(int tableIndex, int rowIndex) async {
    setState(() {
      editingTableIndex = null;
      editingRowIndex = null;
    });
    List<List<String>> weeklySales = weeklySalesList[tableIndex];
    bool valid = _validateInputs(weeklySales[rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the modified row
      if (double.tryParse(weeklySales[rowIndex][2]) == null) {
        // Clear quantity if invalid
        weeklySales[rowIndex][2] = '';
      }
      if (double.tryParse(weeklySales[rowIndex][3]) == null) {
        // Clear amount if invalid
        weeklySales[rowIndex][3] = '';
      }
      await _saveData(); // Save modified row after clearing invalid inputs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid inputs cleared.'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return false;
    }
  }

  bool _validateInputs(List<String> inputs) {
    // Validate if the "Quantity" field contains only numbers
    bool isQuantityValid = double.tryParse(inputs[2]) != null;
    // Validate if the "Amount" field contains only numbers
    bool isAmountValid = double.tryParse(inputs[3]) != null;
    return isQuantityValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklySalesList.length;
    await prefs.setInt(
        'AugustnumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklySalesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('AugustweeklySales$i', dataToSave);
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('AugustnumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData = prefs.getStringList('AugustweeklySales$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
        developer.log('Saved table $i: $savedData');
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklySalesList = loadedData;
      });
    } else {
      setState(() {
        weeklySalesList = [_initializeWeeklySales()];
      });
    }
  }

  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Table'),
          content: Text('Are you sure you want to delete this table?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed != null && confirmed) {
        _deleteTable(index);
      }
    });
  }

  void _deleteTable(int index) {
    setState(() {
      weeklySalesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklySales) {
    return weeklySales.fold<double>(
        0, (total, entry) => total + (double.tryParse(entry[3]) ?? 0));
  }

  Future<void> _selectDate(
      BuildContext context, int tableIndex, int rowIndex) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        weeklySalesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class SeptemberSalesScreen extends StatefulWidget {
  const SeptemberSalesScreen({Key? key}) : super(key: key);

  @override
  _SeptemberSalesScreenState createState() => _SeptemberSalesScreenState();
}

class _SeptemberSalesScreenState extends State<SeptemberSalesScreen> {
  late List<List<List<String>>> weeklySalesList = [];
  int? editingTableIndex;
  int? editingRowIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final Color selectedColor =
        Provider.of<ColorProvider>(context).selectedColor;
    final bool isDarkBackground = selectedColor.computeLuminance() < 0.5;
    final Color textColor = isDarkBackground ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
        centerTitle: true,
        title: const Text('Weekly Sales Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Sales Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklySalesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(weeklySalesList[index], textColor, index),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteConfirmationDialog(index);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addTable,
              child: const Text('Add Table'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(
      List<List<String>> weeklySales, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklySales);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Quantity', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklySales.asMap().entries.map(
                (entry) => DataRow(
                  cells: [
                    DataCell(Text(_getDayName(entry.key),
                        style: TextStyle(color: textColor))),
                    DataCell(
                      InkWell(
                        onTap: () {
                          _selectDate(context, tableIndex, entry.key);
                        },
                        child: Text(
                          entry.value[1].isEmpty
                              ? 'select date'
                              : entry.value[1],
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[2],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][2] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[3],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][3] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (editingRowIndex != entry.key)
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _editRow(tableIndex, entry.key);
                              },
                            ),
                          if (editingRowIndex == entry.key)
                            IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () async {
                                bool saved =
                                    await _saveRow(tableIndex, entry.key);
                                if (saved) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Saved')),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          DataRow(
            cells: [
              DataCell(Text('Total',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
              DataCell(Text('')),
              DataCell(Text(totalAmount.toStringAsFixed(2),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCell(
      bool enabled, String value, Function(String) onChanged, Color textColor) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));
    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: value,
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            style: TextStyle(color: textColor),
          )
        : Text(value, style: TextStyle(color: textColor));
  }

  String _getDayName(int index) {
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[index];
  }

  void _addTable() {
    setState(() {
      weeklySalesList.add(_initializeWeeklySales());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklySales() {
    List<List<String>> initialData = [];
    // Add initial row for each day of the week
    for (int i = 0; i < 7; i++) {
      initialData.add(['', '', '', '']);
    }
    return initialData;
  }

  void _editRow(int tableIndex, int rowIndex) {
    setState(() {
      editingTableIndex = tableIndex;
      editingRowIndex = rowIndex;
    });
  }

  Future<bool> _saveRow(int tableIndex, int rowIndex) async {
    setState(() {
      editingTableIndex = null;
      editingRowIndex = null;
    });
    List<List<String>> weeklySales = weeklySalesList[tableIndex];
    bool valid = _validateInputs(weeklySales[rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the modified row
      if (double.tryParse(weeklySales[rowIndex][2]) == null) {
        // Clear quantity if invalid
        weeklySales[rowIndex][2] = '';
      }
      if (double.tryParse(weeklySales[rowIndex][3]) == null) {
        // Clear amount if invalid
        weeklySales[rowIndex][3] = '';
      }
      await _saveData(); // Save modified row after clearing invalid inputs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid inputs cleared.'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return false;
    }
  }

  bool _validateInputs(List<String> inputs) {
    // Validate if the "Quantity" field contains only numbers
    bool isQuantityValid = double.tryParse(inputs[2]) != null;
    // Validate if the "Amount" field contains only numbers
    bool isAmountValid = double.tryParse(inputs[3]) != null;
    return isQuantityValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklySalesList.length;
    await prefs.setInt(
        'SeptembernumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklySalesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('SeptemberweeklySales$i', dataToSave);
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('SeptembernumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData = prefs.getStringList('SeptemberweeklySales$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
        developer.log('Saved table $i: $savedData');
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklySalesList = loadedData;
      });
    } else {
      setState(() {
        weeklySalesList = [_initializeWeeklySales()];
      });
    }
  }

  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Table'),
          content: Text('Are you sure you want to delete this table?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed != null && confirmed) {
        _deleteTable(index);
      }
    });
  }

  void _deleteTable(int index) {
    setState(() {
      weeklySalesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklySales) {
    return weeklySales.fold<double>(
        0, (total, entry) => total + (double.tryParse(entry[3]) ?? 0));
  }

  Future<void> _selectDate(
      BuildContext context, int tableIndex, int rowIndex) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        weeklySalesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class OctoberSalesScreen extends StatefulWidget {
  const OctoberSalesScreen({Key? key}) : super(key: key);

  @override
  _OctoberSalesScreenState createState() => _OctoberSalesScreenState();
}

class _OctoberSalesScreenState extends State<OctoberSalesScreen> {
  late List<List<List<String>>> weeklySalesList = [];
  int? editingTableIndex;
  int? editingRowIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final Color selectedColor =
        Provider.of<ColorProvider>(context).selectedColor;
    final bool isDarkBackground = selectedColor.computeLuminance() < 0.5;
    final Color textColor = isDarkBackground ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
        centerTitle: true,
        title: const Text('Weekly Sales Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Sales Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklySalesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(weeklySalesList[index], textColor, index),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteConfirmationDialog(index);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addTable,
              child: const Text('Add Table'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(
      List<List<String>> weeklySales, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklySales);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Quantity', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklySales.asMap().entries.map(
                (entry) => DataRow(
                  cells: [
                    DataCell(Text(_getDayName(entry.key),
                        style: TextStyle(color: textColor))),
                    DataCell(
                      InkWell(
                        onTap: () {
                          _selectDate(context, tableIndex, entry.key);
                        },
                        child: Text(
                          entry.value[1].isEmpty
                              ? 'select date'
                              : entry.value[1],
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[2],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][2] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[3],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][3] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (editingRowIndex != entry.key)
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _editRow(tableIndex, entry.key);
                              },
                            ),
                          if (editingRowIndex == entry.key)
                            IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () async {
                                bool saved =
                                    await _saveRow(tableIndex, entry.key);
                                if (saved) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Saved')),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          DataRow(
            cells: [
              DataCell(Text('Total',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
              DataCell(Text('')),
              DataCell(Text(totalAmount.toStringAsFixed(2),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCell(
      bool enabled, String value, Function(String) onChanged, Color textColor) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));
    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: value,
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            style: TextStyle(color: textColor),
          )
        : Text(value, style: TextStyle(color: textColor));
  }

  String _getDayName(int index) {
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[index];
  }

  void _addTable() {
    setState(() {
      weeklySalesList.add(_initializeWeeklySales());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklySales() {
    List<List<String>> initialData = [];
    // Add initial row for each day of the week
    for (int i = 0; i < 7; i++) {
      initialData.add(['', '', '', '']);
    }
    return initialData;
  }

  void _editRow(int tableIndex, int rowIndex) {
    setState(() {
      editingTableIndex = tableIndex;
      editingRowIndex = rowIndex;
    });
  }

  Future<bool> _saveRow(int tableIndex, int rowIndex) async {
    setState(() {
      editingTableIndex = null;
      editingRowIndex = null;
    });
    List<List<String>> weeklySales = weeklySalesList[tableIndex];
    bool valid = _validateInputs(weeklySales[rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the modified row
      if (double.tryParse(weeklySales[rowIndex][2]) == null) {
        // Clear quantity if invalid
        weeklySales[rowIndex][2] = '';
      }
      if (double.tryParse(weeklySales[rowIndex][3]) == null) {
        // Clear amount if invalid
        weeklySales[rowIndex][3] = '';
      }
      await _saveData(); // Save modified row after clearing invalid inputs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid inputs cleared.'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return false;
    }
  }

  bool _validateInputs(List<String> inputs) {
    // Validate if the "Quantity" field contains only numbers
    bool isQuantityValid = double.tryParse(inputs[2]) != null;
    // Validate if the "Amount" field contains only numbers
    bool isAmountValid = double.tryParse(inputs[3]) != null;
    return isQuantityValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklySalesList.length;
    await prefs.setInt(
        'OctobernumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklySalesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('OctoberweeklySales$i', dataToSave);
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('OctobernumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData = prefs.getStringList('OctoberweeklySales$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
        developer.log('Saved table $i: $savedData');
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklySalesList = loadedData;
      });
    } else {
      setState(() {
        weeklySalesList = [_initializeWeeklySales()];
      });
    }
  }

  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Table'),
          content: Text('Are you sure you want to delete this table?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed != null && confirmed) {
        _deleteTable(index);
      }
    });
  }

  void _deleteTable(int index) {
    setState(() {
      weeklySalesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklySales) {
    return weeklySales.fold<double>(
        0, (total, entry) => total + (double.tryParse(entry[3]) ?? 0));
  }

  Future<void> _selectDate(
      BuildContext context, int tableIndex, int rowIndex) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        weeklySalesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class NovemberSalesScreen extends StatefulWidget {
  const NovemberSalesScreen({Key? key}) : super(key: key);

  @override
  _NovemberSalesScreenState createState() => _NovemberSalesScreenState();
}

class _NovemberSalesScreenState extends State<NovemberSalesScreen> {
  late List<List<List<String>>> weeklySalesList = [];
  int? editingTableIndex;
  int? editingRowIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final Color selectedColor =
        Provider.of<ColorProvider>(context).selectedColor;
    final bool isDarkBackground = selectedColor.computeLuminance() < 0.5;
    final Color textColor = isDarkBackground ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
        centerTitle: true,
        title: const Text('Weekly Sales Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Sales Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklySalesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(weeklySalesList[index], textColor, index),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteConfirmationDialog(index);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addTable,
              child: const Text('Add Table'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(
      List<List<String>> weeklySales, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklySales);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Quantity', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklySales.asMap().entries.map(
                (entry) => DataRow(
                  cells: [
                    DataCell(Text(_getDayName(entry.key),
                        style: TextStyle(color: textColor))),
                    DataCell(
                      InkWell(
                        onTap: () {
                          _selectDate(context, tableIndex, entry.key);
                        },
                        child: Text(
                          entry.value[1].isEmpty
                              ? 'select date'
                              : entry.value[1],
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[2],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][2] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[3],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][3] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (editingRowIndex != entry.key)
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _editRow(tableIndex, entry.key);
                              },
                            ),
                          if (editingRowIndex == entry.key)
                            IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () async {
                                bool saved =
                                    await _saveRow(tableIndex, entry.key);
                                if (saved) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Saved')),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          DataRow(
            cells: [
              DataCell(Text('Total',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
              DataCell(Text('')),
              DataCell(Text(totalAmount.toStringAsFixed(2),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCell(
      bool enabled, String value, Function(String) onChanged, Color textColor) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));
    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: value,
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            style: TextStyle(color: textColor),
          )
        : Text(value, style: TextStyle(color: textColor));
  }

  String _getDayName(int index) {
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[index];
  }

  void _addTable() {
    setState(() {
      weeklySalesList.add(_initializeWeeklySales());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklySales() {
    List<List<String>> initialData = [];
    // Add initial row for each day of the week
    for (int i = 0; i < 7; i++) {
      initialData.add(['', '', '', '']);
    }
    return initialData;
  }

  void _editRow(int tableIndex, int rowIndex) {
    setState(() {
      editingTableIndex = tableIndex;
      editingRowIndex = rowIndex;
    });
  }

  Future<bool> _saveRow(int tableIndex, int rowIndex) async {
    setState(() {
      editingTableIndex = null;
      editingRowIndex = null;
    });
    List<List<String>> weeklySales = weeklySalesList[tableIndex];
    bool valid = _validateInputs(weeklySales[rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the modified row
      if (double.tryParse(weeklySales[rowIndex][2]) == null) {
        // Clear quantity if invalid
        weeklySales[rowIndex][2] = '';
      }
      if (double.tryParse(weeklySales[rowIndex][3]) == null) {
        // Clear amount if invalid
        weeklySales[rowIndex][3] = '';
      }
      await _saveData(); // Save modified row after clearing invalid inputs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid inputs cleared.'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return false;
    }
  }

  bool _validateInputs(List<String> inputs) {
    // Validate if the "Quantity" field contains only numbers
    bool isQuantityValid = double.tryParse(inputs[2]) != null;
    // Validate if the "Amount" field contains only numbers
    bool isAmountValid = double.tryParse(inputs[3]) != null;
    return isQuantityValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklySalesList.length;
    await prefs.setInt(
        'NovembernumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklySalesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('NovemberweeklySales$i', dataToSave);
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('NovembernumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData = prefs.getStringList('NovemberweeklySales$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
        developer.log('Saved table $i: $savedData');
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklySalesList = loadedData;
      });
    } else {
      setState(() {
        weeklySalesList = [_initializeWeeklySales()];
      });
    }
  }

  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Table'),
          content: Text('Are you sure you want to delete this table?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed != null && confirmed) {
        _deleteTable(index);
      }
    });
  }

  void _deleteTable(int index) {
    setState(() {
      weeklySalesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklySales) {
    return weeklySales.fold<double>(
        0, (total, entry) => total + (double.tryParse(entry[3]) ?? 0));
  }

  Future<void> _selectDate(
      BuildContext context, int tableIndex, int rowIndex) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        weeklySalesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class DecemberSalesScreen extends StatefulWidget {
  const DecemberSalesScreen({Key? key}) : super(key: key);

  @override
  _DecemberSalesScreenState createState() => _DecemberSalesScreenState();
}

class _DecemberSalesScreenState extends State<DecemberSalesScreen> {
  late List<List<List<String>>> weeklySalesList = [];
  int? editingTableIndex;
  int? editingRowIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final Color selectedColor =
        Provider.of<ColorProvider>(context).selectedColor;
    final bool isDarkBackground = selectedColor.computeLuminance() < 0.5;
    final Color textColor = isDarkBackground ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
        centerTitle: true,
        title: const Text('Weekly Sales Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Sales Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklySalesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(weeklySalesList[index], textColor, index),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showDeleteConfirmationDialog(index);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addTable,
              child: const Text('Add Table'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(
      List<List<String>> weeklySales, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklySales);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Quantity', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklySales.asMap().entries.map(
                (entry) => DataRow(
                  cells: [
                    DataCell(Text(_getDayName(entry.key),
                        style: TextStyle(color: textColor))),
                    DataCell(
                      InkWell(
                        onTap: () {
                          _selectDate(context, tableIndex, entry.key);
                        },
                        child: Text(
                          entry.value[1].isEmpty
                              ? 'select date'
                              : entry.value[1],
                          style: TextStyle(color: textColor),
                        ),
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[2],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][2] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      _buildEditableCell(
                        editingTableIndex == tableIndex &&
                            editingRowIndex == entry.key,
                        entry.value[3],
                        (value) {
                          setState(() {
                            weeklySales[entry.key][3] = value;
                          });
                        },
                        textColor,
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (editingRowIndex != entry.key)
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _editRow(tableIndex, entry.key);
                              },
                            ),
                          if (editingRowIndex == entry.key)
                            IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () async {
                                bool saved =
                                    await _saveRow(tableIndex, entry.key);
                                if (saved) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Saved')),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          DataRow(
            cells: [
              DataCell(Text('Total',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
              DataCell(Text('')),
              DataCell(Text(totalAmount.toStringAsFixed(2),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: textColor))),
              DataCell(Text('')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableCell(
      bool enabled, String value, Function(String) onChanged, Color textColor) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));
    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: value,
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            style: TextStyle(color: textColor),
          )
        : Text(value, style: TextStyle(color: textColor));
  }

  String _getDayName(int index) {
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    return days[index];
  }

  void _addTable() {
    setState(() {
      weeklySalesList.add(_initializeWeeklySales());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklySales() {
    List<List<String>> initialData = [];
    // Add initial row for each day of the week
    for (int i = 0; i < 7; i++) {
      initialData.add(['', '', '', '']);
    }
    return initialData;
  }

  void _editRow(int tableIndex, int rowIndex) {
    setState(() {
      editingTableIndex = tableIndex;
      editingRowIndex = rowIndex;
    });
  }

  Future<bool> _saveRow(int tableIndex, int rowIndex) async {
    setState(() {
      editingTableIndex = null;
      editingRowIndex = null;
    });
    List<List<String>> weeklySales = weeklySalesList[tableIndex];
    bool valid = _validateInputs(weeklySales[rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the modified row
      if (double.tryParse(weeklySales[rowIndex][2]) == null) {
        // Clear quantity if invalid
        weeklySales[rowIndex][2] = '';
      }
      if (double.tryParse(weeklySales[rowIndex][3]) == null) {
        // Clear amount if invalid
        weeklySales[rowIndex][3] = '';
      }
      await _saveData(); // Save modified row after clearing invalid inputs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid inputs cleared.'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      return false;
    }
  }

  bool _validateInputs(List<String> inputs) {
    // Validate if the "Quantity" field contains only numbers
    bool isQuantityValid = double.tryParse(inputs[2]) != null;
    // Validate if the "Amount" field contains only numbers
    bool isAmountValid = double.tryParse(inputs[3]) != null;
    return isQuantityValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklySalesList.length;
    await prefs.setInt(
        'DecembernumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklySalesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('DecemberweeklySales$i', dataToSave);
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('DecembernumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData = prefs.getStringList('DecemberweeklySales$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
        developer.log('Saved table $i: $savedData');
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklySalesList = loadedData;
      });
    } else {
      setState(() {
        weeklySalesList = [_initializeWeeklySales()];
      });
    }
  }

  void _showDeleteConfirmationDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Table'),
          content: Text('Are you sure you want to delete this table?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    ).then((confirmed) {
      if (confirmed != null && confirmed) {
        _deleteTable(index);
      }
    });
  }

  void _deleteTable(int index) {
    setState(() {
      weeklySalesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklySales) {
    return weeklySales.fold<double>(
        0, (total, entry) => total + (double.tryParse(entry[3]) ?? 0));
  }

  Future<void> _selectDate(
      BuildContext context, int tableIndex, int rowIndex) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        weeklySalesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class WeeklySalesRecordsPage extends StatelessWidget {
  const WeeklySalesRecordsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey, // Set app bar color to gray
        title: Text('Weekly Sales Records'),
      ),
      body: ListView.builder(
        itemCount: 12,
        itemBuilder: (BuildContext context, int index) {
          final month = index + 1;
          final backgroundColor =
              index % 2 == 0 ? Colors.grey.shade300 : Colors.grey.shade300;
          return Padding(
            padding: EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 16.0), // Add padding around each list item
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(
                    color: Colors.black,
                    width: 2.0), // Make the border more visible
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: ListTile(
                title: Center(
                  child: Text(
                    _getMonthName(month),
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                onTap: () {
                  // Navigate to the corresponding screen for the tapped month
                  switch (month) {
                    case 1:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const JanuarySalesScreen()),
                      );
                      break;
                    case 2:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const FebuarySalesScreen()),
                      );
                      break;
                    case 3:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MarchSalesScreen()),
                      );
                      break;
                    case 4:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AprilSalesScreen()),
                      );
                      break;
                    case 5:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MaySalesScreen()),
                      );
                      break;
                    case 6:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const JuneSalesScreen()),
                      );
                      break;
                    case 7:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const JulySalesScreen()),
                      );
                      break;
                    case 8:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AugustSalesScreen()),
                      );
                      break;
                    case 9:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SeptemberSalesScreen()),
                      );
                      break;
                    case 10:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const OctoberSalesScreen()),
                      );
                      break;
                    case 11:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NovemberSalesScreen()),
                      );
                      break;
                    case 12:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const DecemberSalesScreen()),
                      );
                      break;
                    // Add cases for other months similarly
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }
}

void main() {
  runApp(MaterialApp(
    home: WeeklySalesRecordsPage(),
  ));
}
