import '../models/instruction_file.dart';
import 'instruction_file_picker_stub.dart'
    if (dart.library.html) 'instruction_file_picker_web.dart' as platform;

Future<InstructionFile?> pickInstructionFile() => platform.pickInstructionFile();

Future<InstructionFile?> pickProjectFile() => platform.pickProjectFile();
