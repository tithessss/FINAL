import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:LuckyEgg/color_provider.dart';
import 'dart:developer' as developer;

class JanuaryExpensesScreen extends StatefulWidget {
  const JanuaryExpensesScreen({Key? key}) : super(key: key);

  @override
  _JanuaryExpensesScreenState createState() => _JanuaryExpensesScreenState();
}

class _JanuaryExpensesScreenState extends State<JanuaryExpensesScreen> {
  late List<List<List<String>>> weeklyExpensesList = [];
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
        title: const Text('Weekly Expenses Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Expenses Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklyExpensesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(
                          weeklyExpensesList[index], textColor, index),
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
    List<List<String>> weeklyExpenses, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklyExpenses);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Reason', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklyExpenses.asMap().entries.map(
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
                              ? 'Tap to select date'
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
                            weeklyExpenses[entry.key][2] = value;
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
                            weeklyExpenses[entry.key][3] = value;
                          });
                        },
                        textColor,
                        isNumeric: true, // Specify this cell should be numeric
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
      bool enabled, String value, Function(String) onChanged, Color textColor,
      {bool isNumeric = false}) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));

    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            textAlign: TextAlign.start, // Align text input to the start
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
      weeklyExpensesList.add(_initializeWeeklyExpenses());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklyExpenses() {
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
    bool valid = _validateInputs(weeklyExpensesList[tableIndex][rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the cleared data
      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(weeklyExpensesList[tableIndex][rowIndex][2])) {
        weeklyExpensesList[tableIndex][rowIndex][2] =''; // Clear reason if invalid
      }
      if (!RegExp(r'^\d+$').hasMatch(weeklyExpensesList[tableIndex][rowIndex][3])) {
        weeklyExpensesList[tableIndex][rowIndex][3] =''; // Clear amount if invalid
      }
      await _saveData(); // Save cleared data
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
    // Validate if the "Reason" field contains only letters (a-z or A-Z)
    bool isReasonValid = RegExp(r'^[a-zA-Z\s]+$').hasMatch(inputs[2]);
    // Validate if the "Amount" field contains only numbers (0-9)
    bool isAmountValid = RegExp(r'^\d+$').hasMatch(inputs[3]);
    return isReasonValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklyExpensesList.length;
    await prefs.setInt(
        'JanuarynumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklyExpensesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('JanuaryweeklyExpenses$i', dataToSave);
      // Log each table's data
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('JanuarynumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData = prefs.getStringList('JanuaryweeklyExpenses$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
        // Log each table's data
        developer.log('Loaded table $i: $savedData');
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklyExpensesList = loadedData;
      });
    } else {
      setState(() {
        weeklyExpensesList = [_initializeWeeklyExpenses()];
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
      weeklyExpensesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklyExpenses) {
    return weeklyExpenses.fold<double>(0, (total, entry) => total + (double.tryParse(entry[3]) ?? 0));
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
        weeklyExpensesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class FebuaryExpensesScreen extends StatefulWidget {
  const FebuaryExpensesScreen({Key? key}) : super(key: key);

  @override
  _FebuaryExpensesScreenState createState() => _FebuaryExpensesScreenState();
}

class _FebuaryExpensesScreenState extends State<FebuaryExpensesScreen> {
  late List<List<List<String>>> weeklyExpensesList = [];
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
        title: const Text('Weekly Expenses Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Expenses Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklyExpensesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(
                          weeklyExpensesList[index], textColor, index),
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
      List<List<String>> weeklyExpenses, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklyExpenses);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Reason', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklyExpenses.asMap().entries.map(
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
                              ? 'Tap to select date'
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
                            weeklyExpenses[entry.key][2] = value;
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
                            weeklyExpenses[entry.key][3] = value;
                          });
                        },
                        textColor,
                        isNumeric: true, // Specify this cell should be numeric
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
      bool enabled, String value, Function(String) onChanged, Color textColor,
      {bool isNumeric = false}) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));

    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            textAlign: TextAlign.start, // Align text input to the start
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
      weeklyExpensesList.add(_initializeWeeklyExpenses());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklyExpenses() {
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
    bool valid = _validateInputs(weeklyExpensesList[tableIndex][rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the cleared data
      if (!RegExp(r'^[a-zA-Z\s]+$')
          .hasMatch(weeklyExpensesList[tableIndex][rowIndex][2])) {
        weeklyExpensesList[tableIndex][rowIndex][2] =
            ''; // Clear reason if invalid
      }
      if (!RegExp(r'^\d+$')
          .hasMatch(weeklyExpensesList[tableIndex][rowIndex][3])) {
        weeklyExpensesList[tableIndex][rowIndex][3] =
            ''; // Clear amount if invalid
      }
      await _saveData(); // Save cleared data
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
    // Validate if the "Reason" field contains only letters (a-z or A-Z)
    bool isReasonValid = RegExp(r'^[a-zA-Z\s]+$').hasMatch(inputs[2]);
    // Validate if the "Amount" field contains only numbers (0-9)
    bool isAmountValid = RegExp(r'^\d+$').hasMatch(inputs[3]);
    return isReasonValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklyExpensesList.length;
    await prefs.setInt(
        'FebuarynumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklyExpensesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('FebuaryweeklyExpenses$i', dataToSave);
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('FebuarynumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData = prefs.getStringList('FebuaryweeklyExpenses$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
        developer.log('Loaded table $i: $savedData');
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklyExpensesList = loadedData;
      });
    } else {
      setState(() {
        weeklyExpensesList = [_initializeWeeklyExpenses()];
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
      weeklyExpensesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklyExpenses) {
    return weeklyExpenses.fold<double>(
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
        weeklyExpensesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class MarchExpensesScreen extends StatefulWidget {
  const MarchExpensesScreen({Key? key}) : super(key: key);

  @override
  _MarchExpensesScreenState createState() => _MarchExpensesScreenState();
}

class _MarchExpensesScreenState extends State<MarchExpensesScreen> {
  late List<List<List<String>>> weeklyExpensesList = [];
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
        title: const Text('Weekly Expenses Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Expenses Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklyExpensesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(
                          weeklyExpensesList[index], textColor, index),
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
      List<List<String>> weeklyExpenses, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklyExpenses);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Reason', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklyExpenses.asMap().entries.map(
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
                              ? 'Tap to select date'
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
                            weeklyExpenses[entry.key][2] = value;
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
                            weeklyExpenses[entry.key][3] = value;
                          });
                        },
                        textColor,
                        isNumeric: true, // Specify this cell should be numeric
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
      bool enabled, String value, Function(String) onChanged, Color textColor,
      {bool isNumeric = false}) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));

    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            textAlign: TextAlign.start, // Align text input to the start
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
      weeklyExpensesList.add(_initializeWeeklyExpenses());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklyExpenses() {
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
    bool valid = _validateInputs(weeklyExpensesList[tableIndex][rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the cleared data
      if (!RegExp(r'^[a-zA-Z\s]+$')
          .hasMatch(weeklyExpensesList[tableIndex][rowIndex][2])) {
        weeklyExpensesList[tableIndex][rowIndex][2] =
            ''; // Clear reason if invalid
      }
      if (!RegExp(r'^\d+$')
          .hasMatch(weeklyExpensesList[tableIndex][rowIndex][3])) {
        weeklyExpensesList[tableIndex][rowIndex][3] =
            ''; // Clear amount if invalid
      }
      await _saveData(); // Save cleared data
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
    // Validate if the "Reason" field contains only letters (a-z or A-Z)
    bool isReasonValid = RegExp(r'^[a-zA-Z\s]+$').hasMatch(inputs[2]);
    // Validate if the "Amount" field contains only numbers (0-9)
    bool isAmountValid = RegExp(r'^\d+$').hasMatch(inputs[3]);
    return isReasonValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklyExpensesList.length;
    await prefs.setInt(
        'MarchnumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklyExpensesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('MarchweeklyExpenses$i', dataToSave);
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('MarchnumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData = prefs.getStringList('MarchweeklyExpenses$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
        developer.log('Saved table $i: $savedData');
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklyExpensesList = loadedData;
      });
    } else {
      setState(() {
        weeklyExpensesList = [_initializeWeeklyExpenses()];
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
      weeklyExpensesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklyExpenses) {
    return weeklyExpenses.fold<double>(
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
        weeklyExpensesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class AprilExpensesScreen extends StatefulWidget {
  const AprilExpensesScreen({Key? key}) : super(key: key);

  @override
  _AprilExpensesScreenState createState() => _AprilExpensesScreenState();
}

class _AprilExpensesScreenState extends State<AprilExpensesScreen> {
  late List<List<List<String>>> weeklyExpensesList = [];
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
        title: const Text('Weekly Expenses Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Expenses Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklyExpensesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(
                          weeklyExpensesList[index], textColor, index),
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
      List<List<String>> weeklyExpenses, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklyExpenses);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Reason', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklyExpenses.asMap().entries.map(
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
                              ? 'Tap to select date'
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
                            weeklyExpenses[entry.key][2] = value;
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
                            weeklyExpenses[entry.key][3] = value;
                          });
                        },
                        textColor,
                        isNumeric: true, // Specify this cell should be numeric
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
      bool enabled, String value, Function(String) onChanged, Color textColor,
      {bool isNumeric = false}) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));

    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            textAlign: TextAlign.start, // Align text input to the start
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
      weeklyExpensesList.add(_initializeWeeklyExpenses());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklyExpenses() {
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
    bool valid = _validateInputs(weeklyExpensesList[tableIndex][rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the cleared data
      if (!RegExp(r'^[a-zA-Z\s]+$')
          .hasMatch(weeklyExpensesList[tableIndex][rowIndex][2])) {
        weeklyExpensesList[tableIndex][rowIndex][2] =
            ''; // Clear reason if invalid
      }
      if (!RegExp(r'^\d+$')
          .hasMatch(weeklyExpensesList[tableIndex][rowIndex][3])) {
        weeklyExpensesList[tableIndex][rowIndex][3] =
            ''; // Clear amount if invalid
      }
      await _saveData(); // Save cleared data
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
    // Validate if the "Reason" field contains only letters (a-z or A-Z)
    bool isReasonValid = RegExp(r'^[a-zA-Z\s]+$').hasMatch(inputs[2]);
    // Validate if the "Amount" field contains only numbers (0-9)
    bool isAmountValid = RegExp(r'^\d+$').hasMatch(inputs[3]);
    return isReasonValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklyExpensesList.length;
    await prefs.setInt(
        'AprilnumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklyExpensesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('AprilweeklyExpenses$i', dataToSave);
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('AprilnumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData = prefs.getStringList('AprilweeklyExpenses$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
        developer.log('Saved table $i: $savedData');
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklyExpensesList = loadedData;
      });
    } else {
      setState(() {
        weeklyExpensesList = [_initializeWeeklyExpenses()];
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
      weeklyExpensesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklyExpenses) {
    return weeklyExpenses.fold<double>(
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
        weeklyExpensesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class MayExpensesScreen extends StatefulWidget {
  const MayExpensesScreen({Key? key}) : super(key: key);

  @override
  _MayExpensesScreenState createState() => _MayExpensesScreenState();
}

class _MayExpensesScreenState extends State<MayExpensesScreen> {
  late List<List<List<String>>> weeklyExpensesList = [];
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
        title: const Text('Weekly Expenses Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Expenses Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklyExpensesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(
                          weeklyExpensesList[index], textColor, index),
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
      List<List<String>> weeklyExpenses, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklyExpenses);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Reason', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklyExpenses.asMap().entries.map(
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
                              ? 'Tap to select date'
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
                            weeklyExpenses[entry.key][2] = value;
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
                            weeklyExpenses[entry.key][3] = value;
                          });
                        },
                        textColor,
                        isNumeric: true, // Specify this cell should be numeric
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
      bool enabled, String value, Function(String) onChanged, Color textColor,
      {bool isNumeric = false}) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));

    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            textAlign: TextAlign.start, // Align text input to the start
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
      weeklyExpensesList.add(_initializeWeeklyExpenses());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklyExpenses() {
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
    bool valid = _validateInputs(weeklyExpensesList[tableIndex][rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the cleared data
      if (!RegExp(r'^[a-zA-Z\s]+$')
          .hasMatch(weeklyExpensesList[tableIndex][rowIndex][2])) {
        weeklyExpensesList[tableIndex][rowIndex][2] =
            ''; // Clear reason if invalid
      }
      if (!RegExp(r'^\d+$')
          .hasMatch(weeklyExpensesList[tableIndex][rowIndex][3])) {
        weeklyExpensesList[tableIndex][rowIndex][3] =
            ''; // Clear amount if invalid
      }
      await _saveData(); // Save cleared data
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
    // Validate if the "Reason" field contains only letters (a-z or A-Z)
    bool isReasonValid = RegExp(r'^[a-zA-Z\s]+$').hasMatch(inputs[2]);
    // Validate if the "Amount" field contains only numbers (0-9)
    bool isAmountValid = RegExp(r'^\d+$').hasMatch(inputs[3]);
    return isReasonValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklyExpensesList.length;
    await prefs.setInt(
        'MaynumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklyExpensesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('MayweeklyExpenses$i', dataToSave);
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('MaynumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData = prefs.getStringList('MayweeklyExpenses$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
        developer.log('Saved table $i: $savedData');
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklyExpensesList = loadedData;
      });
    } else {
      setState(() {
        weeklyExpensesList = [_initializeWeeklyExpenses()];
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
      weeklyExpensesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklyExpenses) {
    return weeklyExpenses.fold<double>(
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
        weeklyExpensesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class JuneExpensesScreen extends StatefulWidget {
  const JuneExpensesScreen({Key? key}) : super(key: key);

  @override
  _JuneExpensesScreenState createState() => _JuneExpensesScreenState();
}

class _JuneExpensesScreenState extends State<JuneExpensesScreen> {
  late List<List<List<String>>> weeklyExpensesList = [];
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
        title: const Text('Weekly Expenses Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Expenses Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklyExpensesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(
                          weeklyExpensesList[index], textColor, index),
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
      List<List<String>> weeklyExpenses, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklyExpenses);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Reason', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklyExpenses.asMap().entries.map(
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
                              ? 'Tap to select date'
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
                            weeklyExpenses[entry.key][2] = value;
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
                            weeklyExpenses[entry.key][3] = value;
                          });
                        },
                        textColor,
                        isNumeric: true, // Specify this cell should be numeric
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
      bool enabled, String value, Function(String) onChanged, Color textColor,
      {bool isNumeric = false}) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));

    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            textAlign: TextAlign.start, // Align text input to the start
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
      weeklyExpensesList.add(_initializeWeeklyExpenses());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklyExpenses() {
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
    bool valid = _validateInputs(weeklyExpensesList[tableIndex][rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the cleared data
      if (!RegExp(r'^[a-zA-Z\s]+$')
          .hasMatch(weeklyExpensesList[tableIndex][rowIndex][2])) {
        weeklyExpensesList[tableIndex][rowIndex][2] =
            ''; // Clear reason if invalid
      }
      if (!RegExp(r'^\d+$')
          .hasMatch(weeklyExpensesList[tableIndex][rowIndex][3])) {
        weeklyExpensesList[tableIndex][rowIndex][3] =
            ''; // Clear amount if invalid
      }
      await _saveData(); // Save cleared data
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
    // Validate if the "Reason" field contains only letters (a-z or A-Z)
    bool isReasonValid = RegExp(r'^[a-zA-Z\s]+$').hasMatch(inputs[2]);
    // Validate if the "Amount" field contains only numbers (0-9)
    bool isAmountValid = RegExp(r'^\d+$').hasMatch(inputs[3]);
    return isReasonValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklyExpensesList.length;
    await prefs.setInt(
        'JunenumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklyExpensesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('JuneweeklyExpenses$i', dataToSave);
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('JunenumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData = prefs.getStringList('JuneweeklyExpenses$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
        developer.log('Saved table $i: $savedData');
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklyExpensesList = loadedData;
      });
    } else {
      setState(() {
        weeklyExpensesList = [_initializeWeeklyExpenses()];
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
      weeklyExpensesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklyExpenses) {
    return weeklyExpenses.fold<double>(
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
        weeklyExpensesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class JulyExpensesScreen extends StatefulWidget {
  const JulyExpensesScreen({Key? key}) : super(key: key);

  @override
  _JulyExpensesScreenState createState() => _JulyExpensesScreenState();
}

class _JulyExpensesScreenState extends State<JulyExpensesScreen> {
  late List<List<List<String>>> weeklyExpensesList = [];
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
        title: const Text('Weekly Expenses Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Expenses Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklyExpensesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(
                          weeklyExpensesList[index], textColor, index),
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
      List<List<String>> weeklyExpenses, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklyExpenses);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Reason', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklyExpenses.asMap().entries.map(
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
                              ? 'Tap to select date'
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
                            weeklyExpenses[entry.key][2] = value;
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
                            weeklyExpenses[entry.key][3] = value;
                          });
                        },
                        textColor,
                        isNumeric: true, // Specify this cell should be numeric
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
      bool enabled, String value, Function(String) onChanged, Color textColor,
      {bool isNumeric = false}) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));

    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            textAlign: TextAlign.start, // Align text input to the start
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
      weeklyExpensesList.add(_initializeWeeklyExpenses());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklyExpenses() {
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
    bool valid = _validateInputs(weeklyExpensesList[tableIndex][rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the cleared data
      if (!RegExp(r'^[a-zA-Z\s]+$')
          .hasMatch(weeklyExpensesList[tableIndex][rowIndex][2])) {
        weeklyExpensesList[tableIndex][rowIndex][2] =
            ''; // Clear reason if invalid
      }
      if (!RegExp(r'^\d+$')
          .hasMatch(weeklyExpensesList[tableIndex][rowIndex][3])) {
        weeklyExpensesList[tableIndex][rowIndex][3] =
            ''; // Clear amount if invalid
      }
      await _saveData(); // Save cleared data
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
    // Validate if the "Reason" field contains only letters (a-z or A-Z)
    bool isReasonValid = RegExp(r'^[a-zA-Z\s]+$').hasMatch(inputs[2]);
    // Validate if the "Amount" field contains only numbers (0-9)
    bool isAmountValid = RegExp(r'^\d+$').hasMatch(inputs[3]);
    return isReasonValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklyExpensesList.length;
    await prefs.setInt(
        'JulynumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklyExpensesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('JulyweeklyExpenses$i', dataToSave);
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('JulynumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData = prefs.getStringList('JulyweeklyExpenses$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
        developer.log('Saved table $i: $savedData');
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklyExpensesList = loadedData;
      });
    } else {
      setState(() {
        weeklyExpensesList = [_initializeWeeklyExpenses()];
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
      weeklyExpensesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklyExpenses) {
    return weeklyExpenses.fold<double>(
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
        weeklyExpensesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class AugustExpensesScreen extends StatefulWidget {
  const AugustExpensesScreen({Key? key}) : super(key: key);

  @override
  _AugustExpensesScreenState createState() => _AugustExpensesScreenState();
}

class _AugustExpensesScreenState extends State<AugustExpensesScreen> {
  late List<List<List<String>>> weeklyExpensesList = [];
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
        title: const Text('Weekly Expenses Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Expenses Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklyExpensesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(
                          weeklyExpensesList[index], textColor, index),
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
      List<List<String>> weeklyExpenses, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklyExpenses);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Reason', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklyExpenses.asMap().entries.map(
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
                              ? 'Tap to select date'
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
                            weeklyExpenses[entry.key][2] = value;
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
                            weeklyExpenses[entry.key][3] = value;
                          });
                        },
                        textColor,
                        isNumeric: true, // Specify this cell should be numeric
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
      bool enabled, String value, Function(String) onChanged, Color textColor,
      {bool isNumeric = false}) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));

    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            textAlign: TextAlign.start, // Align text input to the start
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
      weeklyExpensesList.add(_initializeWeeklyExpenses());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklyExpenses() {
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
    bool valid = _validateInputs(weeklyExpensesList[tableIndex][rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the cleared data
      if (!RegExp(r'^[a-zA-Z\s]+$')
          .hasMatch(weeklyExpensesList[tableIndex][rowIndex][2])) {
        weeklyExpensesList[tableIndex][rowIndex][2] =
            ''; // Clear reason if invalid
      }
      if (!RegExp(r'^\d+$')
          .hasMatch(weeklyExpensesList[tableIndex][rowIndex][3])) {
        weeklyExpensesList[tableIndex][rowIndex][3] =
            ''; // Clear amount if invalid
      }
      await _saveData(); // Save cleared data
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
    // Validate if the "Reason" field contains only letters (a-z or A-Z)
    bool isReasonValid = RegExp(r'^[a-zA-Z\s]+$').hasMatch(inputs[2]);
    // Validate if the "Amount" field contains only numbers (0-9)
    bool isAmountValid = RegExp(r'^\d+$').hasMatch(inputs[3]);
    return isReasonValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklyExpensesList.length;
    await prefs.setInt(
        'AugustnumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklyExpensesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('AugustweeklyExpenses$i', dataToSave);
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('AugustnumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData = prefs.getStringList('AugustweeklyExpenses$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
        developer.log('Saved table $i: $savedData');
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklyExpensesList = loadedData;
      });
    } else {
      setState(() {
        weeklyExpensesList = [_initializeWeeklyExpenses()];
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
      weeklyExpensesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklyExpenses) {
    return weeklyExpenses.fold<double>(
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
        weeklyExpensesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class SeptemberExpensesScreen extends StatefulWidget {
  const SeptemberExpensesScreen({Key? key}) : super(key: key);

  @override
  _SeptemberExpensesScreenState createState() =>
      _SeptemberExpensesScreenState();
}

class _SeptemberExpensesScreenState extends State<SeptemberExpensesScreen> {
  late List<List<List<String>>> weeklyExpensesList = [];
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
        title: const Text('Weekly Expenses Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Expenses Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklyExpensesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(
                          weeklyExpensesList[index], textColor, index),
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
      List<List<String>> weeklyExpenses, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklyExpenses);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Reason', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklyExpenses.asMap().entries.map(
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
                              ? 'Tap to select date'
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
                            weeklyExpenses[entry.key][2] = value;
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
                            weeklyExpenses[entry.key][3] = value;
                          });
                        },
                        textColor,
                        isNumeric: true, // Specify this cell should be numeric
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
      bool enabled, String value, Function(String) onChanged, Color textColor,
      {bool isNumeric = false}) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));

    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            textAlign: TextAlign.start, // Align text input to the start
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
      weeklyExpensesList.add(_initializeWeeklyExpenses());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklyExpenses() {
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
    bool valid = _validateInputs(weeklyExpensesList[tableIndex][rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the cleared data
      if (!RegExp(r'^[a-zA-Z\s]+$')
          .hasMatch(weeklyExpensesList[tableIndex][rowIndex][2])) {
        weeklyExpensesList[tableIndex][rowIndex][2] =
            ''; // Clear reason if invalid
      }
      if (!RegExp(r'^\d+$')
          .hasMatch(weeklyExpensesList[tableIndex][rowIndex][3])) {
        weeklyExpensesList[tableIndex][rowIndex][3] =
            ''; // Clear amount if invalid
      }
      await _saveData(); // Save cleared data
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
    // Validate if the "Reason" field contains only letters (a-z or A-Z)
    bool isReasonValid = RegExp(r'^[a-zA-Z\s]+$').hasMatch(inputs[2]);
    // Validate if the "Amount" field contains only numbers (0-9)
    bool isAmountValid = RegExp(r'^\d+$').hasMatch(inputs[3]);
    return isReasonValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklyExpensesList.length;
    await prefs.setInt(
        'SeptembernumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklyExpensesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('SeptemberweeklyExpenses$i', dataToSave);
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('SeptembernumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData =
          prefs.getStringList('SeptemberweeklyExpenses$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
        developer.log('Saved table $i: $savedData');
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklyExpensesList = loadedData;
      });
    } else {
      setState(() {
        weeklyExpensesList = [_initializeWeeklyExpenses()];
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
      weeklyExpensesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklyExpenses) {
    return weeklyExpenses.fold<double>(
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
        weeklyExpensesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class OctoberExpensesScreen extends StatefulWidget {
  const OctoberExpensesScreen({Key? key}) : super(key: key);

  @override
  _OctoberExpensesScreenState createState() => _OctoberExpensesScreenState();
}

class _OctoberExpensesScreenState extends State<OctoberExpensesScreen> {
  late List<List<List<String>>> weeklyExpensesList = [];
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
        title: const Text('Weekly Expenses Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Expenses Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklyExpensesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(
                          weeklyExpensesList[index], textColor, index),
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
      List<List<String>> weeklyExpenses, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklyExpenses);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Reason', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklyExpenses.asMap().entries.map(
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
                              ? 'Tap to select date'
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
                            weeklyExpenses[entry.key][2] = value;
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
                            weeklyExpenses[entry.key][3] = value;
                          });
                        },
                        textColor,
                        isNumeric: true, // Specify this cell should be numeric
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
      bool enabled, String value, Function(String) onChanged, Color textColor,
      {bool isNumeric = false}) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));

    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            textAlign: TextAlign.start, // Align text input to the start
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
      weeklyExpensesList.add(_initializeWeeklyExpenses());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklyExpenses() {
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
    bool valid = _validateInputs(weeklyExpensesList[tableIndex][rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the cleared data
      if (!RegExp(r'^[a-zA-Z\s]+$')
          .hasMatch(weeklyExpensesList[tableIndex][rowIndex][2])) {
        weeklyExpensesList[tableIndex][rowIndex][2] =
            ''; // Clear reason if invalid
      }
      if (!RegExp(r'^\d+$')
          .hasMatch(weeklyExpensesList[tableIndex][rowIndex][3])) {
        weeklyExpensesList[tableIndex][rowIndex][3] =
            ''; // Clear amount if invalid
      }
      await _saveData(); // Save cleared data
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
    // Validate if the "Reason" field contains only letters (a-z or A-Z)
    bool isReasonValid = RegExp(r'^[a-zA-Z\s]+$').hasMatch(inputs[2]);
    // Validate if the "Amount" field contains only numbers (0-9)
    bool isAmountValid = RegExp(r'^\d+$').hasMatch(inputs[3]);
    return isReasonValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklyExpensesList.length;
    await prefs.setInt(
        'OctobernumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklyExpensesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('OctoberweeklyExpenses$i', dataToSave);
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('OctobernumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData = prefs.getStringList('OctoberweeklyExpenses$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
        developer.log('Saved table $i: $savedData');
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklyExpensesList = loadedData;
      });
    } else {
      setState(() {
        weeklyExpensesList = [_initializeWeeklyExpenses()];
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
      weeklyExpensesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklyExpenses) {
    return weeklyExpenses.fold<double>(
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
        weeklyExpensesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class NovemberExpensesScreen extends StatefulWidget {
  const NovemberExpensesScreen({Key? key}) : super(key: key);

  @override
  _NovemberExpensesScreenState createState() => _NovemberExpensesScreenState();
}

class _NovemberExpensesScreenState extends State<NovemberExpensesScreen> {
  late List<List<List<String>>> weeklyExpensesList = [];
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
        title: const Text('Weekly Expenses Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Expenses Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklyExpensesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(
                          weeklyExpensesList[index], textColor, index),
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
      List<List<String>> weeklyExpenses, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklyExpenses);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Reason', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklyExpenses.asMap().entries.map(
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
                              ? 'Tap to select date'
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
                            weeklyExpenses[entry.key][2] = value;
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
                            weeklyExpenses[entry.key][3] = value;
                          });
                        },
                        textColor,
                        isNumeric: true, // Specify this cell should be numeric
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
      bool enabled, String value, Function(String) onChanged, Color textColor,
      {bool isNumeric = false}) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));

    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            textAlign: TextAlign.start, // Align text input to the start
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
      weeklyExpensesList.add(_initializeWeeklyExpenses());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklyExpenses() {
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
    bool valid = _validateInputs(weeklyExpensesList[tableIndex][rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the cleared data
      if (!RegExp(r'^[a-zA-Z\s]+$')
          .hasMatch(weeklyExpensesList[tableIndex][rowIndex][2])) {
        weeklyExpensesList[tableIndex][rowIndex][2] =
            ''; // Clear reason if invalid
      }
      if (!RegExp(r'^\d+$')
          .hasMatch(weeklyExpensesList[tableIndex][rowIndex][3])) {
        weeklyExpensesList[tableIndex][rowIndex][3] =
            ''; // Clear amount if invalid
      }
      await _saveData(); // Save cleared data
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
    // Validate if the "Reason" field contains only letters (a-z or A-Z)
    bool isReasonValid = RegExp(r'^[a-zA-Z\s]+$').hasMatch(inputs[2]);
    // Validate if the "Amount" field contains only numbers (0-9)
    bool isAmountValid = RegExp(r'^\d+$').hasMatch(inputs[3]);
    return isReasonValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklyExpensesList.length;
    await prefs.setInt(
        'NovemernumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklyExpensesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('NovemberweeklyExpenses$i', dataToSave);
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('NovembernumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData = prefs.getStringList('NovemberweeklyExpenses$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
        developer.log('Saved table $i: $savedData');
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklyExpensesList = loadedData;
      });
    } else {
      setState(() {
        weeklyExpensesList = [_initializeWeeklyExpenses()];
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
      weeklyExpensesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklyExpenses) {
    return weeklyExpenses.fold<double>(
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
        weeklyExpensesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class DecemberExpensesScreen extends StatefulWidget {
  const DecemberExpensesScreen({Key? key}) : super(key: key);

  @override
  _DecemberExpensesScreenState createState() => _DecemberExpensesScreenState();
}

class _DecemberExpensesScreenState extends State<DecemberExpensesScreen> {
  late List<List<List<String>>> weeklyExpensesList = [];
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
        title: const Text('Weekly Expenses Records'),
      ),
      backgroundColor: selectedColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Weekly Expenses Tables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: weeklyExpensesList.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      _buildDataTable(
                          weeklyExpensesList[index], textColor, index),
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
      List<List<String>> weeklyExpenses, Color textColor, int tableIndex) {
    double totalAmount = _calculateTotalAmount(weeklyExpenses);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Day', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Date', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Reason', style: TextStyle(color: textColor))),
          DataColumn(label: Text('Amount', style: TextStyle(color: textColor))),
          DataColumn(
              label: Text('Actions', style: TextStyle(color: textColor))),
        ],
        rows: [
          ...weeklyExpenses.asMap().entries.map(
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
                              ? 'Tap to select date'
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
                            weeklyExpenses[entry.key][2] = value;
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
                            weeklyExpenses[entry.key][3] = value;
                          });
                        },
                        textColor,
                        isNumeric: true, // Specify this cell should be numeric
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
      bool enabled, String value, Function(String) onChanged, Color textColor,
      {bool isNumeric = false}) {
    final TextEditingController controller = TextEditingController(text: value);
    controller.selection =
        TextSelection.fromPosition(TextPosition(offset: value.length));

    return enabled
        ? TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintStyle: TextStyle(color: textColor),
            ),
            textAlign: TextAlign.start, // Align text input to the start
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
      weeklyExpensesList.add(_initializeWeeklyExpenses());
    });
    _saveData(); // Save data when a new table is added
  }

  List<List<String>> _initializeWeeklyExpenses() {
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
    bool valid = _validateInputs(weeklyExpensesList[tableIndex][rowIndex]);
    if (valid) {
      await _saveData(); // Save data when a row is saved
      return true;
    } else {
      // Clear invalid inputs and save the cleared data
      if (!RegExp(r'^[a-zA-Z\s]+$')
          .hasMatch(weeklyExpensesList[tableIndex][rowIndex][2])) {
        weeklyExpensesList[tableIndex][rowIndex][2] =
            ''; // Clear reason if invalid
      }
      if (!RegExp(r'^\d+$')
          .hasMatch(weeklyExpensesList[tableIndex][rowIndex][3])) {
        weeklyExpensesList[tableIndex][rowIndex][3] =
            ''; // Clear amount if invalid
      }
      await _saveData(); // Save cleared data
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
    // Validate if the "Reason" field contains only letters (a-z or A-Z)
    bool isReasonValid = RegExp(r'^[a-zA-Z\s]+$').hasMatch(inputs[2]);
    // Validate if the "Amount" field contains only numbers (0-9)
    bool isAmountValid = RegExp(r'^\d+$').hasMatch(inputs[3]);
    return isReasonValid && isAmountValid;
  }

  Future<bool> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = weeklyExpensesList.length;
    await prefs.setInt(
        'DecembernumberOfTables', numberOfTables); // Save number of tables
    for (int i = 0; i < numberOfTables; i++) {
      List<String> dataToSave =
          weeklyExpensesList[i].map((row) => row.join(',')).toList();
      await prefs.setStringList('DecemberweeklyExpenses$i', dataToSave);
      developer.log('Saved table $i: $dataToSave');
    }
    return true;
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int numberOfTables = prefs.getInt('DecembernumberOfTables') ?? 0;
    List<List<List<String>>> loadedData = [];
    for (int i = 0; i < numberOfTables; i++) {
      List<String>? savedData = prefs.getStringList('DecemberweeklyExpenses$i');
      if (savedData != null) {
        loadedData.add(savedData.map((row) => row.split(',')).toList());
      }
    }
    if (loadedData.isNotEmpty) {
      setState(() {
        weeklyExpensesList = loadedData;
      });
    } else {
      setState(() {
        weeklyExpensesList = [_initializeWeeklyExpenses()];
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
      weeklyExpensesList.removeAt(index);
    });
    _saveData(); // Save data when a table is deleted
  }

  double _calculateTotalAmount(List<List<String>> weeklyExpenses) {
    return weeklyExpenses.fold<double>(
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
        weeklyExpensesList[tableIndex][rowIndex][1] =
            picked.toString().split(" ")[0];
      });
      await _saveData(); // Save data after selecting a date
    }
  }
}

class WeeklyExpensesRecordsPage extends StatelessWidget {
  const WeeklyExpensesRecordsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey, // Set app bar color to gray
        title: Text('Weekly Expenses Records'),
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
                            builder: (context) =>
                                const JanuaryExpensesScreen()),
                      );
                      break;
                    case 2:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const FebuaryExpensesScreen()),
                      );
                      break;
                    case 3:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MarchExpensesScreen()),
                      );
                      break;
                    case 4:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AprilExpensesScreen()),
                      );
                      break;
                    case 5:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MayExpensesScreen()),
                      );
                      break;
                    case 6:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const JuneExpensesScreen()),
                      );
                      break;
                    case 7:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const JulyExpensesScreen()),
                      );
                      break;
                    case 8:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AugustExpensesScreen()),
                      );
                      break;
                    case 9:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const SeptemberExpensesScreen()),
                      );
                      break;
                    case 10:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const OctoberExpensesScreen()),
                      );
                      break;
                    case 11:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const NovemberExpensesScreen()),
                      );
                      break;
                    case 12:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const DecemberExpensesScreen()),
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
    home: WeeklyExpensesRecordsPage(),
  ));
}
