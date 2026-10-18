#pragma once
#include <stdint.h>
#include <IOKit/pwr_mgt/IOPM.h>

// Swift cannot import this public SDK function-like macro expansion.
static inline uint32_t LDClamshellStateChangeMessage(void) {
    return kIOPMMessageClamshellStateChange;
}
