import socket
import tensorflow as tf
from tensorflow.keras.models import load_model
import numpy as np
import pandas as pd
from sklearn.preprocessing import MinMaxScaler
#Refatorar o codigo assim que possivel

def server(host = '127.0.0.1', port=8082):
    model = tf.keras.models.load_model('LSTM',compile = False)
    sc = MinMaxScaler()
    sc1 = MinMaxScaler()
    df = pd.read_csv('EURUSD.csv', sep=';', header=0)
    
    df = df.iloc[ 0:int(len(df)*0.8),2:5]
    df_y = df.copy()
    
    df = sc.fit_transform(df)
    df_y = sc1.fit_transform(df_y.iloc[:,2].values.reshape(-1,1))
    

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
    

    try:
        while True: 
            valores = []
            data = client.recv(data_payload).decode('utf-8') 
            if data:
                valores = data.split(",")
                predict = predicao(valores,sc,sc1,model)
                client.sendall(predict.encode('utf-8'))
    except KeyboardInterrupt:
        print("Encerrando Servidor de Previsões")
        pass            

def predicao(valores,sc,sc1,model):
    x_test = []
    for i in valores:
        x_test.append(float(i))
    x_test = np.array(x_test)
    x_test = np.reshape(x_test,(2,3))
    x_test = sc.transform(x_test)
    x_test = np.reshape(x_test,(1,2,3))
    predict = model.predict(x_test)
    predict =  sc1.inverse_transform(predict)
    print(str(valores))
    print(str(predict))
    return str(predict[0][0])

server()