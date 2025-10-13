// ignore_for_file: non_constant_identifier_names

part of 'png_kit.dart';

// version
@ffi.Native<ffi.Int32 Function(ffi.Pointer<ffi.Uint8>, ffi.Int32)>(
  symbol: 'ik_png_version_str',
)
external int _ik_png_version_str(ffi.Pointer<ffi.Uint8> out, int outLen);

// info
@ffi.Native<
  ffi.Int32 Function(
    ffi.Pointer<ffi.Uint8>,
    ffi.Int32,
    ffi.Pointer<ffi.Int32>,
    ffi.Pointer<ffi.Int32>,
    ffi.Pointer<ffi.Uint8>,
    ffi.Int32,
  )
>(symbol: 'ik_png_get_info')
external int _ik_png_get_info(
  ffi.Pointer<ffi.Uint8> png,
  int len,
  ffi.Pointer<ffi.Int32> outW,
  ffi.Pointer<ffi.Int32> outH,
  ffi.Pointer<ffi.Uint8> err,
  int errLen,
);

// decode
@ffi.Native<
  ffi.Int32 Function(
    ffi.Pointer<ffi.Uint8>,
    ffi.Int32, // png, len
    ffi.Pointer<ffi.Uint8>,
    ffi.Int32, // outPixels, outPitch
    ffi.Int32,
    ffi.Int32,
    ffi.Int32, // outW, outH, outPf
    ffi.Pointer<ffi.Uint8>,
    ffi.Int32, // err, errLen
  )
>(symbol: 'ik_png_decode_to_pixels')
external int _ik_png_decode_to_pixels(
  ffi.Pointer<ffi.Uint8> png,
  int len,
  ffi.Pointer<ffi.Uint8> outPixels,
  int outPitch,
  int outW,
  int outH,
  int outPf,
  ffi.Pointer<ffi.Uint8> err,
  int errLen,
);

// transform
@ffi.Native<
  ffi.Int32 Function(
    ffi.Pointer<ffi.Uint8>,
    ffi.Int32, // in_png, in_len
    ffi.Int32,
    ffi.Int32, // op, options
    ffi.Int32,
    ffi.Int32,
    ffi.Int32,
    ffi.Int32, // crop_x,y,w,h
    ffi.Pointer<ffi.Pointer<ffi.Uint8>>, // out_png**
    ffi.Pointer<ffi.Int64>, // out_len
    ffi.Int32, // flags
    ffi.Pointer<ffi.Uint8>,
    ffi.Int32, // err, errLen
  )
>(symbol: 'ik_png_transform_simple')
external int _ik_png_transform_simple(
  ffi.Pointer<ffi.Uint8> inPng,
  int inLen,
  int op,
  int options,
  int cropX,
  int cropY,
  int cropW,
  int cropH,
  ffi.Pointer<ffi.Pointer<ffi.Uint8>> outPng,
  ffi.Pointer<ffi.Int64> outLen,
  int flags,
  ffi.Pointer<ffi.Uint8> err,
  int errLen,
);

// encode
@ffi.Native<
  ffi.Int32 Function(
    ffi.Pointer<ffi.Uint8>, // pixels
    ffi.Int32, // width
    ffi.Int32, // pitch
    ffi.Int32, // height
    ffi.Int32, // pf
    ffi.Int32, // compression_level (0..9)
    ffi.Int32, // filter_mask (PNG_* bitmask)
    ffi.Int32, // interlace (0/1)
    ffi.Pointer<ffi.Pointer<ffi.Uint8>>, // out_png**
    ffi.Pointer<ffi.Int64>, // out_len
    ffi.Pointer<ffi.Uint8>, // err
    ffi.Int32, // errLen
  )
>(symbol: 'ik_png_encode_from_pixels_ex')
external int _ik_png_encode_from_pixels_ex(
  ffi.Pointer<ffi.Uint8> pixels,
  int width,
  int pitch,
  int height,
  int pf,
  int compressionLevel,
  int filterMask,
  int interlace,
  ffi.Pointer<ffi.Pointer<ffi.Uint8>> outPng,
  ffi.Pointer<ffi.Int64> outLen,
  ffi.Pointer<ffi.Uint8> err,
  int errLen,
);

// free
@ffi.Native<ffi.Void Function(ffi.Pointer<ffi.Uint8>)>(
  symbol: 'ik_png_free',
  isLeaf: true,
)
external void _ik_png_free(ffi.Pointer<ffi.Uint8> p);
