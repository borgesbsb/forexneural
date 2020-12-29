import socket
import tensorflow as tf


def server(host = '127.0.0.1', port=8082):
    data_payload = 1000 #The maximum amount of data to be received at once
    # Create a TCP socket
    sock = socket.socket(socket.AF_INET,  socket.SOCK_STREAM)
    # Enable reuse address/port 
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    # Bind the socket to the port
    server_address = (host, port)
    print ("Starting up echo server  on %s port %s" % server_address)
    sock.bind(server_address)
    # Listen to clients, argument specifies the max no. of queued connections
    sock.listen(5) 
    client, address = sock.accept()
    #Carreando o modelo neural
    df = pd.read_csv('EURUSD.csv', sep=';', header=0)
    model = tf.keras.models.load_model('LSTM')

    try:
        while True: 
            print ("Aguardando dados")
            valores = []
            data = client.recv(data_payload).decode('UTF-8') 
            if data:
                valores = data.split(",")
                predict = predicao(valores)
                client.sendall(data.encode('utf-8'))
    except KeyboardInterrupt:
        print("Encerrando Servidor de Previsões")
        pass            

def predicao(valores):
    



server()

