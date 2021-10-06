// Configuration
#define AM_FLOODING 79

configuration FloodingC
{
  provides interface Flooding;
  provides interface SimpleSend as FloodSender;
  uses interface List<pack> as neighborListC;
  uses interface Hashmap<int> as NodeCacheC;
}

implementation
{
  components FloodingP;
  Flooding = FloodingP.Flooding;

  components new SimpleSendC(AM_FLOODING); //Flooding packets
  FloodingP.insideSender->SimpleSendC;

  components new AMReceiverC(AM_FLOODING); //Get notification of packet get
  FloodingP.insideReciever->AMReceiverC;
  
  FloodingP.neighborList = neighborListC;

  components NeighborDiscoveryC;
  FloodingP.NeighborDiscovery->NeighborDiscoveryC;

  FloodSender = FloodingP.FloodSender;
  
  FloodingP.NodeCache = NodeCacheC;

  components new ListC(pack, 64) as packetListC;
  FloodingP.packetList->packetListC;
}