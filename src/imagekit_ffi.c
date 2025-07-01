#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

// Include your PNG wrapper header (which should include fpng.h for fpng_init)
#include "png_wrapper.h"

// Include your main FFI header for function declarations
#include "imagekit_ffi.h"

// =============================================================================
// Helper for YUV to RGB conversion (ITU-R BT.601, full range)
// Values clamped to 0-255.
// =============================================================================
void YUV_to_RGB(int Y, int U, int V, uint8_t *R, uint8_t *G, uint8_t *B)
{
  // YUV to RGB conversion (BT.601, full range)
  // R = Y + 1.402 * V
  // G = Y - 0.344136 * U - 0.714136 * V
  // B = Y + 1.772 * U

  // Using integer arithmetic to avoid floats
  int C = Y - 16;
  int D = U - 128;
  int E = V - 128;

  int r = (298 * C + 409 * E + 128) >> 8;
  int g = (298 * C - 100 * D - 208 * E + 128) >> 8;
  int b = (298 * C + 516 * D + 128) >> 8;

  *R = (uint8_t)(r < 0 ? 0 : (r > 255 ? 255 : r));
  *G = (uint8_t)(g < 0 ? 0 : (g > 255 ? 255 : g));
  *B = (uint8_t)(b < 0 ? 0 : (b > 255 ? 255 : b));
}

// =============================================================================
// RGBA intermediate conversion functions (helpers, not exposed via FFI directly)
// =============================================================================

uint8_t *convert_yuv420_to_rgba(const uint8_t *y_plane, const uint8_t *u_plane, const uint8_t *v_plane,
                                int width, int height,
                                int y_stride, int u_stride, int v_stride,
                                int u_pix_stride, int v_pix_stride)
{
  if (y_plane == NULL || u_plane == NULL || v_plane == NULL || width <= 0 || height <= 0)
  {
    fprintf(stderr, "Error (convert_yuv420_to_rgba): Invalid input parameters.\n");
    return NULL;
  }

  uint8_t *rgba_output = (uint8_t *)malloc(width * height * 4);
  if (rgba_output == NULL)
  {
    fprintf(stderr, "Error (convert_yuv420_to_rgba): Failed to allocate RGBA buffer.\n");
    return NULL;
  }

  // YUV 420 chroma planes are half width and half height
  // Ensure correct handling of stride, especially for planes that might be padded.
  // For 4:2:0, UV samples are typically at (x/2, y/2).
  int uv_width = (width + 1) / 2;
  int uv_height = (height + 1) / 2;

  for (int y = 0; y < height; ++y)
  {
    for (int x = 0; x < width; ++x)
    {
      int y_val = y_plane[y * y_stride + x];

      // For YUV420, UV values are for a 2x2 block of Y pixels
      // Ensure bounds checking for U and V plane access based on their actual strides/sizes.
      int u_x_idx = (x / 2) * u_pix_stride;
      int u_y_idx = (y / 2) * u_stride;
      int v_x_idx = (x / 2) * v_pix_stride;
      int v_y_idx = (y / 2) * v_stride;

      int u_val = u_plane[u_y_idx + u_x_idx];
      int v_val = v_plane[v_y_idx + v_x_idx];

      uint8_t R, G, B;
      YUV_to_RGB(y_val, u_val, v_val, &R, &G, &B);

      int rgba_idx = (y * width + x) * 4;
      rgba_output[rgba_idx + 0] = R;
      rgba_output[rgba_idx + 1] = G;
      rgba_output[rgba_idx + 2] = B;
      rgba_output[rgba_idx + 3] = 255; // Alpha
    }
  }
  return rgba_output;
}

uint8_t *convert_nv21_to_rgba(const uint8_t *y_plane, const uint8_t *uv_plane,
                              int width, int height,
                              int y_stride, int uv_stride, int uv_pix_stride)
{
  if (y_plane == NULL || uv_plane == NULL || width <= 0 || height <= 0)
  {
    fprintf(stderr, "Error (convert_nv21_to_rgba): Invalid input parameters.\n");
    return NULL;
  }

  uint8_t *rgba_output = (uint8_t *)malloc(width * height * 4);
  if (rgba_output == NULL)
  {
    fprintf(stderr, "Error (convert_nv21_to_rgba): Failed to allocate RGBA buffer.\n");
    return NULL;
  }

  // NV21 (YUV 4:2:0 semi-planar): Y plane followed by interleaved VU plane
  // U and V planes are half width and half height.
  int uv_half_height = (height + 1) / 2;

  for (int y = 0; y < height; ++y)
  {
    for (int x = 0; x < width; ++x)
    {
      int y_val = y_plane[y * y_stride + x];

      // Calculate UV indices for the current 2x2 Y block
      // uv_pix_stride is usually 2 for NV21 (V then U)
      int uv_x_idx_base = (x / 2) * uv_pix_stride;
      int uv_y_idx = (y / 2) * uv_stride;

      // NV21 stores VU (V is first byte, U is second byte for a UV pair)
      int v_val = uv_plane[uv_y_idx + uv_x_idx_base];
      int u_val = uv_plane[uv_y_idx + uv_x_idx_base + 1];

      uint8_t R, G, B;
      YUV_to_RGB(y_val, u_val, v_val, &R, &G, &B);

      int rgba_idx = (y * width + x) * 4;
      rgba_output[rgba_idx + 0] = R;
      rgba_output[rgba_idx + 1] = G;
      rgba_output[rgba_idx + 2] = B;
      rgba_output[rgba_idx + 3] = 255; // Alpha
    }
  }
  return rgba_output;
}

// =============================================================================
// PNG related functions (using fpng via png_wrapper)
// =============================================================================

uint8_t *convert_png_to_rgba(const uint8_t *png_data, int png_size, int *width, int *height)
{
  fprintf(stderr, "PLACEHOLDER: convert_png_to_rgba - PNG decoding from scratch is extremely complex.\n");
  fprintf(stderr, "Your fpng library is an encoder only. You need a dedicated PNG DECODING library or pure C implementation.\n");
  if (width)
    *width = 0;
  if (height)
    *height = 0;
  return NULL;
}

uint8_t *convert_bgra_to_png_buffer(const uint8_t *bgra, int width, int height, size_t *out_size)
{
  if (bgra == NULL || width <= 0 || height <= 0 || out_size == NULL)
  {
    fprintf(stderr, "Error (convert_bgra_to_png_buffer): Invalid input parameters.\n");
    if (out_size)
      *out_size = 0;
    return NULL;
  }

  uint8_t *rgba = (uint8_t *)malloc(width * height * 4);
  if (rgba == NULL)
  {
    fprintf(stderr, "Error (convert_bgra_to_png_buffer): Failed to allocate memory for RGBA buffer.\n");
    if (out_size)
      *out_size = 0;
    return NULL;
  }

  // Convert BGRA to RGBA (swap R and B channels)
  for (int i = 0; i < width * height; ++i)
  {
    rgba[i * 4 + 0] = bgra[i * 4 + 2]; // R from B
    rgba[i * 4 + 1] = bgra[i * 4 + 1]; // G from G
    rgba[i * 4 + 2] = bgra[i * 4 + 0]; // B from R
    rgba[i * 4 + 3] = bgra[i * 4 + 3]; // A from A
  }

  uint8_t *png_data_buffer = encode_rgba_to_png_buffer(rgba, width, height, out_size);

  free(rgba); // Free the intermediate RGBA buffer
  return png_data_buffer;
}

uint8_t *convert_yuv420_to_png_buffer(const uint8_t *y_plane, const uint8_t *u_plane, const uint8_t *v_plane,
                                      int width, int height,
                                      int y_stride, int u_stride, int v_stride,
                                      int u_pix_stride, int v_pix_stride,
                                      size_t *out_size)
{
  if (out_size == NULL)
  {
    fprintf(stderr, "Error (convert_yuv420_to_png_buffer): out_size is NULL.\n");
    return NULL;
  }

  uint8_t *rgba_data = convert_yuv420_to_rgba(y_plane, u_plane, v_plane, width, height,
                                              y_stride, u_stride, v_stride, u_pix_stride, v_pix_stride);
  if (rgba_data == NULL)
  {
    fprintf(stderr, "Error (convert_yuv420_to_png_buffer): Failed to convert YUV420 to RGBA.\n");
    *out_size = 0;
    return NULL;
  }

  uint8_t *png_data_buffer = encode_rgba_to_png_buffer(rgba_data, width, height, out_size);
  free(rgba_data); // Free the RGBA buffer allocated by convert_yuv420_to_rgba
  return png_data_buffer;
}

uint8_t *convert_nv21_to_png_buffer(const uint8_t *y_plane, const uint8_t *uv_plane,
                                    int width, int height,
                                    int y_stride, int uv_stride, int uv_pix_stride,
                                    size_t *out_size)
{
  if (out_size == NULL)
  {
    fprintf(stderr, "Error (convert_nv21_to_png_buffer): out_size is NULL.\n");
    return NULL;
  }

  uint8_t *rgba_data = convert_nv21_to_rgba(y_plane, uv_plane, width, height,
                                            y_stride, uv_stride, uv_pix_stride);
  if (rgba_data == NULL)
  {
    fprintf(stderr, "Error (convert_nv21_to_png_buffer): Failed to convert NV21 to RGBA.\n");
    *out_size = 0;
    return NULL;
  }

  uint8_t *png_data_buffer = encode_rgba_to_png_buffer(rgba_data, width, height, out_size);
  free(rgba_data); // Free the RGBA buffer allocated by convert_nv21_to_rgba
  return png_data_buffer;
}

// =============================================================================
// Generic Image Processing & Memory Management
// =============================================================================

uint8_t *rotate_rgb_image(uint8_t *rgb, int width, int height, int rotationDegrees)
{
  if (rgb == NULL || width <= 0 || height <= 0 ||
      (rotationDegrees != 0 && rotationDegrees != 90 && rotationDegrees != 180 && rotationDegrees != 270))
  {
    fprintf(stderr, "Error (rotate_rgb_image): Invalid input parameters.\n");
    return NULL;
  }

  int outWidth = (rotationDegrees == 90 || rotationDegrees == 270) ? height : width;
  int outHeight = (rotationDegrees == 90 || rotationDegrees == 270) ? width : height;

  uint8_t *rotated = (uint8_t *)malloc(outWidth * outHeight * 3);
  if (!rotated)
  {
    fprintf(stderr, "Error (rotate_rgb_image): Failed to allocate memory for rotated RGB image.\n");
    return NULL;
  }

  for (int y = 0; y < height; y++)
  {
    for (int x = 0; x < width; x++)
    {
      int i_in = (y * width + x) * 3;

      int rotated_x, rotated_y;
      switch (rotationDegrees)
      {
      case 90:
        rotated_x = height - 1 - y;
        rotated_y = x;
        break;
      case 180:
        rotated_x = width - 1 - x;
        rotated_y = height - 1 - y;
        break;
      case 270:
        rotated_x = y;
        rotated_y = width - 1 - x;
        break;
      case 0:
      default:
        rotated_x = x;
        rotated_y = y;
        break;
      }

      int i_out = (rotated_y * outWidth + rotated_x) * 3;

      rotated[i_out + 0] = rgb[i_in + 0];
      rotated[i_out + 1] = rgb[i_in + 1];
      rotated[i_out + 2] = rgb[i_in + 2];
    }
  }
  return rotated;
}

void free_buffer(uint8_t *buffer)
{
  if (buffer != NULL)
  {
    free(buffer);
  }
}