/// 表示应用中的一个位置（URL）。
///
/// Location 包含了描述 URL 的所有信息，包括路径、查询参数、哈希片段和状态。
class Location {
  /// 创建一个新的 Location 实例。
  ///
  /// [pathname] 是 URL 的路径部分，例如 "/users/123"。
  /// [search] 是 URL 的查询字符串部分，例如 "?page=1"。
  /// [hash] 是 URL 的片段标识符部分，例如 "#section1"。
  /// [state] 是与此位置关联的任意状态对象。
  /// [key] 是此位置的唯一标识符。
  Location({
    required this.pathname,
    this.search = '',
    this.hash = '',
    this.state,
    String? key,
  }) : key = key ?? _generateKey();

  /// 从路径字符串创建 Location。
  ///
  /// 支持完整的 URL 路径，包括查询参数和哈希。
  ///
  /// 示例：
  /// ```dart
  /// Location.fromPath('/users/123');
  /// Location.fromPath('/users/123?page=1');
  /// Location.fromPath('/users/123?page=1#profile');
  /// Location.fromPath('/users/123', state: {'id': 123});
  /// ```
  factory Location.fromPath(String path, {Object? state}) {
    // 提取哈希部分
    final hashIndex = path.indexOf('#');
    final hash = hashIndex >= 0 ? path.substring(hashIndex) : '';
    final pathWithoutHash = hashIndex >= 0 ? path.substring(0, hashIndex) : path;

    // 提取查询参数部分
    final searchIndex = pathWithoutHash.indexOf('?');
    final search = searchIndex >= 0 ? pathWithoutHash.substring(searchIndex) : '';
    final pathname = searchIndex >= 0 ? pathWithoutHash.substring(0, searchIndex) : pathWithoutHash;

    return Location(
      pathname: pathname,
      search: search,
      hash: hash,
      state: state,
    );
  }

  /// URL 的路径部分。
  ///
  /// 例如："/users/123"
  final String pathname;

  /// URL 的查询字符串部分（包含前导 "?"）。
  ///
  /// 例如："?page=1&sort=desc"
  /// 如果没有查询参数，则为空字符串。
  final String search;

  /// URL 的片段标识符部分（包含前导 "#"）。
  ///
  /// 例如："#section1"
  /// 如果没有哈希，则为空字符串。
  final String hash;

  /// 与此位置关联的状态对象。
  ///
  /// 可以是任何可序列化的对象。在某些 History 实现中，
  /// 此对象可能有大小限制（例如浏览器的 640KB 限制）。
  final Object? state;

  /// 此位置的唯一标识符。
  ///
  /// 用于在历史堆栈中唯一标识此位置。
  final String key;

  /// 复制此 Location 并可选地覆盖某些属性。
  Location copyWith({
    String? pathname,
    String? search,
    String? hash,
    Object? state,
    String? key,
  }) {
    return Location(
      pathname: pathname ?? this.pathname,
      search: search ?? this.search,
      hash: hash ?? this.hash,
      state: state ?? this.state,
      key: key ?? this.key,
    );
  }

  /// 将此 Location 转换为完整的 URL 字符串。
  ///
  /// 不包含协议、主机或端口。
  String toUrl() {
    final buffer = StringBuffer(pathname);
    if (search.isNotEmpty) {
      buffer.write(search.startsWith('?') ? search : '?$search');
    }
    if (hash.isNotEmpty) {
      buffer.write(hash.startsWith('#') ? hash : '#$hash');
    }
    return buffer.toString();
  }

  @override
  String toString() {
    return 'Location(pathname: $pathname, search: $search, hash: $hash, key: $key)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location &&
        other.pathname == pathname &&
        other.search == search &&
        other.hash == hash &&
        other.key == key &&
        other.state == state;
  }

  @override
  int get hashCode {
    return Object.hash(pathname, search, hash, key, state);
  }

  /// 生成一个唯一的键。
  static String _generateKey() {
    // 使用时间戳和随机数生成唯一键
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = (timestamp * 0x41C64E6D + 0x3039) & 0xFFFFFFFF;
    return random.toRadixString(36);
  }
}
