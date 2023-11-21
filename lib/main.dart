import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:tow_botic_systems/Compass/neu_circle.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tow Botics System',
      theme: ThemeData(
        useMaterial3: false,
        colorSchemeSeed: const Color(0x9f4376f8),
      ),
      home: const MyHomePage(title: 'Tow Botics System'),
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
  double? compassHeading;

  double rollAngle = 0;
  double pitchAngle = 0;
  double yawAngle = 0;
  double initialYaw = 0;
  double alpha = 0.98;
  String rollDirection = 'Not Rolling';
  String pitchDirection = 'Not Tilting';
  String yawDirection = 'Not Rotating';

  @override
  void initState() {
    super.initState();

    Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      accelerometerEvents.listen((AccelerometerEvent accelerometerEvent) {
        gyroscopeEvents.listen((GyroscopeEvent gyroscopeEvent) {
          double rollGyro = gyroscopeEvent.z;
          double pitchGyro = gyroscopeEvent.x;
          double yawGyro = gyroscopeEvent.y;
          double rollAccel = _calculateRollAngle(
              accelerometerEvent.x, accelerometerEvent.y, accelerometerEvent.z);
          double pitchAccel = _calculatePitchAngle(
              accelerometerEvent.x, accelerometerEvent.y, accelerometerEvent.z);

          if (initialYaw == 0) {
            initialYaw = yawGyro;
          }

          rollAngle = alpha * (rollAngle + rollGyro) + (1 - alpha) * rollAccel;
          pitchAngle =
              alpha * (pitchAngle + pitchGyro) + (1 - alpha) * pitchAccel;
          yawAngle = initialYaw + yawGyro;

          rollAngle = double.parse(rollAngle.toStringAsFixed(2));
          pitchAngle = double.parse(pitchAngle.toStringAsFixed(2));
          yawAngle = double.parse(yawAngle.toStringAsFixed(2));

          rollDirection = getRollDirection(rollAngle);
          pitchDirection = getPitchDirection(pitchAngle);
          yawDirection = getYawDirection(yawAngle);

          setState(() {});
        });
      });
    });

    gyroscopeEvents.listen((GyroscopeEvent event) {
      final angularVelocity = event.y;
      final timeInterval = 0.1000;
      final deltaAngle = angularVelocity * timeInterval;
      integratedAngle += deltaAngle;

      setState(() {});
    });

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
  }

  double _calculateRollAngle(double x, double y, double z) {
    return -1 * math.atan2(-x, math.sqrt(y * y + z * z)) * (180 / math.pi);
  }

  double _calculatePitchAngle(double x, double y, double z) {
    return math.atan2(y, math.sqrt(x * x + z * z)) * (180 / math.pi);
  }

  String getRollDirection(double angle) {
    if (angle > 0) {
      return 'Rolling to Port';
    } else if (angle < 0) {
      return 'Rolling to Starboard';
    } else {
      return 'Not Rolling';
    }
  }

  String getPitchDirection(double angle) {
    if (angle > 0) {
      return 'By Stern';
    } else if (angle < 0) {
      return 'By Head';
    } else {
      return 'Not Tilting';
    }
  }

  String getYawDirection(double angle) {
    if (compassHeading != null) {
      double difference = angle - compassHeading!;
      if (difference.abs() < 5) {
        return 'Not Rotating';
      } else if (difference > 0) {
        return 'Yaw to Starboard';
      } else {
        return 'Yaw to Port';
      }
    } else {
      return 'Not Rotating';
    }
  }

  void initLocation() async {
    final location = loc.Location();
    location.changeSettings(accuracy: loc.LocationAccuracy.high);

    location.onLocationChanged.listen((loc.LocationData locationData) {
      setState(() {
        currentLocation = locationData;
        speed = locationData.speed;
      });
    });
  }

  List<double>? _userAccelerometerValues;
  List<double>? _accelerometerValues;
  List<double>? _gyroscopeValues;
  List<double>? _magnetometerValues;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  double integratedAngle = 0.0;



  @override
  Widget build(BuildContext context) {
    final userAccelerometer = _userAccelerometerValues
        ?.map((double v) => v.toStringAsFixed(1))
        .toList();
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
                    Text(
                      'Latitude: ${currentLocation!.latitude}',
                      style: const TextStyle(color: Colors.black),
                    ),
                  const SizedBox(
                    height: 10,
                  ),
                  if (currentLocation != null)
                    Text('Longitude: ${currentLocation!.longitude}',
                        style: const TextStyle(color: Colors.black)),
                  const SizedBox(
                    height: 10,
                  ),
                  if (speed != null)
                    Text('Speed (km/h): ${speed!.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.black)),
                  const SizedBox(
                    height: 10,
                  ),
                  if (speed != null)
                    Text(
                        'Speed (Knots): ${(speed! * 0.539957).toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.black)),
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            const SizedBox(
              height: 10,
            ),


            // TODO:UserAccelerometer values
            Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Text('UserAccelerometer values',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(
                      height: 10,
                    ),
                    Text('X-Axis-: ${userAccelerometer?[0]} m/s\u00b2'),
                    const SizedBox(height: 5),
                    Text('Y-Axis: ${userAccelerometer?[1]} m/s\u00b2'),
                    const SizedBox(height: 5),
                    Text('Z-Axis: ${userAccelerometer?[2]} m/s\u00b2'),
                    // Text('UserAccelerometer: $userAccelerometer'),
                    // Text('UserAccelerometer: $userAccelerometer'),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
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
            // TODO:UserAccelerometer values
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Gyroscope Values',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(
                    height: 10,
                  ),

                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                            'Roll Angle: ${rollAngle.toStringAsFixed(0)} degrees'),
                        Text('Roll Direction: $rollDirection'),
                        const SizedBox(height: 20),
                        Text(
                            'Pitch Angle: ${pitchAngle.toStringAsFixed(0)} degrees'),
                        Text('Pitch Direction: $pitchDirection'),
                        const SizedBox(height: 20),
                        Text(
                            'Yaw Angle: ${yawAngle.toStringAsFixed(0)} degrees'),
                        Text('Yaw Direction: $yawDirection'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            const SizedBox(
              height: 10,
            ),
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
        compassHeading = snapshot.data?.heading;
        if (compassHeading == null) {
          return const Center(
            child: Text("Device does not have sensors !"),
          );
        }
        return NeuCircle(
          child: Transform.rotate(
            angle: (compassHeading! * (math.pi / 180) * -1),
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













// import 'package:flutter/material.dart';
// import 'dart:math';
// import 'dart:async';
// import 'package:sensors_plus/sensors_plus.dart';
// import 'dart:math' as math;
// import 'package:flutter_compass/flutter_compass.dart';
// import 'package:location/location.dart' as loc;
// import 'package:permission_handler/permission_handler.dart';
// import 'package:tow_botic_systems/Compass/neu_circle.dart';
// import 'package:flutter/services.dart';
//
//
// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   SystemChrome.setPreferredOrientations(
//     [
//       DeviceOrientation.portraitUp,
//       DeviceOrientation.portraitDown,
//     ],
//   );
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Tow Botics System',
//       theme: ThemeData(
//         useMaterial3: false,
//         colorSchemeSeed: const Color(0x9f4376f8),
//       ),
//       home: const MyHomePage(title: 'Tow Botics System'),
//     );
//   }
// }
//
// class MyHomePage extends StatefulWidget {
//   const MyHomePage({Key? key, this.title}) : super(key: key);
//   final String? title;
//
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> {
//   bool _hasPermissions = false;
//   loc.LocationData? currentLocation;
//   double? speed;
//
//   double integratedAngle = 0.0;
//   late Timer timer;
//
//   double rollAngle = 0; // Initial roll angle (set to 10 degrees)
//   double pitchAngle = 0; // Initial pitch angle
//   double yawAngle = 0; // Initial yaw angle
//   double initialYaw = 0; // Initial yaw when monitoring starts
//   double alpha = 0.98; // Complementary filter coefficient
//   String rollDirection = 'Not Rolling';
//   String pitchDirection = 'Not Tilting';
//   String yawDirection = 'Not Rotating';
//
//   @override
//   void initState() {
//     super.initState();
//
//     Timer.periodic(const Duration(seconds: 1), (Timer timer) {
//       // Update every second
//       accelerometerEvents.listen((AccelerometerEvent accelerometerEvent) {
//         gyroscopeEvents.listen((GyroscopeEvent gyroscopeEvent) {
//           double rollGyro = gyroscopeEvent.z;
//           double pitchGyro = gyroscopeEvent.x;
//           double yawGyro = gyroscopeEvent.y;
//           double rollAccel = _calculateRollAngle(
//               accelerometerEvent.x, accelerometerEvent.y, accelerometerEvent.z);
//           double pitchAccel = _calculatePitchAngle(
//               accelerometerEvent.x, accelerometerEvent.y, accelerometerEvent.z);
//
//           // Initialize initial yaw when monitoring starts
//           if (initialYaw == 0) {
//             initialYaw = yawGyro;
//           }
//
//           // Combine gyroscope and accelerometer data using a complementary filter
//           rollAngle = alpha * (rollAngle + rollGyro) + (1 - alpha) * rollAccel;
//           pitchAngle =
//               alpha * (pitchAngle + pitchGyro) + (1 - alpha) * pitchAccel;
//           yawAngle =
//               initialYaw + yawGyro; // Adjust yaw from the initial position
//
//           // Round off angle values
//           rollAngle = double.parse(rollAngle.toStringAsFixed(2));
//           pitchAngle = double.parse(pitchAngle.toStringAsFixed(2));
//           yawAngle = double.parse(yawAngle.toStringAsFixed(2));
//
//           // Update the direction based on the angles
//           rollDirection = getRollDirection(rollAngle);
//           pitchDirection = getPitchDirection(pitchAngle);
//           yawDirection = getYawDirection(yawAngle);
//
//           setState(() {});
//         });
//       });
//     });
//
//     gyroscopeEvents.listen((GyroscopeEvent event) {
//       // Convert angular velocity to radians per second
//       final angularVelocity = event.y; // Assuming z-axis for rolling angle
//
//       // Calculate the time interval (you can use a timer for better accuracy)
//       final timeInterval =
//           0.1000; // Change this to your desired interval in seconds
//
//       // Integrate angular velocity to get incremental angle change
//       final deltaAngle = angularVelocity * timeInterval;
//
//       // Update the integrated angle
//       integratedAngle += deltaAngle;
//
//       setState(() {});
//     });
//
//     _fetchPermissionStatus();
//     initLocation();
//
//     _streamSubscriptions.add(
//       userAccelerometerEvents.listen(
//         (UserAccelerometerEvent event) {
//           setState(() {
//             _userAccelerometerValues = <double>[event.x, event.y, event.z];
//           });
//         },
//         onError: (e) {
//           showDialog(
//               context: context,
//               builder: (context) {
//                 return const AlertDialog(
//                   title: Text("Sensor Not Found"),
//                   content: Text(
//                       "It seems that your device doesn't support Accelerometer Sensor"),
//                 );
//               });
//         },
//         cancelOnError: true,
//       ),
//     );
//     _streamSubscriptions.add(
//       accelerometerEvents.listen(
//         (AccelerometerEvent event) {
//           setState(() {
//             _accelerometerValues = <double>[event.x, event.y, event.z];
//           });
//         },
//         onError: (e) {
//           showDialog(
//               context: context,
//               builder: (context) {
//                 return const AlertDialog(
//                   title: Text("Sensor Not Found"),
//                   content: Text(
//                       "It seems that your device doesn't support Gyroscope Sensor"),
//                 );
//               });
//         },
//         cancelOnError: true,
//       ),
//     );
//     _streamSubscriptions.add(
//       gyroscopeEvents.listen(
//         (GyroscopeEvent event) {
//           setState(() {
//             _gyroscopeValues = <double>[event.x, event.y, event.z];
//           });
//         },
//         onError: (e) {
//           showDialog(
//               context: context,
//               builder: (context) {
//                 return const AlertDialog(
//                   title: Text("Sensor Not Found"),
//                   content: Text(
//                       "It seems that your device doesn't support User Accelerometer Sensor"),
//                 );
//               });
//         },
//         cancelOnError: true,
//       ),
//     );
//     _streamSubscriptions.add(
//       magnetometerEvents.listen(
//         (MagnetometerEvent event) {
//           setState(() {
//             _magnetometerValues = <double>[event.x, event.y, event.z];
//           });
//         },
//         onError: (e) {
//           showDialog(
//               context: context,
//               builder: (context) {
//                 return const AlertDialog(
//                   title: Text("Sensor Not Found"),
//                   content: Text(
//                       "It seems that your device doesn't support Magnetometer Sensor"),
//                 );
//               });
//         },
//         cancelOnError: true,
//       ),
//     );
//   }
//
//   double _calculateRollAngle(double x, double y, double z) {
//     return -1 * atan2(-x, sqrt(y * y + z * z)) * (180 / pi);
//   }
//
//   double _calculatePitchAngle(double x, double y, double z) {
//     return atan2(y, sqrt(x * x + z * z)) * (180 / pi);
//   }
//
//   String getRollDirection(double angle) {
//     if (angle > 0) {
//       return 'Rolling to Port';
//     } else if (angle < 0) {
//       return 'Rolling to Starboard';
//     } else {
//       return 'Not Rolling';
//     }
//   }
//
//   String getPitchDirection(double angle) {
//     if (angle > 0) {
//       return 'By Stern'; // Pitch Upward
//     } else if (angle < 0) {
//       return 'By Head'; // Pitch Downward
//     } else {
//       return 'Not Tilting';
//     }
//   }
//
//   String getYawDirection(double angle) {
//     if (angle > 0.5) {
//       return 'Yaw to Starboard';
//     } else if (angle < -0.5) {
//       return 'Yaw to Port';
//     } else {
//       return 'Not Rotating';
//     }
//   }
//
//   void initLocation() async {
//     final location = loc.Location();
//     location.changeSettings(accuracy: loc.LocationAccuracy.high);
//
//     location.onLocationChanged.listen((loc.LocationData locationData) {
//       setState(() {
//         currentLocation = locationData;
//         speed = locationData.speed;
//       });
//     });
//   }
//
//   List<double>? _userAccelerometerValues;
//   List<double>? _accelerometerValues;
//   List<double>? _gyroscopeValues;
//   List<double>? _magnetometerValues;
//   final _streamSubscriptions = <StreamSubscription<dynamic>>[];
//
//   @override
//   Widget build(BuildContext context) {
//
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Center(child: Text('Mobile Sensors Data')),
//         elevation: 4,
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: <Widget>[
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
//             Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: <Widget>[
//                   if (currentLocation != null)
//                     Text(
//                       'Latitude: ${currentLocation!.latitude}',
//                       style: const TextStyle(color: Colors.black),
//                     ),
//                   const SizedBox(
//                     height: 10,
//                   ),
//                   if (currentLocation != null)
//                     Text('Longitude: ${currentLocation!.longitude}',
//                         style: const TextStyle(color: Colors.black)),
//                   const SizedBox(
//                     height: 10,
//                   ),
//                   if (speed != null)
//                     Text('Speed (km/h): ${speed!.toStringAsFixed(2)}',
//                         style: const TextStyle(color: Colors.black)),
//                   const SizedBox(
//                     height: 10,
//                   ),
//                   if (speed != null)
//                     Text(
//                         'Speed (Knots): ${(speed! * 0.539957).toStringAsFixed(2)}',
//                         style: const TextStyle(color: Colors.black)),
//                 ],
//               ),
//             ),
//             const SizedBox(
//               height: 10,
//             ),
//             const SizedBox(
//               height: 10,
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   const Text('Gyroscope Values',
//                       style: TextStyle(fontWeight: FontWeight.bold)),
//                   const SizedBox(
//                     height: 10,
//                   ),
//                   Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: <Widget>[
//                         Text(
//                             'Roll Angle: ${rollAngle.toStringAsFixed(0)} degrees'),
//                         Text('Roll Direction: $rollDirection'),
//                         const SizedBox(height: 20),
//                         Text(
//                             'Pitch Angle: ${pitchAngle.toStringAsFixed(0)} degrees'),
//                         Text('Pitch Direction: $pitchDirection'),
//                         const SizedBox(height: 20),
//                         Text(
//                             'Yaw Angle: ${yawAngle.toStringAsFixed(0)} degrees'),
//                         Text('Yaw Direction: $yawDirection'),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(
//               height: 10,
//             ),
//             const SizedBox(
//               height: 10,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     for (final subscription in _streamSubscriptions) {
//       subscription.cancel();
//     }
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
