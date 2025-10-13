// ignore_for_file: camel_case_types, non_constant_identifier_names

part of 'webp.dart';

typedef _VerStrNative = ffi.Int32 Function(ffi.Pointer<ffi.Uint8>, ffi.Int32);
typedef _GetInfoNative =
    ffi.Int32 Function(
      ffi.Pointer<ffi.Uint8>,
      ffi.Int32, // data, len
      ffi.Pointer<ffi.Int32>,
      ffi.Pointer<ffi.Int32>, // w, h
      ffi.Pointer<ffi.Uint8>,
      ffi.Int32, // err, errCap
    );
typedef _DecodeNative =
    ffi.Int32 Function(
      ffi.Pointer<ffi.Uint8>,
      ffi.Int32, // data, len
      ffi.Pointer<ffi.Uint8>,
      ffi.Int32, // out, outPitch (0=tight)
      ffi.Int32,
      ffi.Int32, // outW, outH
      ffi.Int32, // pixelFormat
      ffi.Pointer<ffi.Uint8>,
      ffi.Int32, // err, errCap
    );
typedef _EncodeNative =
    ffi.Int32 Function(
      ffi.Pointer<ffi.Uint8>, // pixels
      ffi.Int32,
      ffi.Int32,
      ffi.Int32, // width, pitch, height
      ffi.Int32, // pixelFormat
      ffi.Int32, // subsampling
      ffi.Int32, // quality
      ffi.Pointer<ffi.Pointer<ffi.Uint8>>, // out**
      ffi.Pointer<ffi.Int64>, // out_len
      ffi.Pointer<ffi.Uint8>,
      ffi.Int32, // err, errCap
    );
typedef _TransformNative =
    ffi.Int32 Function(
      ffi.Pointer<ffi.Uint8>,
      ffi.Int32, // data, len
      ffi.Int32,
      ffi.Int32, // op, options
      ffi.Int32,
      ffi.Int32,
      ffi.Int32,
      ffi.Int32, // cropX,Y,W,H
      ffi.Pointer<ffi.Pointer<ffi.Uint8>>, // out**
      ffi.Pointer<ffi.Int64>, // out_len
      ffi.Int32, // flags (игнорим/проходим)
      ffi.Pointer<ffi.Uint8>,
      ffi.Int32, // err, errCap
    );
typedef _FreeNative = ffi.Void Function(ffi.Pointer<ffi.Uint8>);

// ---- externals (без DynamicLibrary.open!) ----

@ffi.Native<_VerStrNative>(symbol: 'ik_webp_version_str')
external int _ik_webp_version_str(ffi.Pointer<ffi.Uint8> out, int cap);

@ffi.Native<_GetInfoNative>(symbol: 'ik_webp_get_info')
external int _ik_webp_get_info(
  ffi.Pointer<ffi.Uint8> data,
  int len,
  ffi.Pointer<ffi.Int32> w,
  ffi.Pointer<ffi.Int32> h,
  ffi.Pointer<ffi.Uint8> err,
  int errCap,
);

@ffi.Native<_DecodeNative>(symbol: 'ik_webp_decode_to_pixels')
external int _ik_webp_decode_to_pixels(
  ffi.Pointer<ffi.Uint8> data,
  int len,
  ffi.Pointer<ffi.Uint8> out,
  int outPitch,
  int outW,
  int outH,
  int pixelFormat,
  ffi.Pointer<ffi.Uint8> err,
  int errCap,
);

@ffi.Native<_EncodeNative>(symbol: 'ik_webp_encode_from_pixels_ex')
external int _ik_webp_encode_from_pixels_ex(
  ffi.Pointer<ffi.Uint8> pixels,
  int width,
  int pitch,
  int height,
  int pixelFormat,
  int subsampling,
  int quality,
  ffi.Pointer<ffi.Pointer<ffi.Uint8>> out,
  ffi.Pointer<ffi.Int64> outLen,
  ffi.Pointer<ffi.Uint8> err,
  int errCap,
);

@ffi.Native<_TransformNative>(symbol: 'ik_webp_transform_simple')
external int _ik_webp_transform_simple(
  ffi.Pointer<ffi.Uint8> data,
  int len,
  int op,
  int options,
  int cropX,
  int cropY,
  int cropW,
  int cropH,
  ffi.Pointer<ffi.Pointer<ffi.Uint8>> out,
  ffi.Pointer<ffi.Int64> outLen,
  int flags,
  ffi.Pointer<ffi.Uint8> err,
  int errCap,
);

@ffi.Native<_FreeNative>(symbol: 'ik_webp_free')
external void _ik_webp_free(ffi.Pointer<ffi.Uint8> p);
