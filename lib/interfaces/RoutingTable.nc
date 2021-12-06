#include "../../includes/listInfo.h"

interface RoutingTable{
	command void start();
	command void print();
	command uint16_t getNextHop(uint16_t dest);
	/*
	command void initLSTable(); 
	command void sendLSPacket();
	command void updateLSTable(uint8_t * payload, uint16_t source);
	command void printLSTable();
	command void dijkstra();
	command uint16_t minDist(uint16_t dist[], bool sptSet[]);
	command void printRoutingTable();
	*/
}
