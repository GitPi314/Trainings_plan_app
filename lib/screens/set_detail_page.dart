import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/exercise.dart';
import '../models/set.dart';

class SetDetailPage extends StatefulWidget {
  final Exercise exercise;

  const SetDetailPage({super.key, required this.exercise});

  @override
  _SetDetailPageState createState() => _SetDetailPageState();
}

class _SetDetailPageState extends State<SetDetailPage> {
  late Box<Set> setBox;
  late Box<Exercise> exerciseBox;
  List<Set> sets = [];
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    setBox = Hive.box<Set>('setBox');
    exerciseBox = Hive.box<Exercise>('exerciseBox');
    sets = setBox.values.where((s) => s.exerciseId == widget.exercise.key).toList();
    _notesController.text = widget.exercise.notes ?? "";
  }

  void _addSet() {
    final newSet = Set(
      exerciseId: widget.exercise.key as int,
      initialWeight: 0.0,
    );
    setBox.add(newSet);
    setState(() {
      sets = setBox.values.where((s) => s.exerciseId == widget.exercise.key).toList();
    });
  }

  void _deleteSet(int index) {
    setBox.delete(sets[index].key);
    setState(() {
      sets = setBox.values.where((s) => s.exerciseId == widget.exercise.key).toList();
    });
  }

  void _saveNotes() {
    widget.exercise.notes = _notesController.text;
    widget.exercise.save();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Satz', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.blue)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Wdh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.blue), textAlign: TextAlign.center),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Gewicht', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.blue), textAlign: TextAlign.center),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Pause', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.blue), textAlign: TextAlign.center),
                  ),
                  SizedBox(width: 50), // Platzhalter für das Minus-Symbol
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: sets.length + 1, // +1 für den Button
                itemBuilder: (context, index) {
                  if (index == sets.length) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _addSet,
                            child: const Text('+ Satz hinzufügen', style: TextStyle(fontSize: 20, color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(height: 25),
                        const Divider(),
                        Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent, // Entfernt den unteren Strich
                            iconTheme: const IconThemeData(color: Colors.grey), // Farbe des Dreiecks
                            textTheme: Theme.of(context).textTheme.copyWith(
                              titleMedium: const TextStyle(color: Colors.blue, fontSize: 20), // Titel des ExpansionTile
                            ),
                          ),
                          child: ExpansionTile(
                            title: const Text('Notizen', style: TextStyle(fontSize: 20, color: Colors.grey)),
                            collapsedIconColor: Colors.grey,
                            iconColor: Colors.grey,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: TextFormField(
                                  controller: _notesController,
                                  maxLines: 5,
                                  decoration: const InputDecoration(
                                    hintText: 'Bemerkungen zur Übung',
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.blue), // Farbe der Umrandung, wenn ausgewählt
                                    ),
                                  ),
                                  onChanged: (value) {
                                    _saveNotes();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  final set = sets[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    padding: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: const Color(0XFF25232A),
                      borderRadius: BorderRadius.circular(50.0),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 18.0),
                            child: Text((index + 1).toString(), style: const TextStyle(fontSize: 23, color: Colors.white)),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: set.reps.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            style: TextStyle(fontSize: 22, color: set.reps > set.initialReps ? Colors.green : Colors.white),
                            textAlign: TextAlign.center,
                            onChanged: (value) {
                              final newValue = int.tryParse(value) ?? 0;
                              set.reps = newValue;
                              set.save();
                              setState(() {});
                            },
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: set.weight.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            style: TextStyle(fontSize: 22, color: set.weight > set.initialWeight ? Colors.green : Colors.white),
                            textAlign: TextAlign.center,
                            onChanged: (value) {
                              final newValue = double.tryParse(value) ?? 0.0;
                              set.weight = newValue;
                              set.save();
                              setState(() {});
                            },
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: set.rest.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            style: TextStyle(fontSize: 22, color: set.rest > set.initialRest ? Colors.green : Colors.white),
                            textAlign: TextAlign.center,
                            onChanged: (value) {
                              final newValue = int.tryParse(value) ?? 0;
                              set.rest = newValue;
                              set.save();
                              setState(() {});
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle),
                          onPressed: () {
                            _deleteSet(index);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
