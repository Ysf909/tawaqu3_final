class BrokerService {
  bool mt5Connected = true;

  void connectMT5() {
    mt5Connected = true;
  }

  void disconnectMT5() {
    mt5Connected = false;
  }
}
