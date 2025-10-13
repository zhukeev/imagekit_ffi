import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';

import 'builders/turbo_jpeg_build.dart';
import 'builders/png_build.dart';
import 'builders/webp_build.dart';

Future<void> main(List<String> args) => build(args, (input, output) async {
  hierarchicalLoggingEnabled = true;
  final log = Logger('build');

  log.onRecord.listen((r) => print(r.message));

  // 1) libjpeg-turbo glue
  final tj = TurboJpegBuild(input, output);
  if (tj.defines.enabled) {
    await tj.runBuild();
    log.info('TurboJPEG glue built');
  }

  // 2) libpng glue
  final png = PngBuild(input, output);
  if (png.defines.enabled) {
    await png.runBuild();
    log.info('libpng glue built');
  }

  // 3) webp glue
  final webp = WebpBuild(input, output);
  if (webp.defines.enabled) {
    await webp.runBuild();
    log.info('webp glue built');
  }
});
