library discovery_api_streamy_client_generator;

import 'dart:async';
import 'dart:io' as io;
import 'package:json/json.dart';
import 'package:streamy/generator.dart';

/// Generates a Streamy API client library for a given [discoveryFile] in the
/// pub package format.
Future generateStreamyClientLibrary(
    String discoveryFile,
    String outputDir,
    {io.File addendumFile,
    // TODO: the caller needs to check if directory exists before passing in here
    io.Directory templatesDir,
    String fileName
    }) {
  var discovery = new Discovery.fromJsonString(discoveryFile);
  var addendumData = {};
  if (addendumFile != null) {
    addendumData = parse(addendumFile.readAsStringSync());
  }
  if (fileName == null) {
    fileName = discovery.name;
  }

  // TODO: join path safely
  var basePath = '${outputDir}/$fileName';
  var rootOut = new io.File('${basePath}.dart').openWrite();
  var resourceOut = new io.File('${basePath}_resources.dart').openWrite();
  var requestOut = new io.File('${basePath}_requests.dart').openWrite();
  var objectOut = new io.File('${basePath}_objects.dart').openWrite();

  var templateProvider = templatesDir != null
      ? new DefaultTemplateProvider(templatesDir.path)
      : new DefaultTemplateProvider.defaultInstance();

  emitCode(new EmitterConfig(
      discovery,
      templateProvider,
      rootOut,
      resourceOut,
      requestOut,
      objectOut,
      addendumData: addendumData,
      fileName: fileName));

  return Future.wait([
    rootOut.close(),
    resourceOut.close(),
    requestOut.close(),
    objectOut.close(),
  ]);
}
