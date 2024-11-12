import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

void main() {
  runApp(DroneControllerApp());
}

class DroneControllerApp extends StatefulWidget {
  @override
  State<DroneControllerApp> createState() => _DroneControllerAppState();
}

class _DroneControllerAppState extends State<DroneControllerApp> {
  double leftJoystickY = 0.0; // Y-axis value for the left joystick
  double rightJoystickX = 0.0; // X-axis value for the right joystick
  double rightJoystickY = 0.0; // Y-axis value for the right joystick
  late WebSocketChannel channel;
  bool isConnected = false;
  bool isConnecting = false; // New variable to track connecting state

  @override
  void initState() {
    super.initState();
    // connectToWebSocket();
  }

  void connectToWebSocket() {
    setState(() {
      isConnecting = true; // Set connecting state to true
    });
    try {
      channel = IOWebSocketChannel.connect('ws://192.168.4.1/ws');
      
      channel.stream.listen(
        (message) {
          print("Message from ESP32: $message");
        },
        onDone: () {
          setState(() {
            isConnected = false;
            isConnecting = false;
          });
          print("Disconnected from WebSocket");
        },
        onError: (error) {
          setState(() {
            isConnected = false;
            isConnecting = false;
          });
          print("WebSocket error: $error");
        },
      );

      setState(() {
        isConnected = true;
        isConnecting = false; // Connection established
      });
    } catch (e) {
      setState(() {
        isConnecting = false; // Connection failed
      });
      print("Could not connect to WebSocket: $e");
    }
  }

  void sendJoystickData() {
    if (isConnected) {
      final data = {
        "throttle": leftJoystickY,
        "rightJoystickX": rightJoystickX,
        "rightJoystickY": rightJoystickY,
      };
      channel.sink.add(jsonEncode(data)); // Send data as JSON string
    }
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: DroneControlScreen(
          leftJoystickY: leftJoystickY,
          rightJoystickX: rightJoystickX,
          rightJoystickY: rightJoystickY,
          onLeftJoystickMove: (y) {
            setState(() {
              leftJoystickY = y;
            });
            sendJoystickData();
          },
          onRightJoystickMove: (x, y) {
            setState(() {
              rightJoystickX = x;
              rightJoystickY = y;
            });
            sendJoystickData();
          },
          onConnectButtonPressed: () {
            if (!isConnected && !isConnecting) {
              connectToWebSocket();
            }
          },
          isConnected: isConnected,
          isConnecting: isConnecting, // Pass new state to the screen
        ),
      ),
    );
  }
}

class DroneControlScreen extends StatelessWidget {
  final double leftJoystickY;
  final double rightJoystickX;
  final double rightJoystickY;
  final Function(double) onLeftJoystickMove;
  final Function(double, double) onRightJoystickMove;
  final VoidCallback onConnectButtonPressed;
  final bool isConnected;
  final bool isConnecting; // New parameter to show connecting state

  const DroneControlScreen({
    super.key,
    required this.leftJoystickY,
    required this.rightJoystickX,
    required this.rightJoystickY,
    required this.onLeftJoystickMove,
    required this.onRightJoystickMove,
    required this.onConnectButtonPressed,
    required this.isConnected,
    required this.isConnecting, // Receive connecting state
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Center(
              child: ElevatedButton(
                onPressed: onConnectButtonPressed,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: TextStyle(fontSize: 20),
                ),
                child: Text(
                  isConnecting
                      ? 'Connecting...' // Show "Connecting..." if in connecting state
                      : isConnected
                          ? 'Connected'
                          : 'Connect',
                ),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Left Joystick Y: ${leftJoystickY.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Joystick(
                          mode: JoystickMode.vertical,
                          listener: (details) {
                            onLeftJoystickMove(details.y);
                          },
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Right Joystick X: ${rightJoystickX.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      Text(
                        'Right Joystick Y: ${rightJoystickY.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Joystick(
                          mode: JoystickMode.all,
                          listener: (details) {
                            onRightJoystickMove(details.x, details.y);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
