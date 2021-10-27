#ifndef LSP_H
#define LSP_H

enum{

	MAX_LSP = 25

};

typedef nx_struct lspLink{
	nx_uint16_t neighbor;
	nx_uint8_t cost;
	nx_uint8_t src;
}lspLink;

#endif
