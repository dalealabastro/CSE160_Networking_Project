//#define AM_NEIGHBOR 62 //Hard coded number for AM

configuration NeighborDiscoveryC
{

  provides interface NeighborDiscovery;

  uses interface List<pack> as neighborListC;
}

implementation
{

  components NeighborDiscoveryP;

  //list of neighbors
  NeighborDiscoveryP.neighborListC = neighborListC;

  //timer for neighbor discovery component
  components new TimerMilliC() as NDTimerC;
  NeighborDiscoveryP.NDTimer->NDTimerC;

  //connect negihbor dicovery to flooding
  components FloodingC;
  NeighborDiscoveryP.FloodSender->FloodingC.FloodSender;
  NeighborDiscoveryP.Flooding -> FloodingC;

  // External Wiring
  NeighborDiscovery = NeighborDiscoveryP.NeighborDiscovery;

}
