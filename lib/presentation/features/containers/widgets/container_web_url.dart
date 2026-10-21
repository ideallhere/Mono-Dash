import '../../../../domain/entities/server.dart';

/// 端口白名单之外的已知非 Web 端口（数据库/消息/SSH 等纯 TCP 服务）。
const Set<int> _nonWebPorts = {
  22, // SSH
  3306, // MySQL
  5432, // PostgreSQL
  6379, // Redis
  27017, // MongoDB
  9092, // Kafka
  5672, // RabbitMQ
  1883, // MQTT
  53, // DNS
};

/// 从 1Panel 容器 ports 字段解析宿主访问 URL 列表。
///
/// 1Panel 返回的 port 形如：
///   "0.0.0.0:5244->5244/tcp"   宿主端口 5244
///   "[::]:8080->80/tcp"        宿主端口 8080（IPv6 通配）
///   "127.0.0.1:3306->3306"     仅本机可达，外部访问不了，丢弃
///   "5244/tcp"                 未发布端口，无法从外部访问，丢弃
///
/// [server] 提供目标主机地址与协议偏好（1Panel 面板用了 https 时，
/// 容器大概率也在反代后面，但无确证时仍用 http；保留 host 一致性）。
List<Uri> extractWebUrls(List<String>? ports, Server server) {
  if (ports == null || ports.isEmpty) return const [];
  final urls = <Uri>[];
  for (final raw in ports) {
    final published = _publishedHostPort(raw);
    if (published == null) continue;
    final bindIp = published.$1;
    final hostPort = published.$2;
    if (hostPort == null) continue;
    if (_nonWebPorts.contains(hostPort)) continue;
    // 仅绑定本机回环的端口从外部访问不到，跳过
    if (bindIp != null &&
        (bindIp == '127.0.0.1' || bindIp == '::1' || bindIp == 'localhost')) {
      continue;
    }
    final uri = Uri(
      scheme: 'http',
      host: server.host,
      port: hostPort,
    );
    if (!urls.contains(uri)) urls.add(uri);
  }
  return urls;
}

/// 解析 "0.0.0.0:5244->5244/tcp" → ("0.0.0.0", 5244)
/// 未发布端口（"5244/tcp"）→ (null, null)
(String?, int?)? _publishedHostPort(String portEntry) {
  final arrow = portEntry.indexOf('->');
  final left = arrow >= 0 ? portEntry.substring(0, arrow) : null;
  if (left == null || left.isEmpty) return null;
  // left 形如 "0.0.0.0:5244" / "[::]:8080" / "5244"（仅宿主端口无绑定地址）
  final colon = left.lastIndexOf(':');
  if (colon < 0) {
    final p = int.tryParse(left.trim());
    return (null, p);
  }
  final hostPart = left.substring(0, colon).trim();
  final portPart = left.substring(colon + 1).trim();
  final p = int.tryParse(portPart);
  if (p == null) return null;
  return (hostPart.isEmpty ? null : hostPart, p);
}
