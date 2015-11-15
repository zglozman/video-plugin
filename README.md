Installation

1. cordova plugin add path_to_plugin_dir
2. Add Xcod.proj -> Target -> Build Settings -> "Header Search Paths" (debug/release)
```
"${SDK_DIR}/usr/include/libxml2"
```

3. Add libxml2.dylib "Linked Frameworks"
4. cordova build ios

5. Add 'Web' folder in Xcode.proj 