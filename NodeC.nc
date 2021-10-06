/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */

#include <Timer.h>
#include "includes/CommandMsg.h"
#include "includes/packet.h"

configuration NodeC{
}
implementation {
    components MainC;
    components Node;
    components new AMReceiverC(AM_PACK) as GeneralReceive;
    components new ListC(pack, 64) as neighborListC; //==================
    components new HashmapC(int, 64) as NodeCacheC; //================

    Node -> MainC.Boot;

    Node.Receive -> GeneralReceive;

    components ActiveMessageC;
    Node.AMControl -> ActiveMessageC;

    components new SimpleSendC(AM_PACK);
    Node.Sender -> SimpleSendC;

    components NeighborDiscoveryC; //========================
    Node.NeighborDiscovery -> NeighborDiscoveryC;
    NeighborDiscoveryC.neighborListC -> neighborListC;
    //LinkStateC.lspLinkC -> lspLinkC;

    components CommandHandlerC;
    Node.CommandHandler -> CommandHandlerC;

    components FloodingC; //=============================
    //Node.FloodSender -> FloodingC.FloodSender;
    FloodingC.NodeCacheC -> NodeCacheC;
    FloodingC.neighborListC -> neighborListC;
    FloodingC.HashmapC -> HashmapC;
}
