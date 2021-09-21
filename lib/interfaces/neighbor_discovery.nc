interface neighbor_discovery
{
  //command void neighbor_discovery.linkedListGenerator()
  command void neighborSearch(uint16_t src_node);
  command bool Flood_empty();
  command uint16_t get_Flood();
  command bool checkFlood(uint16_t node);
}