part of discovery_api_client_generator;

class Config {
  String get clientVersion => "0.4";

  bool get isDev => false;

  String get dartEnvironmentVersionConstraint => '>=1.0.0 <2.0.0';

  Map<String, String> get dependencyVersions => const {
    'google_oauth2_client': " '>=0.3.2 <0.4.0'",
    'meta': " '>=0.8.8 <0.9.0'"
  };

  Map<String, String> get devDependencyVersions => const {
    'hop': " '>=0.30.2 <0.31.0'",
  };

  const Config();

  void writeAllDependencies(StringSink sink) {
    sink.writeln("dependencies:");
    forEachOrdered(dependencyVersions, (String lib, String constraint) {
      sink.writeln("  $lib:$constraint");
    });

    sink.writeln("dev_dependencies:");
    forEachOrdered(devDependencyVersions, (String lib, String constraint) {
      sink.writeln("  $lib:$constraint");
    });
  }

  String getLibraryVersion(int clientVersionBuild) {
    assert(clientVersionBuild >= 0);
    var value = "$clientVersion.${clientVersionBuild}";
    if(isDev) {
      value = "$value-dev";
    }
    return value;
  }
}
