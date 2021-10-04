interface NeighborDiscovery
{
	command void start();
	command void print();
	command void neighborReceived(pack * thisPack);
}