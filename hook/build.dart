import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';

import '../helpers/builders/turbo_jpeg_build.dart';
import '../helpers/builders/png_build.dart';
import '../helpers/builders/webp_build.dart';

Future<void> main(List<String> args) => build(args, (input, output) async {
  hierarchicalLoggingEnabled = true;
  final log = Logger('build');

  log.onRecord.listen((r) => print(r.message));

  final os = input.config.code.targetOS;

  // 1) libjpeg-turbo glue
  final tj = TurboJpegBuild(input, output);

  if (tj.defines.isEnabledForOs(os)) {
    await tj.runBuild();
    log.info('TurboJPEG glue built');
  }

  // 2) libpng glue
  final png = PngBuild(input, output);
  if (png.defines.isEnabledForOs(os)) {
    await png.runBuild();
    log.info('libpng glue built');
  }

  // 3) webp glue
  final webp = WebpBuild(input, output);
  if (webp.defines.isEnabledForOs(os)) {
    await webp.runBuild();
    log.info('webp glue built');
  }
});
