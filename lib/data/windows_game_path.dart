import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

typedef _ShortPath = Uint32 Function(Pointer<Utf16>, Pointer<Utf16>, Uint32);
final _getShortPath = DynamicLibrary.open('kernel32.dll')
    .lookupFunction<
      _ShortPath,
      int Function(Pointer<Utf16>, Pointer<Utf16>, int)
    >('GetShortPathNameW');

/// DST's Windows build can lose non-ASCII characters in its configuration path.
String gameStoragePath(String path) {
  bool ascii(String text) => text.codeUnits.every((unit) => unit < 128);
  if (!Platform.isWindows || ascii(path)) return path;
  return using((arena) {
    final input = path.toNativeUtf16(allocator: arena);
    final size = _getShortPath(input, nullptr, 0);
    if (size > 0) {
      final out = arena<Uint16>(size).cast<Utf16>();
      final length = _getShortPath(input, out, size);
      if (length > 0 && length < size) {
        final result = out.toDartString(length: length);
        if (ascii(result)) return result;
      }
    }
    throw FileSystemException(
      'DST needs an ASCII storage path on this drive. Choose a folder such as C:\\DSTWorlds and import a copy of the stopped cluster.',
      path,
    );
  });
}
