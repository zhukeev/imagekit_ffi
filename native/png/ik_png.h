#pragma once
#include <stdint.h>

#ifdef __cplusplus
extern "C"
{
#endif

/* Export macro */
#if defined(_WIN32)
#define IKPNG_EXPORT __declspec(dllexport)
#else
#define IKPNG_EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

  /* ========= Public C API mirroring the JPEG glue naming ========= */

  /* Human-readable libpng version string (e.g., "1.6.43"). */
  IKPNG_EXPORT int32_t ik_png_version_str(char *out, int32_t out_len);

  /* Parse width/height; err is optional. */
  IKPNG_EXPORT int32_t ik_png_get_info(
      const uint8_t *png_bytes, int32_t len,
      int32_t *out_w, int32_t *out_h,
      char *err, int32_t err_len);

  /* Decode PNG -> interleaved pixels.
     out_pf is the "PixelFormat" enum from Dart.
     out_pitch: bytes per row (0 = tight).
     out buffer must fit out_w*out_h*bpp (or out_pitch*out_h if non-zero). */
  IKPNG_EXPORT int32_t ik_png_decode_to_pixels(
      const uint8_t *png_bytes, int32_t len,
      uint8_t *out_pixels, int32_t out_pitch,
      int32_t out_w, int32_t out_h, int32_t out_pf,
      char *err, int32_t err_len);

  /* Encode interleaved pixels -> PNG.
     pf is the "PixelFormat" enum from Dart.
     pitch: bytes per row (0 = tight).
     Returns malloc'ed *out_png which must be freed via ik_png_free(). */
  IKPNG_EXPORT int32_t ik_png_encode_from_pixels(
      const uint8_t *pixels,
      int32_t width,
      int32_t pitch,
      int32_t height,
      int32_t pf,
      uint8_t **out_png,
      int64_t *out_len,
      char *err, int32_t err_len);

  /* Lossless-like transform by full decode -> pixel transform -> encode.
     Mirrors JPEG’s tjx_transform_simple signature. */
  IKPNG_EXPORT int32_t ik_png_transform_simple(
      const uint8_t *in_png, int32_t in_len,
      int32_t op,      /* TransformOp */
      int32_t options, /* XformOptions bitmask: perfect/trim/crop/gray/noOutput */
      int32_t crop_x, int32_t crop_y, int32_t crop_w, int32_t crop_h,
      uint8_t **out_png, int64_t *out_len,
      int32_t flags, /* ignored for PNG, kept for symmetry */
      char *err, int32_t err_len);

  int32_t ik_png_encode_from_pixels_ex(const uint8_t *pixels,
                                       int32_t width, int32_t pitch, int32_t height,
                                       int32_t pf,
                                       int32_t compression_level, // 0..9
                                       int32_t filter_mask,       // libpng filter mask, e.g. PNG_ALL_FILTERS
                                       int32_t interlace,         // 0=none, 1=Adam7
                                       uint8_t **out_png, int64_t *out_len,
                                       uint8_t *err, int32_t err_len);

  void ik_png_free(uint8_t *p);

#ifdef __cplusplus
}
#endif

/* Free buffer allocated by ik_png_encode_from_pixels/ik_png_transform_simple. */
IKPNG_EXPORT void ik_png_free(uint8_t *p);

#ifdef __cplusplus
}
#endif
