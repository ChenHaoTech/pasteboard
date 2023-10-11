import 'package:logger/logger.dart';
import 'package:logger_flutter_viewer/logger_flutter_viewer.dart';

Logger logger = Logger(
  // todo kDebugMode, 环境指定不同的 日志等级
  output: ScreenOutput(),
  printer: PrettyPrinter(
      methodCount: 2, // Number of method calls to be displayed
      errorMethodCount: 8, // Number of method calls if stacktrace is provided
      lineLength: 120, // Width of the output
      colors: true, // Colorful log messages
      printEmojis: true, // Print an emoji for each log message
      printTime: false // Should each log print contain a timestamp
  ),
);

// shake 未完全 要包一层
class ScreenOutput extends LogOutput {
  final ConsoleOutput consoleOutput = ConsoleOutput();
  @override
  void output(OutputEvent event) {
    consoleOutput.output(event);
    LogConsole.output(event);
  }
}