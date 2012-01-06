










typedef int INT;
typedef unsigned int UINT;


typedef char CHAR;
typedef unsigned char UCHAR;
typedef unsigned char BYTE;


typedef short SHORT;
typedef unsigned short USHORT;
typedef unsigned short WORD;
typedef unsigned short WCHAR;


typedef long LONG;
typedef unsigned long ULONG;
typedef unsigned long DWORD;






typedef BYTE DSTATUS;


typedef enum {
RES_OK = 0, 
RES_ERROR, 
RES_WRPRT, 
RES_NOTRDY, 
RES_PARERR 
} DRESULT;


typedef struct {
BYTE drv;
const BYTE* buf;
DWORD* sec;
BYTE num;
} DIO_PAR;
extern DIO_PAR dio_par;





int assign_drives (int, int);

extern DSTATUS disk_initialize (BYTE,BYTE*);

extern DRESULT disk_read (void);

extern DRESULT disk_write (void);
DRESULT disk_ioctl (BYTE, BYTE, void*);
extern BYTE ds_m[3];
























































































































typedef char TCHAR;






typedef struct {
BYTE fs_type; 
BYTE drv; 
BYTE part; 
BYTE csize; 
BYTE n_fats; 
BYTE wflag; 
BYTE fsi_flag; 
WORD id; 
WORD n_rootdir; 
DWORD last_clust; 
DWORD free_clust; 
DWORD fsi_sector; 
DWORD cdir; 
DWORD n_fatent; 
DWORD fsize; 
DWORD fatbase; 
DWORD dirbase; 
DWORD database; 
DWORD winsect; 
BYTE win[ 512 ]; 
} FATFS;





typedef struct {
FATFS* fs; 
WORD id; 
BYTE flag; 
BYTE pad1;
DWORD fptr; 
DWORD fsize; 
DWORD sclust; 
DWORD clust; 
DWORD dsect; 
DWORD dir_sect; 
BYTE* dir_ptr; 
BYTE buf[ 512 ]; 
} FIL;





typedef struct {
FATFS* fs; 
WORD id; 
WORD index; 
DWORD sclust; 
DWORD clust; 
DWORD sect; 
BYTE* dir; 
BYTE* fn; 
} DIR;





typedef struct {
DWORD fsize; 
WORD fdate; 
WORD ftime; 
BYTE fattrib; 
TCHAR fname[13]; 
} FILINFO;





typedef enum {
FR_OK = 0, 
FR_DISK_ERR, 
FR_INT_ERR, 
FR_NOT_READY, 
FR_NO_FILE, 
FR_NO_PATH, 
FR_INVALID_NAME, 
FR_DENIED, 
FR_EXIST, 
FR_INVALID_OBJECT, 
FR_WRITE_PROTECTED, 
FR_INVALID_DRIVE, 
FR_NOT_ENABLED, 
FR_NO_FILESYSTEM, 
FR_MKFS_ABORTED, 
FR_TIMEOUT, 
FR_LOCKED, 
FR_NOT_ENOUGH_CORE, 
FR_TOO_MANY_OPEN_FILES 
} FRESULT;






FRESULT f_mount (BYTE, FATFS*); 
FRESULT f_open (FIL*, const TCHAR*, BYTE); 
FRESULT f_read (FIL*, void*, UINT, UINT*); 
FRESULT f_lseek (FIL*, DWORD); 
FRESULT f_close (FIL*); 
FRESULT f_opendir (DIR*, const TCHAR*); 
FRESULT f_readdir (DIR*, FILINFO*); 
FRESULT f_stat (const TCHAR*, FILINFO*); 
FRESULT f_write (FIL*, const void*, UINT, UINT*); 
FRESULT f_getfree (const TCHAR*, DWORD*, FATFS**); 
FRESULT f_truncate (FIL*); 
FRESULT f_sync (FIL*); 
FRESULT f_unlink (const TCHAR*); 
FRESULT f_mkdir (const TCHAR*); 
FRESULT f_chmod (const TCHAR*, BYTE, BYTE); 
FRESULT f_utime (const TCHAR*, const FILINFO*); 
FRESULT f_rename (const TCHAR*, const TCHAR*); 
FRESULT f_forward (FIL*, UINT(*)(const BYTE*,UINT), UINT, UINT*); 
FRESULT f_mkfs (BYTE, BYTE, UINT); 
FRESULT f_chdrive (BYTE); 
FRESULT f_chdir (const TCHAR*); 
FRESULT f_getcwd (TCHAR*, UINT); 
int f_putc (TCHAR, FIL*); 
int f_puts (const TCHAR*, FIL*); 
int f_printf (FIL*, const TCHAR*, ...); 
TCHAR* f_gets (TCHAR*, int, FIL*); 










extern void get_fattime (DWORD*);



































DRESULT disk_ioctl (BYTE a, BYTE b, void* c)
{
return (0);
}
