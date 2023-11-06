

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import 'package:tow_botic_systems/Compass/neu_circle.dart';

// void main() => runApp(const MyApp());
//
// class MyApp extends StatefulWidget {
//   const MyApp({
//     Key? key,
//   }) : super(key: key);
//
//   @override
//   _MyAppState createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   bool _hasPermissions = false;
//   loc.LocationData? currentLocation;
//   double? speed;
//
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchPermissionStatus();
//     initLocation();
//   }
//
//   void initLocation() async {
//     final location = loc.Location();
//     location.changeSettings(accuracy:loc.LocationAccuracy.high );
//
//     location.onLocationChanged.listen((loc.LocationData locationData) {
//       setState(() {
//         currentLocation = locationData;
//         speed = locationData.speed;
//       });
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text("Tow-botic Systems"),
//         ),
//         // backgroundColor: Colors.brown[600],
//         backgroundColor: Colors.black,
//         body: Column(
//           children: [
//
//             Center(
//               child: SizedBox(
//                 height: 400,
//                 width: 400,
//                 child: Builder(
//                   builder: (context) {
//                     if (_hasPermissions) {
//                       return _buildCompass();
//                     } else {
//                       return _buildPermissionSheet();
//                     }
//                   },
//                 ),
//               ),
//             ),
//
//             Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: <Widget>[
//                   if (currentLocation != null)
//                     Text('Latitude: ${currentLocation!.latitude}',style: const TextStyle(color: Colors.white),),
//                   const SizedBox(height: 10,),
//                   if (currentLocation != null)
//                     Text('Longitude: ${currentLocation!.longitude}',style: const TextStyle(color: Colors.white)),
//                   const SizedBox(height: 10,),
//                   if (speed != null)
//                     Text('Speed (km/h): ${speed!.toStringAsFixed(2)}',style: const TextStyle(color: Colors.white)),
//                   const SizedBox(height: 10,),
//                   if (speed != null)
//                     Text('Speed (Knots): ${(speed!*0.539957).toStringAsFixed(2)}',style: const TextStyle(color: Colors.white)),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildCompass() {
//     return StreamBuilder<CompassEvent>(
//       stream: FlutterCompass.events,
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return Text('Error reading heading: ${snapshot.error}');
//         }
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Center(
//             child: CircularProgressIndicator(),
//           );
//         }
//         double? direction = snapshot.data!.heading;
//         if (direction == null) {
//           return const Center(
//             child: Text("Device does not have sensors !"),
//           );
//         }
//         return NeuCircle(
//           child: Transform.rotate(
//             angle: (direction * (math.pi / 180) * -1),
//             child: Image.asset(
//               'assets/img.png',
//               color: Colors.black,
//               fit: BoxFit.fill,
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildPermissionSheet() {
//     return Center(
//       child: ElevatedButton(
//         child: const Text('Request Permissions'),
//         onPressed: () {
//           Permission.locationWhenInUse.request().then((ignored) {
//             _fetchPermissionStatus();
//           });
//         },
//       ),
//     );
//   }
//
//   void _fetchPermissionStatus() {
//     Permission.locationWhenInUse.status.then((status) {
//       if (mounted) {
//         setState(() => _hasPermissions = status == PermissionStatus.granted);
//       }
//     });
//   }
// }



// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tow_botic_systems/snake.dart';

// import 'snake.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
    [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mobile Sensors Data Demo',
      theme: ThemeData(
        useMaterial3: false,
        colorSchemeSeed: const Color(0x9f4376f8),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {



  bool _hasPermissions = false;
  loc.LocationData? currentLocation;
  double? speed;

  //
  // @override
  // void initState() {
  //   super.initState();
  //   _fetchPermissionStatus();
  //   initLocation();
  // }

  void initLocation() async {
    final location = loc.Location();
    location.changeSettings(accuracy:loc.LocationAccuracy.high );

    location.onLocationChanged.listen((loc.LocationData locationData) {
      setState(() {
        currentLocation = locationData;
        speed = locationData.speed;
      });
    });
  }









  static const int _snakeRows = 20;
  static const int _snakeColumns = 20;
  static const double _snakeCellSize = 10.0;

  List<double>? _userAccelerometerValues;
  List<double>? _accelerometerValues;
  List<double>? _gyroscopeValues;
  List<double>? _magnetometerValues;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  @override
  Widget build(BuildContext context) {

    final userAccelerometer = _userAccelerometerValues
        ?.map((double v) => v.toStringAsFixed(1))
        .toList();
    final accelerometer =
    _accelerometerValues?.map((double v) => v.toStringAsFixed(1)).toList();
    final gyroscope =
    _gyroscopeValues?.map((double v) => v.toStringAsFixed(1)).toList();
    final magnetometer =
    _magnetometerValues?.map((double v) => v.toStringAsFixed(1)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Mobile Sensors Data')),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[

            Center(
              child: SizedBox(
                height: 400,
                width: 400,
                child: Builder(
                  builder: (context) {
                    if (_hasPermissions) {
                      return _buildCompass();
                    } else {
                      return _buildPermissionSheet();
                    }
                  },
                ),
              ),
            ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (currentLocation != null)
                    Text('Latitude: ${currentLocation!.latitude}',style: const TextStyle(color: Colors.black),),
                  const SizedBox(height: 10,),
                  if (currentLocation != null)
                    Text('Longitude: ${currentLocation!.longitude}',style: const TextStyle(color: Colors.black)),
                  const SizedBox(height: 10,),
                  if (speed != null)
                    Text('Speed (km/h): ${speed!.toStringAsFixed(2)}',style: const TextStyle(color: Colors.black)),
                  const SizedBox(height: 10,),
                  if (speed != null)
                    Text('Speed (Knots): ${(speed!*0.539957).toStringAsFixed(2)}',style: const TextStyle(color: Colors.black)),
                ],
              ),
            ),
            const SizedBox(height: 10,),
            // Center(
            //   child: DecoratedBox(
            //     decoration: BoxDecoration(
            //       border: Border.all(width: 1.0, color: Colors.black38),
            //     ),
            //     child:Image.asset("assets/axis.png")
            //
            //     // SizedBox(
            //     //   height: _snakeRows * _snakeCellSize,
            //     //   width: _snakeColumns * _snakeCellSize,
            //     //   child:
            //     //
            //     //   Snake(
            //     //     rows: _snakeRows,
            //     //     columns: _snakeColumns,
            //     //     cellSize: _snakeCellSize,
            //     //   ),
            //     // ),
            //   ),
            // ),
            const SizedBox(height: 10,),

            Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text('UserAccelerometer values' ,style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10,),
                    Text('X-Axis-: ${userAccelerometer?[0]} m/s\u00b2'),
                    const SizedBox(height: 5),
                    Text('Y-Axis: ${userAccelerometer?[1]} m/s\u00b2'),
                    const SizedBox(height: 5),
                    Text('Z-Axis: ${userAccelerometer?[2]} m/s\u00b2'),
                    // Text('UserAccelerometer: $userAccelerometer'),
                    // Text('UserAccelerometer: $userAccelerometer'),
                  ],
                ),
                const SizedBox(height: 10,),
                // Padding(
                //   padding: const EdgeInsets.all(8.0),
                //   child: Container(
                //     padding: const EdgeInsets.all(16.0), // Add padding for spacing
                //     decoration: BoxDecoration(
                //       border: Border.all(color: Colors.black), // Add a border
                //       borderRadius: BorderRadius.circular(8.0), // Optional: Add rounded corners
                //     ),
                //     child: const Text(
                //       "UserAccelerometerEvent describes the acceleration of the device, in m/s2. If the device is still, or is moving along a straight line at constant speed, the reported acceleration is zero. If the device is moving e.g. towards north and its speed is increasing, the reported acceleration is towards north; if it is slowing down, the reported acceleration is towards south; if it is turning right, the reported acceleration is towards east. The data of this stream is obtained by filtering out the effect of gravity from AccelerometerEvent",
                //       style: TextStyle(fontSize: 12.0),
                //     ),
                //   ),
                // ),
              ],
            ),

            Column(
              children: [
                Column(
                  children: [
                    const Text('Accelerometer Values',style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10,),
                    Text('X-Axis: ${accelerometer?[0]} m/s\u00b2'),
                    const SizedBox(height: 5),
                    Text('Y-Axis: ${accelerometer?[1]} m/s\u00b2'),
                    const SizedBox(height: 5),
                    Text('Z-Axis: ${accelerometer?[2]} m/s\u00b2'),
                  ],
                ),
                const SizedBox(height: 10,),
                // Padding(
                //   padding: const EdgeInsets.all(8.0),
                //   child: Container(
                //     padding: const EdgeInsets.all(16.0), // Add padding for spacing
                //     decoration: BoxDecoration(
                //       border: Border.all(color: Colors.black), // Add a border
                //       borderRadius: BorderRadius.circular(8.0), // Optional: Add rounded corners
                //     ),
                //     child: const Text(
                //       "AccelerometerEvent describes the acceleration of the device, in m/s2, including the effects of gravity. Unlike UserAccelerometerEvent, this stream reports raw data from the accelerometer (physical sensor embedded in the mobile device) without any post-processing. The accelerometer is unable to distinguish between the effect of an accelerated movement of the device and the effect of the surrounding gravitational field. This means that, at the surface of Earth, even if the device is completely still, the reading of AccelerometerEvent is an acceleration of intensity 9.8 directed upwards (the opposite of the graviational acceleration). This can be used to infer information about the position of the device (horizontal/vertical/tilted). AccelerometerEvent reports zero acceleration if the device is free falling.",
                //       style: TextStyle(fontSize: 12.0),
                //     ),
                //   ),
                // ),
              ],
            ),
            // Padding(
            //   padding: const EdgeInsets.all(16.0),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: <Widget>[
            //       Column(
            //         children: [
            //           const Text('Accelerometer Values'),
            //           Text('X-Axis: ${accelerometer?[0]} m/s\u00b2'),
            //           Text('Y-Axis: ${accelerometer?[1]} m/s\u00b2'),
            //           Text('Z-Axis: ${accelerometer?[2]} m/s\u00b2'),
            //         ],
            //       ),
            //       Column(
            //         children: [
            //           const Text('Accelerometer Values'),
            //           Text('X-Axis: ${accelerometer?[0]} m/s\u00b2'),
            //           Text('Y-Axis: ${accelerometer?[1]} m/s\u00b2'),
            //           Text('Z-Axis: ${accelerometer?[2]} m/s\u00b2'),
            //         ],
            //       ),
            //
            //     ],
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Gyroscope Values',style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10,),
                  Text('X-Axis (Pitch): ${gyroscope?[0]}'),
                  const SizedBox(height: 5),
                  Text('Y-Axis (Roll): ${gyroscope?[1]}'),
                  const SizedBox(height: 5),
                  Text('Z-Axis (Yaw): ${gyroscope?[2]}'),
                ],
              ),
            ),
            // Center(
            //   child: DecoratedBox(
            //       decoration: BoxDecoration(
            //         border: Border.all(width: 1.0, color: Colors.black38),
            //       ),
            //       child:Image.asset("assets/gyroscope.png")
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  @override
  void initState() {
    super.initState();

    _fetchPermissionStatus();
    initLocation();

    _streamSubscriptions.add(
      userAccelerometerEvents.listen(
            (UserAccelerometerEvent event) {
          setState(() {
            _userAccelerometerValues = <double>[event.x, event.y, event.z];
          });
        },
        onError: (e) {
          showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text("Sensor Not Found"),
                  content: Text(
                      "It seems that your device doesn't support Accelerometer Sensor"),
                );
              });
        },
        cancelOnError: true,
      ),
    );
    _streamSubscriptions.add(
      accelerometerEvents.listen(
            (AccelerometerEvent event) {
          setState(() {
            _accelerometerValues = <double>[event.x, event.y, event.z];
          });
        },
        onError: (e) {
          showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text("Sensor Not Found"),
                  content: Text(
                      "It seems that your device doesn't support Gyroscope Sensor"),
                );
              });
        },
        cancelOnError: true,
      ),
    );
    _streamSubscriptions.add(
      gyroscopeEvents.listen(
            (GyroscopeEvent event) {
          setState(() {
            _gyroscopeValues = <double>[event.x, event.y, event.z];
          });
        },
        onError: (e) {
          showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text("Sensor Not Found"),
                  content: Text(
                      "It seems that your device doesn't support User Accelerometer Sensor"),
                );
              });
        },
        cancelOnError: true,
      ),
    );
    _streamSubscriptions.add(
      magnetometerEvents.listen(
            (MagnetometerEvent event) {
          setState(() {
            _magnetometerValues = <double>[event.x, event.y, event.z];
          });
        },
        onError: (e) {
          showDialog(
              context: context,
              builder: (context) {
                return const AlertDialog(
                  title: Text("Sensor Not Found"),
                  content: Text(
                      "It seems that your device doesn't support Magnetometer Sensor"),
                );
              });
        },
        cancelOnError: true,
      ),
    );
  }



  Widget _buildCompass() {
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error reading heading: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        double? direction = snapshot.data!.heading;
        if (direction == null) {
          return const Center(
            child: Text("Device does not have sensors !"),
          );
        }
        return NeuCircle(
          child: Transform.rotate(
            angle: (direction * (math.pi / 180) * -1),
            child: Image.asset(
              'assets/img.png',
              color: Colors.black,
              fit: BoxFit.fill,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPermissionSheet() {
    return Center(
      child: ElevatedButton(
        child: const Text('Request Permissions'),
        onPressed: () {
          Permission.locationWhenInUse.request().then((ignored) {
            _fetchPermissionStatus();
          });
        },
      ),
    );
  }

  void _fetchPermissionStatus() {
    Permission.locationWhenInUse.status.then((status) {
      if (mounted) {
        setState(() => _hasPermissions = status == PermissionStatus.granted);
      }
    });
  }
}

//
//
//
// // import 'package:flutter/material.dart';
// //
// // void main() {
// //   runApp(const MyApp());
// // }
// //
// // class MyApp extends StatelessWidget {
// //   const MyApp({super.key});
// //
// //   // This widget is the root of your application.
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       title: 'Flutter Demo',
// //       theme: ThemeData(
// //
// //         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
// //         useMaterial3: true,
// //       ),
// //       home: const MyHomePage(title: 'Flutter Demo Home Page'),
// //     );
// //   }
// // }
// //
// //
// //
// //
// // class MyHomePage extends StatefulWidget {
// //   const MyHomePage({super.key, required this.title});
// //
// //   final String title;
// //
// //   @override
// //   State<MyHomePage> createState() => _MyHomePageState();
// // }
// //
// // class _MyHomePageState extends State<MyHomePage> {
// //   int _counter = 0;
// //
// //   void _incrementCounter() {
// //     setState(() {
// //       // This call to setState tells the Flutter framework that something has
// //       // changed in this State, which causes it to rerun the build method below
// //       // so that the display can reflect the updated values. If we changed
// //       // _counter without calling setState(), then the build method would not be
// //       // called again, and so nothing would appear to happen.
// //       _counter++;
// //     });
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     // This method is rerun every time setState is called, for instance as done
// //     // by the _incrementCounter method above.
// //     //
// //     // The Flutter framework has been optimized to make rerunning build methods
// //     // fast, so that you can just rebuild anything that needs updating rather
// //     // than having to individually change instances of widgets.
// //     return Scaffold(
// //       appBar: AppBar(
// //         // TRY THIS: Try changing the color here to a specific color (to
// //         // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
// //         // change color while the other colors stay the same.
// //         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
// //         // Here we take the value from the MyHomePage object that was created by
// //         // the App.build method, and use it to set our appbar title.
// //         title: Text(widget.title),
// //       ),
// //       body: Center(
// //         // Center is a layout widget. It takes a single child and positions it
// //         // in the middle of the parent.
// //         child: Column(
// //           // Column is also a layout widget. It takes a list of children and
// //           // arranges them vertically. By default, it sizes itself to fit its
// //           // children horizontally, and tries to be as tall as its parent.
// //           //
// //           // Column has various properties to control how it sizes itself and
// //           // how it positions its children. Here we use mainAxisAlignment to
// //           // center the children vertically; the main axis here is the vertical
// //           // axis because Columns are vertical (the cross axis would be
// //           // horizontal).
// //           //
// //           // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
// //           // action in the IDE, or press "p" in the console), to see the
// //           // wireframe for each widget.
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: <Widget>[
// //             const Text(
// //               'You have pushed the button this many times:',
// //             ),
// //             Text(
// //               '$_counter',
// //               style: Theme.of(context).textTheme.headlineMedium,
// //             ),
// //           ],
// //         ),
// //       ),
// //       floatingActionButton: FloatingActionButton(
// //         onPressed: _incrementCounter,
// //         tooltip: 'Increment',
// //         child: const Icon(Icons.add),
// //       ), // This trailing comma makes auto-formatting nicer for build methods.
// //     );
// //   }
// // }
