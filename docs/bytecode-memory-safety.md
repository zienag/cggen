# Bytecode memory safety

The runtime requires a Swift 6.2 or newer compiler and preserves macOS 14 and
iOS 13 as its minimum deployment targets. CocoaPods uses Swift 6 language mode;
this is separate from the minimum compiler version.

## Storage and caching

Generated Swift drawings and paths share one `BytecodeStorage` per compressed
block. Generated Objective-C creates a retained storage handle with
`dispatch_once`; that handle lives with the generated static assets for the
process lifetime. Creating a C handle copies the compressed bytes once. Temporary
C callers balance creation with `CGGenReleaseBytecodeStorage`.

The decoded cache uses storage object identity, and its keys retain the source
owners. An entry cannot be confused with another allocation at a reused address.
Lookup, decompression, insertion, and explicit eviction are serialized with an
`NSLock`, so simultaneous requests for one uncached block share its decoded
result. `NSCache` can evict decoded data under memory pressure. Readers retain
their decoded arrays independently of cache eviction.

Array-based Swift initializers remain source-compatible. They register native
`UInt8` array storage when the drawing is constructed, keeping drawings from the
same older generated block shared. Registry entries retain the immutable source
array, so its address cannot be reused while registered. Drawing does not repeat
this lookup or compare compressed contents on each render.

Legacy C entry points (`runMergedBytecode`, `runMergedPathBytecode`) require
immutable source storage valid for the process lifetime, as supplied by older
generated static arrays. Their compatibility registry is separate from the
decoded cache. New generated C callers use retained handles.

## Reading and unsafe boundaries

`Bytecode` owns an `ArraySlice<UInt8>`. Reads and subroute extraction check bounds
before advancing and leave the cursor unchanged on failure. Subroutes retain
slices of the same allocation without copying bytes.

Integer decoding uses `ArraySlice.span`, available on the supported OS versions.
`Array.span` requires newer OS versions and is not used. Inlinable integer reads
allow specialization in callers without unchecked pointer loads.

Unsafe operations are confined to the C handle and legacy pointer interfaces,
the native-array compatibility registry, Compression, and Core Graphics APIs
that accept pointers. Pointer interfaces document the required source lifetime;
Compression bounds its destination and checks both stream completion and output
size. Core Graphics array calls supply the required component counts.

## Verification

`CGGenRTSupport` and `CGGenBytecodeDecoding` enable strict memory safety in package
settings and their podspecs. Warnings-as-errors belongs to validation commands:

```sh
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors
xcodebuild -xcconfig .github/WarningsAsErrors.xcconfig ...
```

SwiftPM applies command-line warnings-as-errors to this package. The Xcode
configuration applies it to the `cggen` and `Demo` projects and leaves third-party
warnings visible. Package consumers do not inherit warnings-as-errors.

Tests cover rejected reads and ranges, source mutation and address reuse, cache
eviction and retained readers, retries after decoder failure, concurrent cache
requests, and value equality of drawings. Generated Swift is checked against the
real runtime module; generated Objective-C is compiled, dynamically loaded, and
checked for identical pixels and extracted path geometry. Existing rendering
snapshots exercise the interpreter independently of code generation.
