//File created (not original)

#include "../../includes/sendInfo.h"
#include "../../includes/command.h"
#include "../../includes/channels.h"
#include "../../includes/commandmsg.h"
#include "../../includes/packet.h"
#include <Timer.h>

generic module neighbor_discoveryP()
{
    provides interface neighbor_discovery;
    //List interface and declare it. INclude appropriate headers. 
    uses interface Simplesend;
    uses interface Receive;
    uses interface Hashmap;
    uses interface Timer;
}

//To access the packets stuff: In beginning of each module in implement, we need makepack 
//void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

//Use simplesend, recieve, packet, am_packet, list or hashmap, and Timer to send periodically pings to nodes.
//Headers: for neighbor disc: use built in timer in tiny os: Timer.h. Use command.h, packet.h, commandmsg.h, send info .h, and channels.h

//Use protocol ping and ping reply. Send ping to each node and get ping reply back
//How to send ping to neighbor: Use list and save all the nodes into it. Use output from list to use for said purpose.

//How to access topography: Access to topography through commandhandler and commandmsg automatically. List and hashmap do it automatically, inspect those codes and study it
//line by line. Include them as interface or header at the beginning of code. Use them thru code.

//We are just calling functions, wiring, and linking them together and print output. Read code and learn from it.

//How is it automatically getting access: There are some functions (get from listC.nc, list.get,size,) through neighbor discovery.
//Get the info and use that info in the code. commandhandler,commandmsg, handler. Wire in list (list.get)? Yes. Command handler declared in node.nc so don't need to change.
//All you need to do is declare list or hashmap and call some function of it during module.

//How to put size: Call it and during code and during debug, if topography is bigger than value do this, if not, do that.

implementation
{
    int target_node;
    int flood_node;
    int size = 19;
    int i;
    int j;
    int search[19];
    int flood[19];
    int done[19];

    command int neighbor_discovery.neighborSearch(int src_node) // Testing
    {

        if(search[0] == 0)
        {
            search[0] = src_node;
        }

        // Moves nodes that recived message and neighbors of node found into done-array
        while(search[0] != 0)
        {
            // Finds Neighbors and inserts into flood-array for flooding
            for(i = 0; i < 4; i++)
            {

                flood[i] = i + 1;
                dbg(NEIGHBOR_CHANNEL, "Node Inserted: %i\n", flood[i]);
            }

            done[search[0] - 1] = search[0];
            dbg(NEIGHBOR_CHANNEL, "Node Done: %i\n", search[0]);
            for(i = 0; i < 19-1; i++)
            {
				search[i] = search[i+1];
			}
        }
    }

    command int neighbor_discovery.Flood_empty()
    {
        dbg(NEIGHBOR_CHANNEL, "Flood Check\n");
        for(i = 0; i < size; i++)
        {
            if(flood[i] != 0)
            {
                return SUCCESS;
            }
        }

        return FAIL;
    }

    //Returns node that is viable for flooding
    command uint16_t neighbor_discovery.get_Flood()
    {
        dbg(NEIGHBOR_CHANNEL, "Getting Node For Flooding\n");
        //Checks for any node that is already flooded and remove from the queue
        for(i = 0; i < size; i++)
        {
            if(flood[i] == 0)
            {
                break;
            }

            if(flood[i] == done[flood[i] - 1])
            {
                for(j = i; j < size - 1; j++)
                {
                    flood[j] = flood[j + 1];
                }
                i = 0;
            }
        }

        flood_node = flood[0];

        //Removes node that will be returned and move all other nodes up the queue
        for(i = 0; i < size-1; i++)
        {
            flood[i] = flood[i+1];
        }

        //Moves node that will be returned into queue for neighbor search
        for(i = 0; i < size-1; i++)
        {
            //If node exists at current location move to the next spot
            if(search[i] > 0)
            {
                continue;
            }
            else
            {
                search[i] = flood_node;
                break;
            }
        }

        return flood_node;

    }

    //Checks if the node that is inputted has already been flooded
    command int neighbor_discovery.checkFlood(int node)
    {
        dbg(NEIGHBOR_CHANNEL, "Checking Node Has Been Flooded\n");
        for(i = 0; i < size; i++)
        {
            if(search[i] == node)
            {
                return FAIL;
            }
            else if(done[i] == node)
            {
                return FAIL;
            }
        }

        return SUCCESS;
    }
}