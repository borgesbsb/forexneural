import socket


class Connection:
    def __init__(self):
        self.host = '127.0.0.1' 
        self.port = 8083
        self.data_payload = 1000
    
    def listen(self):
         self.sock = socket.socket(socket.AF_INET,  socket.SOCK_STREAM)
         self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
         self.server_address = (self.host, self.port)
         self.sock.bind(self.server_address)
         
    def forecasts(self,prediction):
        while True:
            print("Servidor Pronto, aguardando conexões")
            self.sock.listen(5)
            self.client, self.address = self.sock.accept()
            print("Cliente conectado!, Servidor aguardando dados para previsao")
            clientconnect = True
            while clientconnect:
                valores = []
                data = self.client.recv(self.data_payload).decode('utf-8')
                if data:
                    print("Dados Recebidos = "+data)
                    predict = prediction.makepredictions(data)
                    print("Dado Previsto = "+predict)
                    self.client.sendall(bytes(predict, "utf-8"))
                else:
                    print("Cliente desconectado")
                    clientconnect = False