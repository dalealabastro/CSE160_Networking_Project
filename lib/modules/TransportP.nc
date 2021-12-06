#include "../../includes/channels.h"
#include "../../includes/protocol.h"
#include "../../includes/packet.h"
#include "../../includes/socket.h"
#include "../../includes/TCPPacket.h"
#include <Timer.h>

module TransportP{
	
	uses interface Timer<TMilli> as beaconTimer;

	uses interface SimpleSend as Sender;
	uses interface Forwarder;


	uses interface List<socket_t> as SocketList;
	uses interface Queue<pack> as packetQueue;

	uses interface RoutingTable;

	provides interface Transport;
}
implementation{

	socket_t getSocket(uint8_t destPort, uint8_t srcPort);
	socket_t getServerSocket(uint8_t destPort);


	event void beaconTimer.fired(){
		pack myMsg = call packetQueue.head();
		pack sendMsg;

		//cast as a tcpPacket
		tcpPacket* myTCPPack = (tcpPacket *)(myMsg.payload);
		socket_t mySocket = getSocket(myTCPPack->srcPort, myTCPPack->destPort);
		
		if(mySocket.dest.port){
			call SocketList.pushback(mySocket);

			//have to cast it as a uint8_t* pointer

			call Transport.makePack(&sendMsg, TOS_NODE_ID, mySocket.dest.addr, 15, 4, 0, myTCPPack, PACKET_MAX_PAYLOAD_SIZE);
			call Sender.send(sendMsg, mySocket.dest.addr);
		}
	

	}

	socket_t getSocket(uint8_t destPort, uint8_t srcPort){
		socket_t mySocket;
		uint32_t i = 0;
		uint32_t size = call SocketList.size();
		
		for (i = 0; i < size; i++){
			mySocket = call SocketList.get(i);
			if(mySocket.dest.port == srcPort && mySocket.src.port == destPort){
				return mySocket;
			}
		}

	}

	socket_t getServerSocket(uint8_t destPort){
		socket_t mySocket;
		bool foundSocket;
		uint16_t i = 0;
		uint16_t size = call SocketList.size();
		
		for(i = 0; i < size; i++){
			mySocket = call SocketList.get(i);
			if(mySocket.src.port == destPort && mySocket.state == LISTEN){
				return mySocket;
			}
		}
		dbg(TRANSPORT_CHANNEL, "Socket not found. \n");
	}
	//Creates and packs our packet and send
	command error_t Transport.connect(socket_t fd){
		pack myMsg;
		tcpPacket* myTCPPack;
		socket_t mySocket = fd;
		
		myTCPPack = (tcpPacket*)(myMsg.payload);
		myTCPPack->destPort = mySocket.dest.port;
		myTCPPack->srcPort = mySocket.src.port;
		myTCPPack->ACK = 0;
		myTCPPack->seq = 1;
		myTCPPack->flags = SYN_FLAG;

		call Transport.makePack(&myMsg, TOS_NODE_ID, mySocket.dest.addr, 15, 4, 0, myTCPPack, PACKET_MAX_PAYLOAD_SIZE);
		mySocket.state = SYN_SENT;

		dbg(ROUTING_CHANNEL, "Node %u State is %u \n", mySocket.src.addr, mySocket.state);

		dbg(ROUTING_CHANNEL, "CLIENT TRYING \n");
		//Call sender.send which goes to fowarder.P
		call Sender.send(myMsg, mySocket.dest.addr);

}	
	
	void connectDone(socket_t fd){
		pack myMsg;
		tcpPacket* myTCPPack;
		socket_t mySocket = fd;
		uint16_t i = 0;

	
		myTCPPack = (tcpPacket*)(myMsg.payload);
		myTCPPack->destPort = mySocket.dest.port;
		myTCPPack->srcPort = mySocket.src.port;
		myTCPPack->flags = DATA_FLAG;
		myTCPPack->seq = 0;

		i = 0;
		while(i < TCP_PACKET_MAX_PAYLOAD_SIZE && i <= mySocket.effectiveWindow){
			myTCPPack->payload[i] = i;
			i++;
		}

		myTCPPack->ACK = i;
		call Transport.makePack(&myMsg, TOS_NODE_ID, mySocket.dest.addr, 15, 4, 0, myTCPPack, PACKET_MAX_PAYLOAD_SIZE);

		dbg(ROUTING_CHANNEL, "Node %u State is %u \n", mySocket.src.addr, mySocket.state);

		dbg(ROUTING_CHANNEL, "SERVER CONNECTED\n");

		call packetQueue.enqueue(myMsg);

		call beaconTimer.startOneShot(140000);

		call Sender.send(myMsg, mySocket.dest.addr);

}	

	command error_t Transport.receive(pack* msg){
		tcp_pack * msg = (tcp_pack *) myMsg->payload;
        uint8_t srcPort, destPort, seq, ACKnum, flag;
        socket_t mySocket;
        uint16_t i, j;
        
        pack p;
        tcp_pack * t;
        srcPort = msg->srcPort;
        destPort = msg->destPort;
        seq = msg->seq;
        ACKnum = msg->ACK;
        flag = msg->flag;
    
        if(flag == SYN_FLAG || flag == SYN_ACK_FLAG || flag == ACK_FLAG){       // Connection setup (three way handshake)

            switch(flag){
           
                case SYN_FLAG:

                    dbg(TRANSPORT_CHANNEL, "RECEIVED SYN!\n"); 
                    mySocket = serverGetSocket(destPort);
                    if(mySocket.src.port && mySocket.CONN == LISTEN){
                        mySocket.CONN = SYN_RCVD;
                        mySocket.dest.port = srcPort;
                        mySocket.dest.location = myMsg->src;
                        call SocketList.pushfront(mySocket);
                        t = (tcp_pack*)(p.payload);
                        t->destPort = mySocket.dest.port;
                        t->srcPort = mySocket.src.port;
                        t->seq = 1;
                        t->ACK = seq + 1;
                        t->flag = SYN_ACK_FLAG;
                        makePack(&p, TOS_NODE_ID, mySocket.dest.location, MAX_TTL, PROTOCOL_TCP, 0, t, PACKET_MAX_PAYLOAD_SIZE);
                        if(call RoutingTable.get(mySocket.dest.location))
                            call Sender.send(p, call RoutingTable.get(mySocket.dest.location));
                        else
                            dbg(TRANSPORT_CHANNEL, "Can't find route to client...\n");     
                    }

                    break;

                case SYN_ACK_FLAG:

                    dbg(TRANSPORT_CHANNEL, "RECEIVED SYN_ACK!\n");
                    mySocket = getSocket(destPort, srcPort);      
                    if(mySocket.dest.port){
                        mySocket.CONN = ESTABLISHED;
                        call SocketList.pushfront(mySocket);
                        t = (tcp_pack*)(p.payload);
                        t->destPort = mySocket.dest.port;
                        t->srcPort = mySocket.src.port;
                        t->seq = 1;
                        t->ACK = seq + 1;
                        t->flag = ACK_FLAG;
                        makePack(&p, TOS_NODE_ID, mySocket.dest.location, MAX_TTL, PROTOCOL_TCP, 0, t, PACKET_MAX_PAYLOAD_SIZE);
                        if(call RoutingTable.get(mySocket.dest.location))
                            call Sender.send(p, call RoutingTable.get(mySocket.dest.location));
                        else
                            dbg(TRANSPORT_CHANNEL, "Can't find route to server...\n");
        
                        connectDone(mySocket);
    
                    }

                    break;

                case ACK_FLAG:

                    dbg(TRANSPORT_CHANNEL, "ACK RECEIVED, FINALIZING CONNECTION\n");
                    mySocket = getSocket(destPort, srcPort);
                    if(mySocket.src.port && mySocket.CONN == SYN_RCVD){
                        mySocket.CONN = ESTABLISHED;
                        call SocketList.pushfront(mySocket);
                    }

                    break; 
            }
        }

        if(flag == DATA_FLAG || flag == DATA_ACK_FLAG){  // Handle data (ACKS and transmissions)

            if(flag == DATA_FLAG){
            
               dbg(TRANSPORT_CHANNEL, "RECEIVED DATA\n");
               mySocket = getSocket(destPort, srcPort);
               if(mySocket.src.port && mySocket.CONN == ESTABLISHED){             
                   
                   t = (tcp_pack*)(p.payload);
                   if(msg->payload[0] !=  0 && seq == mySocket.nextExp){
                      i = mySocket.lastRCVD + 1;
                      j = 0;
                      while(j < msg->ACK){
                         dbg(TRANSPORT_CHANNEL, "Writing to Receive Buffer: %d\n", i);
                         mySocket.rcvdBuffer[i] = msg->payload[j];
                         mySocket.lastRCVD = msg->payload[j];
                         i++;
                         j++;
                      }
                   }else if(seq == mySocket.nextExp){
                      i = 0;
                      while(i < msg->ACK){
                         dbg(TRANSPORT_CHANNEL, "Writing to Receive Buffer: %d\n", i);
                         mySocket.rcvdBuffer[i] = msg->payload[i];
                         mySocket.lastRCVD = msg->payload[i];
                         i++;
                      }
                   }
    
                   mySocket.advertisedWindow = BUFFER_SIZE - (mySocket.lastRCVD + 1);
                   mySocket.nextExp = seq + 1; 
 
                   call SocketList.pushfront(mySocket);
                   t->destPort = mySocket.dest.port;
                   t->srcPort = mySocket.src.port;
                   t->seq = seq;
                   t->ACK = seq + 1;
                   t->lastACKed = mySocket.lastRCVD;
                   t->advertisedWindow = mySocket.advertisedWindow;
                   t->flag = DATA_ACK_FLAG;
                   makePack(&p, TOS_NODE_ID, mySocket.dest.location, MAX_TTL, PROTOCOL_TCP, 0, t, PACKET_MAX_PAYLOAD_SIZE);
         
                   if(call RoutingTable.get(mySocket.dest.location))
                       call Sender.send(p, call RoutingTable.get(mySocket.dest.location));
                   else
                       dbg(TRANSPORT_CHANNEL, "Can't find route to client...\n");     
               }
              
            }

            else if(flag == DATA_ACK_FLAG){
        
              dbg(TRANSPORT_CHANNEL, "RECEIVED DATA ACK, LAST ACKED: %d\n", msg->lastACKed);
              mySocket = getSocket(destPort, srcPort);
              if(mySocket.dest.port && mySocket.CONN == ESTABLISHED){
                if(msg->advertisedWindow != 0 && msg->lastACKed != mySocket.transfer){
                    dbg(TRANSPORT_CHANNEL, "SENDING NEXT DATA\n");
                    
                    t = (tcp_pack*)(p.payload);
                    i = msg->lastACKed + 1;
                    j = 0;
                    while(j < msg->advertisedWindow && j < TCP_MAX_PAYLOAD_SIZE && i <= mySocket.transfer){
                        dbg(TRANSPORT_CHANNEL, "Writing to Payload: %d\n", i);
                        t->payload[j] = i;
                        i++; 
                        j++;
                    } 
                     
                    call SocketList.pushfront(mySocket);        
                    t->flag = DATA_FLAG;
                    t->destPort = mySocket.dest.port;
                    t->srcPort = mySocket.src.port;
                    t->ACK = (i - 1) - msg->lastACKed;;
                    t->seq = ACKnum;
             
                    makePack(&p, TOS_NODE_ID, mySocket.dest.location, MAX_TTL, PROTOCOL_TCP, 0, t, PACKET_MAX_PAYLOAD_SIZE);     
                                        
                    makePack(&inFlight, TOS_NODE_ID, mySocket.dest.location, MAX_TTL, PROTOCOL_TCP, 0, t, PACKET_MAX_PAYLOAD_SIZE);
                    
                    call transmitTimer.startOneShot(TIMEOUT);
            
                    if(call RoutingTable.get(mySocket.dest.location)){
                        call Sender.send(p, call RoutingTable.get(mySocket.dest.location));
                    }
                    else{
                        dbg(ROUTING_CHANNEL, "Route to destination server not found...\n");
                    }
  
                }else{

                    dbg(TRANSPORT_CHANNEL, "ALL DATA SENT, CLOSING CONNECTION\n");                  
                    mySocket.CONN = FIN_WAIT1;
                    call SocketList.pushfront(mySocket);
                    t = (tcp_pack*)(p.payload);
                    t->destPort = mySocket.dest.port;
                    t->srcPort = mySocket.src.port;
                    t->seq = 1;
                    t->ACK = seq + 1;
                    t->flag = FIN_FLAG;
                    makePack(&p, TOS_NODE_ID, mySocket.dest.location, MAX_TTL, PROTOCOL_TCP, 0, t, PACKET_MAX_PAYLOAD_SIZE);
                    if(call RoutingTable.get(mySocket.dest.location))
                        call Sender.send(p, call RoutingTable.get(mySocket.dest.location));
                    else
                        dbg(TRANSPORT_CHANNEL, "Can't find route to server...\n");
               }
            }
          }
        }

        if(flag == FIN_FLAG || flag == ACK_FIN_FLAG){   // Handle connection teardown

            if(flag == FIN_FLAG){

                dbg(TRANSPORT_CHANNEL, "RECEIVED FIN REQUEST\n");
                mySocket = getSocket(destPort, srcPort);
                if(mySocket.src.port){
                    mySocket.CONN = CLOSED;
                    mySocket.dest.port = srcPort;
                    mySocket.dest.location = myMsg->src;
                    //call SocketList.pushfront(mySocket); Don't add the socket to the list again so it's basically dropped
                    t = (tcp_pack*)(p.payload);
                    t->destPort = mySocket.dest.port;
                    t->srcPort = mySocket.src.port;
                    t->seq = 1;
                    t->ACK = seq + 1;
                    t->flag = ACK_FIN_FLAG;

                    dbg(TRANSPORT_CHANNEL, "CONNECTION CLOSING, DATA RECEIVED: \n");

                    for(i = 0; i <= mySocket.lastRCVD; i++){
                        dbg(TRANSPORT_CHANNEL, "%d\n", mySocket.rcvdBuffer[i]);
                    }
                 
                    makePack(&p, TOS_NODE_ID, mySocket.dest.location, MAX_TTL, PROTOCOL_TCP, 0, t, PACKET_MAX_PAYLOAD_SIZE);
                    if(call RoutingTable.get(mySocket.dest.location))
                        call Sender.send(p, call RoutingTable.get(mySocket.dest.location));
                    else
                        dbg(TRANSPORT_CHANNEL, "Can't find route to client...\n");     
                 }
            }

            if(flag == ACK_FIN_FLAG){
            
                dbg(TRANSPORT_CHANNEL, "RECEIVED FIN ACK, GOODBYE\n");
                mySocket = getSocket(destPort, srcPort);      
                if(mySocket.dest.port){
                    mySocket.CONN = CLOSED;
                    //call SocketList.pushfront(mySocket); Don't add the socket to the list again so it's basically dropped
                }
            }
        }
    }

	command void Transport.setTestServer(){

		socket_t mySocket;
		socket_addr_t myAddr;
		
		myAddr.addr = TOS_NODE_ID;
		myAddr.port = 123;
		
		mySocket.src = myAddr;
		mySocket.state = LISTEN;
	
		call SocketList.pushback(mySocket);
	}
	command void Transport.setTestClient(){
		//Set test client and undergoe 3 way connection. Goes to transport.connect
		socket_t mySocket;
		socket_addr_t myAddr;

		myAddr.addr = TOS_NODE_ID;
		myAddr.port = 200;

		mySocket.dest.port = 123;
		mySocket.dest.addr = 1;
	
		mySocket.src = myAddr;
		
		call SocketList.pushback(mySocket);
		call Transport.connect(mySocket);
	}
	command void Transport.makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
		Package->src = src;
		Package->dest = dest;
		Package->TTL = TTL;
		Package->seq = seq;
		Package->protocol = protocol;
		memcpy(Package->payload, payload, length);
}
}
