generic configuration floodingC()
{
    provides interface flooding;               
}

implementation
{
    //Add
    components new floodingP();
    flooding = floodingP.flooding;

    components new neighbor_discoveryC();
    floodingP.neighbor_discovery -> neighbor_discoveryC;
}