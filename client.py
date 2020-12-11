import socket

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(('127.0.0.1', 9090))

msg = 'Nunca Vou Pra la'
s.send(msg.encode('UTF-8'))

while True:
    msgsrv = s.recv(10000)
    if not msgsrv:
                break
    print(msgsrv)