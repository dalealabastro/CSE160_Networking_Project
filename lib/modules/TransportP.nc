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


	uses interface List<socket_t> as sockList;
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

		tcpPack* mainTCPPacket = (tcpPack *)(myMsg.payload);
		socket_t mainSock = getSocket(mainTCPPacket->srcPort, mainTCPPacket->destPort);
		
		if(mainSock.dest.port){
			call sockList.pushback(mainSock);
			call Transport.makePack(&sendMsg, TOS_NODE_ID, mainSock.dest.addr, 15, 4, 0, mainTCPPacket, PACKET_MAX_PAYLOAD_SIZE);
			call Sender.send(sendMsg, mainSock.dest.addr);
		}
	

	}

	socket_t getSocket(uint8_t destPort, uint8_t srcPort){
		socket_t mainSock;
		uint32_t i = 0;
		uint32_t size = call sockList.size();
		
		for (i = 0; i < size; i++){
			mainSock = call sockList.get(i);
			if(mainSock.dest.port == srcPort && mainSock.src.port == destPort){
				return mainSock;
			}
		}

	}

	socket_t getServerSocket(uint8_t destPort){
		socket_t mainSock;
		uint16_t i = 0;
		uint16_t size = call sockList.size();
		
		for(i = 0; i < size; i++){
			mainSock = call sockList.get(i);
			if(mainSock.src.port == destPort && mainSock.state == LISTEN){
				return mainSock;
			}
		}
		dbg(TRANSPORT_CHANNEL, "Socket not found. \n");
	}

	command error_t Transport.connect(socket_t fd){
		pack myMsg;
		tcpPack* mainTCPPacket;
		socket_t mainSock = fd;
		
		mainTCPPacket = (tcpPack*)(myMsg.payload);
		mainTCPPacket->destPort = mainSock.dest.port;
		mainTCPPacket->srcPort = mainSock.src.port;
		mainTCPPacket->ACK = 0;
		mainTCPPacket->seq = 1;
		mainTCPPacket->flags = SYN_FLAG;

		call Transport.makePack(&myMsg, TOS_NODE_ID, mainSock.dest.addr, 15, 4, 0, mainTCPPacket, PACKET_MAX_PAYLOAD_SIZE);
		mainSock.state = SYN_SENT;

		dbg(ROUTING_CHANNEL, "Node %u State is %u \n", mainSock.src.addr, mainSock.state);

		dbg(ROUTING_CHANNEL, "CLIENT IS TRYING \n");

		call Sender.send(myMsg, mainSock.dest.addr);

}	
	
	void connectionFinished(socket_t fd){
		pack myMsg;
		tcpPack* mainTCPPacket;
		socket_t mainSock = fd;
		uint16_t i = 0;

	
		mainTCPPacket = (tcpPack*)(myMsg.payload);
		mainTCPPacket->destPort = mainSock.dest.port;
		mainTCPPacket->srcPort = mainSock.src.port;
		mainTCPPacket->flags = DATA_FLAG;
		mainTCPPacket->seq = 0;

		i = 0;
		while(i < tcpPackET_MAX_PAYLOAD_SIZE && i <= mainSock.effectiveWindow){
			mainTCPPacket->payload[i] = i;
			i++;
		}

		mainTCPPacket->ACK = i;
		call Transport.makePack(&myMsg, TOS_NODE_ID, mainSock.dest.addr, 15, 4, 0, mainTCPPacket, PACKET_MAX_PAYLOAD_SIZE);

		dbg(ROUTING_CHANNEL, "Node %u State is %u \n", mainSock.src.addr, mainSock.state);

		dbg(ROUTING_CHANNEL, "SERVER CONNECTED\n");

		call packetQueue.enqueue(myMsg);

		call beaconTimer.startOneShot(140000);

		call Sender.send(myMsg, mainSock.dest.addr);

}	

	command error_t Transport.receive(pack* msg){
		uint8_t srcPort = 0;
		uint8_t destPort = 0;
		uint8_t seq = 0;
		uint8_t lastAck = 0;
		uint8_t flags = 0;
		uint16_t i = 0;
		uint16_t j = 0;
		uint32_t key = 0;
		socket_t mainSock;
		tcpPack* myMsg = (tcpPack *)(msg->payload);


		pack myNewMsg;
		tcpPack* mainTCPPacket;

		srcPort = myMsg->srcPort;
		destPort = myMsg->destPort;
		seq = myMsg->seq;
		lastAck = myMsg->ACK;
		flags = myMsg->flags;

		if(flags == SYN_FLAG || flags == SYN_ACK_FLAG || flags == ACK_FLAG){

			if(flags == SYN_FLAG){
				dbg(TRANSPORT_CHANNEL, "Got SYN! \n");
				mainSock = getServerSocket(destPort);
				if(mainSock.state == LISTEN){
					mainSock.state = SYN_GOT;
					mainSock.dest.port = srcPort;
					mainSock.dest.addr = msg->src;
					call sockList.pushback(mainSock);
				
					mainTCPPacket = (tcpPack *)(myNewMsg.payload);
					mainTCPPacket->destPort = mainSock.dest.port;
					mainTCPPacket->srcPort = mainSock.src.port;
					mainTCPPacket->seq = 1;
					mainTCPPacket->ACK = seq + 1;
					mainTCPPacket->flags = SYN_ACK_FLAG;
					dbg(TRANSPORT_CHANNEL, "SEND SYN ACK! - PAYLOAD SIZE = %i \n", tcpPackET_MAX_PAYLOAD_SIZE);
					call Transport.makePack(&myNewMsg, TOS_NODE_ID, mainSock.dest.addr, 15, 4, 0, mainTCPPacket, PACKET_MAX_PAYLOAD_SIZE);
					call Sender.send(myNewMsg, mainSock.dest.addr);
				}
			}

			else if(flags == SYN_ACK_FLAG){
				dbg(TRANSPORT_CHANNEL, "Got SYN ACK! \n");
				mainSock = getSocket(destPort, srcPort);
				mainSock.state = CONNECTION_ESTABLISHED;
				call sockList.pushback(mainSock);

				mainTCPPacket = (tcpPack*)(myNewMsg.payload);
				mainTCPPacket->destPort = mainSock.dest.port;
				mainTCPPacket->srcPort = mainSock.src.port;
				mainTCPPacket->seq = 1;
				mainTCPPacket->ACK = seq + 1;
				mainTCPPacket->flags = ACK_FLAG;
				dbg(TRANSPORT_CHANNEL, "SENDING ACK \n");
				call Transport.makePack(&myNewMsg, TOS_NODE_ID, mainSock.dest.addr, 15, 4, 0, mainTCPPacket, PACKET_MAX_PAYLOAD_SIZE);
				call Sender.send(myNewMsg, mainSock.dest.addr);

				connectionFinished(mainSock);
			}

			else if(flags == ACK_FLAG){
				dbg(TRANSPORT_CHANNEL, "GOT ACK \n");
				mainSock = getSocket(destPort, srcPort);
				if(mainSock.state == SYN_GOT){
					mainSock.state = CONNECTION_ESTABLISHED;
					call sockList.pushback(mainSock);
				}
			}
		}

		if(flags == DATA_FLAG || flags == DATA_ACK_FLAG){

			if(flags == DATA_FLAG){
				mainSock = getSocket(destPort, srcPort);
				if(mainSock.state == CONNECTION_ESTABLISHED){
					mainTCPPacket = (tcpPack*)(myNewMsg.payload);
					if(myMsg->payload[0] != 0){
						i = mainSock.lastRcvd + 1;
						j = 0;
						while(j < myMsg->ACK){
							mainSock.rcvdBuff[i] = myMsg->payload[j];
							mainSock.lastRcvd = myMsg->payload[j];
							i++;
							j++;
						}
					}else{
						i = 0;
						while(i < myMsg->ACK){
							mainSock.rcvdBuff[i] = myMsg->payload[i];
							mainSock.lastRcvd = myMsg->payload[i];
							i++;
						}
					}

				mainSock.effectiveWindow = SOCKET_BUFFER_SIZE - mainSock.lastRcvd + 1;
				call sockList.pushback(mainSock);
			
				mainTCPPacket->destPort = mainSock.dest.port;
				mainTCPPacket->srcPort = mainSock.src.port;
				mainTCPPacket->seq = seq;
				mainTCPPacket->ACK = seq + 1;
				mainTCPPacket->lastACK = mainSock.lastRcvd;
				mainTCPPacket->window = mainSock.effectiveWindow;
				mainTCPPacket->flags = DATA_ACK_FLAG;
				dbg(TRANSPORT_CHANNEL, "SENDING DATA ACK FLAG\n");
				call Transport.makePack(&myNewMsg, TOS_NODE_ID, mainSock.dest.addr, 15, 4, 0 , mainTCPPacket, PACKET_MAX_PAYLOAD_SIZE);
				call Sender.send(myNewMsg, mainSock.dest.addr);
				}
			
			} else if (flags == DATA_ACK_FLAG){
				mainSock = getSocket(destPort, srcPort);
				if(mainSock.state == CONNECTION_ESTABLISHED){
					if(myMsg->window != 0 && myMsg->lastACK != mainSock.effectiveWindow){
						mainTCPPacket = (tcpPack*)(myNewMsg.payload);
						i = myMsg->lastACK + 1;
						j = 0;
						while(j < myMsg->window && j < tcpPackET_MAX_PAYLOAD_SIZE && i <= mainSock.effectiveWindow){
							mainTCPPacket->payload[j] = i;
							i++;
							j++;
						}
					
						call sockList.pushback(mainSock);
						mainTCPPacket->flags = DATA_FLAG;
						mainTCPPacket->destPort = mainSock.dest.port;
						mainTCPPacket->srcPort = mainSock.src.port;
						mainTCPPacket->ACK = i - 1 - myMsg->lastACK;
						mainTCPPacket->seq = lastAck;
						call Transport.makePack(&myMsg, TOS_NODE_ID, mainSock.dest.addr, 15, 4, 0, mainTCPPacket, PACKET_MAX_PAYLOAD_SIZE);
						call packetQueue.dequeue();
						call packetQueue.enqueue(myNewMsg);
						dbg(TRANSPORT_CHANNEL, "SENDING NEW DATA \n");
						call Sender.send(myNewMsg, mainSock.dest.addr);
					}else{
						mainSock.state = FIN_FLAG;
						call sockList.pushback(mainSock);
						mainTCPPacket = (tcpPack*)(myNewMsg.payload);
						mainTCPPacket->destPort = mainSock.dest.port;
						mainTCPPacket->srcPort = mainSock.src.port;
						mainTCPPacket->seq = 1;
						mainTCPPacket->ACK = seq + 1;
						mainTCPPacket->flags = FIN_FLAG;
						call Transport.makePack(&myNewMsg, TOS_NODE_ID, mainSock.dest.addr, 15, 4, 0, mainTCPPacket, PACKET_MAX_PAYLOAD_SIZE);
						call Sender.send(myNewMsg, mainSock.dest.addr);
					}
				}
			}
		}
		if(flags == FIN_FLAG || flags == FIN_ACK){
			if(flags == FIN_FLAG){
				dbg(TRANSPORT_CHANNEL, "GOT FIN FLAG \n");
				mainSock = getSocket(destPort, srcPort);
				mainSock.state = CLOSED;
				mainSock.dest.port = srcPort;
				mainSock.dest.addr = msg->src;
				mainTCPPacket = (tcpPack *)(myNewMsg.payload);
				mainTCPPacket->destPort = mainSock.dest.port;
				mainTCPPacket->srcPort = mainSock.src.port;
				mainTCPPacket->seq = 1;
				mainTCPPacket->ACK = seq + 1;
				mainTCPPacket->flags = FIN_ACK;
				
				call Transport.makePack(&myNewMsg, TOS_NODE_ID, mainSock.dest.addr, 15, 4, 0, mainTCPPacket, PACKET_MAX_PAYLOAD_SIZE);
				call Sender.send(myNewMsg, mainSock.dest.addr);
			}
			if(flags == FIN_ACK){
				dbg(TRANSPORT_CHANNEL, "GOT FIN ACK \n");
				mainSock = getSocket(destPort, srcPort);
				mainSock.state = CLOSED;
			}
		}
}

	command void Transport.setTestServer(){

		socket_t mainSock;
		socket_addr_t myAddr;
		
		myAddr.addr = TOS_NODE_ID;
		myAddr.port = 123;
		
		mainSock.src = myAddr;
		mainSock.state = LISTEN;
	
		call sockList.pushback(mainSock);
	}
	command void Transport.setTestClient(){

		socket_t mainSock;
		socket_addr_t myAddr;

		myAddr.addr = TOS_NODE_ID;
		myAddr.port = 200;

		mainSock.dest.port = 123;
		mainSock.dest.addr = 1;
	
		mainSock.src = myAddr;
		
		call sockList.pushback(mainSock);
		call Transport.connect(mainSock);
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
