//File created (not original)

#include "../../includes/sendInfo.h"

generic module neighbor_discoveryP()
{
    provides interface neighbor_discovery;                    
}

implementation
{
    int true = 1;
    int false = 0;
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
            for(i = 0; i < 4 - 1; i++)
            {

                flood[0] = src_node + 1;
                dbg(GENERAL_CHANNEL, "Node Inserted: %i\n", flood[i]);
            }

            done[search[0] - 1] = search[0];
            dbg(GENERAL_CHANNEL, "Node Done: %i\n", search[0]);
            for(i = 0; i < 19-1; i++)
            {
				search[i] = search[i+1];
			}
        }
    }

    command int neighbor_discovery.Flood_empty()
    {
        dbg(GENERAL_CHANNEL, "Flood Check\n");
        for(i = 0; i < size; i++)
        {
            if(flood[i] != 0)
            {
                return true;
            }
        }

        return false;
    }

    //Returns node that is viable for flooding
    command uint16_t neighbor_discovery.get_Flood()
    {
        dbg(GENERAL_CHANNEL, "Getting Node For Flooding\n");
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
        dbg(GENERAL_CHANNEL, "Checking Node Has Been Flooded\n");
        for(i = 0; i < size; i++)
        {
            if(search[i] == node)
            {
                return false;
            }
            else if(done[i] == node)
            {
                return false;
            }
        }

        return true;
    }

    // command void neighbor_discovery.neighborFlood()
    // {
    //     while(flood[0] != 0)
    //     {
    //         // Checks if node in line to flooded already flooded to avoid backtracking
    //         if(flood[0] == done[flood[0] - 1])
    //         {
    //             for(i = 0; i < 19-1; i++)
    //             {
	// 			    flood[i] = flood[i+1];
	// 		    }
    //             continue;
    //         }

    //         // call Flood Function
            
    //         //Checks if there are anymore nodes to flood or target node has been reached
    //         if(flood[0] == 0 || flood[0] == target_node)
    //         {
    //             break;
    //         }

    //         for(i = 0; i < 19-1; i++)
    //         {
    //             //Moves flood line up by one for next node to be flooded
	// 			flood[i] = flood[i+1];
	// 		}
    //     }
    //}
}