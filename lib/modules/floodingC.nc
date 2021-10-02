#include "includes/packet.h"

generic configuration floodingC()
{
    provides interface flooding;  
    //SimpleSend
    //Recieve             
}

implementation
{
    //Add
    components new floodingP();
    flooding = floodingP.flooding;

    components new neighbor_discoveryC();
    floodingP.neighbor_discovery -> neighbor_discoveryC;

    // components new QueueC();
    // floodingP.Queue -> QueueC;

    components new HashmapC();
    floodingP.Hashmap -> HashmapC;

    components new SimpleSendC(AM_PACK);
    floodingP.Send -> SimpleSendC;
}



// How to access topo data in neighbor_discovery for neighbor search?
// How to flood nodes?
// How to setup nodes for TTL checks?
// How to end the whole program properly?