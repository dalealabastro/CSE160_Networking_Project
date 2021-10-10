#define AM_LinkState 62

 
configuration LinkStateC
{
  provides interface LinkState;
  uses interface List<pack> as neighborListC;
  uses interface List<lspLink> as lspLinkC;
   uses interface Hashmap<route> as HashmapC;
}

implementation
{

  components LinkStateP;
  //components new TimerMilliC() as neigbordiscoveryTimer;
  //components new SimpleSendC(AM_NEIGHBOR);
  components new AMReceiverC(AM_NEIGHBOR);

  components new TimerMilliC() as lsrTimer;
  LinkStateP.lsrTimer->lsrTimer;

  components new TimerMilliC() as dijkstra;
  LinkStateP.dijkstraTimer -> dijkstra;

  LinkStateP.neighborList = neighborListC;

  components RandomC as Random;
  LinkStateP.Random->Random;

  //LinkStateP.LspReceiver->AMReceiverC;

  // External Wiring
  LinkState = LinkStateP.LinkState;

  LinkStateP.lspLinkList = lspLinkC;
  LinkStateP.routingTable = HashmapC;
  
  components FloodingC;
  LinkStateP.LspSender->FloodingC.LspSender;

}