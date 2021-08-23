import socket
import tensorflow as tf
from tensorflow.keras.models import load_model
import numpy as np
import pandas as pd
from sklearn.preprocessing import MinMaxScaler
import joblib as jl


class Connection:
    def __init__(self):
        self.host = '127.0.0.1' 
        self.port = 8082
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
    
###########################################Classe de Prfedição#######################################
class Predictions:   
    def __init__(self,namemodel, timestamp, features ):
        self.model = load_model('../redeneural/'+namemodel)
        self.scaler_X  = MinMaxScaler()
        self.scaler_Y  = MinMaxScaler()
        self.timestamp = timestamp
        self.features  = features
        self.predict = None
        self.setScaler()

    def setScaler(self):
        self.scaler_X = jl.load('../redeneural/scaler_x.pkl')
        self.scaler_y = jl.load('../redeneural/scaler_y.pkl')

    def makepredictions(self,values):
        values = values.split(",")
        x_values = []
        for i in values:
            x_values.append(float(i))
        x_values = np.array(x_values)
        x_values = np.reshape(x_values,(2,13))
        x_values = self.scaler_X.transform(x_values)
        x_values = np.reshape(x_values,(1, 2, 13))
        self.predict =  self.model.predict(x_values)
        prevision = self.scaler_y.inverse_transform(self.predict)
        return  str(prevision[0][0])

    def getPrediction(self):
        if (self.predict):
            return self.predict
        else:
            return "Previsao nao encontrada" 
        
    
##############################################################ALgoritmo################################################
print("Carregando os Módulos, aguarde! Tenha Paciência")
timestamp = 2
features = ['open1','max1','min1','open2','max2','min2','open3','max3','min3','open4','max4','min4','close4']
namemodel1 = 'LSTM_EURUSD-15M-1H'
prediction = Predictions(namemodel1, timestamp, features)
brain = Connection()
brain.listen()
brain.forecasts(prediction)
