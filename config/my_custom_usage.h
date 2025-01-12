#pragma once

#include <zmk/hid_usage.h>

// 0xFF00 is a common choice for a vendor page, but pick any 0xFFxx range
#define MY_VENDOR_USAGE_PAGE  0xFF00

// Define a few custom usages. The high 16 bits is the usage page; low 16 bits is the usage ID.
#define MY_KEY_1  HID_USAGE(MY_VENDOR_USAGE_PAGE, 0x01)
#define MY_KEY_2  HID_USAGE(MY_VENDOR_USAGE_PAGE, 0x02)
#define MY_KEY_3  HID_USAGE(MY_VENDOR_USAGE_PAGE, 0x03)