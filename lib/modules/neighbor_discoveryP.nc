//File created (not original)

#include "../../includes/sendInfo.h"

generic module neighbor_discoveryP()
{
    provides interface neighbor_discovery;
    uses interface List<uint16_t*>;                    
}

implementation
{
    int target_node = 0;
    int search[19];
    int flood[19];
    int done[19];

    command void neighbor_discovery.neighborSearch() // Testing
    {
        int i;
        int j = 0;

        if(search[0] == 0)
        {
            search[0] = 1;
        }
        //call List.pushback(19);
        dbg(GENERAL_CHANNEL, "List Trial: %d\n", &(call List.front));

        // Moves nodes that recived message and neighbors of node found into done-array
        while(search[j] != 0)
        {
            dbg(GENERAL_CHANNEL, "Current Node in Line: %i\n", search[0]);
            // Finds Neighbors and inserts into flood-array for flooding
            for(i = 0; i < 4 - 1; i++)
            {

                flood[i] = i + 1;
                dbg(GENERAL_CHANNEL, "Node Inserted: %i\n", flood[i]);
            }

            if(search[j] == 0)
            {
                break;
            }

            done[search[j] - 1] = search[j];
            dbg(GENERAL_CHANNEL, "Node Done: %i\n", search[j]);
            for(i = 0; i < 19-1; i++)
            {
				search[i] = search[i+1];
			}
        }
    }

    command void neighbor_discovery.neighborFlood()
    {
        int i;
        while(flood[0] != 0)
        {
            // Checks if node in line to flooded already flooded to avoid backtracking
            if(flood[0] == done[flood[0] - 1])
            {
                for(i = 0; i < 19-1; i++)
                {
				    flood[i] = flood[i+1];
			    }
                continue;
            }

            // call Flood Function
            
            //Checks if there are anymore nodes to flood or target node has been reached
            if(flood[0] == 0 || flood[0] == target_node)
            {
                break;
            }

            //Adds node that has been flooded to search-array for neighbor search
            for(i = 0; i < 19-1; i++)
            {
                if(search[i] > 0)
                {
                    continue;
                }
                else
                {
                    search[i] = flood[0];
                    dbg(GENERAL_CHANNEL, "Node Flooded: %i\n", flood[0]);
                    break;
                }
            }

            for(i = 0; i < 19-1; i++)
            {
                //Moves flood line up by one for next node to be flooded
				flood[i] = flood[i+1];
			}
        }
    }
}









    //Create function that creates linked list (state variable that we can access)
    //Said function ^ also calls another function that will search for neighbors for each node and returns a list
    //Flood neighbor depending on which origin node we are searchly at.
    //Call another function which will store neighbors that sent the message in another list to make sure no message is sent backwards up the pipeline.