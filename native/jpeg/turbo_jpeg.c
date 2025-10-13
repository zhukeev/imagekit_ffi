#include "turbo_jpeg.h"

#include <stdio.h>
#include <string.h>
#include <turbojpeg.h>

/* ---------- helpers ---------- */
static void set_err(char *err, int32_t err_len, const char *msg)
{
  if (!err || err_len <= 0)
    return;
  if (!msg)
  {
    err[0] = '\0';
    return;
  }
  snprintf(err, (size_t)err_len, "%s", msg);
  err[err_len - 1] = '\0';
}

static const char *last_err(tjhandle h)
{
#if defined(TJ_NUMERIC_VERSION) && (TJ_NUMERIC_VERSION >= 2000000)
  return tjGetErrorStr2(h);
#else
  (void)h;
  return tjGetErrorStr();
#endif
}

/* ---------- version / error ---------- */
int32_t tjx_version_str(char *out, int32_t out_len)
{
  if (!out || out_len <= 0)
    return -1;

  // Пытаемся собрать "MAJOR.MINOR.PATCH" из известных макросов.
#if defined(TJ_VERSION_MAJOR) && defined(TJ_VERSION_MINOR) && defined(TJ_VERSION_PATCH)
  snprintf(out, (size_t)out_len, "%d.%d.%d", TJ_VERSION_MAJOR, TJ_VERSION_MINOR, TJ_VERSION_PATCH);

#elif defined(TJ_VERSION) /* числовой код, например 3000000 */
  int v = (int)TJ_VERSION;
  int maj = v / 1000000;
  int min = (v / 1000) % 1000;
  int pat = v % 1000;
  snprintf(out, (size_t)out_len, "%d.%d.%d", maj, min, pat);

#elif defined(TJ_NUMERIC_VERSION) /* числовой код, например 2000000 */
  int v = (int)TJ_NUMERIC_VERSION;
  int maj = v / 1000000;
  int min = (v / 1000) % 1000;
  int pat = v % 1000;
  snprintf(out, (size_t)out_len, "%d.%d.%d", maj, min, pat);

#else
  snprintf(out, (size_t)out_len, "unknown");
#endif

  out[out_len - 1] = '\0';
  return 0;
}

int32_t tjx_version_int(void)
{
#ifdef TJ_NUMERIC_VERSION
  return (int32_t)TJ_NUMERIC_VERSION;
#else
  return 0;
#endif
}

int32_t tjx_get_error_str(void *handle, char *out, int32_t out_len)
{
  const char *s = last_err((tjhandle)handle);
  if (!s)
    s = "";
  if (out && out_len > 0)
  {
    snprintf(out, (size_t)out_len, "%s", s);
    out[out_len - 1] = '\0';
  }
  return 0;
}

/* ---------- handles ---------- */
void *tjx_init_compress(char *err, int32_t err_len)
{
  tjhandle h = tjInitCompress();
  if (!h)
    set_err(err, err_len, "tjInitCompress failed");
  else
    set_err(err, err_len, NULL);
  return (void *)h;
}

void *tjx_init_decompress(char *err, int32_t err_len)
{
  tjhandle h = tjInitDecompress();
  if (!h)
    set_err(err, err_len, "tjInitDecompress failed");
  else
    set_err(err, err_len, NULL);
  return (void *)h;
}

void *tjx_init_transform(char *err, int32_t err_len)
{
  tjhandle h = tjInitTransform();
  if (!h)
    set_err(err, err_len, "tjInitTransform failed");
  else
    set_err(err, err_len, NULL);
  return (void *)h;
}

int32_t tjx_destroy(void *handle)
{
  if (!handle)
    return 0;
  return tjDestroy((tjhandle)handle);
}

/* ---------- header helpers ---------- */
int32_t tjx_decompress_header3(
    void *dec,
    const uint8_t *jpg, int32_t len,
    int32_t *out_w, int32_t *out_h, int32_t *out_subsamp, int32_t *out_colorspace,
    char *err, int32_t err_len)
{
  if (!dec || !jpg || len <= 0 || !out_w || !out_h || !out_subsamp || !out_colorspace)
  {
    set_err(err, err_len, "invalid arguments");
    return -1;
  }
  int w = 0, h = 0, subsamp = 0, cs = 0;
  int rc = tjDecompressHeader3((tjhandle)dec, jpg, (unsigned long)len, &w, &h, &subsamp, &cs);
  if (rc != 0)
  {
    set_err(err, err_len, last_err((tjhandle)dec));
    return -2;
  }
  *out_w = w;
  *out_h = h;
  *out_subsamp = subsamp;
  *out_colorspace = cs;
  set_err(err, err_len, NULL);
  return 0;
}

int32_t tjx_get_size(
    const uint8_t *jpg, int32_t len,
    int32_t *out_w, int32_t *out_h,
    char *err, int32_t err_len)
{
  if (!jpg || len <= 0 || !out_w || !out_h)
  {
    set_err(err, err_len, "invalid arguments");
    return -1;
  }
  tjhandle h = tjInitDecompress();
  if (!h)
  {
    set_err(err, err_len, "tjInitDecompress failed");
    return -2;
  }
  int w = 0, hgt = 0, s = 0, cs = 0;
  int rc = tjDecompressHeader3(h, jpg, (unsigned long)len, &w, &hgt, &s, &cs);
  if (rc != 0)
  {
    set_err(err, err_len, last_err(h));
    tjDestroy(h);
    return -3;
  }
  *out_w = w;
  *out_h = hgt;
  set_err(err, err_len, NULL);
  tjDestroy(h);
  return 0;
}

/* ---------- JPEG -> RGB ---------- */
int32_t tjx_decompress_to_rgb(
    void *dec,
    const uint8_t *jpg, int32_t len,
    uint8_t *out_rgb, int32_t out_pitch,
    int32_t out_w, int32_t out_h, int32_t out_pf,
    int32_t flags,
    char *err, int32_t err_len)
{
  if (!dec || !jpg || len <= 0 || !out_rgb || out_w <= 0 || out_h <= 0)
  {
    set_err(err, err_len, "invalid arguments");
    return -1;
  }
  int rc = tjDecompress2(
      (tjhandle)dec,
      jpg, (unsigned long)len,
      out_rgb, out_w, out_pitch, out_h,
      out_pf, flags);
  if (rc != 0)
  {
    set_err(err, err_len, last_err((tjhandle)dec));
    return -2;
  }
  set_err(err, err_len, NULL);
  return 0;
}

/* ---------- JPEG -> YUV (single buffer) ---------- */
int32_t tjx_decompress_to_yuv(
    void *dec,
    const uint8_t *jpg, int32_t len,
    uint8_t *out_yuv, int32_t out_w, int32_t out_h,
    int32_t pad, int32_t flags,
    char *err, int32_t err_len)
{
  if (!dec || !jpg || len <= 0 || !out_yuv || out_w <= 0 || out_h <= 0)
  {
    set_err(err, err_len, "invalid arguments");
    return -1;
  }
  int rc = tjDecompressToYUV2(
      (tjhandle)dec,
      jpg, (unsigned long)len,
      out_yuv, out_w, pad, out_h, flags);
  if (rc != 0)
  {
    set_err(err, err_len, last_err((tjhandle)dec));
    return -2;
  }
  set_err(err, err_len, NULL);
  return 0;
}

/* ---------- YUV (single buffer) -> RGB ---------- */
int32_t tjx_decode_yuv_to_rgb(
    void *dec,
    const uint8_t *yuv, int32_t pad, int32_t subsamp,
    uint8_t *out_rgb, int32_t out_pitch,
    int32_t out_w, int32_t out_h, int32_t out_pf,
    int32_t flags,
    char *err, int32_t err_len)
{
  if (!dec || !yuv || !out_rgb || out_w <= 0 || out_h <= 0)
  {
    set_err(err, err_len, "invalid arguments");
    return -1;
  }
  int rc = tjDecodeYUV(
      (tjhandle)dec,
      yuv, pad, subsamp,
      out_rgb, out_w, out_pitch, out_h,
      out_pf, flags);
  if (rc != 0)
  {
    set_err(err, err_len, last_err((tjhandle)dec));
    return -2;
  }
  set_err(err, err_len, NULL);
  return 0;
}

/* ---------- RGB -> JPEG ---------- */
int32_t tjx_compress_from_rgb(
    void *enc,
    const uint8_t *rgb, int32_t w, int32_t pitch, int32_t h, int32_t pf,
    uint8_t **out_jpeg, int64_t *out_len,
    int32_t subsamp, int32_t quality, int32_t flags,
    char *err, int32_t err_len)
{
  if (!enc || !rgb || w <= 0 || h <= 0 || !out_jpeg || !out_len)
  {
    set_err(err, err_len, "invalid arguments");
    return -1;
  }
  if (quality < 1)
    quality = 1;
  if (quality > 100)
    quality = 100;
  unsigned long jpegSize = 0;
  int rc = tjCompress2(
      (tjhandle)enc,
      rgb, w, pitch, h, pf,
      out_jpeg, &jpegSize,
      subsamp, quality, flags);
  if (rc != 0)
  {
    set_err(err, err_len, last_err((tjhandle)enc));
    return -2;
  }
  *out_len = (int64_t)jpegSize;
  set_err(err, err_len, NULL);
  return 0;
}

/* ---------- YUV (single buffer) -> JPEG ---------- */
int32_t tjx_compress_from_yuv(
    void *enc,
    const uint8_t *yuv, int32_t w, int32_t pad, int32_t h, int32_t subsamp,
    uint8_t **out_jpeg, int64_t *out_len,
    int32_t quality, int32_t flags,
    char *err, int32_t err_len)
{
  if (!enc || !yuv || w <= 0 || h <= 0 || !out_jpeg || !out_len)
  {
    set_err(err, err_len, "invalid arguments");
    return -1;
  }
  if (quality < 1)
    quality = 1;
  if (quality > 100)
    quality = 100;
  unsigned long jpegSize = 0;
  int rc = tjCompressFromYUV(
      (tjhandle)enc,
      yuv, w, pad, h, subsamp,
      out_jpeg, &jpegSize,
      quality, flags);
  if (rc != 0)
  {
    set_err(err, err_len, last_err((tjhandle)enc));
    return -2;
  }
  *out_len = (int64_t)jpegSize;
  set_err(err, err_len, NULL);
  return 0;
}

/* ---------- RGB -> YUV (planes) ---------- */
int32_t tjx_encode_yuv_from_rgb(
    void *enc,
    const uint8_t *rgb, int32_t w, int32_t pitch, int32_t h, int32_t pf,
    uint8_t *out_yuv, int32_t pad, int32_t subsamp,
    int32_t flags,
    char *err, int32_t err_len)
{
  if (!enc || !rgb || !out_yuv || w <= 0 || h <= 0)
  {
    set_err(err, err_len, "invalid arguments");
    return -1;
  }
  int rc = tjEncodeYUV3(
      (tjhandle)enc,
      rgb, w, pitch, h, pf,
      out_yuv, pad, subsamp, flags);
  if (rc != 0)
  {
    set_err(err, err_len, last_err((tjhandle)enc));
    return -2;
  }
  set_err(err, err_len, NULL);
  return 0;
}

/* ---------- JPEG -> Y, U, V planes ---------- */
int32_t tjx_decompress_to_yuv_planes(
    void *dec, const uint8_t *jpg, int32_t len,
    uint8_t *y, int32_t stride_y,
    uint8_t *u, int32_t stride_u,
    uint8_t *v, int32_t stride_v,
    int32_t width, int32_t height,
    int32_t flags,
    char *err, int32_t err_len)
{
  if (!dec || !jpg || len <= 0 || !y || !u || !v || width <= 0 || height <= 0)
  {
    set_err(err, err_len, "invalid arguments");
    return -1;
  }
  unsigned char *planes[3] = {y, u, v};
  int strides[3] = {stride_y, stride_u, stride_v};
  int rc = tjDecompressToYUVPlanes(
      (tjhandle)dec, jpg, (unsigned long)len,
      planes, width, strides, height, flags);
  if (rc != 0)
  {
    set_err(err, err_len, last_err((tjhandle)dec));
    return -2;
  }
  set_err(err, err_len, NULL);
  return 0;
}

/* ---------- RGB -> Y, U, V planes ---------- */
int32_t tjx_encode_yuv_planes_from_rgb(
    void *enc, const uint8_t *rgb, int32_t w, int32_t pitch, int32_t h, int32_t pf,
    uint8_t *y, int32_t stride_y,
    uint8_t *u, int32_t stride_u,
    uint8_t *v, int32_t stride_v,
    int32_t subsamp, int32_t flags,
    char *err, int32_t err_len)
{
  if (!enc || !rgb || !y || !u || !v || w <= 0 || h <= 0)
  {
    set_err(err, err_len, "invalid arguments");
    return -1;
  }
  unsigned char *planes[3] = {y, u, v};
  int strides[3] = {stride_y, stride_u, stride_v};
  int rc = tjEncodeYUVPlanes(
      (tjhandle)enc, rgb, w, pitch, h, pf,
      planes, strides, subsamp, flags);
  if (rc != 0)
  {
    set_err(err, err_len, last_err((tjhandle)enc));
    return -2;
  }
  set_err(err, err_len, NULL);
  return 0;
}

/* ---------- Y, U, V planes -> JPEG ---------- */
int32_t tjx_compress_from_yuv_planes(
    void *enc,
    uint8_t *y, int32_t stride_y,
    uint8_t *u, int32_t stride_u,
    uint8_t *v, int32_t stride_v,
    int32_t width, int32_t height, int32_t subsamp,
    uint8_t **out_jpeg, int64_t *out_len,
    int32_t quality, int32_t flags,
    char *err, int32_t err_len)
{
  if (!enc || !y || !u || !v || width <= 0 || height <= 0 || !out_jpeg || !out_len)
  {
    set_err(err, err_len, "invalid arguments");
    return -1;
  }
  if (quality < 1)
    quality = 1;
  if (quality > 100)
    quality = 100;

  unsigned long jpegSize = 0;
  unsigned char *planes[3] = {y, u, v};
  int strides[3] = {stride_y, stride_u, stride_v};

  int rc = tjCompressFromYUVPlanes(
      (tjhandle)enc,
      (const unsigned char **)planes,
      width, strides, height, subsamp,
      out_jpeg, &jpegSize, quality, flags);
  if (rc != 0)
  {
    set_err(err, err_len, last_err((tjhandle)enc));
    return -2;
  }
  *out_len = (int64_t)jpegSize;
  set_err(err, err_len, NULL);
  return 0;
}

/* ---------- Transform (rotate/flip/crop) ---------- */
int32_t tjx_transform_simple(
    const uint8_t *in_jpeg, int32_t in_len,
    int32_t op, int32_t options,
    int32_t crop_x, int32_t crop_y, int32_t crop_w, int32_t crop_h,
    uint8_t **out_jpeg, int64_t *out_len,
    int32_t flags,
    char *err, int32_t err_len)
{
  if (!in_jpeg || in_len <= 0 || !out_jpeg || !out_len)
  {
    set_err(err, err_len, "invalid arguments");
    return -1;
  }

  tjhandle h = tjInitTransform();
  if (!h)
  {
    set_err(err, err_len, "tjInitTransform failed");
    return -2;
  }

  tjtransform xform;
  memset(&xform, 0, sizeof(xform));
  xform.op = op;
  xform.options = options;
  if (crop_w > 0 && crop_h > 0)
  {
    xform.r.x = crop_x;
    xform.r.y = crop_y;
    xform.r.w = crop_w;
    xform.r.h = crop_h;
    xform.options |= TJX_OPT_CROP; /* ensure crop bit is set */
  }

  unsigned long outSize = 0;
  int rc = tjTransform(
      h, in_jpeg, (unsigned long)in_len, 1,
      out_jpeg, &outSize,
      &xform, flags);

  if (rc != 0)
  {
    set_err(err, err_len, last_err(h));
    tjDestroy(h);
    return -3;
  }

  *out_len = (int64_t)outSize;
  set_err(err, err_len, NULL);
  tjDestroy(h);
  return 0;
}

/* --- helpers to map our stable enums -> TurboJPEG macros --- */
static int _map_op_to_tjx(int op_)
{
  switch (op_)
  {
  case TJX_OP_HFLIP_:
    return TJXOP_HFLIP;
  case TJX_OP_VFLIP_:
    return TJXOP_VFLIP;
  case TJX_OP_TRANSPOSE_:
    return TJXOP_TRANSPOSE;
  case TJX_OP_TRANSVERSE_:
    return TJXOP_TRANSVERSE;
  case TJX_OP_ROT90_:
    return TJXOP_ROT90;
  case TJX_OP_ROT180_:
    return TJXOP_ROT180;
  case TJX_OP_ROT270_:
    return TJXOP_ROT270;
  case TJX_OP_NONE_:
  default:
    return TJXOP_NONE;
  }
}

static int _map_opts_to_tjx(int opts_)
{
  int o = 0;
  if (opts_ & TJX_OPT_PERFECT_)
    o |= TJXOPT_PERFECT;
  if (opts_ & TJX_OPT_TRIM_)
    o |= TJXOPT_TRIM;
  if (opts_ & TJX_OPT_CROP_)
    o |= TJXOPT_CROP;
  if (opts_ & TJX_OPT_GRAY_)
    o |= TJXOPT_GRAY;
  if (opts_ & TJX_OPT_NOOUTPUT_)
    o |= TJXOPT_NOOUTPUT;
  return o;
}

/* ---------- size helpers ---------- */
int32_t tjx_buf_size(int32_t w, int32_t h, int32_t subsamp, int64_t *out)
{
  if (!out || w <= 0 || h <= 0)
    return -1;
  *out = (int64_t)tjBufSize(w, h, subsamp);
  return 0;
}

int32_t tjx_buf_size_yuv2(int32_t w, int32_t pad, int32_t h, int32_t subsamp, int64_t *out)
{
  if (!out || w <= 0 || h <= 0)
    return -1;
  *out = (int64_t)tjBufSizeYUV2(w, pad, h, subsamp);
  return 0;
}

/* ---------- scaling factors ---------- */
int32_t tjx_get_scaling_factors(
    int32_t *out_num, int32_t *out_den, int32_t max,
    int32_t *out_count,
    char *err, int32_t err_len)
{
  int n = 0;
  tjscalingfactor *s = tjGetScalingFactors(&n);
  if (out_count)
    *out_count = n;
  if (!s)
  {
    set_err(err, err_len, "tjGetScalingFactors failed");
    return -1;
  }
  if (out_num && out_den && max > 0)
  {
    int m = (n < max) ? n : max;
    for (int i = 0; i < m; ++i)
    {
      out_num[i] = s[i].num;
      out_den[i] = s[i].denom;
    }
  }
  set_err(err, err_len, NULL);
  return 0;
}

/* ---------- free ---------- */
void tjx_free(uint8_t *p)
{
  if (p)
    tjFree(p);
}
