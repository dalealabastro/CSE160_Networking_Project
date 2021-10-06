#define AM_NEIGHBOR 62 

configuration NeighborDiscoveryC
{

  provides interface NeighborDiscovery;

  //list for neighbor list
  //uses interface List<pack> as neighborListC;

  ///uses interface Flooding;

}

implementation
{

  components NeighborDiscoveryP; //---------------------------------------------------------------------------

  //list of neighbors
  components new ListC<pack, 64> as neighborListC
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
