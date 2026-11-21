// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import '../models/instruction_file.dart';

Future<InstructionFile?> pickInstructionFile() => _pickFile('.pdf,.docx,.txt');

Future<InstructionFile?> pickProjectFile() => _pickFile('.pdf,.docx,.txt,.zip');

Future<InstructionFile?> _pickFile(String accept) async {
  final input = html.FileUploadInputElement()
    ..accept = accept;
  final changed = input.onChange.first;
  input.click();
  await changed;
  final file = input.files?.firstOrNull;
  if (file == null) return null;
  final reader = html.FileReader();
  final loaded = reader.onLoadEnd.first;
  reader.readAsArrayBuffer(file);
  await loaded;
  if (reader.error != null) {
    throw StateError('Could not read the selected file.');
  }
  final bytes = reader.result;
  if (bytes is ByteBuffer) {
    return InstructionFile(file.name, Uint8List.view(bytes));
  }
  if (bytes is Uint8List) {
    return InstructionFile(file.name, bytes);
  }
  if (bytes is List<int>) {
    return InstructionFile(file.name, Uint8List.fromList(bytes));
  }
  throw StateError('Could not read the selected file.');
}
