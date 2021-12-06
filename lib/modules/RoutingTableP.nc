#include "../../includes/channels.h"
#include "../../includes/protocol.h"
#include "../../includes/packet.h"
#define TIMEOUT_MAX 10
#define MAX 20

module RoutingTableP{

	uses interface Timer<TMilli> as PeriodicTimer;
	uses interface SimpleSend as Sender;
	uses interface Receive as Receive;
	uses interface NeighborDiscovery;
	
	provides interface RoutingTable;	
}

implementation {

	uint16_t LSTable[MAX][MAX];

	command void initLSTable(){
		uint16_t i, j;
		for(i = 0; i < MAX; i++){
		    for(j = 0; j < MAX; j++){
			    LSTable[i][j] = INFINITY;                           // Initialize all link state table values to infinity(20)
		    }
		}
	}

	command void sendLSPacket(){
		char payload[255];
		char tempC[127];
		uint16_t i, size = call NeighborList.size();            // Construct the link state packet by concatenating the neighborlist to the payload
		Neighbor neighbor;      
		for(i = 0; i < size; i++){
		    neighbor = call NeighborList.get(i);
		    sprintf(tempC, "%d", neighbor.srcNode);
		    strcat(payload, tempC);
		    strcat(payload, ",");
		}

		makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 50, PROTOCOL_LINKSTATE, seqNum,
			(uint8_t *) payload, (uint8_t)sizeof(payload));

		seqNum++;
		addPack(sendPackage);
		call Sender.send(sendPackage, AM_BROADCAST_ADDR);
	}

	command void updateLSTable(uint8_t * payload, uint16_t source){
		uint8_t * temp = payload;
		uint16_t length = strlen((char *)payload);              // Update the link state table neighbor pairs upon receiving a link state packet
		uint16_t i = 0;
		char buffer[5];
		while (i < length){
		    if(*(temp + 1) == ','){
			memcpy(buffer, temp, 1);
			temp += 2;
			i += 2;
			buffer[1] = '\0';
		    }else if(*(temp + 2) == ','){
		       memcpy(buffer, temp, 2);
			temp += 3;
			i += 3;
			buffer[2] = '\0';
		    }

			LSTable[source - 1][atoi(buffer) - 1] = 1;
		}

		dijkstra();
	}

	command void printLSTable(){
		uint16_t i;                                            // Print out the neighbor pairs in the local link state table
		uint16_t j;
		for(i = 0; i < 20; i++){
		    for(j = 0; j < 20; j++){
			if(LSTable[i][j] == 1)
			    dbg(ROUTING_CHANNEL, "Neighbors: %d and %d\n", i + 1, j + 1);
		    }
		}
		}

		command uint16_t minDist(uint16_t dist[], bool sptSet[]){
		uint16_t min = INFINITY, minIndex = 18, i;
		for(i = 0; i < MAX; i++){
		    if(sptSet[i] == FALSE && dist[i] < min)
			min = dist[i], minIndex = i;
		}
		return minIndex;
	}

	command void dijkstra(){
		uint16_t myID = TOS_NODE_ID - 1, i, count, v, u;
		uint16_t dist[MAX];
		bool sptSet[MAX];
		int parent[MAX];
		int temp;

		for(i = 0; i < MAX; i++){
		    dist[i] = INFINITY;
		    sptSet[i] = FALSE;
		    parent[i] = -1;   
		}

		dist[myID] = 0;

		for(count = 0; count < MAX - 1; count++){
		    u = minDist(dist, sptSet);
		    sptSet[u] = TRUE;

		    for(v = 0; v < MAX; v++){
			if(!sptSet[v] && LSTable[u][v] != INFINITY && dist[u] + LSTable[u][v] < dist[v]){
			    parent[v] = u;
			    dist[v] = dist[u] + LSTable[u][v];
			}
		    }           
		}

		for(i = 0; i < MAX; i++){
		    temp = i;
		    while(parent[temp] != -1  && parent[temp] != myID && temp < MAX){
			temp = parent[temp];
		    }
		    if(parent[temp] != myID){
			call RoutingTable.insert(i + 1, 0);
		    }
		    else
			call RoutingTable.insert(i + 1, temp + 1);
		}
	}

	command void printRoutingTable(){

		uint16_t size = call RoutingTable.size(), i, output;
		for(i = 0; i < size; i++){
		    output = call RoutingTable.get((uint32_t) i);
		    dbg(ROUTING_CHANNEL, "Key: %d\t Next Hop: %d\n", i, output);
		}

		dbg(ROUTING_CHANNEL, "\n");
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

