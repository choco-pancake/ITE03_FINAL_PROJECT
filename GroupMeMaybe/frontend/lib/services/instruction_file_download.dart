import 'dart:typed_data';
import 'instruction_file_download_stub.dart'
    if (dart.library.html) 'instruction_file_download_web.dart' as platform;

void saveInstructionFile(String name, Uint8List bytes) =>
    platform.saveInstructionFile(name, bytes);
