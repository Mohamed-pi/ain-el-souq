import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:csv/csv.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Map<String, dynamic>> stocks = [];
  bool isLoading = false;

  Future<void> fetchStockData() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
        'https://docs.google.com/spreadsheets/d/1DykifEVdNIr3lTnGgqm2tuooJ_tTW1l-b4QHSXFyo9Q/gviz/tq?tqx=out:csv');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final csvBody = response.body;
      final List<List<dynamic>> rowsAsListOfValues =
          const CsvToListConverter().convert(csvBody);

      List<Map<String, dynamic>> newStocks = [];

      for (int i = 1; i < rowsAsListOfValues.length; i++) {
        final row = rowsAsListOfValues[i];
        try {
          final symbol = row[0].toString();
          final price = double.tryParse(row[1].toString()) ?? 0.0;
          final sma200 = double.tryParse(row[2].toString()) ?? 0.0;
          final rsi = double.tryParse(row[3].toString()) ?? 0.0;

          if (price >= sma200 && rsi < 40) {
            newStocks.add({
              "symbol": symbol,
              "price": price,
              "sma200": sma200,
              "rsi": rsi,
            });
          }
        } catch (e) {
          // Skip any bad rows
        }
      }

      setState(() {
        stocks = newStocks;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchStockData();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'عين السوق - محمد أحمد',
      home: Scaffold(
        appBar: AppBar(
          title: Text('عين السوق - محمد أحمد'),
          backgroundColor: Colors.green,
        ),
        body: Column(
          children: [
            ElevatedButton(
              onPressed: fetchStockData,
              child: Text("تحديث البيانات"),
            ),
            isLoading
                ? CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: stocks.length,
                      itemBuilder: (context, index) {
                        final stock = stocks[index];
                        return ListTile(
                          title: Text('${stock["symbol"]}'),
                          subtitle: Text(
                              'السعر: ${stock["price"]} | RSI: ${stock["rsi"]}'),
                          trailing: stock["rsi"] > 40
                              ? Icon(Icons.check_circle, color: Colors.green)
                              : Icon(Icons.warning, color: Colors.orange),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}