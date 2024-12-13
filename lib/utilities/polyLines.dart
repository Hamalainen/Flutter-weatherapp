import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart' as xml;

Future<List<Polyline<Object>>> getPolylines() async {
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