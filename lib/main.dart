import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

/*
! Highly Efficient Lookups (Separate Chaining)
? - use Array of LinkedLists and a HashCode Function
? - To insert a Entry: Key -> might be a String | Value -> Some Value
? - 1º: Compute key's hashcode (two different Keys can have the same Hashcode)
? - 2º: Infinite Number of Keys and limit number of int
? - 3º: Map HashCode to an index in the array (hash % _buckets.length).
? - 4º: At This index there is a LinkedList of Entry(key,value) 
? - 5º: Have to use LikedLists because of collisions
? - 6º: You can have Two differnt keys with the same hashcode, or 
? -     two different hashcode that map to the same index.
*/

/// Entry class with [key] and [value] based on types you associate [K] and [V]
final class _Entry<K, V> extends LinkedListEntry<_Entry<K, V>> {
  final K key;
  V value;
  _Entry(this.key, this.value);

  @override
  String toString() {
    return "($key, $value)";
  }
}

/// Separate Chaining Impl with [LinkedList] and [_Entry]
class ChainedHashMap<K, V> extends MapBase<K, V> {
  final int _bucketCount;
  final List<LinkedList<_Entry<K, V>>> _buckets;

  ChainedHashMap({int bucketCount = 8})
    : _bucketCount = bucketCount,
      _buckets = List.generate(bucketCount, (_) => LinkedList<_Entry<K, V>>());

  @override
  V? operator [](Object? key) {
    final hash = key.hashCode;
    final index = hash % _bucketCount;
    final bucket = _buckets[index];
    for (final e in bucket) {
      if (e.key == key) return e.value;
    }
    return null;
  }

  @override
  void operator []=(K key, V value) {
    final hash = key.hashCode;
    final index = hash % _bucketCount;
    final bucket = _buckets[index];
    for (var e in bucket) {
      if (e.key == key) {
        e.value = value;
        return;
      }
    }
    final entry = _Entry(key, value);
    bucket.add(entry);
    // print("Mapped INDEX for $entry : $index");
  }

  @override
  void clear() {
    for (var bucket in _buckets) {
      bucket.clear();
    }
  }

  @override
  Iterable<K> get keys sync* {
    for (var bucket in _buckets) {
      for (var e in bucket) {
        yield e.key;
      }
    }
  }

  @override
  V? remove(Object? key) {
    final hash = key.hashCode;
    final index = hash % _buckets.length;

    final bucket = _buckets[index];
    for (var e in bucket) {
      if (e.key == key) {
        final oldValue = e.value;
        e.unlink();
        return oldValue;
      }
    }

    return null;
  }
}

class MainAppCubit extends Cubit<MainAppState> {
  MainAppCubit()
    : super(
        MainAppState(
          isListGenerated: false,
          list: [],
          isLoadingList: false,
          isLoadingHashMap: false,
          hashMap: ChainedHashMap<String, int>(),
          listLookUpElapsedMicrosec: 0,
          hashtableLookUpElapsedMicrosec: 0,
          isLookingUpHashTable: false,
          isLookingUpList: false,
          isHashMapGenerated: false,
          isHashMapLookedUp: false,
          isListLookedUp: false,
        ),
      );
  final Stopwatch stopwatch = Stopwatch();

  void generateList() {
    emit(state.copywith(isLoadingList: true));
    final list = List.generate(100000, (index) => "arthur $index"); //! HERE
    emit(state.copywith(list: list, isLoadingList: false, isListGenerated: true));
  }

  void populateHashMap() {
    emit(state.copywith(isLoadingHashMap: true));
    final hashMap = ChainedHashMap<String, int>(bucketCount: 100);
    for (var element in state.list) {
      hashMap[element] = Random().nextInt(100);
    }
    emit(state.copywith(isLoadingHashMap: false, hashMap: hashMap, isHashMapGenerated: true));
  }

  void listLookUp(String value) {
    emit(state.copywith(isLookingUpList: true, isListLookedUp: false,));
    stopwatch.reset();
    stopwatch.start();
    state.list.indexOf(value);
    stopwatch.stop();

    emit(
      state.copywith(
        listLookUpElapsedMicrosec: stopwatch.elapsedMicroseconds,
        isLookingUpList: false,
        isListLookedUp: true,
      ),
    );
  }

  void hashTableLookUp(String value) {
    emit(state.copywith(isLookingUpHashTable: true, isHashMapLookedUp: false,));
    stopwatch.reset();
    stopwatch.start();
    state.hashMap[value];
    stopwatch.stop();

    emit(
      state.copywith(
        hashtableLookUpElapsedMicrosec: stopwatch.elapsedMicroseconds,
        isLookingUpHashTable: false,
        isHashMapLookedUp: true,
      ),
    );
  }
}

class MainAppState extends Equatable {
  final bool isListGenerated;
  final bool isHashMapGenerated;
  final List list;
  final bool isLoadingList;
  final bool isLoadingHashMap;
  final ChainedHashMap<String, int> hashMap;
  final int listLookUpElapsedMicrosec;
  final int hashtableLookUpElapsedMicrosec;
  final bool isLookingUpList;
  final bool isLookingUpHashTable;
  final bool isListLookedUp;
  final bool isHashMapLookedUp;

  const MainAppState({
    required this.isListGenerated,
    required this.list,
    required this.isLoadingList,
    required this.hashMap,
    required this.isLoadingHashMap,
    required this.listLookUpElapsedMicrosec,
    required this.hashtableLookUpElapsedMicrosec,
    required this.isLookingUpList,
    required this.isLookingUpHashTable,
    required this.isHashMapGenerated,
    required this.isListLookedUp,
    required this.isHashMapLookedUp,
  });

  MainAppState copywith({
    bool? isListGenerated,
    List? list,
    bool? isLoadingList,
    ChainedHashMap<String, int>? hashMap,
    bool? isLoadingHashMap,
    int? listLookUpElapsedMicrosec,
    int? hashtableLookUpElapsedMicrosec,
    bool? isLookingUpHashTable,
    bool? isLookingUpList,
    bool? isHashMapGenerated,
    bool? isListLookedUp,
    bool? isHashMapLookedUp,
  }) {
    return MainAppState(
      isListGenerated: isListGenerated ?? this.isListGenerated,
      list: list ?? this.list,
      isLoadingList: isLoadingList ?? this.isLoadingList,
      hashMap: hashMap ?? this.hashMap,
      isLoadingHashMap: isLoadingHashMap ?? this.isLoadingHashMap,
      hashtableLookUpElapsedMicrosec:
          hashtableLookUpElapsedMicrosec ?? this.hashtableLookUpElapsedMicrosec,
      listLookUpElapsedMicrosec:
          listLookUpElapsedMicrosec ?? this.listLookUpElapsedMicrosec,
      isLookingUpHashTable: isLookingUpHashTable ?? this.isLookingUpHashTable,
      isLookingUpList: isLookingUpList ?? this.isLookingUpList,
      isHashMapGenerated: isHashMapGenerated ?? this.isHashMapGenerated,
      isHashMapLookedUp: isHashMapLookedUp ?? this.isHashMapLookedUp,
      isListLookedUp: isListLookedUp ?? this.isListLookedUp,
    );
  }

  @override
  List<Object?> get props => [
    isListGenerated,
    list,
    isLoadingList,
    hashMap,
    isLoadingHashMap,
    hashtableLookUpElapsedMicrosec,
    listLookUpElapsedMicrosec,
    isLookingUpHashTable,
    isLookingUpList,
    isHashMapGenerated,
    isHashMapLookedUp,
    isListLookedUp,
  ];
}

void main() {
  runApp(
    BlocProvider(create: (context) => MainAppCubit(), child: const MainApp()),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: BlocBuilder<MainAppCubit, MainAppState>(
          builder: (context, state) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  state.isLoadingList
                      ? const CircularProgressIndicator()
                      : TextButton(
                          onPressed: () {
                            context.read<MainAppCubit>().generateList();
                          },
                          child: const Text("1º Generate List"),
                        ),
                  Text(
                    state.isListGenerated
                        ? "List Generated"
                        : "List Not Generated",
                  ),
                  SizedBox(height: 30),
                  state.isLoadingHashMap
                      ? const CircularProgressIndicator()
                      : TextButton(
                          onPressed: () {
                            context.read<MainAppCubit>().populateHashMap();
                          },
                          child: const Text("2º Populate HashMap"),
                        ),
                  Text(
                    state.isHashMapGenerated
                        ? "HashMap Generated"
                        : "HashMap Not Generated",
                  ),
                  SizedBox(height: 30),
                  state.isLookingUpHashTable
                      ? const CircularProgressIndicator()
                      : TextButton(
                          onPressed: () {
                            context.read<MainAppCubit>().hashTableLookUp(
                              "arthur 99999", //! HERE
                            );
                          },
                          child: const Text("3º LookUp HashMap"),
                        ),
                  Text(
                    state.isHashMapLookedUp
                        ? "HashMap Looked up | Elapsed: ${state.hashtableLookUpElapsedMicrosec} Microseconds"
                        : "HashMap Not Looked Up",
                  ),
                  SizedBox(height: 30),
                  state.isLookingUpList
                      ? const CircularProgressIndicator()
                      : TextButton(
                          onPressed: () {
                            context.read<MainAppCubit>().listLookUp(
                              "arthur 99999", //! HERE
                            );
                          },
                          child: const Text("3º LookUp List"),
                        ),
                  Text(
                    state.isListLookedUp
                        ? "List Looked up | Elapsed: ${state.listLookUpElapsedMicrosec} Microseconds"
                        : "List Not Looked Up",
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
