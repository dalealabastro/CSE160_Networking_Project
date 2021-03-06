#ifndef TCP_PACKET_H
#define TCP_PACKET_H

#include "protocol.h"
#include "channels.h"

#define DATA_FLAG 0
#define DATA_ACK_FLAG 1
#define SYN_FLAG 2
#define SYN_ACK_FLAG 3
#define ACK_FLAG 4
#define FIN_FLAG 5
#define FIN_ACK 6
#define TCP_MAX_PAYLOAD_SIZE 6

typedef nx_struct tcpPacket{
	nx_uint8_t destPort;
	nx_uint8_t srcPort;
	nx_uint8_t seq;
	nx_uint16_t lastACKed;
	nx_uint8_t ACK;
	nx_uint8_t flag;
	nx_uint8_t advertisedWindow;
	nx_uint16_t payload[TCP_MAX_PAYLOAD_SIZE];
}tcpPacket;

#endif
