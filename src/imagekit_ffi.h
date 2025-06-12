#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#if _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

// BGRA8888 to JPEG
uint8_t *convert_bgra8888_to_jpeg_rotate(
    uint8_t *bgra,
    int width,
    int height,
    int rowStride,
    int rotationDegrees,
    int *outSize);

// YUV420 to JPEG
uint8_t *convert_yuv420_to_jpeg_rotate(
    uint8_t *y_plane, uint8_t *u_plane, uint8_t *v_plane,
    int width, int height,
    int y_stride, int u_stride, int v_stride,
    int u_pix_stride, int v_pix_stride,
    int rotationDegrees,
    int *out_size);

// NV21 to JPEG
uint8_t *convert_nv21_to_jpeg_rotate(
    uint8_t *y_plane, uint8_t *uv_plane,
    int width, int height,
    int y_stride, int uv_stride, int uv_pix_stride,
    int rotationDegrees,
    int *out_size);

uint8_t *rotate_rgb_image(
    uint8_t *rgb, int width, int height, int rotationDegrees);
