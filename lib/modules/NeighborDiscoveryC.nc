/*Neighbor Discovery
Request or Reply field
– Monotonically increasing sequence number to
uniquely identify the packet
– Source address information can be obtained from the
link layer*/

// Configuration
// Active Message definition
#define AM_NEIGHBOR 62 

configuration NeighborDiscoveryC
{

  provides interface NeighborDiscovery;

  //list for neighbor list
  uses interface List<pack> as neighborListC;

  ///uses interface Flooding;

}

implementation
{

  components NeighborDiscoveryP;

  //AM Receiver, generic receiver implemented in tinyos to receive generic AM types
  components new AMReceiverC(AM_NEIGHBOR);

  //using simplesend to send package
  components new SimpleSendC(AM_NEIGHBOR);

  //list of neighbors
  NeighborDiscoveryP.neighborListC = neighborListC;


  //random # generator
  components RandomC as Random;
  NeighborDiscoveryP.Random->Random;
  
  //timer for neighbor discovery component
  components new TimerMilliC() as NDTimerC;
  NeighborDiscoveryP.NDTimer->NDTimerC; //Wire the interface to the component

  //connect negihbor dicovery to flooding
  components FloodingC;
  NeighborDiscoveryP.FloodSender->FloodingC.FloodSender;
  NeighborDiscoveryP.Flooding -> FloodingC;

  // External Wiring
  NeighborDiscovery = NeighborDiscoveryP.NeighborDiscovery;

}
