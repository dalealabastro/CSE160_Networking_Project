//Author: UCM ANDES Lab
//$Author: abeltran2 $
//$LastChangedBy: abeltran2 $

#ifndef PACKET_H
#define PACKET_H


#include "protocol.h"
#include "channels.h"

enum{
	PACKET_HEADER_LENGTH = 8,
	PACKET_MAX_PAYLOAD_SIZE = 28 - PACKET_HEADER_LENGTH,
	MAX_TTL = 15,
	//to identify the age of neighbors in neighbor discovery
	MAX_NEIGHBOR_AGE = 5
};


typedef nx_struct pack{
	nx_uint16_t dest;
	nx_uint16_t src;
	nx_uint16_t seq;		//Sequence Number
	nx_uint8_t TTL;		//Time to Live
	nx_uint8_t protocol;
	nx_uint8_t payload[PACKET_MAX_PAYLOAD_SIZE];
}pack;

enum{
	AM_PACK=6
};

#endif
