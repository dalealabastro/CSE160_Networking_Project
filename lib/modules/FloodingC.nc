// Configuration
#define AM_FLOODING 79

configuration FloodingC
{
  provides interface Flooding;
  provides interface SimpleSend as LspSender;
  provides interface SimpleSend as FloodSender;
  provides interface SimpleSend as RouteSender;
  uses interface List<pack> as neighborListC;
  uses interface List<lspLink> as lspLinkC;
  uses interface Hashmap<int> as NodeCacheC;
  uses interface Hashmap<int> as HashmapC;
}

implementation
{
  components FloodingP;

  //components to receive and send flooding header
  components new SimpleSendC(AM_FLOODING);
  components new AMReceiverC(AM_FLOODING);

  // Wire Internal Components
  FloodingP.InternalSender->SimpleSendC;
  FloodingP.InternalReceiver->AMReceiverC;
  //link state packet
  FloodingP.lspLinkList = lspLinkC;
  
  FloodingP.routingTable = HashmapC;
  
  FloodingP.neighborList = neighborListC;


  // Provide External Interfaces.
  components NeighborDiscoveryC;
  FloodingP.NeighborDiscovery->NeighborDiscoveryC;

  FloodSender = FloodingP.FloodSender;
  LspSender = FloodingP.LspSender;
  RouteSender = FloodingP.RouteSender;

  Flooding = FloodingP.Flooding;
  
  FloodingP.NodeCache = NodeCacheC;

  components new ListC(pack, 64) as packetListC;
  FloodingP.packetList->packetListC;
}
