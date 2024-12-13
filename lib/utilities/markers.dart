 import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

Set<Marker> detailedMarker (LatLng latilongi, weatherlist, now, Function whenPressed) => 
{ Marker(
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
                            onPressed: () => {whenPressed},
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
                ))))};



Set<Marker> summaryMarker (LatLng latilongi, now, Function closePressed, Function moreInfoPressed) => 
{Marker(
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
                        onPressed: () => {closePressed},
                        child: const Text('Close')),
                    Text(
                        '${now.time.hour}:${now.time.minute < 10 ? '0${now.time.minute}' : now.time.minute}'),
                    Text(' ${now.airtemp}°C'),
                    Text('Elevation ${now.elevation}m'),
                    Text('Freezing point ${now.freezingPoint}m'),
                    TextButton(
                        onPressed: () => {moreInfoPressed},
                        child: const Text('More info')),
                  ],
                ))))};