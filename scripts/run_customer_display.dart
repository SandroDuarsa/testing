import 'dart:io';

void main(List<String> args) async {
  // Parse arguments for display position and size
  final x = args.isNotEmpty ? args[0] : '800';
  final y = args.length > 1 ? args[1] : '0';
  final width = args.length > 2 ? args[2] : '800';
  final height = args.length > 3 ? args[3] : '600';

  print(
    'Starting customer display at position ($x, $y) with size ${width}x$height',
  );

  // Run Flutter app with customer display configuration
  final result = await Process.run('flutter', [
    'run',
    '-t',
    'lib/customer_main.dart',
    '--dart-define=DISPLAY_MODE=customer',
    '--dart-define=WINDOW_X=$x',
    '--dart-define=WINDOW_Y=$y',
    '--dart-define=WINDOW_WIDTH=$width',
    '--dart-define=WINDOW_HEIGHT=$height',
  ]);

  print('Customer display process exited with code: ${result.exitCode}');
  if (result.stdout.isNotEmpty) {
    print('STDOUT: ${result.stdout}');
  }
  if (result.stderr.isNotEmpty) {
    print('STDERR: ${result.stderr}');
  }
}
