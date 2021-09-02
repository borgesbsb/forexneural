
best_neurons = 0
best_epochs  = 0
best_accuracy = 0
save_to_csv   = None
variables_saves = ['best_neurons','best_epochs','best_accuracy','loop_epochs' , 'neurons_i','epochs_i','variables_saves','save_to_csv','mes','ano', 'jl']
ano = 2021
mes = 8
best_neurons = 0
best_epochs  = 0
best_accuracy = 0
for neurons_i  in range(13,14):
    for epochs_i  in range(26,27):
        for loop_epochs in range(1,6):
            import warnings
            warnings.simplefilter(action='ignore', category=FutureWarning)
            import pandas as pd
            import numpy as np
            import matplotlib.pyplot as plt
            from tensorflow.keras.models import Sequential
            from tensorflow.keras.layers import Dense, LSTM, Dropout
            from sklearn.preprocessing import MinMaxScaler
            import joblib as jl



            class Processing:
                def __init__(self, currency, begining_training, end_training,begin_validate,end_validate, timestamp, features, target):
                    self.timestamp = timestamp
                    self.currency = currency
                    self.features  = features
                    self.begining_training = begining_training
                    self.end_training      = end_training
                    self.begin_validate    = begin_validate
                    self.end_validate      = end_validate
                    self.df  = self.importDataset()
                    self.x_train =     []
                    self.y_train =     []
                    self.x_test  =     []
                    self.y_test  =     []
                    self.x_validate =  []
                    self.y_validate =  []
                    self.scaler_x =    None
                    self.scaler_y =    None
                    self.target =      target
                    self.df_training = None
                    self.df_test =     None
                    self.df_validade = None
                    self.splitData()
            
                def importDataset(self):
                    parser = lambda x: pd.datetime.strptime(x, "%Y-%m-%d %H:%M:%S")
                    df = pd.read_csv( '../arquivos_de_coleta/'+self.currency+'.csv', sep=',', header=0, parse_dates=['time'],date_parser=parser) 
                    return df
            
                def selectInterval(self, start, end):
                    mask = (self.df['time'] > start) & (self.df['time'] <= end )
                    return self.df.loc[mask]
            
                def scalerDataset(self, dataset):
                    self.scaler_x = MinMaxScaler()
                    self.scaler_y = MinMaxScaler()
                    self.scaler_x.fit(dataset)
                    self.scaler_y.fit(self.df_training[[target]])
                    return self.scaler_x.transform(dataset)

                def processXY(self, dataframe):
                    length = len(dataframe)
                    x_data = []
                    y_data = []
                    for i in range(self.timestamp, length):
                        x_data.append( dataframe[i-self.timestamp:i,:])
                        #Target no fechamento
                        #y_data.append( dataframe[i,self.features.index(target)])
                        # Target no ponto medio
                        # maximum = dataframe[i].max()
                        # minimum = dataframe[i].min()
                        # point_mean = (maximum+minimum)/2
                        # y_data.append(point_mean)
                        # Target do maximo e minimo
                        maximum = dataframe[i,self.features.index('max4')]
                        minimum = dataframe[i,self.features.index('min4')]
                        close   = dataframe[i,self.features.index('close4')]
                        point_men = (maximum+minimum)/2
                        if point_men > close:
                            y_data.append( dataframe[i,self.features.index('max4')])
                        else:
                            y_data.append( dataframe[i,self.features.index('min4')])
                    x_data = np.array(x_data)
                    y_data = np.array(y_data)
                    x_data = np.reshape(x_data, (x_data.shape[0], self.timestamp, len(features)))
                    return x_data, y_data
            
                def splitData(self):
                    #Selecionando Intervalos de datas para treino
                    self.df_training = self.selectInterval(self.begining_training, self.end_training)
                    #selecionando colunas para treino
                    self.df_training = self.df_training[self.features]
                    #Escalando o dataset de treino usando a funcao MinMax()
                    self.x_train = self.scalerDataset(self.df_training)
                    #Processando o dataset com o shape adequado para a modelagem 
                    # self.x_train, self.y_train = self.processXY( self.x_train )
                    self.x_train, self.y_train = self.processXY( self.x_train )
                    #Selecionando Intervalos de datas para teste
                    self.df_test     = self.selectInterval(self.end_training,   self.begin_validate)
                    #self.df_validate = self.selectInterval(self.begin_validate, self.end_validate)
                    #selecionando colunas do dataset para teste
                    self.x_test = self.df_test[self.features]
                    #self.x_validate = self.df_validate[self.features]
                    #Escalando o dataset de treino
                    self.x_test = self.scaler_x.transform(self.x_test)
                    #self.x_validate = self.scaler_x.transform(self.x_validate)
                    #Processando o dataset com o shape adequado para a modelagem 
                    self.x_test , self.y_test  = self.processXY( self.x_test )
                    #self.x_validate, self.y_validate = self.processXY( self.x_validate )


            #########################Fim da classe de processamento############################################################

            class Training:
                def __init__(self, ds, neurons, timestamp, features, epochs):
                    self.model = None
                    self.ds = ds
                    self.neurons = neurons
                    self.timestamp = timestamp
                    self.features = features
                    self.epochs = epochs
                    self.trainingLSTM()
                
                def configuringLSTM(self):
                    self.model = Sequential()
                    self.model.add(LSTM(units = self.neurons, return_sequences = False, input_shape=( self.timestamp , len(self.features) ) ))
                    # self.model.add(Dropout(0.01))
                    self.model.add(Dense(1))
                    self.model.compile(loss='mae', optimizer='adam')
            
                def trainingLSTM(self):
                    self.configuringLSTM()
                    self.model.fit(self.ds.x_train, self.ds.y_train, epochs = self.epochs, verbose=0)
                

                def saveLSTM(self):
                    self.model.save('../redeneural/LSTM_'+self.ds.currency)
                    jl.dump(self.ds.scaler_x, '../redeneural/scaler_x.pkl') 
                    jl.dump(self.ds.scaler_y, '../redeneural/scaler_y.pkl')
                    
                    
                
            #########################Fim da classe de Treinamento#############################################################

            class Testing:
                def __init__(self, modelTraining, ds ):
                    self.modelTraining  = modelTraining
                    self.ds     = ds
                    self.y_pred = []
                    self.predictedPrice = []
                    self.predictedPrice_validate = []
                    self.prevision = None
                    self.prevision_validate = None
                    self.time = None
                    self.time_validate = None
                    self.max = None
                    self.max_validate = None
                    self.min = None
                    self.min_validate = None
                    self.open = None
                    self.result_to_csv = None
                    self.result_to_csv_validate = None
                    self.predicting()
                    self.estatistical()
                    self.acuracy = self.estatistical_pred(len(self.predictedPrice))
            
                def predicting(self):
                    self.predictedPrice =  self.modelTraining.model.predict(self.ds.x_test)
                    #self.predictedPrice_validate =  self.modelTraining.model.predict(self.ds.x_validate) 
                    self.predictedPrice =  self.ds.scaler_y.inverse_transform(self.predictedPrice)
                    #self.predictedPrice_validate =  self.ds.scaler_y.inverse_transform(self.predictedPrice_validate)
            
                def estatistical(self):
                    self.y_test         = pd.DataFrame(data=self.ds.df_test['close4'].shift(-self.ds.timestamp).dropna().values, columns=['Y_TEST'])
                    self.open           = pd.DataFrame(data=self.ds.df_test['open1'].shift(-self.ds.timestamp).dropna().values, columns=['Abertura'])
                    self.prevision      = pd.DataFrame(data=self.predictedPrice, columns=['Previsão'])
                    #self.prevision_validate      = pd.DataFrame(data=self.predictedPrice_validate, columns=['Previsão'])
                    self.time           = pd.DataFrame(data=self.ds.df_test['time'].shift(-4).dropna().values, columns=['Data'])
                    #self.time_validate  = pd.DataFrame(data=self.ds.df_validate['time'].shift(-self.ds.timestamp).dropna().values, columns=['Data'])
                    self.maxima           = pd.DataFrame(data=self.ds.df_test['max4'].shift(-self.ds.timestamp).dropna().values, columns=['Máxima'])
                    self.maxima           = self.maxima
                    #self.maxima_validate  = pd.DataFrame(data=self.ds.df_validate[['max1','max2','max3','max4']].max(axis=1).shift(-self.ds.timestamp).dropna().values, columns=['Máxima'])
                    #self.maxima_validate  = self.maxima_validate
                    self.minima           = pd.DataFrame(data=self.ds.df_test['min4'].shift(-self.ds.timestamp).dropna().values, columns=['Minima'])
                    self.minima           = self.minima
                    #self.minima_validate  = pd.DataFrame(data=self.ds.df_validate[['min1','min2','min3','min4']].min(axis=1).shift(-self.ds.timestamp).dropna().values, columns=['Minima'])
                    #self.minima_validate  = self.minima_validate 
                    frames_to_csv       = [ self.time, self.maxima, self.minima, self.prevision ]
                    #frames_to_csv_validate       = [ self.time_validate, self.maxima_validate, self.minima_validate, self.prevision_validate ]
                    self.result_to_csv  = pd.concat( frames_to_csv, axis=1, join='inner')
                    #self.result_to_csv_validate  = pd.concat( frames_to_csv_validate, axis=1, join='inner')
                
                # def saveToCsv(self):
                #     #self.result_to_csv_validate.to_csv('previsoes_'+self.ds.currency, mode='a', header=False, index=False)
                    
            
                def graphicMaxMin(self, window):
                    y_test = []
                    y_test = self.ds.df_test['close4'].shift(-self.ds.timestamp).dropna()
                    plt.plot(y_test[:window], color='red', label='Preço Atual das Ações')
                    plt.plot(y_test.index.values[:window], self.prevision.iloc[:window,0] , '.')
                    plt.fill_between(y_test.index.values[:window], self.maxima.iloc[:window,0], self.minima.iloc[:window,0], alpha=0.5)
                    plt.title('Previsão de Preço de Ações')
                    plt.xlabel('Tempo')
                    plt.ylabel('Preço das Ações')
                    plt.legend()
                    plt.show()
                    print(self.modelTraining.model.evaluate(self.ds.x_test, y_test, verbose=0)*100)
                
                def estatistical_pred(self, window):
                    self.acertos     = 0
                    resumo_acumulado = []
                    self.erros       = 0
                    for i in range (window):
                        soma = 0
                        if self.prevision.iloc[i,0] in pd.Interval(left=self.minima.iloc[i,0], right=self.maxima.iloc[i,0]):
                            soma = abs( self.prevision.iloc[i,0] - self.open.iloc[i,0])
                            soma = int(soma*100000)
                            self.acertos = self.acertos + 1
                        else:
                            if self.y_test.iloc[i,0] > self.open.iloc[i,0]:
                                if self.prevision.iloc[i,0] > self.open.iloc[i,0]:
                                    soma = abs( self.y_test.iloc[i,0] - self.open.iloc[i,0] )
                                    soma = int(soma*10000)
                                    self.acertos = self.acertos + 1
                                else:
                                    soma = self.open.iloc[i,0] - self.y_test.iloc[i,0]
                                    soma = int(soma*10000)
                                    self.erros = self.erros + 1
                            else:
                                if self.prevision.iloc[i,0] < self.open.iloc[i,0]:
                                    soma = abs( self.y_test.iloc[i,0] - self.open.iloc[i,0])
                                    soma = int(soma*10000)
                                    self.acertos = self.acertos + 1
                                else:
                                    soma = self.y_test.iloc[i,0] - self.open.iloc[i,0]
                                    soma = int(soma*10000)
                                    self.erros = self.erros + 1
                    portcentagem = self.acertos*100/window
                    # print("Acertos: ", self.acertos)
                    # print("Erros: ", self.erros)
                    # print("%", portcentagem)
                    resumo_acumulado = pd.DataFrame(data=resumo_acumulado , columns=['Resumo Acumulado '])
                    return portcentagem
        
            print('Ano = '+str(ano)+' - '+ 'Mes = '+str(mes)+' - Neurons = '+str(neurons_i)+' -  Epochs = '+str(epochs_i)+' - Loop = '+str(loop_epochs) )    
            begining_training = str(ano-6)+'-01'+'-01 00:00:00'
            end_training      = str(ano)+'-07'+'-27 00:00:00'
            begin_validate    = str(ano)+'-08'+'-27 23:45:00'
            end_validate      = str(ano)+'-09'+'-27 23:45:00'
            
            currency          = 'EURUSD-15M-1H'
            features          = ['open1','max1','min1','open2','max2','min2','open3','max3','min3','open4','max4','min4','close4']
            target            = 'close4'
            timestamp = 1
            neurons = neurons_i
            epochs  = epochs_i
            datasetProcessed = Processing( currency, begining_training, end_training, begin_validate, end_validate, timestamp, features, target  )
            modelTrained = Training( datasetProcessed, neurons, timestamp, features, epochs )
            estatisticalTested  = Testing( modelTrained, datasetProcessed )
            if estatisticalTested.acuracy > best_accuracy:
                best_accuracy = estatisticalTested.acuracy
                best_epochs = epochs_i
                best_neurons = neurons_i
                print('Melhor Aproveitamento = '+str(np.round(best_accuracy,2))+'%')
                print('Epochs = ',best_epochs)
                print('Neurons = ', best_neurons)
                print('Acertos = '+str(estatisticalTested.acertos))
                print('Erros = '+str(estatisticalTested.erros)+'\n')
                save_to_csv = estatisticalTested
            for element in dir():
                if element not in variables_saves :
                    del globals()[element]
    # save_to_csv.saveToCsv()
    save_to_csv.modelTraining.saveLSTM()
