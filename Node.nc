/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"
#include "includes/lsp.h"
#include "includes/route.h"

#include "includes/socket.h"

#define SERVER_SOCKET 123
#define CLIENT_DEFAULT_SOCKET 200
#define APP_TIMER 135000
#define APP_BUFFER_SIZE 40

module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;

   uses interface Receive;

   uses interface SimpleSend as Sender;

   uses interface CommandHandler;

   uses interface NeighborDiscovery;

   uses interface Flooding;

   uses interface SimpleSend as FloodSender;

   uses interface SimpleSend as RouteSender;

   uses interface SimpleSend as LspSender;

   uses interface Hashmap<route> as routingTable;

   uses interface LinkState;

   uses interface TCPhandler;
}

implementation{
   pack sendPackage;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   event void Boot.booted(){
      call AMControl.start();

      dbg(GENERAL_CHANNEL, "Booted\n");

      call NeighborDiscovery.start();

      call LinkState.start();
   }

   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err){
      
   }

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      dbg(GENERAL_CHANNEL, "Packet Received\n");
      if(len==sizeof(pack)){
         pack* myMsg=(pack*) payload;
         dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
         return msg;
      }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }


   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      route routeDest;
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
        if(call routingTable.contains(destination))
        {
           
            routeDest = call routingTable.get(destination);
            // for(i = 0; i < routeDest.cost; i++){
               
            // }
            makePack(&sendPackage, routeDest.nextHop, destination, MAX_TTL, PROTOCOL_PING, 0, payload, PACKET_MAX_PAYLOAD_SIZE);

            dbg(NEIGHBOR_CHANNEL, "Current Node: %d, To get to: %d, send through: %d\n",TOS_NODE_ID, destination, routeDest.nextHop);

            call RouteSender.send(sendPackage, routeDest.nextHop);
        }
        else{
          makePack(&sendPackage, TOS_NODE_ID, destination, 0, PROTOCOL_PING, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
          dbg(NEIGHBOR_CHANNEL, "Coudn't find the Routing Table for:%d so flooding\n", TOS_NODE_ID);
          call Sender.send(sendPackage, destination);
        }
   }

   event void CommandHandler.printNeighbors(){
      call NeighborDiscovery.print();
   }

   event void CommandHandler.printRouteTable(){
      call LinkState.printRoutingTable();
   }

   event void CommandHandler.printLinkState(){
      //call LinkState.print();
   }

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){
      call TCPHandler.startServer(123);
   }

   event void CommandHandler.setTestClient(){
      call TCPHandler.startClient(TOS_NODE_ID, 200, 123, 1);
   }

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
}
