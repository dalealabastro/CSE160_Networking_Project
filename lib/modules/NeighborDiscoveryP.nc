// Module
#include "../../includes/channels.h"
#include "../../includes/protocol.h"
#include "../../includes/packet.h"
#include "../../includes/listInfo.h"
#define BEACON_PERIOD 9000
#define NEIGHBORLIST_SIZE 255

module NeighborDiscoveryP{
	// uses interface
	uses interface Timer<TMilli> as beaconTimer;
	uses interface SimpleSend as NeighborSender;
	uses interface Receive as MainReceive;
	
	provides interface NeighborDiscovery;
}

implementation{

	void addPack(pack Package){
	      call PacketList.pushback(Package);     // Add the packet to the front of the packet list
	   }

   bool checkForPack(pack* Package){
      pack Temp;
      uint16_t i;
      for(i = 0; i < call PacketList.size(); i++){
         Temp = call PacketList.get(i);
         if(Temp.src == Package->src && Temp.seq == Package->seq && Temp.dest == Package->dest){    // If the source/dest and sequence numbers are equal, we've seen this packet before
            return TRUE;
         }

      }

      return FALSE;                                                         // If the packet isn't found, return false
   }

   bool isNeighbor(uint16_t src){
      if(!call NeighborList.isEmpty()){                                     // Check to see if the neighbor exists in the neighbor list
         uint16_t i, size = call NeighborList.size();
         Neighbor neighbor;
         for(i = 0; i < size; i++){
             neighbor = call NeighborList.get(i);
             if(neighbor.srcNode == src){
                 neighbor.Age = 0;
                 return TRUE;
             }
         }

      }

      return FALSE;
   }

   void findNeighbors(){
        char * message;
        Neighbor neighbor, temp;
        uint16_t i, size = call NeighborList.size();
        for(i = 0; i < size; i++){                           // Age each neighbor on each neighbor discovery
            neighbor = call NeighborList.get(i);             // Really messy, but this can't be done with pointers since nesC only allows static allocation
            neighbor.Age++;                                  // Since we have to call a function to retrieve each neighbor, we can't directly change the age value
            call NeighborList.remove(i);                     // i.e. call NeighborList.get(i).Age++;
            call NeighborList.pushback(neighbor);
        }
        for(i = 0; i < size; i++){
            temp = call NeighborList.get(i);
            if(temp.Age > 3){                                // If neighbor is missing for 3 consecutive calls, drop them
                call NeighborList.remove(i);
                size--;
                i--;
            }
        }
        // dbg(NEIGHBOR_CHANNEL, "Sending discovery packets to neighbors...\n");
        message = "foobar";
        makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 2, PROTOCOL_PING, 1,     // Send the neighbor discovery packet(dest = AM_BROADCAST_ADDR) 
                (uint8_t *)message,(uint8_t)sizeof(message));

        addPack(sendPackage);
        call Sender.send(sendPackage, AM_BROADCAST_ADDR);
    }


	void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
		Package->src = src;
		Package->dest = dest;
		Package->TTL = TTL;
		Package->seq = seq;
		Package->protocol = protocol;
		memcpy(Package->payload, payload, length);
	}
}
