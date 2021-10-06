#include "../../includes/channels.h"
#include "../../includes/CommandMsg.h"


module FloodingP
{

    provides interface SimpleSend as FloodSender;
    provides interface Flooding;

    // Internal
    uses interface SimpleSend as insideSender;
    uses interface Receive as insideReciever;
    uses interface List<pack> as packetList;
    uses interface NeighborDiscovery;
    uses interface List<pack> as neighborList;
    uses interface Hashmap<int> as NodeCache;
}

implementation
{
    uint16_t sequenceN = 0;
    
    pack sendPackage;

    bool findMyPacket(pack * Package);

    void checkPackets(pack * myMsg);

    void makePack(pack * Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t * payload, uint8_t length);

    bool isvalueinarray(uint8_t val, uint8_t * arr, uint8_t size);

    command error_t FloodSender.send(pack msg, uint16_t dest)
    {
        msg.src = TOS_NODE_ID; //Src flood
        msg.protocol = PROTOCOL_PING;
        msg.seq = sequenceN + 1; //Inc of seq. #
        msg.TTL = MAX_TTL; //Max time to live
         if(call insideSender.send(msg, AM_BROADCAST_ADDR) != SUCCESS){
            return FAIL;
         }else{
            dbg(FLOODING_CHANNEL, "Node: %d FloodingNetwork: %s\n",msg.src, msg.payload);
            return SUCCESS;
         }
    }

    command void Flooding.flood(uint16_t source){
        pack neighborFlood;
        uint8_t floodingPayload[2] = {TOS_NODE_ID,0};

        makePack(&neighborFlood, source, AM_BROADCAST_ADDR, MAX_TTL, PROTOCOL_FLOODING, sequenceN+1,  floodingPayload, PACKET_MAX_PAYLOAD_SIZE);

        call insideSender.send(neighborFlood, AM_BROADCAST_ADDR);

    }
 
    event message_t *insideReciever.receive(message_t * msg, void *payload, uint8_t len)
    {
        if (len == sizeof(pack)) //check for dupe
        {
            pack *myMsg = (pack *)payload;

            //if we've seen the package or TTL has reached 0 drop packet
            if (myMsg->TTL == 0 || findMyPacket(myMsg))
            {
                return msg; //If msg dest
            }
            else if (TOS_NODE_ID == myMsg->dest) //If dest found
            { 
                
                if(myMsg->protocol == PROTOCOL_PING){
                    dbg(FLOODING_CHANNEL, "PING-REPLY EVENT \n");

                    checkPackets(myMsg);

                }else if(myMsg->protocol == PROTOCOL_PINGREPLY){

                    dbg(FLOODING_CHANNEL, "Received a Ping Reply from %d\n", myMsg->src);
                
                }else if(myMsg->protocol == PROTOCOL_FLOODING){

                    dbg(FLOODING_CHANNEL, "Flooding from %d\n", myMsg->src);
                    makePack(&sendPackage, myMsg->src, AM_BROADCAST_ADDR, myMsg->TTL - 1, PROTOCOL_FLOODING, myMsg->seq, (uint8_t *)myMsg->payload, sizeof(myMsg->payload));
                        
                    call insideSender.send(sendPackage, AM_BROADCAST_ADDR);
                }

                return msg; //only if broadcast msg
            }
            else if (myMsg->dest == AM_BROADCAST_ADDR)
            {
                //Handle neighbor discovery packets here
                if (myMsg->protocol == PROTOCOL_PING)
                {
                    makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, myMsg->TTL - 1, PROTOCOL_PINGREPLY, sequenceN, (uint8_t*) myMsg->payload, PACKET_MAX_PAYLOAD_SIZE);
                    //Check TOS_NODE_ID and destination
                    call insideSender.send(sendPackage, myMsg->src);
                }
                //neighbor ping reply
                if (myMsg->protocol == PROTOCOL_PINGREPLY)
                {
                    dbg(GENERAL_CHANNEL, "Packet recieved check\n");
                    
                    call NeighborDiscovery.neighborReceived(myMsg);
                }
                if (myMsg->protocol == PROTOCOL_FLOODING)
                {
                    //if not seen before cache
                    if( myMsg->seq != call NodeCache.get(myMsg->src) || myMsg->seq >  call NodeCache.get(myMsg->src)){
                        uint16_t i = 0;
                        uint8_t llh[2];

                        //update cache with the new value
                        call NodeCache.insert(myMsg->src, myMsg->seq);

                        //forward the message
                        for (i = 0; i < call neighborList.size(); i++)
                        {
                            pack neighborFlood = call neighborList.get(i);
                            
                            if(myMsg->src !=  neighborFlood.src){ //Don't send
                            
                            myMsg->payload[0] = TOS_NODE_ID;
                            myMsg->payload[1] = neighborFlood.src;

                            makePack(&sendPackage, myMsg->src, neighborFlood.src, myMsg->TTL - 1, PROTOCOL_FLOODING, myMsg->seq, (uint8_t *)llh, sizeof(llh));
                            //TOS_NODE_ID + dest check
                
                             call insideSender.send(sendPackage, neighborFlood.src);
                            
                            }
                            
                        }
                    }else{
                        dbg(FLOODING_CHANNEL,"In the Cache Already\n");
                    }
                    
                }
                return msg;
            }
            else
            {
                checkPackets(myMsg);

                makePack(&sendPackage, myMsg->src, myMsg->dest, myMsg->TTL - 1, PROTOCOL_PING, myMsg->seq, (uint8_t *)myMsg->payload, sizeof(myMsg->payload));
                call insideSender.send(sendPackage, AM_BROADCAST_ADDR);
                return msg;
            }
            dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
            return msg;
        }else{
            dbg(FLOODING_CHANNEL, "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n");
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

    bool isvalueinarray(uint8_t val, uint8_t * arr, uint8_t size)//?????????????????????????????????????????
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