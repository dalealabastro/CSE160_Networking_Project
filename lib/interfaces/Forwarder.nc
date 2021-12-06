interface Forwarder{

	command error_t sending(pack msg, uint16_t dest);
}
