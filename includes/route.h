#ifndef ROUTE_H
#define ROUTE_H

#define MAX_ROUTES 128;
//#define MAX_TTL 120;

typedef nx_struct route{
	nx_uint16_t dest;
	nx_uint8_t nextHop;
	nx_uint8_t cost;
}route;

#endif