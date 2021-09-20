//File created (not original)


generic configuration neighbor_discoveryC()
    {
        provides interface neighbor_discovery;
    }

implementation
    {
        components new neighbor_discoveryP();
        neighbor_discovery = neighbor_discoveryP.neighbor_discovery;

        components new ListC(int, 20);
        neighbor_discoveryP.List -> ListC;
    }