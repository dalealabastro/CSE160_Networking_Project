#include <Timer.h>
#include "includes/CommandMsg.h"
#include "includes/packet.h"

configuration NodeC{
}
implementation {
    components MainC;
    components Node;
    components new AMReceiverC(AM_PACK) as GeneralReceive;

    //Project 1
    components new ListC(pack, 64) as neighborListC;
    components new ListC(lspLink, 64) as lspLinkC;
    components new HashmapC(int, 64) as NodeCacheC;

    //project 2
    components new HashmapC(route, 300) as HashmapC;

    Node -> MainC.Boot;


    Node.Receive -> GeneralReceive;

    components ActiveMessageC;
    Node.AMControl -> ActiveMessageC;

    components new SimpleSendC(AM_PACK);
    Node.Sender -> SimpleSendC;

    components NeighborDiscoveryC;
    Node.NeighborDiscovery -> NeighborDiscoveryC;
    NeighborDiscoveryC.neighborListC -> neighborListC;

    components CommandHandlerC;
    Node.CommandHandler -> CommandHandlerC;

    components FloodingC;
    FloodingC.lspLinkC -> lspLinkC;
    FloodingC.NodeCacheC -> NodeCacheC;
    FloodingC.neighborListC -> neighborListC;
    FloodingC.HashmapC -> HashmapC;
    Node.RouteSender -> FloodingC.RouteSender;

    components RoutingTableC;
	Node.RoutingTable -> RoutingTableC.RoutingTable;

	components ForwarderC;
	Node.ForwardSender -> ForwarderC.SimpleSend;
	Node.ForwardReceive -> ForwarderC.MainReceive;

	components TransportC;
	Node.Transport -> TransportC.Transport;
	
	components new QueueC(socket_t, 30) as SocketQueue;
	Node.SocketQueue->SocketQueue;
}