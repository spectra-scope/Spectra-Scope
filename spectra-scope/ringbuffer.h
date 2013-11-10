//
//  ringbuffer.h
//  spectra-scope
//
//  Created by tt on 13-11-10.
//  Copyright (c) 2013 spectra. All rights reserved.
//

#ifndef spectra_scope_ringbuffer_h
#define spectra_scope_ringbuffer_h
#include <stdlib.h>
#include <string.h>

/* an unsafe, typeless implementation of a ring buffer*/
struct ringbuffer{
    unsigned ele_size;
    unsigned size;
    unsigned len;
    unsigned in;
    unsigned out;
    char * buf;
};

/* create a ring buffer of fixed capacity*/
static struct ringbuffer ringbuffer_create(unsigned size, unsigned ele_size)
{
    return (struct ringbuffer){
        .ele_size = ele_size,
        .size = size,
        .len = 0,
        .in = 0,
        .out = 0,
        .buf = calloc(size, ele_size)
    };
}
/* free up memory used by the ring buffer*/
static void ringbuffer_destroy(struct ringbuffer * rb)
{
    if(rb != NULL)
    {
        free(rb->buf);
        rb->buf = NULL;
    }
}
/* enqueue an item*/
static void ringbuffer_enq(struct ringbuffer * rb, void * mem)
{
    memcpy(rb->buf + rb->in * rb->ele_size, mem, rb->ele_size);
    rb->in = (rb->in + 1) % rb->size;
    rb->len++;
}

/* dequeue an item*/
static void ringbuffer_deq(struct ringbuffer * rb)
{
    rb->out = (rb->out + 1) % rb->size;
    rb->len--;
}

/* get the item at the top of the queue*/
static void ringbuffer_top(struct ringbuffer * rb, void * ret)
{
    memcpy(ret, rb->buf + rb->out * rb->ele_size, rb->ele_size);
}
#endif
