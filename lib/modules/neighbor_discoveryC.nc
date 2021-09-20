//File created (not original)


generic configuration neighbor_discoveryC()
    {
        provides interface neighbor_discovery;
    }

implementation
    {
        /*components new QueueC (uint16_t*, 20);
        neighbor_discoveryP.Queue -> QueueC;
        components new ListC(uint16_t, size - 1);
        neighbor_discoveryP.List -> ListC;
*/

        components new neighbor_discoveryP();
        neighbor_discovery = neighbor_discoveryP.neighbor_discovery;
    }