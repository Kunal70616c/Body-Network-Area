import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _prediction = 'Unknown';
  double heartRate = 0.0;
  double bodyTemp = 0.0;
  double accelerometerX = 0.0;
  double accelerometerY = 0.0;
  double accelerometerZ = 0.0;
  String activity = 'Unknown';
  String animationUrl =
      'https://lottie.host/a271c9ab-202a-4e09-be16-a90dd3398926/iZG9QEBaKh.json';

  double heartRateThreshold = 116.0;
  double bodyTempThreshold = 38.0;
  double accelerometerThreshold = 1000.0;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchPrediction();
    fetchData();
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchPrediction();
      fetchData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchPrediction() async {
    final response = await http
        .get(Uri.parse('https://body-network-area.onrender.com/predict'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      setState(() {
        _prediction = data['prediction'] == 1
            ? 'Warning: Unusual Health Parameters Found ❤️‍🩹'
            : 'Great! Your Health Parameters Look Good 💚';
        animationUrl = data['prediction'] == 1
            ? 'https://lottie.host/d83f1fd7-b39a-408a-a255-a3576e5df2b7/Ql1eYkHNj4.json' // URL for "unwell" animation
            : 'https://lottie.host/1843d9e7-962e-41e1-bec4-c11c8e2acc06/nX3e93SX1C.json'; // URL for "healthy" animation
      });
    } else {
      setState(() {
        _prediction = 'Fetching Failed ❌';
      });
    }
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse(
        'https://api.thingspeak.com/channels/2574220/feeds.json?api_key=ER31YYKXAWLEOAXW&results=1'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final feed = data['feeds'][0];
      setState(() {
        accelerometerX = double.parse(feed['field1']);
        accelerometerY = double.parse(feed['field2']);
        accelerometerZ = double.parse(feed['field3']);
        bodyTemp = double.parse(feed['field4']);
        heartRate = double.parse(feed['field5']);
        activity =
            calculateActivity(accelerometerX, accelerometerY, accelerometerZ);
      });

      // Check thresholds and show alert dialogs
      if (heartRate > heartRateThreshold) {
        showAlertDialog('High Heart Rate',
            'Try to relax, focus on calming your breathing.If you are experiencing a high heart rate, especially if it is accompanied by other symptoms like chest pain, dizziness, or shortness of breath, it is important to seek medical attention immediately.');
      }

      if (bodyTemp > bodyTempThreshold) {
        showAlertDialog(
            'High Body Temperature', 'Your body temperature is high!');
      }
    } else {
      setState(() {
        accelerometerX = 0.0;
        accelerometerY = 0.0;
        accelerometerZ = 0.0;
        bodyTemp = 0.0;
        heartRate = 0.0;
        activity = 'Unknown';
      });
    }
  }

  void showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Color getColorBasedOnThreshold(double value, double threshold) {
    return value > threshold ? Colors.red : Colors.green;
  }

  String calculateActivity(double accelX, double accelY, double accelZ) {
    const double thresholdLittleMoving = 0.05;
    const double thresholdWalk = 0.1;
    const double thresholdRun = 0.2;

    double normAccelX = accelX / 16384.0;
    double normAccelY = accelY / 16384.0;
    double normAccelZ = accelZ / 16384.0;

    double magnitude = sqrt(normAccelX * normAccelX +
        normAccelY * normAccelY +
        normAccelZ * normAccelZ);

    if (magnitude < 1.0 + thresholdLittleMoving &&
        magnitude > 1.0 - thresholdLittleMoving) {
      return "Little moving";
    } else if (magnitude >= 1.0 + thresholdWalk &&
        magnitude < 1.0 + thresholdRun) {
      return "Walking";
    } else if (magnitude >= 1.0 + thresholdRun) {
      return "Running";
    } else {
      return "Idle";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text(
          'BAN Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 300,
                width: 300,
                child: Lottie.network(animationUrl),
              ),
              Text(
                _prediction,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              SizedBox(height: 20),
              buildDataSection('Heart Rate', heartRate, heartRateThreshold,
                  unit: 'BPM'),
              buildDataSection('Body Temperature', bodyTemp, bodyTempThreshold,
                  unit: '°C'),
              buildAccelerometerSection(),
              SizedBox(height: 20),
              buildActivitySection(),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  fetchPrediction();
                  fetchData();
                },
                child: Text('Refresh Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDataSection(String label, double value, double threshold,
      {String unit = ''}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 18),
        ),
        Text(
          '${value.toStringAsFixed(0)} $unit',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: getColorBasedOnThreshold(value, threshold),
          ),
        ),
      ],
    );
  }

  Widget buildAccelerometerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 10,
        ),
        Text(
          'Accelerometer Data',
          style: TextStyle(fontSize: 18),
        ),
        buildDataSection('Axis-X', accelerometerX, accelerometerThreshold),
        buildDataSection('Axis-Y', accelerometerY, accelerometerThreshold),
        buildDataSection('Axis-Z', accelerometerZ, accelerometerThreshold),
      ],
    );
  }

  Widget buildActivitySection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Activity Status',
          style: TextStyle(fontSize: 18),
        ),
        Text(
          activity,
          style: TextStyle(
            fontSize: 18,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }
}
