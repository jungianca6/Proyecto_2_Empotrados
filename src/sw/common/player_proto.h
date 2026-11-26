#ifndef PLAYER_PROTO_H
#define PLAYER_PROTO_H

#include <stdint.h>
#include <stddef.h>

/* Direcciones base. Nios V: acceso directo. HPS: 0xFF200000 + offset. */
#define NIOSV_CTRL_RAM_BASE   0x00030000u
#define NIOSV_PCM_RAM_BASE    0x00040000u
#define HPS_LWBRIDGE_BASE     0xFF200000u
#define HPS_CTRL_RAM_OFFSET   0x00000u
#define HPS_PCM_RAM_OFFSET    0x10000u

#define PLAYER_MAGIC          0x41554449u
#define PCM_RING_WORDS        16384u

/* STATE */
#define ST_STOPPED   0u
#define ST_PLAYING   1u
#define ST_PAUSED    2u
#define ST_LOADING   3u

/* CMD (HPS -> Nios V) */
#define CMD_LIST_READY    0x01u
#define CMD_TRACK_READY   0x02u
#define CMD_TRACK_ERROR   0x03u

/* EVT (Nios V -> HPS) */
#define EVT_REQ_LOAD      0x01u
#define EVT_REQ_STOP      0x02u

/* HPS_FLAGS / NIOS_FLAGS */
#define HPS_FLAG_EOF         (1u << 0)
#define NIOS_FLAG_UNDERRUN   (1u << 0)

typedef struct {
    uint32_t magic;        /* 0x00 HPS    */
    uint32_t cmd;          /* 0x04 HPS    */
    uint32_t cmd_arg;      /* 0x08 HPS    */
    uint32_t cmd_seq;      /* 0x0C HPS    */
    uint32_t ack_seq;      /* 0x10 Nios V */
    uint32_t evt;          /* 0x14 Nios V */
    uint32_t evt_seq;      /* 0x18 Nios V */
    uint32_t evt_ack;      /* 0x1C HPS    */
    uint32_t state;        /* 0x20 Nios V */
    uint32_t track_idx;    /* 0x24 Nios V */
    uint32_t track_count;  /* 0x28 HPS    */
    uint32_t sample_rate;  /* 0x2C HPS    */
    uint32_t total_sec;    /* 0x30 HPS    */
    uint32_t elapsed_sec;  /* 0x34 Nios V */
    uint32_t pcm_wr;       /* 0x38 HPS    */
    uint32_t pcm_rd;       /* 0x3C Nios V */
    uint32_t pcm_size;     /* 0x40 HPS    */
    uint32_t hps_flags;    /* 0x44 HPS    */
    uint32_t nios_flags;   /* 0x48 Nios V */
    uint32_t filter;       /* 0x4C Nios V */
} player_ctrl_t;

_Static_assert(offsetof(player_ctrl_t, cmd_seq)   == 0x0C, "layout");
_Static_assert(offsetof(player_ctrl_t, evt_seq)   == 0x18, "layout");
_Static_assert(offsetof(player_ctrl_t, state)     == 0x20, "layout");
_Static_assert(offsetof(player_ctrl_t, pcm_wr)    == 0x38, "layout");
_Static_assert(offsetof(player_ctrl_t, filter)    == 0x4C, "layout");
_Static_assert(sizeof(player_ctrl_t)              == 0x50, "layout");

/* Uso (siempre con volatile):
 *   Nios V: #define CTRL ((volatile player_ctrl_t *)NIOSV_CTRL_RAM_BASE)
 *   HPS:    mmap /dev/mem en HPS_LWBRIDGE_BASE y sumar HPS_CTRL_RAM_OFFSET.
 */

#endif 
