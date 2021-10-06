interface neighbor_discovery
{
  //command void neighbor_discovery.linkedListGenerator()
  command int neighborSearch(int src_node);
  command int Flood_empty();
  command uint16_t get_Flood();
  command int checkFlood(int node);
}