//File created (not original)
#include <vector.h>

configuration neighbor_discoveryC
    {
        provides interface neighbor_discovery;
    }

implementation
    {
        components new QueueC (uint16_t*, 20);
        neighbor_discoveryP.Queue -> QueueC;
        components new ListC(uint16_t, size - 1);
        neighbor_discoveryP.List -> ListC;
    }