import socket
from tensorflow import keras


class socketserver:
    def __init__(self, address = '', port = 9090):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.address = address
        self.port = port
        self.sock.bind((self.address, self.port))
        self.cummdata = ''
        
    def recvmsg(self):
        self.sock.listen(1)
        self.conn, self.addr = self.sock.accept()
        print('connected to', self.addr)
        self.cummdata = ''

        while True:
            data = self.conn.recv(10000)
            self.cummdata+=data.decode("utf-8")
                        
            if not data:
                break
            msgsrv = 'Mensagem vindo do servidor'    
            self.conn.send(msgsrv.decode('utf-8'))
            return self.cummdata
            
    def __del__(self):
        self.sock.close()

def calcregr(msg = ''):
    model = keras.models.load_model('LSTM')
    
    
    return str("Teste")



serv = socketserver('127.0.0.1', 9090)
while True:  
    msg = serv.recvmsg()
    



