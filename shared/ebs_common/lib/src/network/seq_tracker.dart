class SeqTracker {
  int _lastSeq = 0;

  int get lastSeq => _lastSeq;

  List<(int from, int to)> apply(int incomingSeq) {
    if (incomingSeq <= _lastSeq) {
      return const [];
    }
    if (incomingSeq == _lastSeq + 1) {
      _lastSeq = incomingSeq;
      return const [];
    }
    final gap = (_lastSeq + 1, incomingSeq - 1);
    _lastSeq = incomingSeq;
    return [gap];
  }

  void reset(int toSeq) {
    _lastSeq = toSeq;
  }
}
