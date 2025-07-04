#pragma once

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C"
{
#endif

#define EXPORT __attribute__((visibility("default")))

    EXPORT uint8_t *encode_bgra_to_jpeg_buffer(const uint8_t *bgra, int width, int height, int quality, size_t *out_size);
    EXPORT uint8_t *rotate_jpeg_buffer(const uint8_t *jpeg_data, size_t jpeg_size, int rotationDegrees, size_t *out_size);

    EXPORT void free_buffer(uint8_t *buffer);

    EXPORT uint8_t *rotate_rgba_image(const uint8_t *rgba, int width, int height, int rotationDegrees);

    EXPORT uint8_t *convert_yuv420_to_rgba(const uint8_t *y_plane, const uint8_t *u_plane, const uint8_t *v_plane,
                                           int width, int height,
                                           int y_stride, int u_stride, int v_stride,
                                           int u_pix_stride, int v_pix_stride,
                                           int rotationDegrees);

    EXPORT uint8_t *convert_nv21_to_rgba(const uint8_t *y_plane, const uint8_t *uv_plane,
                                         int width, int height,
                                         int y_stride, int uv_stride, int uv_pix_stride,
                                         int rotationDegrees);

    EXPORT uint8_t *encode_rgba_to_jpeg_buffer(const uint8_t *rgba, int width, int height, int quality, size_t *out_size);

    EXPORT uint8_t *convert_yuv420_to_jpeg(const uint8_t *y_plane, const uint8_t *u_plane, const uint8_t *v_plane,
                                           int width, int height,
                                           int y_stride, int u_stride, int v_stride,
                                           int u_pix_stride, int v_pix_stride,
                                           int rotationDegrees,
                                           int quality,
                                           size_t *out_size);

    EXPORT uint8_t *convert_nv21_to_jpeg(const uint8_t *y_plane, const uint8_t *uv_plane,
                                         int width, int height,
                                         int y_stride, int uv_stride, int uv_pix_stride,
                                         int rotationDegrees,
                                         int quality,
                                         size_t *out_size);

    EXPORT uint8_t *encode_bgra_to_jpeg_buffer(const uint8_t *bgra, int width, int height, int quality, size_t *out_size);
    EXPORT uint8_t *rotate_jpeg_buffer(const uint8_t *jpeg_data, size_t jpeg_size, int rotationDegrees, size_t *out_size);

#ifdef __cplusplus
}
#endif
