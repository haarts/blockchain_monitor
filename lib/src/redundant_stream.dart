import 'dart:async';

import 'package:async/async.dart';

class AllStreamsFailed implements Exception {
  AllStreamsFailed(this.amount);
  final int amount;

  @override
  String toString() => 'AllStreamsFailed(originalNrOfStreams: $amount)';
}

class RedundantStream<T> {
  RedundantStream(Iterable<Stream<T>> streams) {
    _active = streams.length;
    stream = StreamGroup.merge(streams).transform(Unique()).handleError((_) {
      _active--;
      if (_active == 0) {
        throw AllStreamsFailed(streams.length);
      }
    });
  }

  int _active;
  Stream<T> stream;
}

class Unique<T> extends StreamTransformerBase<T, T> {
  const Unique({this.memory = 10});

  final int memory;

  Stream<T> bind(Stream<T> stream) => Stream<T>.eventTransformed(
      stream, (sink) => _UniqueSink<T>(sink, memory: memory));
}

class _UniqueSink<T> implements EventSink<T> {
  _UniqueSink(this._output, {this.memory = 10}) : _head = (memory / 5).ceil();

  final EventSink<T> _output;
  final Set<T> _seen = {};
  final int memory;
  final int _head;

  @override
  void add(T data) {
    // add it if we haven't seen it yet
    if (!_seen.contains(data)) {
      _seen.add(data);
      _output.add(data);
    }

    if (_seen.length > memory + _head) {
      _seen.removeAll(_seen.take(_head).toList());
    }
  }

  void addError(e, [st]) => _output.addError(e, st);
  void close() => _output.close();
}
