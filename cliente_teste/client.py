import socket

def client(host = '127.0.0.1', port=8082): 
    # Create a TCP/IP socket 
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM) 
    # Connect the socket to the server 
    server_address = (host, port) 
    print ("Connecting to %s port %s" % server_address) 
    sock.connect(server_address)
    #message = "init"
    #sock.sendall(message.encode('utf-8')) 
    # Send data 
    try: 
        while True:
            message = input("Digite a msg para o server\n") 
            print ("Sending %s" % message) 
            sock.sendall(message.encode('utf-8'))
            data = sock.recv(1000)
            if data:
                print(data)
    except socket.error as e: 
        print ("Socket error: %s" %str(e)) 
    except Exception as e: 
        print ("Other exception: %s" %str(e)) 
    finally: 
        print ("Closing connection to the server") 
        sock.close() 

client()