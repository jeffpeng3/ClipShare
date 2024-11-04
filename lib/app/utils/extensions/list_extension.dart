extension ListExt<T> on List<T> {
  List<List<T>> partition(int size) {
    List<List<T>> result = [];
    for (var i = 0; i < length; i += size) {
      int start = i;
      int end = i + size > length ? length : i + size;
      var subList = sublist(start, end);
      result.add(subList);
    }
    return result;
  }
}

extension ListEquals on List<int> {
  bool equals(List<int> other) {
    if (length != other.length) return false;
    for (int i = 0; i < length; i++) {
      if (this[i] != other[i]) return false;
    }
    return true;
  }
}
