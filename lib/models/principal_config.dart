class PrincipalConfig {
  final String host;
  final int port;
  final String teacher;
  final String code;

  const PrincipalConfig({
    required this.host,
    required this.port,
    required this.teacher,
    required this.code,
  });

  String get baseUrl => 'http://$host:$port';

  Map<String, dynamic> toJson() => {
        'host': host,
        'port': port,
        'teacher': teacher,
        'code': code,
      };

  factory PrincipalConfig.fromJson(Map<String, dynamic> json) => PrincipalConfig(
        host: (json['host'] ?? '').toString(),
        port: int.tryParse((json['port'] ?? '').toString()) ?? 0,
        teacher: (json['teacher'] ?? '').toString(),
        code: (json['code'] ?? '').toString(),
      );
}
