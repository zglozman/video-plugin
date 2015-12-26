#!/usr/bin/env node

'use strict';

var
  fs = require("fs"),
  path = require("path"),
  xcode = require('xcode'),
  
  BUILD_VERSION = '8.0',
  BUILD_VERSION_XCODE = '"' + BUILD_VERSION + '"',
  RUNPATH_SEARCH_PATHS = '@executable_path/Frameworks',
  RUNPATH_SEARCH_PATHS_XCODE = '"' + RUNPATH_SEARCH_PATHS + '"',
  ENABLE_BITCODE = 'NO',
  ENABLE_BITCODE_XCODE = '"' + ENABLE_BITCODE + '"',
  INTERFACE_HEADER = 'testCocoaBinarySocket-Swift.h',
  INTERFACE_HEADER_XCODE = '"'+ INTERFACE_HEADER +'"',
  COMMENT_KEY = /_comment$/;


function getProjectName(protoPath) {
  var
    cordovaConfigPath = path.join(protoPath, 'config.xml'),
    content = fs.readFileSync(cordovaConfigPath, 'utf-8');

  return /<name>([\s\S]*)<\/name>/mi.exec(content)[1].trim();
}


function nonComments(obj) {
  var
    keys = Object.keys(obj),
    newObj = {},
    i = 0;

  for (i; i < keys.length; i += 1) {
    if (!COMMENT_KEY.test(keys[i])) {
      newObj[keys[i]] = obj[keys[i]];
    }
  } 

  return newObj;
}

module.exports = function (context) {
  var
    projectRoot = context.opts.projectRoot,
    projectName = getProjectName(projectRoot),
    xcconfigPath = path.join(projectRoot, '/platforms/ios/cordova/build.xcconfig'),
    xcodeProjectName = projectName + '.xcodeproj',
    xcodeProjectPath = path.join(projectRoot, 'platforms', 'ios', xcodeProjectName, 'project.pbxproj'),
    dylib = path.join(projectRoot, 'plugins', 'lfe.VideoStreamerCordovaPlugin', 'libxml2.dylib'),
    xcodeProject,
    swiftBridgingHead = '$(PROJECT_DIR)/${PRODUCT_NAME}/Plugins/lfe.VideoStreamerCordovaPlugin/TcpProxyClient-Swift.h',
    swiftBridgingHeadXcode = '"' + swiftBridgingHead + '"',
    xcodeOptions = [''];

  // Checking if the project files are in the right place
  if (!fs.existsSync(xcodeProjectPath)) {
    debugerror('an error occurred searching the project file at: "' + xcodeProjectPath + '"');

    return;
  }
  debug('".pbxproj" project file found: ' + xcodeProjectPath);

  if (!fs.existsSync(xcconfigPath)) {
    debugerror('an error occurred searching the project file at: "' + xcconfigPath + '"');

    return;
  }
  debug('".xcconfig" project file found: ' + xcconfigPath);


  xcodeProject = xcode.project(xcodeProjectPath);

  xcodeOptions.push('LD_RUNPATH_SEARCH_PATHS = ' + RUNPATH_SEARCH_PATHS);
  xcodeOptions.push('SWIFT_OBJC_BRIDGING_HEADER = ' + swiftBridgingHead);
  xcodeOptions.push('IPHONEOS_DEPLOYMENT_TARGET = ' + BUILD_VERSION);
  xcodeOptions.push('ENABLE_BITCODE = '+ ENABLE_BITCODE);
  xcodeOptions.push('SWIFT_OBJC_INTERFACE_HEADER_NAME = '+ INTERFACE_HEADER);

  fs.appendFileSync(xcconfigPath, xcodeOptions.join('\n'));

  // "project.pbxproj"
  // Parsing it
  xcodeProject.parse(function (error) {
    var configurations, buildSettings;

    if (error) {
      debugerror('an error occurred during the parsing of the project file');

      return;
    }


    configurations = nonComments(xcodeProject.pbxXCBuildConfigurationSection());
    // Adding or changing the parameters we need
    Object.keys(configurations).forEach(function (config) {
      buildSettings = configurations[config].buildSettings;

      if (buildSettings != undefined){
        var header = buildSettings.HEADER_SEARCH_PATHS;
        var newHeadersPath = [], lastKey;

        for(var option in header){
          lastKey = option;
          
          newHeadersPath[option] = header[option];
        }

        lastKey = parseInt(lastKey) + 1;

        var a = []

        a[0] = '"\\"${SDK_DIR}/usr/include/libxml2\\""';
        a[1] = '"\\"$(TARGET_BUILD_DIR)/usr/local/lib/include\\""'
        a[2] = '"\\"$(OBJROOT)/UninstalledProducts/include\\""'
        a[3] = '"\\"$(BUILT_PRODUCTS_DIR)\\""'
        a[4] = '"\\"$(OBJROOT)/UninstalledProducts/$(PLATFORM_NAME)/include\\""'

        buildSettings.HEADER_SEARCH_PATHS = a;

        buildSettings.LD_RUNPATH_SEARCH_PATHS = RUNPATH_SEARCH_PATHS_XCODE;
        buildSettings.SWIFT_OBJC_BRIDGING_HEADER = swiftBridgingHeadXcode;
        buildSettings.IPHONEOS_DEPLOYMENT_TARGET = BUILD_VERSION_XCODE;
        buildSettings.ENABLE_BITCODE = ENABLE_BITCODE_XCODE;
        buildSettings.SWIFT_OBJC_INTERFACE_HEADER_NAME = INTERFACE_HEADER_XCODE;
      }
    });

    xcodeProject.addFramework(dylib);

    // Writing the file again
    fs.writeFileSync(xcodeProjectPath, xcodeProject.writeSync(), 'utf-8');
    debug('file correctly fixed: ' + xcodeProjectPath);
  });
};


function debug(msg) {
  console.log('[INFO] ' + msg);
}


function debugerror(msg) {
  console.error('[ERROR] ' + msg);
}