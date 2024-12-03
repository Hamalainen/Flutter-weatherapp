import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart' as xml;

class Weather {
  final DateTime time;
  final double airtemp;
  final int elevation;
  final String summary;
  final int freezingPoint;
  const Weather({
    required this.time,
    required this.airtemp,
    required this.summary,
    required this.elevation,
    required this.freezingPoint,
  });
}



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 6, 15, 136)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
   late Future<List<Polyline<Object>>> polylinesLayer;

  final List<Marker> _markerList = [];

  void _updatemarkers(Marker tmp) {
    setState(() {
      for (var marker in _markerList) {
        if (marker.point == tmp.point) {
          _markerList.remove(marker);
        }
      }
      _markerList.add(tmp);
    });
  }

  void _closeWeatherData(LatLng latilongi) {
    setState(() {
      for (var marker in _markerList) {
        if (marker.point == latilongi) {
          _markerList.remove(marker);
        }
      }
    });
  }

  Future<List<xml.XmlDocument>> readgpx() async {
    List<xml.XmlDocument> xmlList = [];

    final AssetManifest assetManifest =
        await AssetManifest.loadFromAssetBundle(rootBundle);
    final List<String> assets = assetManifest.listAssets();
    for (var asset in assets) {
      if (asset.substring(asset.length - 4) == '.gpx') {
        try {
          xmlList
              .add(xml.XmlDocument.parse(await rootBundle.loadString(asset)));
        } catch (e) {
          print(e);
        }
      }
    }
    return xmlList;
  }

  Future<List<Polyline<Object>>> _getPolylines() async {
    List<Polyline> polyLines = [];
    var gpxStrings = await readgpx();

    for (var gpxString in gpxStrings) {
      for (var segment in gpxString.findAllElements('trkseg')) {
        List<LatLng> polySegment = [];
        for (var trackpath in segment.findAllElements('trkpt')) {
          polySegment.add(LatLng(
              double.parse(trackpath.getAttribute('lat').toString()),
              double.parse(trackpath.getAttribute('lon').toString())));
        }
        polyLines.add(Polyline(
            points: polySegment,
            color: Colors.blue,
            // pattern: const StrokePattern.solid()
            ));
      }
    }
    return polyLines;
  }

  Future<void> _openWeatherData(now, LatLng latilongi) async {
    int elevation = await _getGroundElevation(latilongi);
    var weatherOnGround = await _getWeatherWithAltitude(latilongi, elevation);
    int freezingPoint = await _findfreezingPoint(latilongi, elevation);

    Weather now = Weather(
        time: DateTime.parse(weatherOnGround[2]['time']),
        airtemp: weatherOnGround[2]['data']['instant']['details']
            ['air_temperature'],
        elevation: elevation,
        freezingPoint: freezingPoint,
        summary: weatherOnGround[2]['data']['next_1_hours']['summary']
            ['symbol_code']);

    var weatherlist = [];
    for (var i = 2; i < 26; i++) {
      int freezingpoint =
          await _findfreezingPoint(latilongi, elevation, timeIndex: i);
      weatherlist.add(Weather(
          time: DateTime.parse(weatherOnGround[i]['time']),
          airtemp: weatherOnGround[i]['data']['instant']['details']
              ['air_temperature'],
          freezingPoint: freezingpoint,
          elevation: -1,
          summary: ''));
    }

    _updatemarkers(Marker(
        height: 700,
        width: 400,
        point: latilongi,
        child: Container(
            color: Colors.white,
            height: double.infinity,
            width: double.infinity,
            child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    Column(
                      children: [
                        TextButton(
                            onPressed: () => {_closeWeatherData(latilongi)},
                            child: const Text('Close')),
                        const Padding(
                            padding: EdgeInsets.all(2),
                            child: Row(
                              children: [
                                Expanded(child: Text('Time')),
                                Expanded(child: Text('Air temperature')),
                                Expanded(child: Text('Freezing point'))
                              ],
                            ))
                      ],
                    ),
                    Column(
                        children: List.generate(weatherlist.length, (index) {
                      return Padding(
                          padding: const EdgeInsets.all(2),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Text(
                                      '${weatherlist[index].time.hour}:${weatherlist[index].time.minute < 10 ? '0${weatherlist[index].time.minute}' : now.time.minute}')),
                              Expanded(
                                  child:
                                      Text('${weatherlist[index].airtemp}°C')),
                              Expanded(
                                  child: Text(
                                      '${weatherlist[index].freezingPoint}m'))
                            ],
                          ));
                    })),
                  ],
                )))));
  }

  _getWeatherWithAltitude(LatLng latilongi, int elevation) async {
    final weatherOnGround = await http.get(Uri.parse(
        'https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=${latilongi.latitude}&lon=${latilongi.longitude}&altitude=${elevation}'));
    return jsonDecode(weatherOnGround.body)['properties']['timeseries'];
  }

  _getGroundElevation(LatLng latilongi) async {
    final elevationResponse = await http.get(Uri.parse(
        'https://corsproxy.io/?https://api.opentopodata.org/v1/eudem25m?locations=${latilongi.latitude},${latilongi.longitude}'));
    return jsonDecode(elevationResponse.body)['results'][0]['elevation']
        .toInt();
  }

  _findfreezingPoint(LatLng latilongi, int elevation,
      {int timeIndex = 2}) async {
    bool foundFreezing = false;

    int freezingPoint = elevation;
    while (!foundFreezing) {
      var data = await _getWeatherWithAltitude(latilongi, freezingPoint);
      if (data[timeIndex]['data']['instant']['details']['air_temperature'] >
          0.3) {
        freezingPoint += 250;
      } else if (data[timeIndex]['data']['instant']['details']
              ['air_temperature'] <
          -0.3) {
        freezingPoint -= 25;
      } else {
        freezingPoint -= elevation;

        foundFreezing = true;
      }
    }
    return freezingPoint;
  }

  void _getWeather(LatLng latilongi) async {
    int elevation = await _getGroundElevation(latilongi);
    var groundData = await _getWeatherWithAltitude(latilongi, elevation);
    int freezingPoint = elevation;
    if (groundData[2]['data']['instant']['details']['air_temperature'] > 0) {
      freezingPoint = await _findfreezingPoint(latilongi, elevation);
    }

    Weather now = Weather(
        time: DateTime.parse(groundData[2]['time']),
        airtemp: groundData[2]['data']['instant']['details']['air_temperature'],
        elevation: elevation,
        freezingPoint: freezingPoint,
        summary: groundData[2]['data']['next_1_hours']['summary']
            ['symbol_code']);
    _updatemarkers(Marker(
        height: 220,
        width: 220,
        point: latilongi,
        child: Padding(
            padding: const EdgeInsets.all(30),
            child: Container(
                color: Colors.white,
                height: double.infinity,
                width: double.infinity,
                child: Column(
                  children: [
                    TextButton(
                        onPressed: () => {_closeWeatherData(latilongi)},
                        child: const Text('Close')),
                    Text(
                        '${now.time.hour}:${now.time.minute < 10 ? '0${now.time.minute}' : now.time.minute}'),
                    Text(' ${now.airtemp}°C'),
                    Text('Elevation ${now.elevation}m'),
                    Text('Freezing point ${now.freezingPoint}m'),
                    TextButton(
                        onPressed: () => {_openWeatherData(now, latilongi)},
                        child: const Text('More info')),
                  ],
                )))));
  }

  @override
  void initState() {
    super.initState();
    polylinesLayer = _getPolylines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(62.598858, 17.049204),
              initialZoom: 14,
              onTap: (tapPosition, point) => _getWeather(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
                tileProvider: CancellableNetworkTileProvider(),
              ),
              FutureBuilder<List<Polyline<Object>>>(
                  future: polylinesLayer,
                  builder: (context,
                      AsyncSnapshot<List<Polyline<Object>>> snapshot) {
                    if (snapshot.hasData) {
                      return PolylineLayer(polylines: snapshot.data!);
                    } else {
                      return const CircularProgressIndicator();
                    }
                  }),
              MarkerLayer(
                markers: _markerList,
                alignment: const Alignment(0.75,0.75),
              )
            ],
          ),
        ],
      ),
    );
  }
}
