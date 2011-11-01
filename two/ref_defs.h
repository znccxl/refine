

#ifndef REF_DEFS_H
#define REF_DEFS_H

#ifdef __cplusplus
#  define BEGIN_C_DECLORATION extern "C" {
#  define END_C_DECLORATION }
#else
#  define BEGIN_C_DECLORATION
#  define END_C_DECLORATION
#endif

BEGIN_C_DECLORATION

#define REF_TRUE (1==1)
#define REF_FALSE (1==0)

#if !defined(REF_ECHO_ASSERT)
#define REF_ECHO_ASSERT (REF_FALSE)
#endif

#define REF_EMPTY (-1)

#if !defined(ABS)
#define ABS(a)   ((a)>0?(a):-(a))
#endif

#if !defined(MIN)
#define MIN(a,b) ((a)<(b)?(a):(b)) 
#endif

#if !defined(MAX)
#define MAX(a,b) ((a)>(b)?(a):(b))
#endif

#define ref_cond_free(ptr) {if ( NULL != (ptr) ) free((ptr));}

typedef int REF_INT;
typedef double REF_DBL;

typedef int REF_STATUS;

#define REF_SUCCESS       (0)
#define REF_FAILURE       (1)
#define REF_NULL          (2)
#define REF_INVALID       (3)
#define REF_IMPLEMENT     (4)

#define RSS(fcn,msg)							\
  {									\
    REF_STATUS code;							\
    code = (fcn);							\
    if (REF_SUCCESS != code){						\
      printf("%s: %d: %s: %d %s\n",__FILE__,__LINE__,__func__,code,(msg)); \
      return code;							\
    }									\
  }

#define RNS(ptr,msg)							\
  {									\
    if (NULL == (ptr)){							\
      printf("%s: %d: %s: %s\n",__FILE__,__LINE__,__func__,(msg)); \
      return REF_NULL;							\
    }									\
  }

#define RES(a,b,msg)							\
  {									\
    if ((a)!=(b)){							\
      printf("%s: %d: %s: %s\n",__FILE__,__LINE__,__func__,(msg)); \
      return REF_FAILURE;						\
    }									\
  }

#define RUS(a,b,msg)							\
  {									\
    if ((a)==(b)){							\
      printf("%s: %d: %s: %s\n",__FILE__,__LINE__,__func__,(msg)); \
      return REF_FAILURE;						\
    }									\
  }

#define RAS(a,msg)							\
  {									\
    if (!(a)){								\
      printf("%s: %d: %s: %s\n",__FILE__,__LINE__,__func__,(msg)); \
      return REF_FAILURE;						\
    }									\
  }

#define RFS(fcn,msg)							\
  {									\
    REF_STATUS code;							\
    code = (fcn);							\
    if (REF_SUCCESS == code){						\
      printf("%s: %d: %s: %s\n",__FILE__,__LINE__,__func__,(msg)); \
      return code;							\
    }									\
  }

#define SUPRESS_UNUSED_COMPILER_WARNING(ptr)                    \
  if (NULL == &(ptr)) printf("unused macro failed\n");

END_C_DECLORATION

#endif /* REF_DEFS_H */

