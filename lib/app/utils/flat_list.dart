class FlatList<T> {
  final List<List<T>> _lists = [];
  int _length = 0;

  int get length => _length;

  get isEmpty => length == 0;

  get isNotEmpty => !isEmpty;

  void add(List<T> list) {
    _lists.add(list);
    _length += list.length;
  }

  List<int> _convertIndex(int index) {
    index++;
    for (var i = 0; i < _lists.length; i++) {
      if (index > _lists[i].length) {
        index -= _lists[i].length;
      } else {
        return [i, index - 1];
      }
    }
    throw RangeError('Index out of range $length:$index');
  }

  T operator [](int index) {
    final [i, j] = _convertIndex(index);
    return _lists[i][j];
  }

  List<T> sublist(int start, [int? end]) {
    end ??= length;
    //开始截取的坐标
    final [si, sj] = _convertIndex(start);
    //结束截取的坐标
    final [ei, ej] = _convertIndex(end - 1);
    //开始和结束坐标位于同一个list
    if (ei == si) return _lists[si].sublist(sj, ej + 1);
    List<T> result = [];
    for (var i = si; i <= ei; i++) {
      if (i == si) {
        result.addAll(_lists[si].sublist(sj));
      } else if (i == ei) {
        result.addAll(_lists[ei].sublist(0, sj + 1));
      } else {
        result.addAll(_lists[i]);
      }
    }
    return result;
  }

  void removeRange(int start, int end) {
    //开始截取的坐标
    final [si, sj] = _convertIndex(start);
    //结束截取的坐标
    final [ei, ej] = _convertIndex(end - 1);
    List<T> subList = [];
    subList.addAll(_lists[si].sublist(0, sj));
    if (ej + 1 < _lists[ei].length) {
      //结束坐标小于list长度时截取剩余部分
      subList.addAll(_lists[ei].sublist(ej + 1));
    }
    _lists[si] = subList;
    if (si != ei) {
      _lists.removeRange(si + 1, ei + 1);
    }
    _length -= end - start;
  }
}
