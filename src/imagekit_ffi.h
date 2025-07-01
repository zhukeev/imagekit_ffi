#pragma once

#include <stdint.h>  // For uint8_t
#include <stdbool.h> // For bool type
#include <stddef.h>  // For size_t

// Forward declare encode_rgba_to_png_buffer if png_wrapper.h isn't included directly,
// but it's better to just include it as done below.
#include "png_wrapper.h" // Include to get encode_rgba_to_png_buffer declaration

// =============================================================================
// PNG related functions
// =============================================================================

// Decodes a PNG image buffer into RGBA8888 format.
// NOTE: This is a PLACEHOLDER. Your fpng library is an encoder, not a decoder.
//       Implementing a PNG decoder in pure C is complex and requires
//       significant additional code or a dedicated decoding library.
// - png_data: Pointer to the raw PNG image data.
// - png_size: Size of the PNG data in bytes.
// - width: Output parameter to store image width.
// - height: Output parameter to store image height.
// Returns: A pointer to a newly allocated buffer containing RGBA8888 data.
//          Returns NULL on failure. The caller is responsible for freeing this buffer via free_buffer().
uint8_t *convert_png_to_rgba(const uint8_t *png_data, int png_size, int *width, int *height);

// Converts BGRA8888 image data to a PNG byte buffer.
// - bgra: Pointer to the BGRA8888 image data.
// - width: Image width in pixels.
// - height: Image height in pixels.
// - out_size: Pointer to a size_t variable that will store the size of the encoded PNG data.
// Returns: A pointer to a newly allocated buffer containing the PNG data.
//          Returns NULL on failure. The caller is responsible for freeing this buffer via free_buffer().
uint8_t *convert_bgra_to_png_buffer(const uint8_t *bgra, int width, int height, size_t *out_size);

// Converts YUV420 image data (separate planes) to a PNG byte buffer.
// - y_plane, u_plane, v_plane: Pointers to Y, U, and V plane data.
// - width, height: Image dimensions.
// - y_stride, u_stride, v_stride: Stride (bytes per row) for each plane.
// - u_pix_stride, v_pix_stride: Pixel stride for U and V planes (e.g., 1 for YUV420P).
// - out_size: Pointer to a size_t variable that will store the size of the encoded PNG data.
// Returns: A pointer to a newly allocated buffer containing the PNG data.
//          Returns NULL on failure. The caller is responsible for freeing this buffer via free_buffer().
uint8_t *convert_yuv420_to_png_buffer(const uint8_t *y_plane, const uint8_t *u_plane, const uint8_t *v_plane,
                                      int width, int height,
                                      int y_stride, int u_stride, int v_stride,
                                      int u_pix_stride, int v_pix_stride,
                                      size_t *out_size);

// Converts NV21 image data (Y + interleaved UV) to a PNG byte buffer.
// - y_plane: Pointer to Y plane data.
// - uv_plane: Pointer to interleaved UV plane data.
// - width, height: Image dimensions.
// - y_stride, uv_stride: Stride for Y and UV planes.
// - uv_pix_stride: Pixel stride in UV plane (e.g., 2 for NV21).
// - out_size: Pointer to a size_t variable that will store the size of the encoded PNG data.
// Returns: A pointer to a newly allocated buffer containing the PNG data.
//          Returns NULL on failure. The caller is responsible for freeing this buffer via free_buffer().
uint8_t *convert_nv21_to_png_buffer(const uint8_t *y_plane, const uint8_t *uv_plane,
                                    int width, int height,
                                    int y_stride, int uv_stride, int uv_pix_stride,
                                    size_t *out_size);

// =============================================================================
// Image Processing & Memory Management
// =============================================================================

// Rotates an RGB image buffer by 0, 90, 180, or 270 degrees.
// - rgb: Pointer to the input RGB image data (3 bytes per pixel, tightly packed).
// - width: The width of the original image in pixels.
// - height: The height of the original image in pixels.
// - rotationDegrees: The rotation angle in degrees (must be 0, 90, 180, or 270).
// Returns: A pointer to a new buffer containing the rotated image data.
//          Returns NULL if memory allocation fails.
//          The returned buffer MUST be freed by the caller using free_buffer().
uint8_t *rotate_rgb_image(uint8_t *rgb, int width, int height, int rotationDegrees);

// Frees a memory buffer that was allocated by native C code (e.g., via malloc).
// This is essential for Dart FFI to prevent memory leaks when C functions
// allocate memory and pass ownership to Dart.
// - buffer: Pointer to the memory buffer to be freed.
void free_buffer(uint8_t *buffer);

// =============================================================================
// RGBA intermediate conversion functions (helpers, not exposed via FFI directly)
// =============================================================================

// Converts YUV420 image data (separate planes) to RGBA8888 format.
// Returns: A pointer to a newly allocated buffer containing RGBA8888 data.
//          Returns NULL on failure. The caller is responsible for freeing this buffer via free_buffer().
uint8_t *convert_yuv420_to_rgba(const uint8_t *y_plane, const uint8_t *u_plane, const uint8_t *v_plane,
                                int width, int height,
                                int y_stride, int u_stride, int v_stride,
                                int u_pix_stride, int v_pix_stride);

// Converts NV21 image data (Y + interleaved UV) to RGBA8888 format.
// Returns: A pointer to a newly allocated buffer containing RGBA8888 data.
//          Returns NULL on failure. The caller is responsible for freeing this buffer via free_buffer().
uint8_t *convert_nv21_to_rgba(const uint8_t *y_plane, const uint8_t *uv_plane,
                              int width, int height,
                              int y_stride, int uv_stride, int uv_pix_stride);