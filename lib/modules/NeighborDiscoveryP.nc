#include "../../includes/channels.h"
#include "../../includes/packet.h"

// You need to send neighbor discovery packets
// periodically
// – Nodes could die at any time
// – Use a timer and post a task to do this periodically
// o What is a good timer to avoid overloading thenetwork?
// • Upon reception of a neighbor discovery packet,
// the receiving node must reply back
// • The mechanism is very similar to Ping and Ping
// Reply, you could copy or reuse the code (Skeleton
// code!)
// • When getting a reply back, the node should gather
// statistics

module NeighborDiscoveryP
{

  provides interface NeighborDiscovery;

  /// uses interface
  uses interface Timer<TMilli> as NDTimer;
  uses interface SimpleSend as FloodSender;
  uses interface List<pack> as neighborListC;
  uses interface Flooding;
}

implementation
{
  pack outPackage;
  uint16_t seqNumber = 0;
  uint16_t neighborAge = 0;

  bool findMyNeighbor(pack * Package);

  void removeNeighbors();

  void makePack(pack * Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t * payload, uint8_t length);

  command void NeighborDiscovery.start()
  {
    uint32_t startTimer;
    dbg(GENERAL_CHANNEL, "Run: Neighbor Discovery\n");

    startTimer = (6000 + (uint16_t) ((call Random.rand16())%5000));;

    call NDTimer.startOneShot(startTimer);
  }

  command void NeighborDiscovery.neighborReceived(pack * inMsg)
  {
    //dbg(GENERAL_CHANNEL, "Package Received \n"); // DEBUG ================================
    if (!findMyNeighbor(inMsg))
    {
      call neighborListC.pushback(*inMsg);
      call NeighborDiscovery.print();
    }
  }

  command void NeighborDiscovery.print()
  {

    if (call neighborListC.size() > 0)
    {
      uint16_t registerSize = call neighborListC.size();
      uint16_t i = 0;
      dbg(NEIGHBOR_CHANNEL, "Printing out %d neighbours from node:%d\n", registerSize, TOS_NODE_ID);
      for (i = 0; i < registerSize; i++)
      {
        //retrieve neighbor nodes
        pack neighbor = call neighborListC.get(i);

        dbg(NEIGHBOR_CHANNEL, "%d - %d\n", TOS_NODE_ID, neighbor.src);
      }

      call Flooding.flood(TOS_NODE_ID);

    }
    else
    {
      dbg(COMMAND_CHANNEL, "%d has no neighbours!\n", TOS_NODE_ID);
    }
  }

  event void NDTimer.fired()
  {
    char *neighborPayload = "Neighbor Discovery";
    //neighbor register size
    uint16_t size = call neighborListC.size();

    uint16_t i = 0;

    //dbg(NEIGHBOR_CHANNEL,"Neighbor Discovery Timer Fired\n");

    if (neighborAge == MAX_NEIGHBOR_AGE)
    {
      dbg(NEIGHBOR_CHANNEL, "removing neighbor of %d with Age %d \n", TOS_NODE_ID, neighborAge);
      neighborAge = 0;
      for (i = 0; i < size; i++)
      {
        call neighborListC.popfront();
      }
    }

    makePack(&outPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, MAX_TTL, PROTOCOL_PING, seqNumber, (uint8_t *)neighborPayload, PACKET_MAX_PAYLOAD_SIZE);

    neighborAge++;
    //seqNumber++;
    //dbg(FLOODING_CHANNEL, "AM_BROADCAST_ADDR: %d\n", AM_BROADCAST_ADDR);

    call FloodSender.send(outPackage, AM_BROADCAST_ADDR);
  }
  void removeNeighbors()
  {
    uint16_t size = call neighborListC.size();
    uint16_t i = 0;
    for (i = 0; i < size; i++)
    {
      call neighborListC.popback();
    }
  }

  bool findMyNeighbor(pack * Package)
  {

    uint16_t size = call neighborListC.size();
    uint16_t i = 0;
    pack thisPack;
    for (i = 0; i < size; i++)
    {
      thisPack = call neighborListC.get(i);
      if (thisPack.src == Package->src && thisPack.dest == Package->dest)
      {
        return TRUE;
      }
    }
    return FALSE;
  }

  void makePack(pack * Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t * payload, uint8_t length)
  {
    //dbg(NEIGHBOR_CHANNEL,"src: %d | dest: %d | TTL: %d | seq: %d | protocol: %d | payload: %d |\n",src ,dest,TTL,seq,protocol,payload);
    Package->src = src;
    Package->dest = dest;
    Package->TTL = TTL;
    Package->seq = seq;
    Package->protocol = protocol;
    memcpy(Package->payload, payload, length);
  }
}
