generic module floodingP()
{
    provides interface flooding;
    uses interface neighbor_discovery;                
}

implementation
{
    int i = 0;
    uint16_t src_node;
    int flood[19];

    command void flooding.Flood()
    {
        do
        {
            // Take src node and sets it neighbors
            src_node = 1
            call neighbor_discovery.neighborSearch(src_node);

            while(call neighbor_discovery.Flood_empty() == 1)
            {
                flood[i] = call neighbor_discovery.get_Flood();
                i++;
            }
            //Loops through all neighbor nodes in line for flooding
            for(i = 0; i < 19; i++)
            {
                if(flood[i] == 0)
                {
                    break; //If flood array is zero, that means no more nodes to flood and loop can end
                }
                //Sends node to function to be flooded by package
                call flooding.flood(flood[i]);

                //Clears node from array
                flood[i] = 0;

            }
        }while(call neighbor_discovery.checkFlood(node_forCheck) == 1);
    }

    command void flooding.flood()
    {
        //write code block
    }
}