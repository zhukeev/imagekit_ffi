#ifndef IK_WEBP_H_
#define IK_WEBP_H_

#include <stdint.h>

// Export macro for Windows DLL
#ifdef _WIN32
  #define IK_EXPORT __declspec(dllexport)
#else
  #define IK_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Pixel format tags used by Dart side.
enum {
  IK_WEBP_FMT_RGB  = 1,
  IK_WEBP_FMT_BGR  = 2,
  IK_WEBP_FMT_RGBA = 3,
  IK_WEBP_FMT_BGRA = 4,
  IK_WEBP_FMT_ARGB = 5,
  IK_WEBP_FMT_ABGR = 6,
};

// Version -> NUL-terminated string into `out` (cap includes trailing NUL).
IK_EXPORT int ik_webp_version_str(uint8_t* out, int cap);

// Header probing. Returns 0 on success; sets out_w/out_h.
IK_EXPORT int ik_webp_get_info(const uint8_t* data, int len,
                               int* out_w, int* out_h,
                               uint8_t* err, int err_cap);

// Decode into caller-provided buffer with optional pitch (0=tight).
IK_EXPORT int ik_webp_decode_to_pixels(const uint8_t* data, int len,
                                       uint8_t* out, int out_pitch,
                                       int out_w, int out_h,
                                       int pixel_format,
                                       uint8_t* err, int err_cap);

// Encode from pixels with specified pixel_format, pitch and quality (0..100).
// On success returns 0 and sets *out/*out_len. Free with ik_webp_free().
IK_EXPORT int ik_webp_encode_from_pixels_ex(const uint8_t* pixels,
                                            int width, int pitch, int height,
                                            int pixel_format,
                                            int subsampling,    // 0:4:2:0, 1:4:2:2, 2:4:4:4
                                            float quality,      // 0..100
                                            uint8_t** out, int64_t* out_len,
                                            uint8_t* err, int err_cap);

// Simple pixel-domain transform pipeline:
// - Decode to RGBA
// - Apply rotate/flip/transpose and optional crop
// - Encode back to WebP (quality=90 by default inside)
//
// `op` follows the shared TransformOp enum used in Dart (0=none, 1=rot90,
// 2=rot180, 3=rot270, 4=flipH, 5=flipV, 6=transpose, 7=transverse).
// Crop is applied if cropW>0 && cropH>0 starting at (cropX,cropY).
IK_EXPORT int ik_webp_transform_simple(const uint8_t* data, int len,
                                       int op, int options,
                                       int cropX, int cropY, int cropW, int cropH,
                                       uint8_t** out, int64_t* out_len,
                                       int flags,
                                       uint8_t* err, int err_cap);

// Frees a buffer returned by the encoder.
IK_EXPORT void ik_webp_free(uint8_t* p);

#ifdef __cplusplus
}
#endif

#endif // IK_WEBP_H_
