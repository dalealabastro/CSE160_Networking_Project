//interface to interact with other modules
//start the negihbor discovery
//print the list
//receive message
interface NeighborDiscovery
{
	command void start();
	command void print();
	command void neighborReceived(pack * thisPack);
	
}