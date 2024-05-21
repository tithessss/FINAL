import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class CustomersRecordsPage extends StatefulWidget {
  const CustomersRecordsPage({Key? key}) : super(key: key);

  @override
  _CustomersRecordsPageState createState() => _CustomersRecordsPageState();
}

class _CustomersRecordsPageState extends State<CustomersRecordsPage> {
  List<CustomerRecord> customerRecords = [];
  late Color textColor;

  TextEditingController nameController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController purchasedController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  String? selectedSize;

  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  void loadRecords() async {
    developer.log('Loading records from SharedPreferences...',
        name: 'CustomerRecords');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? recordsList = prefs.getStringList('customerRecords');
    if (recordsList != null) {
      setState(() {
        customerRecords = recordsList
            .map((recordString) => CustomerRecord.fromString(recordString))
            .toList();
        pancakeSortCustomerRecords();
      });
      developer.log('Loaded records: $customerRecords',
          name: 'CustomerRecords');
    } else {
      developer.log('No records found', name: 'CustomerRecords');
    }
  }

  void saveRecords() async {
    developer.log('Saving records to SharedPreferences...',
        name: 'CustomerRecords');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> recordsList =
        customerRecords.map((record) => record.toString()).toList();
    await prefs.setStringList('customerRecords', recordsList);
    developer.log('Saved records: $recordsList', name: 'CustomerRecords');
  }

  void deleteRecord(int index) async {
    setState(() {
      customerRecords.removeAt(index);
      saveRecords();
    });
  }

  bool validateFields(
      String name, String contact, String purchased, String amount) {
    if (name.isEmpty ||
        contact.isEmpty ||
        purchased.isEmpty ||
        amount.isEmpty) {
      return false;
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(contact) ||
        !RegExp(r'^[0-9]+$').hasMatch(amount)) {
      return false;
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      return false;
    }
    return true;
  }

  void addRecord() {
    if (validateFields(nameController.text, contactController.text,
        purchasedController.text, amountController.text)) {
      setState(() {
        customerRecords.add(CustomerRecord(
          customerName: nameController.text,
          contactNumber: contactController.text,
          size: selectedSize!,
          purchased: purchasedController.text,
          amountPurchased: amountController.text,
        ));
        saveRecords();
        loadRecords();
        pancakeSortCustomerRecords();
      });
      nameController.clear();
      contactController.clear();
      purchasedController.clear();
      amountController.clear();
    } else {
      nameController.clear();
      contactController.clear();
      purchasedController.clear();
      amountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid input(s), try again'),
          duration: Duration(milliseconds: 1500),
        ),
      );
    }
  }

  void pancakeSortCustomerRecords() {
    for (int i = 0; i < customerRecords.length; i++) {
      int highestIndex = findHighestIndex(i, customerRecords.length - 1);
      if (highestIndex != i) {
        flipSublist(i, highestIndex);
      }
    }
  }

  int findHighestIndex(int start, int end) {
    int highestIndex = start;
    for (int i = start + 1; i <= end; i++) {
      if (int.parse(customerRecords[i].amountPurchased) >
          int.parse(customerRecords[highestIndex].amountPurchased)) {
        highestIndex = i;
      }
    }
    return highestIndex;
  }

  void flipSublist(int start, int end) {
    while (start < end) {
      CustomerRecord temp = customerRecords[start];
      customerRecords[start] = customerRecords[end];
      customerRecords[end] = temp;
      start++;
      end--;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = Colors.white;
    final bool isDarkBackground = selectedColor.computeLuminance() < 0.5;
    textColor =
        isDarkBackground ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey,
        centerTitle: true,
        title: Text(
          'Customers Records',
          style: TextStyle(
            color: textColor,
          ),
        ),
      ),
      backgroundColor: selectedColor,
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 16.0,
            dividerThickness: 1.0,
            columns: [
              DataColumn(
                label: Text(
                  'Customer Name',
                  style: TextStyle(
                    color: textColor,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Contact Number',
                  style: TextStyle(
                    color: textColor,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Size',
                  style: TextStyle(
                    color: textColor,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Purchased',
                  style: TextStyle(
                    color: textColor,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Amount Purchased',
                  style: TextStyle(
                    color: textColor,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Actions',
                  style: TextStyle(
                    color: textColor,
                  ),
                ),
              ),
            ],
            rows: List.generate(
              customerRecords.length,
              (index) => DataRow(
                cells: [
                  DataCell(
                    Text(
                      customerRecords[index].customerName,
                      style: TextStyle(
                        color: textColor,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      customerRecords[index].contactNumber,
                      style: TextStyle(
                        color: textColor,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      customerRecords[index].size,
                      style: TextStyle(
                        color: textColor,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      customerRecords[index].purchased,
                      style: TextStyle(
                        color: textColor,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      customerRecords[index].amountPurchased,
                      style: TextStyle(
                        color: textColor,
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddRecordDialog();
        },
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: TotalAmountTile(customerRecords: customerRecords),
    );
  }

  Future<void> showAddRecordDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Record'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Customer Name',
                  ),
                  keyboardType: TextInputType.text,
                ),
                TextField(
                  controller: contactController,
                  decoration: InputDecoration(
                    labelText: 'Contact Number',
                  ),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: selectedSize,
                  items: <String>['Small', 'Medium', 'Large']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedSize = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Size',
                  ),
                ),
                TextField(
                  controller: purchasedController,
                  decoration: InputDecoration(
                    labelText: 'Purchased',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount Purchased',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: addRecord,
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

class CustomerRecord {
  String customerName;
  String contactNumber;
  String size;
  String purchased;
  String amountPurchased;

  CustomerRecord({
    required this.customerName,
    required this.contactNumber,
    required this.size,
    required this.purchased,
    required this.amountPurchased,
  });

  static CustomerRecord fromString(String recordString) {
    List<String> values = recordString.split(',');
    return CustomerRecord(
      customerName: values[0],
      contactNumber: values[1],
      size: values[2],
      purchased: values[3],
      amountPurchased: values[4],
    );
  }

  @override
  String toString() {
    return '$customerName,$contactNumber,$size,$purchased,$amountPurchased';
  }
}

class TotalAmountTile extends StatefulWidget {
  final List<CustomerRecord> customerRecords;

  const TotalAmountTile({
    Key? key,
    required this.customerRecords,
  }) : super(key: key);

  @override
  _TotalAmountTileState createState() => _TotalAmountTileState();
}

class _TotalAmountTileState extends State<TotalAmountTile> {
  TextEditingController smallSizeController = TextEditingController();
  TextEditingController mediumSizeController = TextEditingController();
  TextEditingController largeSizeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadPrices();
  }

  void loadPrices() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      smallSizeController.text = prefs.getString('smallPrice') ?? '';
      mediumSizeController.text = prefs.getString('mediumPrice') ?? '';
      largeSizeController.text = prefs.getString('largePrice') ?? '';
    });
  }

  void savePrices() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('smallPrice', smallSizeController.text);
    prefs.setString('mediumPrice', mediumSizeController.text);
    prefs.setString('largePrice', largeSizeController.text);
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text('Total Amount Purchased: ${calculateTotalAmount()}'),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Table(
            border: TableBorder.all(),
            children: [
              TableRow(
                children: [
                  TableCell(
                    child: Center(
                      child: Text(
                        'Size',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  TableCell(
                    child: Center(
                      child: Text(
                        'Price',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  TableCell(
                    child: Center(
                      child: Text(
                        'Small',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  TableCell(
                    child: Center(
                      child: TextFormField(
                        controller: smallSizeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'Enter price',
                        ),
                        onChanged: (value) {
                          savePrices();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  TableCell(
                    child: Center(
                      child: Text(
                        'Medium',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  TableCell(
                    child: Center(
                      child: TextFormField(
                        controller: mediumSizeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'Enter price',
                        ),
                        onChanged: (value) {
                          savePrices();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  TableCell(
                    child: Center(
                      child: Text(
                        'Large',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  TableCell(
                    child: Center(
                      child: TextFormField(
                        controller: largeSizeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: 'Enter price',
                        ),
                        onChanged: (value) {
                          savePrices();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  int calculateTotalAmount() {
    return widget.customerRecords.fold<int>(
      0,
      (previousValue, record) => previousValue + int.parse(record.amountPurchased),
    );
  }
}

