#include <Timer.h>
#include "includes/CommandMsg.h"
#include "includes/packet.h"
#include "includes/lsp.h"
#include "includes/route.h"

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

    //Neighbor Discovery
    //neighbor register list
    //using neighbor discovery component
    //wiring node to neighbor discovery
    //wiring neighbor discovery resiter to node
    components NeighborDiscoveryC;
    Node.NeighborDiscovery -> NeighborDiscoveryC;
    NeighborDiscoveryC.neighborListC -> neighborListC;
    LinkStateC.lspLinkC -> lspLinkC;

    components CommandHandlerC;
    Node.CommandHandler -> CommandHandlerC;

    //components FloodingC;
    components FloodingC;
    //Node.FloodSender -> FloodingC.FloodSender;
    FloodingC.lspLinkC -> lspLinkC;
    FloodingC.NodeCacheC -> NodeCacheC;
    FloodingC.neighborListC -> neighborListC;
    FloodingC.HashmapC -> HashmapC;
    Node.RouteSender -> FloodingC.RouteSender;
    
    components LinkStateC;
    Node.LinkState -> LinkStateC;
    //Node.lspLinkList -> lspLinkC;
    Node.routingTable ->HashmapC;
    LinkStateC.neighborListC-> neighborListC;
    LinkStateC.HashmapC -> HashmapC;
}