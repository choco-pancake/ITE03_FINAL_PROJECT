import 'dart:typed_data';

class InstructionFile {
  const InstructionFile(this.name, this.bytes);

  final String name;
  final Uint8List bytes;
}
