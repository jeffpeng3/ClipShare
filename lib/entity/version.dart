class Version{
  final String name;
  final String code;
  const Version(this.name,this.code);
  @override
  String toString() {
    return "$name($code)";
  }
}