#pragma once

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C"
{
#endif

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT __attribute__((visibility("default")))
#endif

    // Освобождение выделенной памяти
    EXPORT void free_buffer(uint8_t *buffer);

    // Поворот RGBA8888 изображения (4 канала, 8 бит на канал)
    EXPORT uint8_t *rotate_rgba_image(const uint8_t *rgba, int width, int height, int rotationDegrees);

    // Конвертация YUV420 (сепарированные планы) в RGBA8888 с поворотом
    EXPORT uint8_t *convert_yuv420_to_rgba(const uint8_t *y_plane, const uint8_t *u_plane, const uint8_t *v_plane,
                                           int width, int height,
                                           int y_stride, int u_stride, int v_stride,
                                           int u_pix_stride, int v_pix_stride,
                                           int rotationDegrees);

    // Конвертация NV21 (Y + UV интерливинг) в RGBA8888 с поворотом
    EXPORT uint8_t *convert_nv21_to_rgba(const uint8_t *y_plane, const uint8_t *uv_plane,
                                         int width, int height,
                                         int y_stride, int uv_stride, int uv_pix_stride,
                                         int rotationDegrees);

    // Кодирование RGBA8888 изображения в PNG в памяти (возвращает буфер с PNG)
    EXPORT uint8_t *encode_rgba_to_png_buffer(const uint8_t *rgba, int width, int height, size_t *out_size);

    // Конвертация YUV420 в PNG (RGBA + PNG кодирование)
    EXPORT uint8_t *convert_yuv420_to_png(const uint8_t *y_plane, const uint8_t *u_plane, const uint8_t *v_plane,
                                          int width, int height,
                                          int y_stride, int u_stride, int v_stride,
                                          int u_pix_stride, int v_pix_stride,
                                          int rotationDegrees,
                                          size_t *out_size);

    // Конвертация NV21 в PNG (RGBA + PNG кодирование)
    EXPORT uint8_t *convert_nv21_to_png(const uint8_t *y_plane, const uint8_t *uv_plane,
                                        int width, int height,
                                        int y_stride, int uv_stride, int uv_pix_stride,
                                        int rotationDegrees,
                                        size_t *out_size);

#ifdef __cplusplus
}
#endif
