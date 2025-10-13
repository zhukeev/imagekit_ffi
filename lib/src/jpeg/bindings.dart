// ignore_for_file: non_constant_identifier_names

part of 'turbo_jpeg.dart';

/* ========================== Native FFI (C glue) ========================== */

// version
@ffi.Native<ffi.Int32 Function(ffi.Pointer<ffi.Uint8>, ffi.Int32)>(
  symbol: 'tjx_version_str',
)
external int _tjx_version_str(ffi.Pointer<ffi.Uint8> out, int outLen);

@ffi.Native<ffi.Int32 Function()>(symbol: 'tjx_version_int')
external int _tjx_version_int();

// handles
@ffi.Native<ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Uint8>, ffi.Int32)>(
  symbol: 'tjx_init_compress',
)
external ffi.Pointer<ffi.Void> _tjx_init_compress(
  ffi.Pointer<ffi.Uint8> err,
  int errLen,
);

@ffi.Native<ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Uint8>, ffi.Int32)>(
  symbol: 'tjx_init_decompress',
)
external ffi.Pointer<ffi.Void> _tjx_init_decompress(
  ffi.Pointer<ffi.Uint8> err,
  int errLen,
);

@ffi.Native<ffi.Int32 Function(ffi.Pointer<ffi.Void>)>(symbol: 'tjx_destroy')
external int _tjx_destroy(ffi.Pointer<ffi.Void> handle);

// header
@ffi.Native<
  ffi.Int32 Function(
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Uint8>,
    ffi.Int32,
    ffi.Pointer<ffi.Int32>,
    ffi.Pointer<ffi.Int32>,
    ffi.Pointer<ffi.Int32>,
    ffi.Pointer<ffi.Int32>,
    ffi.Pointer<ffi.Uint8>,
    ffi.Int32,
  )
>(symbol: 'tjx_decompress_header3')
external int _tjx_decompress_header3(
  ffi.Pointer<ffi.Void> dec,
  ffi.Pointer<ffi.Uint8> jpg,
  int len,
  ffi.Pointer<ffi.Int32> outW,
  ffi.Pointer<ffi.Int32> outH,
  ffi.Pointer<ffi.Int32> outSubsamp,
  ffi.Pointer<ffi.Int32> outColorspace,
  ffi.Pointer<ffi.Uint8> err,
  int errLen,
);

// JPEG -> RGB
@ffi.Native<
  ffi.Int32 Function(
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Uint8>,
    ffi.Int32,
    ffi.Pointer<ffi.Uint8>,
    ffi.Int32, // outRgb, outPitch
    ffi.Int32,
    ffi.Int32,
    ffi.Int32, // outW, outH, outPf
    ffi.Int32, // flags
    ffi.Pointer<ffi.Uint8>,
    ffi.Int32, // err, errLen
  )
>(symbol: 'tjx_decompress_to_rgb')
external int _tjx_decompress_to_rgb(
  ffi.Pointer<ffi.Void> dec,
  ffi.Pointer<ffi.Uint8> jpg,
  int len,
  ffi.Pointer<ffi.Uint8> outRgb,
  int outPitch,
  int outW,
  int outH,
  int outPf,
  int flags,
  ffi.Pointer<ffi.Uint8> err,
  int errLen,
);

// RGB -> JPEG
@ffi.Native<
  ffi.Int32 Function(
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Uint8>,
    ffi.Int32,
    ffi.Int32,
    ffi.Int32,
    ffi.Int32, // rgb,w,pitch,h,pf
    ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
    ffi.Pointer<ffi.Int64>, // outJpeg, outLen
    ffi.Int32,
    ffi.Int32,
    ffi.Int32, // subsamp, quality, flags
    ffi.Pointer<ffi.Uint8>,
    ffi.Int32,
  )
>(symbol: 'tjx_compress_from_rgb')
external int _tjx_compress_from_rgb(
  ffi.Pointer<ffi.Void> enc,
  ffi.Pointer<ffi.Uint8> rgb,
  int w,
  int pitch,
  int h,
  int pf,
  ffi.Pointer<ffi.Pointer<ffi.Uint8>> outJpeg,
  ffi.Pointer<ffi.Int64> outLen,
  int subsamp,
  int quality,
  int flags,
  ffi.Pointer<ffi.Uint8> err,
  int errLen,
);

// JPEG -> YUV planes
@ffi.Native<
  ffi.Int32 Function(
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Uint8>,
    ffi.Int32,
    ffi.Pointer<ffi.Uint8>,
    ffi.Int32, // y, strideY
    ffi.Pointer<ffi.Uint8>,
    ffi.Int32, // u, strideU
    ffi.Pointer<ffi.Uint8>,
    ffi.Int32, // v, strideV
    ffi.Int32,
    ffi.Int32, // width, height
    ffi.Int32, // flags
    ffi.Pointer<ffi.Uint8>,
    ffi.Int32,
  )
>(symbol: 'tjx_decompress_to_yuv_planes')
external int _tjx_decompress_to_yuv_planes(
  ffi.Pointer<ffi.Void> dec,
  ffi.Pointer<ffi.Uint8> jpg,
  int len,
  ffi.Pointer<ffi.Uint8> y,
  int strideY,
  ffi.Pointer<ffi.Uint8> u,
  int strideU,
  ffi.Pointer<ffi.Uint8> v,
  int strideV,
  int width,
  int height,
  int flags,
  ffi.Pointer<ffi.Uint8> err,
  int errLen,
);

// YUV planes -> JPEG
@ffi.Native<
  ffi.Int32 Function(
    ffi.Pointer<ffi.Void>,
    ffi.Pointer<ffi.Uint8>,
    ffi.Int32, // y, strideY
    ffi.Pointer<ffi.Uint8>,
    ffi.Int32, // u, strideU
    ffi.Pointer<ffi.Uint8>,
    ffi.Int32, // v, strideV
    ffi.Int32,
    ffi.Int32,
    ffi.Int32, // width, height, subsamp
    ffi.Pointer<ffi.Pointer<ffi.Uint8>>,
    ffi.Pointer<ffi.Int64>,
    ffi.Int32,
    ffi.Int32, // quality, flags
    ffi.Pointer<ffi.Uint8>,
    ffi.Int32,
  )
>(symbol: 'tjx_compress_from_yuv_planes')
external int _tjx_compress_from_yuv_planes(
  ffi.Pointer<ffi.Void> enc,
  ffi.Pointer<ffi.Uint8> y,
  int strideY,
  ffi.Pointer<ffi.Uint8> u,
  int strideU,
  ffi.Pointer<ffi.Uint8> v,
  int strideV,
  int width,
  int height,
  int subsamp,
  ffi.Pointer<ffi.Pointer<ffi.Uint8>> outJpeg,
  ffi.Pointer<ffi.Int64> outLen,
  int quality,
  int flags,
  ffi.Pointer<ffi.Uint8> err,
  int errLen,
);

// Transform (rotate/flip/crop)
@ffi.Native<
  ffi.Int32 Function(
    ffi.Pointer<ffi.Uint8>, // in_jpeg
    ffi.Int32, // in_len
    ffi.Int32, // op (TransformOp.value)
    ffi.Int32, // options (XformOptions bitmask)
    ffi.Int32, // crop_x
    ffi.Int32, // crop_y
    ffi.Int32, // crop_w
    ffi.Int32, // crop_h
    ffi.Pointer<ffi.Pointer<ffi.Uint8>>, // out_jpeg**
    ffi.Pointer<ffi.Int64>, // out_len
    ffi.Int32, // flags (TJFLAG_*)
    ffi.Pointer<ffi.Uint8>, // err (char*)
    ffi.Int32, // err_len
  )
>(symbol: 'tjx_transform_simple')
external int _tjx_transform_simple(
  ffi.Pointer<ffi.Uint8> inJpeg,
  int inLen,
  int op,
  int options,
  int cropX,
  int cropY,
  int cropW,
  int cropH,
  ffi.Pointer<ffi.Pointer<ffi.Uint8>> outJpeg,
  ffi.Pointer<ffi.Int64> outLen,
  int flags,
  ffi.Pointer<ffi.Uint8> err,
  int errLen,
);

// Free TurboJPEG-allocated memory
@ffi.Native<ffi.Void Function(ffi.Pointer<ffi.Uint8>)>(
  symbol: 'tjx_free',
  isLeaf: true,
)
external void _tjx_free(ffi.Pointer<ffi.Uint8> p);
