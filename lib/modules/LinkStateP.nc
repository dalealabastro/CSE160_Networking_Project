#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/route.h"

#define MAXNODES 20

module LinkStateP{

  // provides intefaces
  provides interface LinkState;

  /// uses interface
  uses interface Timer<TMilli> as lsrTimer;
  uses interface Timer<TMilli> as dijkstraTimer;
  uses interface SimpleSend as LspSender;
  uses interface List<lspLink> as lspLinkList;
  uses interface List<pack> as neighborList;
  uses interface Hashmap<route> as routingTable;
  uses interface Random as Random;
}

implementation{
  pack sendPackage;
  lspLink lspL;
  uint16_t lspAge = 0;
  bool isvalueinarray(uint8_t val, uint8_t *arr, uint8_t size);
  int makeGraph();

  void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

  command void LinkState.start(){
    dbg(ROUTING_CHANNEL, "Link-State Routing Booted\n");
    call lsrTimer.startPeriodic(80000 + (uint16_t)((call Random.rand16())%10000));
    call dijkstraTimer.startOneShot(80000 + (uint16_t)((call Random.rand16())%10000));
  }

  command void LinkState.printRoutingTable()
  {
    route PriRoute;
    int i = 0;
    for(i=1; i <= call routingTable.size(); i++){
      PriRoute = call routingTable.get(i);
      dbg(ROUTING_CHANNEL, "Dest: %d \t Next Hop: %d Cost: %d\n", PriRoute.dest,  PriRoute.nextHop, PriRoute.cost);
    }
    call LinkState.print();
  }

  command void LinkState.print()
  {

    if(call lspLinkList.size() > 0)
    {
      uint16_t lspLinkListSize = call lspLinkList.size();
      uint16_t i = 0;

      for(i = 0; i < lspLinkListSize; i++)
      {
        lspLink lspackets =  call lspLinkList.get(i);
        dbg(ROUTING_CHANNEL,"Source:%d\tNeighbor:%d\tcost:%d\n",lspackets.src,lspackets.neighbor,lspackets.cost);
      }
    }
    else{
      //dbg(COMMAND_CHANNEL, "***0 LSP of node  %d!\n",TOS_NODE_ID);
    }

  }

  event void lsrTimer.fired()
  {
    uint16_t neighborListSize = call neighborList.size();
    uint16_t lspListSize = call lspLinkList.size();

    uint8_t neighborArr[neighborListSize];
    uint16_t i,j = 0;
    bool enterdata = TRUE;
    

    //dbg(GENERAL_CHANNEL, "NEIGHBOR LIST SIZE: %hu\n", neighborListSize);

    //if the link state packet is age 5 then clea all its contents
    if(lspAge==10){
     
      lspAge = 0;
      for(i = 0; i < lspListSize; i++) {
        call lspLinkList.popfront();
      }
    }

    //update lsp list
    for(i = 0; i < neighborListSize; i++)
    {
      pack neighborNode = call neighborList.get(i);
      for(j = 0; j < lspListSize; j++)
      {
        lspLink lspackets = call lspLinkList.get(j);
        //if we already have any of the packets in this list dont edit the lsp list
        if(lspackets.src == TOS_NODE_ID && lspackets.neighbor==neighborNode.src){
          enterdata = FALSE;
        }
      }
      //if new data is present update lsp list
      if (enterdata){
        lspL.neighbor = neighborNode.src;
        lspL.cost = 1;
        lspL.src = TOS_NODE_ID;
        //update lspl
        call lspLinkList.pushback(lspL);
        //update sshortest past 
	      call dijkstraTimer.startOneShot(80000 + (uint16_t)((call Random.rand16())%10000));
      }
      
      if(!isvalueinarray(neighborNode.src,neighborArr,neighborListSize)){
        neighborArr[i] = neighborNode.src;
        //dbg(ROUTING_CHANNEL,"**Adding %d in node %d\n",neighborNode.src,TOS_NODE_ID);
        }else{
        //dbg(ROUTING_CHANNEL,"**Node %d already in %d\n",neighborNode.src,TOS_NODE_ID);
        }
      }
      //send the link state packe back with the new neighbor list in the payload
      makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, MAX_TTL, 2, neighborListSize, (uint8_t *) neighborArr, neighborListSize);
      

      call LspSender.send(sendPackage, AM_BROADCAST_ADDR);
      //dbg(ROUTING_CHANNEL, "Sending LSPs\n");
    }


    bool isvalueinarray(uint8_t val, uint8_t *arr, uint8_t size){
      int i;
      for (i=0; i < size; i++) {
        if (arr[i] == val)
        return TRUE;
      }
      return FALSE;
    }

    void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
    }

    event void dijkstraTimer.fired()
      {
        route newRoute;
        int nodesize[MAXNODES];
        int size = call lspLinkList.size();
        int maxNode = MAXNODES;
        int i,j,next_hop, cost[maxNode][maxNode], distance[maxNode], pred_list[maxNode];
        int visited[maxNode], node_count, mindistance, nextnode;
     
        int start_node = TOS_NODE_ID;
        bool adjMatrix[maxNode][maxNode];

        //dbg(GENERAL_CHANNEL, "Link list size: %d\n", size);
        for(i=0;i<maxNode;i++)
        {
          for(j=0;j<maxNode;j++){
            adjMatrix[i][j] = FALSE;
          }
        }

        for(i=0; i<size;i++){
          lspLink stuff = call lspLinkList.get(i);
          adjMatrix[stuff.src][stuff.neighbor] = TRUE;
        }

        for(i=0;i<maxNode;i++)
        {
          for(j=0;j<maxNode;j++)
          {
            if (adjMatrix[i][j] == 0)
           	cost[i][j] = 9999;
            else
            	cost[i][j] = adjMatrix[i][j];
          }
        }

        //initialize pred[],distance[] and visited[]
        for(i = 0; i < maxNode; i++)
        {
          distance[i] = cost[start_node][i];
          //dbg(GENERAL_CHANNEL, "Starting distance: %d\n", distance[i]); //=========================================
          pred_list[i] = start_node;
          visited[i] = 0;
        }


        distance[start_node] = 0;
        visited[start_node] = 1;
        node_count = 1;

        while (node_count <= maxNode - 1)
        {
          //dbg(GENERAL_CHANNEL, "Node Count: %d\n", node_count); //==========================================
          mindistance = 9999;
          //nextnode gives the node at minimum distance
          for (i = 0; i < maxNode; i++)
          {
            dbg(GENERAL_CHANNEL, "I: %d Check Distance: %d Min Distance: %d\n", i, distance[i], mindistance); //===================================
            if (distance[i] <= mindistance && !visited[i])
            {
              dbg(GENERAL_CHANNEL, "CHANGE OCCURS FOR - MINDISTANCE = %d - NEXT NODE FROM %d TO %d\n", distance[i], nextnode, i); //===============
              mindistance = distance[i];
              nextnode = i;
            }
          }
          visited[nextnode] = 1;

          for(i = 0; i < maxNode; i++)
          {
            dbg(GENERAL_CHANNEL, "NODE: %d TO NODE %d NODE VISITED: %d\n", node_count, i, visited[i]); //=======================
          }
          //Checks to see if a better path through next node exists
          for (i = 0; i < maxNode; i++)
          {
            if (!visited[i])
            {
              if (mindistance + cost[nextnode][i] < distance[i])
              {
                distance[i] = mindistance + cost[nextnode][i];
                pred_list[i] = nextnode;
              }
            }
          }
          node_count++;
        }
      for (i = 0; i < maxNode; i++) 
      {
        next_hop = TOS_NODE_ID;
        dbg(GENERAL_CHANNEL, "Check One-Node %d Distance to Node: %d\n", i, distance[i]);
        if (distance[i] != 9999) 
        {
          dbg(GENERAL_CHANNEL, "Check Two-Node %d\n", i);
          if (i != start_node) 
          {
            dbg(GENERAL_CHANNEL, "Check Three-Node %d\n", i);
            j = i;
            do 
            {
              if (j!=start_node)
              {
                next_hop = j;
              }

              j = pred_list[j];
            } while (j != start_node);
          }
          else
          {
            dbg(GENERAL_CHANNEL, "Check Three.1-Node %d\n", i);
            next_hop = start_node;
          }
          
          if (next_hop != 0 )
          {
            dbg(GENERAL_CHANNEL, "NODE: %d\n", i);
            newRoute.dest = i;
            newRoute.nextHop = next_hop;
            newRoute.cost = distance[i];
            call routingTable.insert(i, newRoute);
          }
        }
      }

    }
  }