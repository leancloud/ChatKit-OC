#ifndef AVMP_H__
#define AVMP_H__

struct avmp_ctx_s;

typedef bool   (*avmp_reader)(struct avmp_ctx_s *ctx, void *data, size_t limit);
typedef size_t (*avmp_writer)(struct avmp_ctx_s *ctx, const void *data,
                             size_t count);

enum {
  AVMP_TYPE_POSITIVE_FIXNUM, /*  0 */
  AVMP_TYPE_FIXMAP,          /*  1 */
  AVMP_TYPE_FIXARRAY,        /*  2 */
  AVMP_TYPE_FIXSTR,          /*  3 */
  AVMP_TYPE_NIL,             /*  4 */
  AVMP_TYPE_BOOLEAN,         /*  5 */
  AVMP_TYPE_BIN8,            /*  6 */
  AVMP_TYPE_BIN16,           /*  7 */
  AVMP_TYPE_BIN32,           /*  8 */
  AVMP_TYPE_EXT8,            /*  9 */
  AVMP_TYPE_EXT16,           /* 10 */
  AVMP_TYPE_EXT32,           /* 11 */
  AVMP_TYPE_FLOAT,           /* 12 */
  AVMP_TYPE_DOUBLE,          /* 13 */
  AVMP_TYPE_UINT8,           /* 14 */
  AVMP_TYPE_UINT16,          /* 15 */
  AVMP_TYPE_UINT32,          /* 16 */
  AVMP_TYPE_UINT64,          /* 17 */
  AVMP_TYPE_SINT8,           /* 18 */
  AVMP_TYPE_SINT16,          /* 19 */
  AVMP_TYPE_SINT32,          /* 20 */
  AVMP_TYPE_SINT64,          /* 21 */
  AVMP_TYPE_FIXEXT1,         /* 22 */
  AVMP_TYPE_FIXEXT2,         /* 23 */
  AVMP_TYPE_FIXEXT4,         /* 24 */
  AVMP_TYPE_FIXEXT8,         /* 25 */
  AVMP_TYPE_FIXEXT16,        /* 26 */
  AVMP_TYPE_STR8,            /* 27 */
  AVMP_TYPE_STR16,           /* 28 */
  AVMP_TYPE_STR32,           /* 29 */
  AVMP_TYPE_ARRAY16,         /* 30 */
  AVMP_TYPE_ARRAY32,         /* 31 */
  AVMP_TYPE_MAP16,           /* 32 */
  AVMP_TYPE_MAP32,           /* 33 */
  AVMP_TYPE_NEGATIVE_FIXNUM  /* 34 */
};

typedef struct avmp_ext_s {
  int8_t type;
  uint32_t size;
} avmp_ext_t;

union avmp_object_data_u {
  bool      boolean;
  uint8_t   u8;
  uint16_t  u16;
  uint32_t  u32;
  uint64_t  u64;
  int8_t    s8;
  int16_t   s16;
  int32_t   s32;
  int64_t   s64;
  float     flt;
  double    dbl;
  uint32_t  array_size;
  uint32_t  map_size;
  uint32_t  str_size;
  uint32_t  bin_size;
  avmp_ext_t ext;
};

typedef struct avmp_ctx_s {
  uint8_t     error;
  void       *buf;
  avmp_reader  read;
  avmp_writer  write;
} avmp_ctx_t;

typedef struct avmp_object_s {
  uint8_t type;
  union avmp_object_data_u as;
} avmp_object_t;

#ifdef __cplusplus
extern "C" {
#endif
  
  /*
   * ============================================================================
   * === Main API
   * ============================================================================
   */
  
  /* Initializes a AVMP context */
  void avmp_init(avmp_ctx_t *ctx, void *buf, avmp_reader read, avmp_writer write);
  
  /* Returns AVMP's version */
  uint32_t avmp_version(void);
  
  /* Returns the MessagePack version employed by AVMP */
  uint32_t avmp_mp_version(void);
  
  /* Returns a string description of a AVMP context's error */
  const char* avmp_strerror(avmp_ctx_t *ctx);
  
  /* Writes a signed integer to the backend */
  bool avmp_write_sint(avmp_ctx_t *ctx, int64_t d);
  
  /* Writes an unsigned integer to the backend */
  bool avmp_write_uint(avmp_ctx_t *ctx, uint64_t u);
  
  /* Writes a single-precision float to the backend */
  bool avmp_write_float(avmp_ctx_t *ctx, float f);
  
  /* Writes a double-precision float to the backend */
  bool avmp_write_double(avmp_ctx_t *ctx, double d);
  
  /* Writes NULL to the backend */
  bool avmp_write_nil(avmp_ctx_t *ctx);
  
  /* Writes true to the backend */
  bool avmp_write_true(avmp_ctx_t *ctx);
  
  /* Writes false to the backend */
  bool avmp_write_false(avmp_ctx_t *ctx);
  
  /* Writes a boolean value to the backend */
  bool avmp_write_bool(avmp_ctx_t *ctx, bool b);
  
  /*
   * Writes an unsigned char's value to the backend as a boolean.  This is useful
   * if you are using a different boolean type in your application.
   */
  bool avmp_write_u8_as_bool(avmp_ctx_t *ctx, uint8_t b);
  
  /*
   * Writes a string to the backend; according to the MessagePack spec, this must
   * be encoded using UTF-8, but AVMP leaves that job up to the programmer.
   */
  bool avmp_write_str(avmp_ctx_t *ctx, const char *data, uint32_t size);
  
  /*
   * Writes the string marker to the backend.  This is useful if you are writing
   * data in chunks instead of a single shot.
   */
  bool avmp_write_str_marker(avmp_ctx_t *ctx, uint32_t size);
  
  /* Writes binary data to the backend */
  bool avmp_write_bin(avmp_ctx_t *ctx, const void *data, uint32_t size);
  
  /*
   * Writes the binary data marker to the backend.  This is useful if you are
   * writing data in chunks instead of a single shot.
   */
  bool avmp_write_bin_marker(avmp_ctx_t *ctx, uint32_t size);
  
  /* Writes an array to the backend. */
  bool avmp_write_array(avmp_ctx_t *ctx, uint32_t size);
  
  /* Writes a map to the backend. */
  bool avmp_write_map(avmp_ctx_t *ctx, uint32_t size);
  
  /* Writes an extended type to the backend */
  bool avmp_write_ext(avmp_ctx_t *ctx, int8_t type, uint32_t size,
                     const void *data);
  
  /*
   * Writes the extended type marker to the backend.  This is useful if you want
   * to write the type's data in chunks instead of a single shot.
   */
  bool avmp_write_ext_marker(avmp_ctx_t *ctx, int8_t type, uint32_t size);
  
  /* Writes an object to the backend */
  bool avmp_write_object(avmp_ctx_t *ctx, avmp_object_t *obj);
  
  /* Reads a signed integer that fits inside a signed char */
  bool avmp_read_char(avmp_ctx_t *ctx, int8_t *c);
  
  /* Reads a signed integer that fits inside a signed short */
  bool avmp_read_short(avmp_ctx_t *ctx, int16_t *s);
  
  /* Reads a signed integer that fits inside a signed int */
  bool avmp_read_int(avmp_ctx_t *ctx, int32_t *i);
  
  /* Reads a signed integer that fits inside a signed long */
  bool avmp_read_long(avmp_ctx_t *ctx, int64_t *d);
  
  /* Reads a signed integer */
  bool avmp_read_sinteger(avmp_ctx_t *ctx, int64_t *d);
  
  /* Reads an unsigned integer that fits inside an unsigned char */
  bool avmp_read_uchar(avmp_ctx_t *ctx, uint8_t *c);
  
  /* Reads an unsigned integer that fits inside an unsigned short */
  bool avmp_read_ushort(avmp_ctx_t *ctx, uint16_t *s);
  
  /* Reads an unsigned integer that fits inside an unsigned int */
  bool avmp_read_uint(avmp_ctx_t *ctx, uint32_t *i);
  
  /* Reads an unsigned integer that fits inside an unsigned long */
  bool avmp_read_ulong(avmp_ctx_t *ctx, uint64_t *u);
  
  /* Reads an unsigned integer */
  bool avmp_read_uinteger(avmp_ctx_t *ctx, uint64_t *u);
  
  /* Reads a single-precision float from the backend */
  bool avmp_read_float(avmp_ctx_t *ctx, float *f);
  
  /* Reads a double-precision float from the backend */
  bool avmp_read_double(avmp_ctx_t *ctx, double *d);
  
  /* "Reads" (more like "skips") a NULL value from the backend */
  bool avmp_read_nil(avmp_ctx_t *ctx);
  
  /* Reads a boolean from the backend */
  bool avmp_read_bool(avmp_ctx_t *ctx, bool *b);
  
  /*
   * Reads a boolean as an unsigned char from the backend; this is useful if your
   * application uses a different boolean type.
   */
  bool avmp_read_bool_as_u8(avmp_ctx_t *ctx, uint8_t *b);
  
  /* Reads a string's size from the backend */
  bool avmp_read_str_size(avmp_ctx_t *ctx, uint32_t *size);
  
  /*
   * Reads a string from the backend; according to the spec, the string's data
   * ought to be encoded using UTF-8,
   */
  bool avmp_read_str(avmp_ctx_t *ctx, char *data, uint32_t *size);
  
  /* Reads the size of packed binary data from the backend */
  bool avmp_read_bin_size(avmp_ctx_t *ctx, uint32_t *size);
  
  /* Reads packed binary data from the backend */
  bool avmp_read_bin(avmp_ctx_t *ctx, void *data, uint32_t *size);
  
  /* Reads an array from the backend */
  bool avmp_read_array(avmp_ctx_t *ctx, uint32_t *size);
  
  /* Reads a map from the backend */
  bool avmp_read_map(avmp_ctx_t *ctx, uint32_t *size);
  
  /* Reads the extended type's marker from the backend */
  bool avmp_read_ext_marker(avmp_ctx_t *ctx, int8_t *type, uint32_t *size);
  
  /* Reads an extended type from the backend */
  bool avmp_read_ext(avmp_ctx_t *ctx, int8_t *type, uint32_t *size, void *data);
  
  /* Reads an object from the backend */
  bool avmp_read_object(avmp_ctx_t *ctx, avmp_object_t *obj);
  
  /*
   * ============================================================================
   * === Specific API
   * ============================================================================
   */
  
  bool avmp_write_pfix(avmp_ctx_t *ctx, uint8_t c);
  bool avmp_write_nfix(avmp_ctx_t *ctx, int8_t c);
  
  bool avmp_write_sfix(avmp_ctx_t *ctx, int8_t c);
  bool avmp_write_s8(avmp_ctx_t *ctx, int8_t c);
  bool avmp_write_s16(avmp_ctx_t *ctx, int16_t s);
  bool avmp_write_s32(avmp_ctx_t *ctx, int32_t i);
  bool avmp_write_s64(avmp_ctx_t *ctx, int64_t l);
  
  bool avmp_write_ufix(avmp_ctx_t *ctx, uint8_t c);
  bool avmp_write_u8(avmp_ctx_t *ctx, uint8_t c);
  bool avmp_write_u16(avmp_ctx_t *ctx, uint16_t s);
  bool avmp_write_u32(avmp_ctx_t *ctx, uint32_t i);
  bool avmp_write_u64(avmp_ctx_t *ctx, uint64_t l);
  
  bool avmp_write_fixstr_marker(avmp_ctx_t *ctx, uint8_t size);
  bool avmp_write_fixstr(avmp_ctx_t *ctx, const char *data, uint8_t size);
  bool avmp_write_str8_marker(avmp_ctx_t *ctx, uint8_t size);
  bool avmp_write_str8(avmp_ctx_t *ctx, const char *data, uint8_t size);
  bool avmp_write_str16_marker(avmp_ctx_t *ctx, uint16_t size);
  bool avmp_write_str16(avmp_ctx_t *ctx, const char *data, uint16_t size);
  bool avmp_write_str32_marker(avmp_ctx_t *ctx, uint32_t size);
  bool avmp_write_str32(avmp_ctx_t *ctx, const char *data, uint32_t size);
  
  bool avmp_write_bin8_marker(avmp_ctx_t *ctx, uint8_t size);
  bool avmp_write_bin8(avmp_ctx_t *ctx, const void *data, uint8_t size);
  bool avmp_write_bin16_marker(avmp_ctx_t *ctx, uint16_t size);
  bool avmp_write_bin16(avmp_ctx_t *ctx, const void *data, uint16_t size);
  bool avmp_write_bin32_marker(avmp_ctx_t *ctx, uint32_t size);
  bool avmp_write_bin32(avmp_ctx_t *ctx, const void *data, uint32_t size);
  
  bool avmp_write_fixarray(avmp_ctx_t *ctx, uint8_t size);
  bool avmp_write_array16(avmp_ctx_t *ctx, uint16_t size);
  bool avmp_write_array32(avmp_ctx_t *ctx, uint32_t size);
  
  bool avmp_write_fixmap(avmp_ctx_t *ctx, uint8_t size);
  bool avmp_write_map16(avmp_ctx_t *ctx, uint16_t size);
  bool avmp_write_map32(avmp_ctx_t *ctx, uint32_t size);
  
  bool avmp_write_fixext1_marker(avmp_ctx_t *ctx, int8_t type);
  bool avmp_write_fixext1(avmp_ctx_t *ctx, int8_t type, const void *data);
  bool avmp_write_fixext2_marker(avmp_ctx_t *ctx, int8_t type);
  bool avmp_write_fixext2(avmp_ctx_t *ctx, int8_t type, const void *data);
  bool avmp_write_fixext4_marker(avmp_ctx_t *ctx, int8_t type);
  bool avmp_write_fixext4(avmp_ctx_t *ctx, int8_t type, const void *data);
  bool avmp_write_fixext8_marker(avmp_ctx_t *ctx, int8_t type);
  bool avmp_write_fixext8(avmp_ctx_t *ctx, int8_t type, const void *data);
  bool avmp_write_fixext16_marker(avmp_ctx_t *ctx, int8_t type);
  bool avmp_write_fixext16(avmp_ctx_t *ctx, int8_t type, const void *data);
  
  bool avmp_write_ext8_marker(avmp_ctx_t *ctx, int8_t type, uint8_t size);
  bool avmp_write_ext8(avmp_ctx_t *ctx, int8_t type, uint8_t size,
                      const void *data);
  bool avmp_write_ext16_marker(avmp_ctx_t *ctx, int8_t type, uint16_t size);
  bool avmp_write_ext16(avmp_ctx_t *ctx, int8_t type, uint16_t size,
                       const void *data);
  bool avmp_write_ext32_marker(avmp_ctx_t *ctx, int8_t type, uint32_t size);
  bool avmp_write_ext32(avmp_ctx_t *ctx, int8_t type, uint32_t size,
                       const void *data);
  
  bool avmp_read_pfix(avmp_ctx_t *ctx, uint8_t *c);
  bool avmp_read_nfix(avmp_ctx_t *ctx, int8_t *c);
  
  bool avmp_read_sfix(avmp_ctx_t *ctx, int8_t *c);
  bool avmp_read_s8(avmp_ctx_t *ctx, int8_t *c);
  bool avmp_read_s16(avmp_ctx_t *ctx, int16_t *s);
  bool avmp_read_s32(avmp_ctx_t *ctx, int32_t *i);
  bool avmp_read_s64(avmp_ctx_t *ctx, int64_t *l);
  
  bool avmp_read_ufix(avmp_ctx_t *ctx, uint8_t *c);
  bool avmp_read_u8(avmp_ctx_t *ctx, uint8_t *c);
  bool avmp_read_u16(avmp_ctx_t *ctx, uint16_t *s);
  bool avmp_read_u32(avmp_ctx_t *ctx, uint32_t *i);
  bool avmp_read_u64(avmp_ctx_t *ctx, uint64_t *l);
  
  bool avmp_read_fixext1_marker(avmp_ctx_t *ctx, int8_t *type);
  bool avmp_read_fixext1(avmp_ctx_t *ctx, int8_t *type, void *data);
  bool avmp_read_fixext2_marker(avmp_ctx_t *ctx, int8_t *type);
  bool avmp_read_fixext2(avmp_ctx_t *ctx, int8_t *type, void *data);
  bool avmp_read_fixext4_marker(avmp_ctx_t *ctx, int8_t *type);
  bool avmp_read_fixext4(avmp_ctx_t *ctx, int8_t *type, void *data);
  bool avmp_read_fixext8_marker(avmp_ctx_t *ctx, int8_t *type);
  bool avmp_read_fixext8(avmp_ctx_t *ctx, int8_t *type, void *data);
  bool avmp_read_fixext16_marker(avmp_ctx_t *ctx, int8_t *type);
  bool avmp_read_fixext16(avmp_ctx_t *ctx, int8_t *type, void *data);
  
  bool avmp_read_ext8_marker(avmp_ctx_t *ctx, int8_t *type, uint8_t *size);
  bool avmp_read_ext8(avmp_ctx_t *ctx, int8_t *type, uint8_t *size, void *data);
  bool avmp_read_ext16_marker(avmp_ctx_t *ctx, int8_t *type, uint16_t *size);
  bool avmp_read_ext16(avmp_ctx_t *ctx, int8_t *type, uint16_t *size, void *data);
  bool avmp_read_ext32_marker(avmp_ctx_t *ctx, int8_t *type, uint32_t *size);
  bool avmp_read_ext32(avmp_ctx_t *ctx, int8_t *type, uint32_t *size, void *data);
  
  /*
   * ============================================================================
   * === Object API
   * ============================================================================
   */
  
  bool avmp_object_is_char(avmp_object_t *obj);
  bool avmp_object_is_short(avmp_object_t *obj);
  bool avmp_object_is_int(avmp_object_t *obj);
  bool avmp_object_is_long(avmp_object_t *obj);
  bool avmp_object_is_sinteger(avmp_object_t *obj);
  bool avmp_object_is_uchar(avmp_object_t *obj);
  bool avmp_object_is_ushort(avmp_object_t *obj);
  bool avmp_object_is_uint(avmp_object_t *obj);
  bool avmp_object_is_ulong(avmp_object_t *obj);
  bool avmp_object_is_uinteger(avmp_object_t *obj);
  bool avmp_object_is_float(avmp_object_t *obj);
  bool avmp_object_is_double(avmp_object_t *obj);
  bool avmp_object_is_nil(avmp_object_t *obj);
  bool avmp_object_is_bool(avmp_object_t *obj);
  bool avmp_object_is_str(avmp_object_t *obj);
  bool avmp_object_is_bin(avmp_object_t *obj);
  bool avmp_object_is_array(avmp_object_t *obj);
  bool avmp_object_is_map(avmp_object_t *obj);
  bool avmp_object_is_ext(avmp_object_t *obj);
  
  bool avmp_object_as_char(avmp_object_t *obj, int8_t *c);
  bool avmp_object_as_short(avmp_object_t *obj, int16_t *s);
  bool avmp_object_as_int(avmp_object_t *obj, int32_t *i);
  bool avmp_object_as_long(avmp_object_t *obj, int64_t *d);
  bool avmp_object_as_sinteger(avmp_object_t *obj, int64_t *d);
  bool avmp_object_as_uchar(avmp_object_t *obj, uint8_t *c);
  bool avmp_object_as_ushort(avmp_object_t *obj, uint16_t *s);
  bool avmp_object_as_uint(avmp_object_t *obj, uint32_t *i);
  bool avmp_object_as_ulong(avmp_object_t *obj, uint64_t *u);
  bool avmp_object_as_uinteger(avmp_object_t *obj, uint64_t *u);
  bool avmp_object_as_float(avmp_object_t *obj, float *f);
  bool avmp_object_as_double(avmp_object_t *obj, double *d);
  bool avmp_object_as_bool(avmp_object_t *obj, bool *b);
  bool avmp_object_as_str(avmp_object_t *obj, uint32_t *size);
  bool avmp_object_as_bin(avmp_object_t *obj, uint32_t *size);
  bool avmp_object_as_array(avmp_object_t *obj, uint32_t *size);
  bool avmp_object_as_map(avmp_object_t *obj, uint32_t *size);
  bool avmp_object_as_ext(avmp_object_t *obj, int8_t *type, uint32_t *size);
  
#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* AVMP_H__ */

/* vi: set et ts=2 sw=2: */
