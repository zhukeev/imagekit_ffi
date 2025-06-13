// imagekit.c
// C implementation for converting camera image formats to JPEG via libjpeg
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <setjmp.h>
#include <jpeglib.h>

static inline uint8_t clamp(int val)
{
  if (val < 0)
    return 0;
  if (val > 255)
    return 255;
  return (uint8_t)val;
}

// Custom error handler struct for libjpeg
struct my_error_mgr
{
  struct jpeg_error_mgr pub;
  jmp_buf setjmp_buffer;
};

METHODDEF(void)
my_error_exit(j_common_ptr cinfo)
{
  struct my_error_mgr *myerr = (struct my_error_mgr *)cinfo->err;
  longjmp(myerr->setjmp_buffer, 1);
}

// Helper: Write RGB buffer to JPEG with error handling
uint8_t *encode_rgb_to_jpeg(uint8_t *rgb, int width, int height, int *out_size)
{
  struct jpeg_compress_struct cinfo;
  struct my_error_mgr jerr;

  cinfo.err = jpeg_std_error(&jerr.pub);
  jerr.pub.error_exit = my_error_exit;

  if (setjmp(jerr.setjmp_buffer))
  {
    // Error occurred during compression
    jpeg_destroy_compress(&cinfo);
    return NULL;
  }

  jpeg_create_compress(&cinfo);

  unsigned char *outbuffer = NULL;
  unsigned long outsize = 0;
  jpeg_mem_dest(&cinfo, &outbuffer, &outsize);

  cinfo.image_width = width;
  cinfo.image_height = height;
  cinfo.input_components = 3;
  cinfo.in_color_space = JCS_RGB;

  jpeg_set_defaults(&cinfo);
  jpeg_set_quality(&cinfo, 90, TRUE);
  jpeg_start_compress(&cinfo, TRUE);

  JSAMPROW row_pointer[1];
  int row_stride = width * 3;

  while (cinfo.next_scanline < cinfo.image_height)
  {
    row_pointer[0] = &rgb[cinfo.next_scanline * row_stride];
    jpeg_write_scanlines(&cinfo, row_pointer, 1);
  }

  jpeg_finish_compress(&cinfo);
  *out_size = (int)outsize;

  jpeg_destroy_compress(&cinfo);
  return outbuffer;
}

uint8_t *convert_jpeg_to_rgba(
    const uint8_t *jpeg_data,
    int jpeg_size,
    int *out_width,
    int *out_height)
{
  struct jpeg_decompress_struct cinfo;
  struct my_error_mgr jerr;

  cinfo.err = jpeg_std_error(&jerr.pub);
  jerr.pub.error_exit = my_error_exit;

  if (setjmp(jerr.setjmp_buffer))
  {
    jpeg_destroy_decompress(&cinfo);
    return NULL;
  }

  jpeg_create_decompress(&cinfo);
  jpeg_mem_src(&cinfo, jpeg_data, jpeg_size);
  jpeg_read_header(&cinfo, TRUE);
  jpeg_start_decompress(&cinfo);

  int width = cinfo.output_width;
  int height = cinfo.output_height;
  int channels = cinfo.output_components; // should be 3 (RGB)

  *out_width = width;
  *out_height = height;

  uint8_t *rgba = (uint8_t *)malloc(width * height * 4);
  if (!rgba)
    return NULL;

  JSAMPARRAY buffer = (*cinfo.mem->alloc_sarray)((j_common_ptr)&cinfo, JPOOL_IMAGE, width * channels, 1);

  while (cinfo.output_scanline < cinfo.output_height)
  {
    jpeg_read_scanlines(&cinfo, buffer, 1);
    for (int x = 0; x < width; x++)
    {
      int rgb_offset = x * channels;
      int out_offset = ((cinfo.output_scanline - 1) * width + x) * 4;
      rgba[out_offset + 0] = buffer[0][rgb_offset + 0]; // R
      rgba[out_offset + 1] = buffer[0][rgb_offset + 1]; // G
      rgba[out_offset + 2] = buffer[0][rgb_offset + 2]; // B
      rgba[out_offset + 3] = 255;                       // A
    }
  }

  jpeg_finish_decompress(&cinfo);
  jpeg_destroy_decompress(&cinfo);

  return rgba;
}

// BGRA8888 to JPEG with rotation
uint8_t *convert_bgra8888_to_jpeg_rotate(
    uint8_t *bgra,
    int width,
    int height,
    int rowStride,
    int rotationDegrees,
    int *outSize)
{
  int outWidth = (rotationDegrees == 90 || rotationDegrees == 270) ? height : width;
  int outHeight = (rotationDegrees == 90 || rotationDegrees == 270) ? width : height;

  uint8_t *rgb = (uint8_t *)malloc(outWidth * outHeight * 3);
  if (!rgb)
    return NULL;

  for (int y = 0; y < height; y++)
  {
    for (int x = 0; x < width; x++)
    {
      int idx = y * rowStride + x * 4;

      uint8_t B = bgra[idx + 0];
      uint8_t G = bgra[idx + 1];
      uint8_t R = bgra[idx + 2];
      // Alpha channel ignored

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

      int outIdx = (rotated_y * outWidth + rotated_x) * 3;
      rgb[outIdx + 0] = R;
      rgb[outIdx + 1] = G;
      rgb[outIdx + 2] = B;
    }
  }

  uint8_t *jpeg = encode_rgb_to_jpeg(rgb, outWidth, outHeight, outSize);
  free(rgb);
  return jpeg;
}

// YUV420 planar to JPEG with rotation
uint8_t *convert_yuv420_to_jpeg_rotate(
    uint8_t *y_plane, uint8_t *u_plane, uint8_t *v_plane,
    int width, int height,
    int y_stride, int u_stride, int v_stride,
    int u_pix_stride, int v_pix_stride,
    int rotationDegrees,
    int *out_size)
{
  int outWidth = (rotationDegrees == 90 || rotationDegrees == 270) ? height : width;
  int outHeight = (rotationDegrees == 90 || rotationDegrees == 270) ? width : height;

  uint8_t *rgb = (uint8_t *)malloc(outWidth * outHeight * 3);
  if (!rgb)
    return NULL;

  for (int y = 0; y < height; y++)
  {
    for (int x = 0; x < width; x++)
    {
      int y_index = y * y_stride + x;
      int u_index = (y / 2) * u_stride + (x / 2) * u_pix_stride;
      int v_index = (y / 2) * v_stride + (x / 2) * v_pix_stride;

      int Y = y_plane[y_index];
      int U = u_plane[u_index] - 128;
      int V = v_plane[v_index] - 128;

      int R = clamp((int)(Y + 1.402 * V));
      int G = clamp((int)(Y - 0.344136 * U - 0.714136 * V));
      int B = clamp((int)(Y + 1.772 * U));

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

      int i = (rotated_y * outWidth + rotated_x) * 3;
      rgb[i + 0] = R;
      rgb[i + 1] = G;
      rgb[i + 2] = B;
    }
  }

  uint8_t *jpeg = encode_rgb_to_jpeg(rgb, outWidth, outHeight, out_size);
  free(rgb);
  return jpeg;
}

// NV21 (Y + interleaved VU) to JPEG with rotation
uint8_t *convert_nv21_to_jpeg_rotate(
    uint8_t *y_plane, uint8_t *uv_plane,
    int width, int height,
    int y_stride, int uv_stride, int uv_pix_stride,
    int rotationDegrees,
    int *out_size)
{
  int outWidth = (rotationDegrees == 90 || rotationDegrees == 270) ? height : width;
  int outHeight = (rotationDegrees == 90 || rotationDegrees == 270) ? width : height;

  uint8_t *rgb = (uint8_t *)malloc(outWidth * outHeight * 3);
  if (!rgb)
    return NULL;

  for (int y = 0; y < height; y++)
  {
    for (int x = 0; x < width; x++)
    {
      int y_index = y * y_stride + x;
      int uv_index = (y / 2) * uv_stride + (x / 2) * uv_pix_stride;

      // NV21: V first, then U
      int V = uv_plane[uv_index] - 128;
      int U = uv_plane[uv_index + 1] - 128;
      int Y = y_plane[y_index];

      int R = clamp((int)(Y + 1.402 * V));
      int G = clamp((int)(Y - 0.344136 * U - 0.714136 * V));
      int B = clamp((int)(Y + 1.772 * U));

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

      int i = (rotated_y * outWidth + rotated_x) * 3;
      rgb[i + 0] = R;
      rgb[i + 1] = G;
      rgb[i + 2] = B;
    }
  }

  uint8_t *jpeg = encode_rgb_to_jpeg(rgb, outWidth, outHeight, out_size);
  free(rgb);
  return jpeg;
}

// Rotate an RGB image buffer (no conversion)
uint8_t *rotate_rgb_image(
    uint8_t *rgb, int width, int height, int rotationDegrees)
{
  int outWidth = (rotationDegrees == 90 || rotationDegrees == 270) ? height : width;
  int outHeight = (rotationDegrees == 90 || rotationDegrees == 270) ? width : height;

  uint8_t *rotated = (uint8_t *)malloc(outWidth * outHeight * 3);
  if (!rotated)
    return NULL;

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
