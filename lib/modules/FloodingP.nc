#include "../../includes/channels.h"
#include "../../includes/lsp.h"
#include "../../includes/CommandMsg.h"
#include "../../includes/route.h"


module FloodingP
{

    provides interface SimpleSend as FloodSender;
    provides interface SimpleSend as LspSender;
    provides interface SimpleSend as RouteSender;
    provides interface Flooding;

    // Internal
    uses interface SimpleSend as InternalSender;
    uses interface Receive as InternalReceiver;
    uses interface List<pack> as packetList;
    uses interface List<lspLink> as lspLinkList;
    uses interface NeighborDiscovery;
    uses interface List<pack> as neighborList;
    uses interface Hashmap<int> as NodeCache;
    uses interface Hashmap<route> as routingTable;
    uses interface LinkState;
}

implementation
{
    //implement flooding
    //monotonically increasing sequence numbeer
    uint16_t sequenceN = 0;
    //final package to be sent
    pack sendPackage;

    bool findMyPacket(pack * Package);

    void checkPackets(pack * myMsg);

    void makePack(pack * Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t * payload, uint8_t length);

    bool isvalueinarray(uint8_t val, uint8_t * arr, uint8_t size);

    lspLink lspL;

    uint16_t lspAge = 0;

    //command to send new flooding package
    command error_t FloodSender.send(pack msg, uint16_t dest)
    {
        //flooding source
        msg.src = TOS_NODE_ID;
        //protocol
        msg.protocol = PROTOCOL_PING;
        //increase sequence number
        msg.seq = sequenceN+1;
        //time ti live
        msg.TTL = MAX_TTL;
        //dbg(NEIGHBOR_CHANNEL,"src: %d | dest: %d | TTL: %d | seq: %d | protocol: %d | payload: %s |\n",msg.src ,msg.dest,msg.TTL,msg.seq,msg.protocol,msg.payload);
        //call InternalSender.send(msg, AM_BROADCAST_ADDR);
        
        //dbg(NEIGHBOR_CHANNEL,"src: %d | dest: %d | TTL: %d | seq: %d | protocol: %d | payload: %s |\n",msg.src ,msg.dest,msg.TTL,msg.seq,msg.protocol,msg.payload);
         if(call InternalSender.send(msg, AM_BROADCAST_ADDR) !=	SUCCESS){
            return FAIL;
         }else{
            //dbg(FLOODING_CHANNEL, "Node: %d FloodingNetwork: %s\n",msg.src, msg.payload);
            return SUCCESS;
         }
    }

    //command to send new link state packet
    command error_t LspSender.send(pack msg, uint16_t dest)
    {
        call InternalSender.send(msg, AM_BROADCAST_ADDR);
    }

    command error_t RouteSender.send(pack msg, uint16_t dest){
        
        msg.seq = sequenceN++;
        //dbg(COMMAND_CHANNEL, "LSP Network: %s\n", msg.payload);
        call InternalSender.send(msg, dest);
    }

    command void Flooding.flood(uint16_t source){
        pack neighborFlood;

        uint8_t floodingPayload[2] = {TOS_NODE_ID,0};

        makePack(&neighborFlood, source, AM_BROADCAST_ADDR, MAX_TTL, PROTOCOL_FLOODING, sequenceN+1,  floodingPayload, PACKET_MAX_PAYLOAD_SIZE);

        call InternalSender.send(neighborFlood, AM_BROADCAST_ADDR);

    }
 
    event message_t *InternalReceiver.receive(message_t * msg, void *payload, uint8_t len)
    {
        if (len == sizeof(pack))
        {
            pack *myMsg = (pack *)payload;
            if (myMsg->TTL == 0 || findMyPacket(myMsg))
            {
                return msg;
            }
            else if (myMsg->src == myMsg->dest)
            {
                dbg(GENERAL_CHANNEL, "Message: %s\n", msg);
            }
            else if (TOS_NODE_ID == myMsg->src)
            {   
                if(myMsg->protocol == PROTOCOL_PING){
                    route routeDest;
                    dbg(GENERAL_CHANNEL, "PING-REPLY EVENT \n");

                    checkPackets(myMsg);
                
                    if(call routingTable.contains(myMsg -> src)){

                        routeDest = call routingTable.get(myMsg->dest); // ---
                        dbg(NEIGHBOR_CHANNEL, "To get to:%d, send through:%d\n", myMsg->dest, routeDest.nextHop); // ---
                        makePack(&sendPackage, routeDest.nextHop, myMsg->dest, MAX_TTL, PROTOCOL_PING, myMsg->seq, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));
                        call InternalSender.send(sendPackage, routeDest.nextHop);                    
                    }
                    else{
                    
                        dbg(NEIGHBOR_CHANNEL, "Couldn't find the routing table for: %d so flooding\n",TOS_NODE_ID);
                        makePack(&sendPackage, myMsg->dest, myMsg->src, myMsg->TTL-1, PROTOCOL_PINGREPLY, myMsg->seq, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));
                        call InternalSender.send(sendPackage, AM_BROADCAST_ADDR);
                    
                    }
                    
                    return msg;

                }else if(myMsg->protocol == PROTOCOL_PINGREPLY){

                    dbg(FLOODING_CHANNEL, "Received a Ping Reply from %d\n", myMsg->src);
                
                }else if(myMsg->protocol == PROTOCOL_FLOODING){

                    dbg(FLOODING_CHANNEL, "Flooding from %d\n", myMsg->src);
                    makePack(&sendPackage, myMsg->src, AM_BROADCAST_ADDR, myMsg->TTL - 1, PROTOCOL_FLOODING, myMsg->seq, (uint8_t *)myMsg->payload, sizeof(myMsg->payload));
                        
                    call InternalSender.send(sendPackage, AM_BROADCAST_ADDR);
                }

                return msg;
            }
            else if (myMsg->dest == AM_BROADCAST_ADDR)
            {
                if (myMsg->protocol == PROTOCOL_LINKSTATE)
                {
                    uint16_t i, j = 0;
                    uint16_t k = 0;
                    bool enterdata = TRUE;

                    for (i = 0; i < myMsg->seq; i++)
                    {
                        for (j = 0; j < call lspLinkList.size(); j++)
                        {
                            lspLink lspacket = call lspLinkList.get(j);
                            if (lspacket.src == myMsg->src && lspacket.neighbor == myMsg->payload[i])
                            {
                                enterdata = FALSE;
                            }
                        }
                    }
                    if (enterdata)
                    {
                        for (k = 0; k < myMsg->seq; k++)
                        {
                            lspL.neighbor = myMsg->payload[k];
                            lspL.cost = 1;
                            lspL.src = myMsg->src;
                            call lspLinkList.pushback(lspL);
                            //dbg(COMMAND_CHANNEL, "PushBack LSP Link neighbor: %d src: %d\n", lspL.neighbor, myMsg->src);
                        }
                        makePack(&sendPackage, myMsg->src, AM_BROADCAST_ADDR, myMsg->TTL - 1, 2, myMsg->seq, (uint8_t*) myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
                        call InternalSender.send(sendPackage, AM_BROADCAST_ADDR);
                    }
                    else
                    {
                        //dbg(COMMAND_CHANNEL, "LSP already exists for %d\n", TOS_NODE_ID);
                    }
                }
                //Handle neighbor discovery packets here
                if (myMsg->protocol == PROTOCOL_PING)
                {
                    makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, myMsg->TTL - 1, PROTOCOL_PINGREPLY, sequenceN, (uint8_t*) myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
                    //Check TOS_NODE_ID and destination
                    call InternalSender.send(sendPackage, myMsg->src);
                }
                //neighbor ping reply
                if (myMsg->protocol == PROTOCOL_PINGREPLY)
                {   
                    call NeighborDiscovery.neighborReceived(myMsg);
                }
                if (myMsg->protocol == PROTOCOL_FLOODING)
                {
                    if( myMsg->seq != call NodeCache.get(myMsg->src) || myMsg->seq >  call NodeCache.get(myMsg->src)){
                        uint16_t i = 0;
                        uint8_t llh[2];

                        //update cache with the new value
                        call NodeCache.insert(myMsg->src, myMsg->seq);
                        //dbg(FLOODING_CHANNEL,"Inserting sequence number %d in node %d \n",myMsg->seq,myMsg->src);

                        //forward the message
                        for (i = 0; i < call neighborList.size(); i++)
                        {
                            pack neighborFlood = call neighborList.get(i);
                            //link llayer header src, dest
                            //do not send to flood source
                            
                            if(myMsg->src !=  neighborFlood.src){
                            
                            myMsg->payload[0] = TOS_NODE_ID;
                            myMsg->payload[1] = neighborFlood.src;

                            makePack(&sendPackage, myMsg->src, neighborFlood.src, myMsg->TTL - 1, PROTOCOL_FLOODING, myMsg->seq, (uint8_t *)llh, sizeof(llh));
                             call InternalSender.send(sendPackage, neighborFlood.src);
                            
                            }
                            
                        }
                    }else{
                        //dbg(FLOODING_CHANNEL,"In the Cache Already\n");
                    }
                    
                }
                //call lsrTimer.startPeriodic(80000);
                return msg;
            }
            else
            {
                checkPackets(myMsg);

                //dbg(NEIGHBOR_CHANNEL, " Reject Couldn't find the routing table for:%d so flooding\n", TOS_NODE_ID);

                makePack(&sendPackage, myMsg->src, myMsg->dest, myMsg->TTL - 1, PROTOCOL_PING, myMsg->seq, (uint8_t *)myMsg->payload, sizeof(myMsg->payload));
                call InternalSender.send(sendPackage, AM_BROADCAST_ADDR);
                return msg;
            }
            dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
            return msg;
        }else{
            dbg(FLOODING_CHANNEL, "\n\n\n\n\n\n\n\n\n\n?\n\n\n\n\n\n");
        }
    }

    bool findMyPacket(pack * Package)
    {
        uint16_t size = call packetList.size();
        uint16_t i = 0;
        pack checkIfExists;
        for (i = 0; i < size; i++)
        {
            checkIfExists = call packetList.get(i);
            if (checkIfExists.src == Package->src && checkIfExists.dest == Package->dest && checkIfExists.seq == Package->seq)
            {
                return TRUE;
            }
        }
        return FALSE;
    }

    void checkPackets(pack * myMsg)
    {
        call packetList.pushback(*myMsg);
    }

    void makePack(pack * Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t * payload, uint8_t length)
    {
        Package->src = src;
        Package->dest = dest;
        Package->TTL = TTL;
        Package->seq = seq;
        Package->protocol = protocol;
        memcpy(Package->payload, payload, length);
    }

    bool isvalueinarray(uint8_t val, uint8_t * arr, uint8_t size)
    {
        int i;
        for (i = 0; i < size; i++)
        {
        if (arr[i] == val)
            return TRUE;
        }
        return FALSE;
    }

}
