#pragma once
#include <stdint.h>

#ifdef __cplusplus
extern "C"
{
#endif

/* ===== Export macro ===== */
#if defined(_WIN32)
#define TJ_FFI_EXPORT __declspec(dllexport)
#else
#define TJ_FFI_EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

  /* ===== Pixel formats (mirrors TurboJPEG TJPF_*) ===== */
  enum
  {
    TJX_PF_RGB = 0,
    TJX_PF_BGR = 1,
    TJX_PF_RGBX = 2,
    TJX_PF_BGRX = 3,
    TJX_PF_XBGR = 4,
    TJX_PF_XRGB = 5,
    TJX_PF_GRAY = 6,
    TJX_PF_RGBA = 7,
    TJX_PF_BGRA = 8,
    TJX_PF_ABGR = 9,
    TJX_PF_ARGB = 10,
    TJX_PF_CMYK = 11
  };

  /* ===== Subsampling (mirrors TurboJPEG TJSAMP_*) ===== */
  enum
  {
    TJX_SAMP_444 = 0,
    TJX_SAMP_422 = 1,
    TJX_SAMP_420 = 2,
    TJX_SAMP_GRAY = 3,
    TJX_SAMP_440 = 4,
    TJX_SAMP_411 = 5
  };

  /* ===== Common flags (bitmask; mirrors TurboJPEG TJFLAG_*) ===== */
  enum
  {
    TJX_FLAG_BOTTOMUP = 2,
    TJX_FLAG_FASTUPSAMPLE = 256,
    TJX_FLAG_FASTDCT = 2048,
    TJX_FLAG_ACCURATEDCT = 4096,
    TJX_FLAG_PROGRESSIVE = 16384
  };

  /* ===== Colorspace from tjDecompressHeader3 (TJCS_*) ===== */
  enum
  {
    TJX_CS_RGB = 0,
    TJX_CS_YCbCr = 1,
    TJX_CS_GRAY = 2,
    TJX_CS_CMYK = 3,
    TJX_CS_YCCK = 4
  };

  /* ===== Transform ops / options (mirrors TurboJPEG TJXOP_* / TJXOPT_*) ===== */
  enum
  {
    TJX_OP_NONE = 0,
    TJX_OP_HFLIP = 1,
    TJX_OP_VFLIP = 2,
    TJX_OP_TRANSPOSE = 3,
    TJX_OP_TRANSVERSE = 4,
    TJX_OP_ROT90 = 5,
    TJX_OP_ROT180 = 6,
    TJX_OP_ROT270 = 7
  };

  enum
  {
    TJX_OPT_TRIM = 1,
    TJX_OPT_CROP = 2,
    TJX_OPT_GRAY = 4,
    TJX_OPT_NOOUTPUT = 8,
    TJX_OPT_PROGRESSIVE = 16,
    TJX_OPT_COPYNONE = 32
  };

  /* ===== Transform ops/options (stable values for FFI) ===== */
  /* We map these stable values to TurboJPEG's TJXOP_* and TJXOPT_* in C. */
  enum
  {
    TJX_OP_NONE_ = 0,
    TJX_OP_HFLIP_ = 1,
    TJX_OP_VFLIP_ = 2,
    TJX_OP_TRANSPOSE_ = 3,
    TJX_OP_TRANSVERSE_ = 4,
    TJX_OP_ROT90_ = 5,
    TJX_OP_ROT180_ = 6,
    TJX_OP_ROT270_ = 7,
  };

  enum
  {
    TJX_OPT_NONE_ = 0,
    TJX_OPT_PERFECT_ = 1 << 0,  /* reject if not perfect */
    TJX_OPT_TRIM_ = 1 << 1,     /* trim partial MCUs */
    TJX_OPT_CROP_ = 1 << 2,     /* use crop rectangle */
    TJX_OPT_GRAY_ = 1 << 3,     /* grayscale output */
    TJX_OPT_NOOUTPUT_ = 1 << 4, /* no output (test only) */
  };

  /* ===== Simple transform (creates/destroys its own handle) ===== */
  TJ_FFI_EXPORT int32_t tjx_transform_simple(
      const uint8_t *in_jpeg, int32_t in_len,
      int32_t op, int32_t options,
      int32_t crop_x, int32_t crop_y, int32_t crop_w, int32_t crop_h,
      uint8_t **out_jpeg, int64_t *out_len,
      int32_t flags, /* TJFLAG_* */
      char *err, int32_t err_len);

  /* ===== Version / errors ===== */
  TJ_FFI_EXPORT int32_t tjx_version_str(char *out, int32_t out_len);
  TJ_FFI_EXPORT int32_t tjx_version_int(void);
  TJ_FFI_EXPORT int32_t tjx_get_error_str(void *handle, char *out, int32_t out_len);

  /* ===== Handle lifecycle ===== */
  TJ_FFI_EXPORT void *tjx_init_compress(char *err, int32_t err_len);
  TJ_FFI_EXPORT void *tjx_init_decompress(char *err, int32_t err_len);
  TJ_FFI_EXPORT void *tjx_init_transform(char *err, int32_t err_len);
  TJ_FFI_EXPORT int32_t tjx_destroy(void *handle);

  /* ===== Header helpers ===== */
  TJ_FFI_EXPORT int32_t tjx_decompress_header3(
      void *dec,
      const uint8_t *jpg, int32_t len,
      int32_t *out_w, int32_t *out_h,
      int32_t *out_subsamp, int32_t *out_colorspace,
      char *err, int32_t err_len);

  TJ_FFI_EXPORT int32_t tjx_get_size(
      const uint8_t *jpg, int32_t len,
      int32_t *out_w, int32_t *out_h,
      char *err, int32_t err_len);

  /* ===== Decode: JPEG -> RGB ===== */
  TJ_FFI_EXPORT int32_t tjx_decompress_to_rgb(
      void *dec,
      const uint8_t *jpg, int32_t len,
      uint8_t *out_rgb, int32_t out_pitch,
      int32_t out_w, int32_t out_h, int32_t out_pf,
      int32_t flags,
      char *err, int32_t err_len);

  /* ===== Decode: JPEG -> planar YUV (packed as planes) ===== */
  TJ_FFI_EXPORT int32_t tjx_decompress_to_yuv(
      void *dec,
      const uint8_t *jpg, int32_t len,
      uint8_t *out_yuv, int32_t out_w, int32_t out_h,
      int32_t pad, int32_t flags,
      char *err, int32_t err_len);

  /* ===== Decode: planar YUV -> RGB ===== */
  TJ_FFI_EXPORT int32_t tjx_decode_yuv_to_rgb(
      void *dec,
      const uint8_t *yuv, int32_t pad, int32_t subsamp,
      uint8_t *out_rgb, int32_t out_pitch,
      int32_t out_w, int32_t out_h, int32_t out_pf,
      int32_t flags,
      char *err, int32_t err_len);

  /* ===== Encode: RGB -> JPEG ===== */
  TJ_FFI_EXPORT int32_t tjx_compress_from_rgb(
      void *enc,
      const uint8_t *rgb, int32_t w, int32_t pitch, int32_t h, int32_t pf,
      uint8_t **out_jpeg, int64_t *out_len,
      int32_t subsamp, int32_t quality, int32_t flags,
      char *err, int32_t err_len);

  /* ===== Encode: planar YUV -> JPEG ===== */
  TJ_FFI_EXPORT int32_t tjx_compress_from_yuv(
      void *enc,
      const uint8_t *yuv, int32_t w, int32_t pad, int32_t h, int32_t subsamp,
      uint8_t **out_jpeg, int64_t *out_len,
      int32_t quality, int32_t flags,
      char *err, int32_t err_len);

  /* ===== Encode: RGB -> planar YUV (single buffer) ===== */
  TJ_FFI_EXPORT int32_t tjx_encode_yuv_from_rgb(
      void *enc,
      const uint8_t *rgb, int32_t w, int32_t pitch, int32_t h, int32_t pf,
      uint8_t *out_yuv, int32_t pad, int32_t subsamp,
      int32_t flags,
      char *err, int32_t err_len);

  /* ===== Encode/Decode using explicit Y, U, V planes ===== */
  TJ_FFI_EXPORT int32_t tjx_decompress_to_yuv_planes(
      void *dec,
      const uint8_t *jpg, int32_t len,
      uint8_t *y, int32_t stride_y,
      uint8_t *u, int32_t stride_u,
      uint8_t *v, int32_t stride_v,
      int32_t width, int32_t height,
      int32_t flags,
      char *err, int32_t err_len);

  TJ_FFI_EXPORT int32_t tjx_encode_yuv_planes_from_rgb(
      void *enc,
      const uint8_t *rgb, int32_t w, int32_t pitch, int32_t h, int32_t pf,
      uint8_t *y, int32_t stride_y,
      uint8_t *u, int32_t stride_u,
      uint8_t *v, int32_t stride_v,
      int32_t subsamp, int32_t flags,
      char *err, int32_t err_len);

  TJ_FFI_EXPORT int32_t tjx_compress_from_yuv_planes(
      void *enc,
      uint8_t *y, int32_t stride_y,
      uint8_t *u, int32_t stride_u,
      uint8_t *v, int32_t stride_v,
      int32_t width, int32_t height, int32_t subsamp,
      uint8_t **out_jpeg, int64_t *out_len,
      int32_t quality, int32_t flags,
      char *err, int32_t err_len);

  /* ===== Transform (rotate/flip/crop) ===== */
  TJ_FFI_EXPORT int32_t tjx_transform_simple(
      const uint8_t *in_jpeg, int32_t in_len,
      int32_t op, int32_t options,
      int32_t crop_x, int32_t crop_y, int32_t crop_w, int32_t crop_h,
      uint8_t **out_jpeg, int64_t *out_len,
      int32_t flags,
      char *err, int32_t err_len);

  /* ===== Size helpers ===== */
  TJ_FFI_EXPORT int32_t tjx_buf_size(int32_t w, int32_t h, int32_t subsamp, int64_t *out);
  TJ_FFI_EXPORT int32_t tjx_buf_size_yuv2(int32_t w, int32_t pad, int32_t h, int32_t subsamp, int64_t *out);

  /* ===== Scaling factors ===== */
  TJ_FFI_EXPORT int32_t tjx_get_scaling_factors(
      int32_t *out_num, int32_t *out_den, int32_t max,
      int32_t *out_count,
      char *err, int32_t err_len);

  /* ===== Free TurboJPEG-allocated memory ===== */
  TJ_FFI_EXPORT void tjx_free(uint8_t *p);

#ifdef __cplusplus
}
#endif
