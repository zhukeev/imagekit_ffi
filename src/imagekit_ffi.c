#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include "png_wrapper.h"
#include "imagekit_ffi.h"

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT __attribute__((visibility("default")))
#endif

// Перевод YUV в RGB, стандарт BT.601
void YUV_to_RGB(int Y, int U, int V, uint8_t *R, uint8_t *G, uint8_t *B)
{
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

EXPORT uint8_t *rotate_rgba_image(const uint8_t *rgba, int width, int height, int rotationDegrees)
{
  if (!rgba || width <= 0 || height <= 0 ||
      (rotationDegrees != 0 && rotationDegrees != 90 && rotationDegrees != 180 && rotationDegrees != 270))
  {
    fprintf(stderr, "Error (rotate_rgba_image): Invalid input parameters.\n");
    return NULL;
  }

  int outWidth = (rotationDegrees == 90 || rotationDegrees == 270) ? height : width;
  int outHeight = (rotationDegrees == 90 || rotationDegrees == 270) ? width : height;

  uint8_t *rotated = (uint8_t *)malloc(outWidth * outHeight * 4);
  if (!rotated)
  {
    fprintf(stderr, "Error (rotate_rgba_image): Failed to allocate memory.\n");
    return NULL;
  }

  for (int y = 0; y < height; y++)
  {
    for (int x = 0; x < width; x++)
    {
      int src_idx = (y * width + x) * 4;

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

      int dst_idx = (rotated_y * outWidth + rotated_x) * 4;
      rotated[dst_idx + 0] = rgba[src_idx + 0];
      rotated[dst_idx + 1] = rgba[src_idx + 1];
      rotated[dst_idx + 2] = rgba[src_idx + 2];
      rotated[dst_idx + 3] = rgba[src_idx + 3];
    }
  }

  return rotated;
}

EXPORT uint8_t *convert_yuv420_to_rgba(const uint8_t *y_plane, const uint8_t *u_plane, const uint8_t *v_plane,
                                       int width, int height,
                                       int y_stride, int u_stride, int v_stride,
                                       int u_pix_stride, int v_pix_stride,
                                       int rotationDegrees)
{
  if (!y_plane || !u_plane || !v_plane || width <= 0 || height <= 0 ||
      (rotationDegrees != 0 && rotationDegrees != 90 && rotationDegrees != 180 && rotationDegrees != 270))
  {
    fprintf(stderr, "Error (convert_yuv420_to_rgba): Invalid input parameters.\n");
    return NULL;
  }

  uint8_t *intermediate = (uint8_t *)malloc(width * height * 4);
  if (!intermediate)
  {
    fprintf(stderr, "Error (convert_yuv420_to_rgba): Failed to allocate intermediate RGBA buffer.\n");
    return NULL;
  }

  for (int y = 0; y < height; ++y)
  {
    for (int x = 0; x < width; ++x)
    {
      int y_val = y_plane[y * y_stride + x];
      int u_val = u_plane[(y / 2) * u_stride + (x / 2) * u_pix_stride];
      int v_val = v_plane[(y / 2) * v_stride + (x / 2) * v_pix_stride];

      uint8_t R, G, B;
      YUV_to_RGB(y_val, u_val, v_val, &R, &G, &B);

      int rgba_idx = (y * width + x) * 4;
      intermediate[rgba_idx + 0] = R;
      intermediate[rgba_idx + 1] = G;
      intermediate[rgba_idx + 2] = B;
      intermediate[rgba_idx + 3] = 255;
    }
  }

  uint8_t *rotated = rotate_rgba_image(intermediate, width, height, rotationDegrees);
  free(intermediate);
  return rotated;
}

EXPORT uint8_t *convert_nv21_to_rgba(const uint8_t *y_plane, const uint8_t *uv_plane,
                                     int width, int height,
                                     int y_stride, int uv_stride, int uv_pix_stride,
                                     int rotationDegrees)
{
  if (!y_plane || !uv_plane || width <= 0 || height <= 0 ||
      (rotationDegrees != 0 && rotationDegrees != 90 && rotationDegrees != 180 && rotationDegrees != 270))
  {
    fprintf(stderr, "Error (convert_nv21_to_rgba): Invalid input parameters.\n");
    return NULL;
  }

  uint8_t *intermediate = (uint8_t *)malloc(width * height * 4);
  if (!intermediate)
  {
    fprintf(stderr, "Error (convert_nv21_to_rgba): Failed to allocate intermediate RGBA buffer.\n");
    return NULL;
  }

  for (int y = 0; y < height; ++y)
  {
    for (int x = 0; x < width; ++x)
    {
      int y_val = y_plane[y * y_stride + x];
      int uv_x = (x / 2) * uv_pix_stride;
      int uv_y = (y / 2) * uv_stride;
      int v_val = uv_plane[uv_y + uv_x];
      int u_val = uv_plane[uv_y + uv_x + 1];

      uint8_t R, G, B;
      YUV_to_RGB(y_val, u_val, v_val, &R, &G, &B);

      int rgba_idx = (y * width + x) * 4;
      intermediate[rgba_idx + 0] = R;
      intermediate[rgba_idx + 1] = G;
      intermediate[rgba_idx + 2] = B;
      intermediate[rgba_idx + 3] = 255;
    }
  }

  uint8_t *rotated = rotate_rgba_image(intermediate, width, height, rotationDegrees);
  free(intermediate);
  return rotated;
}

EXPORT uint8_t *convert_yuv420_to_png(const uint8_t *y_plane, const uint8_t *u_plane, const uint8_t *v_plane,
                                      int width, int height,
                                      int y_stride, int u_stride, int v_stride,
                                      int u_pix_stride, int v_pix_stride,
                                      int rotationDegrees,
                                      size_t *out_size)
{
  if (!out_size)
  {
    fprintf(stderr, "Error (convert_yuv420_to_png): out_size is NULL.\n");
    return NULL;
  }

  uint8_t *rgba = convert_yuv420_to_rgba(y_plane, u_plane, v_plane,
                                         width, height,
                                         y_stride, u_stride, v_stride,
                                         u_pix_stride, v_pix_stride,
                                         rotationDegrees);
  if (!rgba)
  {
    *out_size = 0;
    return NULL;
  }

  uint8_t *png = encode_rgba_to_png_buffer(rgba,
                                           (rotationDegrees == 90 || rotationDegrees == 270) ? height : width,
                                           (rotationDegrees == 90 || rotationDegrees == 270) ? width : height,
                                           out_size);
  free(rgba);
  return png;
}

EXPORT uint8_t *convert_nv21_to_png(const uint8_t *y_plane, const uint8_t *uv_plane,
                                    int width, int height,
                                    int y_stride, int uv_stride, int uv_pix_stride,
                                    int rotationDegrees,
                                    size_t *out_size)
{
  if (!out_size)
  {
    fprintf(stderr, "Error (convert_nv21_to_png): out_size is NULL.\n");
    return NULL;
  }

  uint8_t *rgba = convert_nv21_to_rgba(y_plane, uv_plane,
                                       width, height,
                                       y_stride, uv_stride, uv_pix_stride,
                                       rotationDegrees);
  if (!rgba)
  {
    *out_size = 0;
    return NULL;
  }

  uint8_t *png = encode_rgba_to_png_buffer(rgba,
                                           (rotationDegrees == 90 || rotationDegrees == 270) ? height : width,
                                           (rotationDegrees == 90 || rotationDegrees == 270) ? width : height,
                                           out_size);
  free(rgba);
  return png;
}

EXPORT void free_buffer(uint8_t *buffer)
{
  if (buffer)
    free(buffer);
}
