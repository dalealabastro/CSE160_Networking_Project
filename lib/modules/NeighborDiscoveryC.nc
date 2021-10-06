#define AM_NEIGHBOR 62 

configuration NeighborDiscoveryC
{

  provides interface NeighborDiscovery;

  //list for neighbor list
  uses interface List<packet> as neighborListC;

  ///uses interface Flooding;

}

implementation
{

  components NeighborDiscoveryP; //---------------------------------------------------------------------------

  //list of neighbors
  NeighborDiscoveryP.neighborListC = neighborListC; //-----------------------------------------

  //timer for neighbor discovery component
  components new TimerMilliC() as NDTimerC; //-------------------------------
  NeighborDiscoveryP.NDTimer->NDTimerC; //Wire the interface to the component

  //connect negihbor dicovery to flooding
  components FloodingC;
  NeighborDiscoveryP.FloodSender->FloodingC.FloodSender;
  NeighborDiscoveryP.Flooding -> FloodingC;//-------------------------------

  // External Wiring
  NeighborDiscovery = NeighborDiscoveryP.NeighborDiscovery;//-------------------------------------------------

}
