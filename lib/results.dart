import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:path_provider/path_provider.dart';


class ResultsPage extends StatefulWidget {
    const ResultsPage({super.key});
    @override
    State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
    List<File> routeFiles = [];
    bool  isLoading = true;

    @override
    void initState() {
        super.initState();
        loadRoutes();
    }

    Future<void> loadRoutes() async {
        final directory = await getApplicationDocumentsDirectory();
        final files = directory
            .listSync()
            .whereType<File>()
            .where(
                (file) =>
                    file.path.endsWith('.geojson') &&
                    file.path.split(Platform.pathSeparator).last.startsWith('trasa_')
            ).toList();

        files.sort.((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        
        if (!mounted) return;

        setState(() {
            routeFiles = files;
            isLoading = false;
        });
    }

    Future<void> deleteRoute (File file) async {
        await file.delete();
        await loadRoutes();
    }

    String formatDate(DateTime date) {
        final day = date.day.toString().padLeft(2, '0');
        final month = date.month.toString().padLeft(2, '0');
        final year = date.year.toString();
        final hour = date.hour.toString().padLeft(2, '0');
        final minute = date.minute.toString().padLeft(2, '0');
        return '$day.$month.$year $hour:$minute';
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Zapisane wyniki'),
                leading: IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Wróć do mapy',
                    onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                    },
                ),
            ),
            
            body: isLoading
                ? const Center(child: CircularProgressIndicator())
                : routeFiles.isEmpty
                ? const Center(child: Text('Brak zapisanych tras',
                        style: TextStyle(fontSize: 20)))

                : ListView.builder(
                    itemCount: routeFiles.length,
                    itemBuilder: (content, index) {
                        final file = routeFiles[index];
                        final fileName = file.path.split(Platform.pathSeparator).last;
                        return ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.route)),
                            title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(formatDate(file.lastModifiedSync())),
                            trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                    showDialog(
                                        context: context,
                                        builder: (context) {
                                            return AlertDialog(
                                                title: const Text('Usuń trasę'),
                                                content: const Text('Czy na pewno chcesz usunąc trasę?'),
                                                actions: [
                                                    TextButton(
                                                        onPressed: () {
                                                            Navigator.pop(context);
                                                        },
                                                        child: const Text('Anuluj')
                                                    ),
                                                    TextButton(
                                                        onPressed: () async {
                                                            Navigator.pop(context);
                                                            await deleteRoute(file);
                                                        },
                                                        child: const Text('Usuń')
                                                    ),
                                                ],
                                            );
                                        },
                                    );
                                },
                            ),

                            onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            RouteDetailsPage(filePath: file.path),
                                    ),
                                );
                            },
                        );
                    },
                ),
        );
    }
}

class RouteDetailsPage extends StatefulWidget {
    final String filePath;
    const RouteDetailsPage({super.key, required this.filePath});

    @override
    State<RouteDetailsPage> createState() => _RouteDetailsPageState();
  }

  class _RouteDetailsPageState extends State<RouteDetailsPage> {
    List<LatLng> routePoints = [];
    double distsance = 0.0;
    Duration duration = Duration.zero;
    double averageSpeed = 0.0;
    bool isLoading = true;

    @override
    void initState() {
        super.initState();
        loadRoute();
    }

    Future<void> loadRoute() async {
        try {
            final file = File(widget.filePath);
            final content = await file.readAsString();
            final geoJson = jsonDecode(content);

            final pointsData = geoJson['properties']['points'] as List;

            routePoints = pointsData
                .map(
                    (points) => LatLng(
                        (points['latitude'] as num).toDouble(),
                        (points['longitude'] as num).toDouble(),
                    ),
                ).toList();
            
            final distanceCalculator = const Distance();
            double totalDistance = 0.0;

            for (int i = 1; i < routePoints.length ; i++) {
                totalDistance += distanceCalculator.as(
                    LengthUnit.Meter,
                    routePoints[i-1],
                    routePoints[i],
                );
            }

            final timestamps = pointsData
                .map((point) => point['timestamp'])
                .where((timestamp) => timestamp != null)
                .map((timestamp) => DateTime.parse(timestamp.toString()))
                .toList();
            
            if (timestamps.length >= 2) {
                final startTime = timestamps.first;
                final endTime = timestamps.last;
                duration = endTime.difference(startTime);
            }

            if (duration.inSeconds > 0) {
                averageSpeed = (distsance / duration.inSeconds) * 3.6;
            } else {
                averageSpeed = 0.0;
            }

            if (!mounted) return;
            setState(() {
              isLoading = false;
            });
        } catch (e) {
            print('Błąd wczytywania strony: $e');
            if(!mounted) return;

            setState(() {
              isLoading = false;
            });
        }
    }

    String formatDuration (Duration duration) {
        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);
        final seconds = duration.inSeconds.remainder(60);

        if (hours > 0) {
            return '$hours h $minutes min $seconds s';
        }
        return '$minutes min $seconds s';
    }
  }