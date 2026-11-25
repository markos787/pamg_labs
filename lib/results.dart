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

        files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        
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

    @override
    Widget build(BuildContext context) {

        if (isLoading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (routePoints.length < 2) {
            return Scaffold(
                appBar: AppBar(title: const Text('Wynik nieprawidłowy')),
                body: Center(child: Text('Brak wystaraczającej ilości danych trasy')),
            );
        }

        final center = routePoints.first;

        return Scaffold(
            appBar: AppBar(
                title: const Text('Wyniki trasy'),
                leading: IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Zamknij',
                    onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                    },
                ),
            ),

            body: Column(
                children: [
                    Expanded(
                        child: FlutterMap(
                            options: MapOptions(initialCenter: center, initialZoom: 15),
                            children: [
                                TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.pamg_labs',
                                    maxZoom: 19,
                                ),
                                PolylineLayer(polylines: [Polyline(points: routePoints, strokeWidth: 5)]),
                            ],
                        ),
                    ),

                    Expanded(
                        child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    const Text(
                                        'Statystyki mapy',
                                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 35),

                                    Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                            _Statistic(
                                                icon: Icons.route,
                                                title: 'Odległość',
                                                value: '${(distsance/1000).toStringAsFixed(2)} km',
                                            ),

                                            _Statistic(
                                                icon: Icons.timer,
                                                title: 'Czas',
                                                value: formatDuration(duration),
                                            ),

                                            _Statistic(
                                                icon: Icons.speed,
                                                title: 'Średnia prędkość',
                                                value: '${averageSpeed.toStringAsFixed(2)} km/h',
                                            ),
                                        ],
                                    ),
                                ],
                            ),
                        ),
                    ),
                ],
            ),
        );
    }
  }

  class _Statistic extends StatelessWidget {
    final IconData icon;
    final String title;
    final String value;

    const _Statistic({
        required this.icon,
        required this.title,
        required this.value,
    });

    @override
    Widget build(BuildContext context) {
        return Expanded(
            child: Column(
                children: [
                    Icon(icon, size: 35),
                    const SizedBox(height: 8),
                    Text(title, textAlign: TextAlign.center),
                    const SizedBox(height: 5),
                    Text(
                        value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                ],
            ),
        );
    }
  }