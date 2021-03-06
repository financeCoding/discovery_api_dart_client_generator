// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:discoveryapis_generator/src'
       '/generated_googleapis/discovery/v1.dart';
import 'package:discoveryapis_generator/src/dart_api_library.dart';
import 'package:discoveryapis_generator/src/dart_resources.dart';
import 'package:discoveryapis_generator/src/dart_schemas.dart';
import 'package:discoveryapis_generator/src/namer.dart';
import 'package:discoveryapis_generator/src/uri_template.dart';
import 'package:unittest/unittest.dart';

withParsedDB(json, function) {
  var namer = new ApiLibraryNamer();
  var imports = new DartApiImports.fromNamer(namer);

  var description = new RestDescription.fromJson(json);
  var db = parseSchemas(imports, description);

  namer.nameAllIdentifiers();

  return function(db);
}

withParsedApiResource(db, json, function) {
  var namer = new ApiLibraryNamer();
  var imports = new DartApiImports.fromNamer(namer);

  var description = new RestDescription.fromJson(json);
  var apiClass = parseResources(imports, db, description);

  namer.nameAllIdentifiers();

  return function(apiClass);
}

main() {
  var schema = {
    'schemas' : {
      'Task' : {
        'type' : 'object',
        'properties' : {
          'name' : { 'type': 'string' },
          'isMale' : { 'type': 'boolean' },
          'age' : { 'type': 'integer' },
          'any' : { 'type': 'any' },
          'labels' : {
            'type': 'array',
            'items' : {
              'type' : 'integer',
            },
          },
          'properties' : {
            'type': 'object',
            'additionalProperties' : {
              'type' : 'string',
            },
          },
        },
      },
    }
  };

  withParsedDB(schema, (DartSchemaTypeDB db) {
    Map buildApi(String i, {Map methods, Map resources}) {
      var api = {
          'name' : 'apiname$i',
          'version' : 'apiversion$i',
          'rootUrl' : 'https://www.googleapis.com/',
          'servicePath' : 'mapsengine/v1/',
      };
      if (methods != null) {
        api['methods'] = methods;
      }
      if (resources != null) {
        api['resources'] = resources;
      }
      return api;
    }

    checkApi(String i, DartApiClass apiClass) {
      expect(apiClass, isNotNull);
      expect(apiClass.className.name, equals('Apiname${i}Api'));
      expect(apiClass.rootUrl, equals('https://www.googleapis.com/'));
      expect(apiClass.servicePath, equals('mapsengine/v1/'));
    }

    Map buildMethods(String i) {
      var map = {
         'foo$i' : {
           'path' : 'foo$i/{id$i}',
           'httpMethod' : 'GET',
           'parameters' : {
             'id$i' : {
               'type' : 'string',
               'required' : true,
               'location' : 'path',
             },
             'reapetedPathParam$i' : {
               'type' : 'string',
               'required' : true,
               'repeated' : true,
               'location' : 'path',
             },
             'reapetedQueryParam$i' : {
              'type' : 'string',
              'required' : true,
              'repeated' : true,
              'location' : 'query',
            }
           },
         },
      };
      for (var reserved in RESERVED_METHOD_PARAMETER_NAMES) {
        map['foo$i']['parameters'][reserved] = {
            'type' : 'string',
            'required' : true,
            'location' : 'path',
        };
      }
      return map;
    }

    checkMethods(String i, List<DartResourceMethod> methods) {
      expect(methods, hasLength(1));
      var foo = methods.first;
      expect(foo, isNotNull);
      expect(foo.urlPattern.parts, hasLength(2));
      expect(foo.urlPattern.parts[0] is StringPart, isTrue);
      expect(foo.urlPattern.parts[0].staticString, equals('foo$i/'));
      expect(foo.urlPattern.parts[1] is VariableExpression, isTrue);
      expect(foo.urlPattern.parts[1].templateVar, equals('id$i'));
      expect(foo.httpMethod, equals('GET'));
      expect(foo.parameters,
             hasLength(3 + RESERVED_METHOD_PARAMETER_NAMES.length));

      var id = foo.parameters[0];
      expect(id, isNotNull);
      expect(id.name.name, equals('id$i'));
      expect(id.type, equals(db.stringType));
      expect(id.required, isTrue);
      expect(id.encodedInPath, isTrue);

      var reapetedPathParam = foo.parameters[1];
      expect(reapetedPathParam, isNotNull);
      expect(reapetedPathParam.name.name, equals('reapetedPathParam$i'));
      expect(reapetedPathParam.type is UnnamedArrayType, isTrue);
      expect(reapetedPathParam.type.innerType, equals(db.stringType));
      expect(reapetedPathParam.required, isTrue);
      expect(reapetedPathParam.encodedInPath, isTrue);

      var reapetedQueryParam = foo.parameters[2];
      expect(reapetedQueryParam, isNotNull);
      expect(reapetedQueryParam.name.name, equals('reapetedQueryParam$i'));
      expect(reapetedQueryParam.type is UnnamedArrayType, isTrue);
      expect(reapetedQueryParam.type.innerType, equals(db.stringType));
      expect(reapetedQueryParam.required, isTrue);
      expect(reapetedQueryParam.encodedInPath, isFalse);

      var rest = foo.parameters.skip(3).toList();
      for (var reserved in RESERVED_METHOD_PARAMETER_NAMES) {
        bool found = false;
        for (var p in rest) {
          if ('${reserved}_1' == p.name.name) {
            found = true;
          }
        }
        expect(found, isTrue);
      }
    }

    Map buildResources(String i, {int level: 0}) {
      if (level > 3) {
        return null;
      } else {
        var methods = buildMethods('${i}M$level');
        var subResources = buildResources('${i}L$level', level: level+1);

        var resources = {
           'resA$i' : {
             'methods' : methods,
           },
           'resB$i' : {
             'methods' : methods,
           },
        };
        if (subResources != null) {
          resources['resA$i']['resources'] = subResources;
          resources['resB$i']['resources'] = subResources;
        }
        return resources;
      }
    }

    checkResources(String i,
                   String parent,
                   List<DartResourceClass> resources,
                   {int level: 0}) {
      if (level > 3) {
        expect(resources, isEmpty);
      } else {
        expect(resources, hasLength(2));
        var abc = resources.first;
        expect(abc, isNotNull);
        expect(abc.className.name, equals('${parent}ResA${i}ResourceApi'));
        checkMethods('${i}M$level', abc.methods);
        checkResources('${i}L$level', '${parent}ResA${i}', abc.subResources,
            level: level + 1);

        var def = resources.last;
        expect(def.className.name, equals('${parent}ResB${i}ResourceApi'));
        expect(def, isNotNull);
        checkMethods('${i}M$level', def.methods);
        checkResources('${i}L$level', '${parent}ResB${i}', def.subResources,
            level: level + 1);
      }
    }

    group('resources', () {
      test('empty-api', () {
        withParsedApiResource(db, buildApi('1'), (DartApiClass apiClass) {
          expect(apiClass, isNotNull);
          checkApi('1', apiClass);
          expect(apiClass.methods, isEmpty);
          expect(apiClass.subResources, isEmpty);
          expect(apiClass.scopes, isEmpty);
        });
      });

      test('api-scopes', () {
        withParsedApiResource(db, {
            'name' : 'apiname',
            'version' : 'apiversion',
            'rootUrl' : 'https://www.googleapis.com/',
            'servicePath' : 'mapsengine/v1/',
            'auth' : {
              'oauth2' : {
                'scopes' : {
                  'https://foo.com' : {
                    'description' : 'com1',
                  },
                  'https://bar.com' : {
                    'description' : 'com2',
                  }
                }
              }
            }
        }, (DartApiClass apiClass) {
          expect(apiClass, isNotNull);
          expect(apiClass.methods, isEmpty);
          expect(apiClass.subResources, isEmpty);
          expect(apiClass.scopes, hasLength(2));
          expect(apiClass.scopes[0].url, equals('https://bar.com'));
          expect(apiClass.scopes[0].comment.rawComment, equals('com2'));
          expect(apiClass.scopes[1].url, equals('https://foo.com'));
          expect(apiClass.scopes[1].comment.rawComment, equals('com1'));
        });
      });

      test('api-methods', () {
        withParsedApiResource(db,
                              buildApi('2', methods: buildMethods('3')),
                              (DartApiClass apiClass) {
          expect(apiClass, isNotNull);
          checkApi('2', apiClass);
          checkMethods('3', apiClass.methods);
          expect(apiClass.subResources, isEmpty);
        });
      });

      test('api-resources-methods', () {
        withParsedApiResource(db,
                              buildApi('4',
                                       methods: buildMethods('5'),
                                       resources: buildResources('6')),
                              (DartApiClass apiClass) {
          expect(apiClass, isNotNull);
          checkApi('4', apiClass);
          checkMethods('5', apiClass.methods);
          checkResources('6', '', apiClass.subResources);
        });
      });
    });
  });
}
