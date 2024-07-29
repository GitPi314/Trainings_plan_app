import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:hive/hive.dart';

class SetRestTimerPage extends StatefulWidget {
  final int setIndex;
  final int restTime;

  const SetRestTimerPage({super.key, required this.setIndex, required this.restTime});

  @override
  _SetRestTimerPageState createState() => _SetRestTimerPageState();
}

class _SetRestTimerPageState extends State<SetRestTimerPage> {
  late Timer _timer;
  late int _remainingSeconds;
  late int _initialRestTime;
  bool _isRunning = true;
  List<int> favoriteTimes = [30, 60, 90];
  late Box<int> favoriteTimesBox;
  final Set<int> _selectedTimesForDeletion = {};
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    favoriteTimesBox = Hive.box<int>('favoriteTimesBox');
    favoriteTimes = favoriteTimesBox.values.toList();
    _initialRestTime = widget.restTime > 0 ? widget.restTime : 60; // Set default rest time if zero or negative
    _remainingSeconds = _initialRestTime;
    _startTimer();
  }

  void _startTimer() {
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer.cancel();
          _showTimerCompleteDialog();
          Vibrate.vibrate();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resumeTimer() {
    _startTimer();
    setState(() {
      _isRunning = true;
    });
  }

  void _showTimerCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rest Time Complete'),
        content: const Text('The rest time for this set is complete.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    ).then((_) {
      Navigator.pop(context);
    });
  }

  void _addFavoriteTime() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        int tempTime = _remainingSeconds;
        return DraggableScrollableSheet(
          initialChildSize: 0.3,
          minChildSize: 0.2,
          maxChildSize: 0.3,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: ListWheelScrollView.useDelegate(
                      controller: FixedExtentScrollController(
                        initialItem: (tempTime / 10).round() - 1,
                      ),
                      itemExtent: 50,
                      onSelectedItemChanged: (index) {
                        tempTime = (index + 1) * 10;
                      },
                      physics: const FixedExtentScrollPhysics(),
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) {
                          final time = (index + 1) * 10;
                          return Center(
                            child: Text(
                              '${time}s',
                              style: const TextStyle(fontSize: 24),
                            ),
                          );
                        },
                        childCount: 30,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        favoriteTimes.add(tempTime);
                        favoriteTimesBox.add(tempTime);
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${remainingSeconds.toString().padLeft(2, '0')}s';
    } else {
      return '${remainingSeconds}s';
    }
  }

  void _toggleTimeDeletion(int time) {
    setState(() {
      if (_selectedTimesForDeletion.contains(time)) {
        _selectedTimesForDeletion.remove(time);
      } else {
        _selectedTimesForDeletion.add(time);
      }
    });
  }

  void _deleteSelectedTimes() {
    setState(() {
      favoriteTimes = favoriteTimes.where((time) => !_selectedTimesForDeletion.contains(time)).toList();
      for (var time in _selectedTimesForDeletion) {
        final key = favoriteTimesBox.keys.firstWhere((k) => favoriteTimesBox.get(k) == time, orElse: () => null);
        if (key != null) {
          favoriteTimesBox.delete(key);
        }
      }
      _selectedTimesForDeletion.clear();
      _isDeleting = false;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        title: Text('Satz ${widget.setIndex}', style: const TextStyle(fontSize: 28, color: Colors.grey),),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, size: 35, color: Colors.grey,),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: 1 - (_remainingSeconds / (_initialRestTime > 0 ? _initialRestTime : 60)),
                    strokeWidth: 10,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  _formatDuration(_remainingSeconds),
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 30),
            IconButton(
              icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow, size: 48),
              onPressed: _isRunning ? _pauseTimer : _resumeTimer,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(_isDeleting ? Icons.check : Icons.delete, color: Colors.grey, size: 32),
                  onPressed: () {
                    if (_isDeleting) {
                      _deleteSelectedTimes();
                    } else {
                      setState(() {
                        _isDeleting = !_isDeleting;
                      });
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.grey, size: 32),
                  onPressed: _addFavoriteTime,
                ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: -30,
                //mainAxisAlignment: MainAxisAlignment.center,
                children: favoriteTimes.map((time) {
                  final isSelected = _selectedTimesForDeletion.contains(time);
                  return GestureDetector(
                    onTap: () {
                      if (_isDeleting) {
                        _toggleTimeDeletion(time);
                      } else {
                        setState(() {
                          _remainingSeconds = time;
                          _initialRestTime = time; // Update initial rest time
                        });
                      }
                    },
                    child: Container(
                      width: 120, // Set a fixed width for each container
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      padding: const EdgeInsets.all(23.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: isSelected ? Colors.grey : Colors.blue, width: 2.0),
                        color: isSelected ? Colors.grey.withOpacity(0.3) : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          _formatDuration(time),
                          style: const TextStyle(color: Colors.blue, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
