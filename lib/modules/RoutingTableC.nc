#define AM_ROUTING 63

configuration RoutingTableC{
	provides interface RoutingTable;
	//provides interface Receive;
}

implementation{
	components RoutingTableP;
	components new TimerMilliC() as PeriodicTimer;
	components new SimpleSendC(AM_ROUTING);
	components new AMReceiverC(AM_ROUTING);

	components NeighborDiscoveryC;
	RoutingTableP.NeighborDiscovery -> NeighborDiscoveryC;
	
	RoutingTable = RoutingTableP.RoutingTable;
	//Receive = RoutingTableP.RoutingTableReceive;

	RoutingTableP.Sender -> SimpleSendC;
	RoutingTableP.Receive -> AMReceiverC;
	RoutingTableP.PeriodicTimer -> PeriodicTimer;

}
