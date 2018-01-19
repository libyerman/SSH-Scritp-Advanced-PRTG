#!/usr/bin/python


import subprocess
import threading
import argparse

# parametros de uso del script
parser = argparse.ArgumentParser(description='%(prog)s es un scritp que ejecuta ping a las IP indicadas y devuelve un JSON valido para PRTG SSH scritp advanced. Uso: ./%(prog)s -d Descripcion -i 192.168.1.1')
parser.add_argument("-d", "--descripcion", required=True, help="Descripcion de la ip a la que le haremos ping. si se desea ejecutar mas de un ping se pondra entre comillas ejemplo: \"Descripcion 1,Descripcion 2\"")
parser.add_argument("-i", "--ip", required=True, help="Direccion de la ip a la que le haremos ping. si se desea ejecutar mas de un ping se pondra entre comillas ejemplo: \"192.168.0.1,192.168.1.1\"")
args = parser.parse_args()

class Pinger(object):
    header = "{  \"prtg\": {    \"result\": [ " # principio de la cadena de JSON para el sensor de PRTG
    status = "" # contenido de los canales que tendra el sensor PRTG
    hosts = [] # listado de hosts e ips
    descr = [] # listado de descripciones de los hosts
    buttom = "],    \"text\": \"Monitor de Hosts\"  } }" # final de la cadena JSON para el sensor de PRTG

    # How many ping process at the time.
    thread_count = 30

    # Lock object to keep track the threads in loops, where it can potentially be race conditions.
    lock = threading.Lock()

    def ping(self, ip):
        # Use the system ping command with count of 4 and wait time of 1.
        ret = subprocess.call(['ping', '-c', '4', '-W', '1', ip],
                              stdout=open('/dev/null', 'w'), stderr=open('/dev/null', 'w'))

        return ret == 0 # Return True if our ping command succeeds

    def pop_queue_hosts(self):
        ip = None

        self.lock.acquire() # Grab or wait+grab the lock.

        if self.hosts:
            ip = self.hosts.pop()

        self.lock.release() # Release the lock, so another thread could grab it.

        return ip

    def pop_queue_descr(self):
        descr = None

        self.lock.acquire() # Grab or wait+grab the lock.

        if self.descr:
            descr = self.descr.pop()

        self.lock.release() # Release the lock, so another thread could grab it.

        return descr    

    def dequeue(self):
        while True:
            ip = self.pop_queue_hosts()
            descr = self.pop_queue_descr()
            result=""
            if not ip:
                return None
            if not descr:
                descr = "Sin Descripcion"
            result+= "{"
            result+= '"channel": "'+descr+' '+ip+'",'
            #result+= '"unit": "custom",'
            #result+= '"mode": "Absolute",'
            #result+= '"showChart": "1",'
            #result+= '"showTable": "1",'
            result+= '"limitmode": "1",'
            result+= '"limitmaxwarning": "1",'
            result+= '"limitmaxerror": "1",'
            result+= '"limitminwarning": "1",'
            result+= '"limitminerror": "1",'
            result+= '"limiterrormsg": "Host error",'        
            result+= '"float": "1",'
            if self.ping(ip):
                result+= '"value": 1'
            else:
                result+= '"value": 0'
            result+= "}," # el canal del sensor tendra dos posibles valores. 1 para una respuesta satisfactoria y 0 para un error
            
            self.status= self.status + result

    def start(self):
        threads = []

        for i in range(self.thread_count):
            # Create self.thread_count number of threads that together will
            # cooperate removing every ip in the list. Each thread will do the
            # job as fast as it can.
            t = threading.Thread(target=self.dequeue)
            t.start()
            threads.append(t)

        # Wait until all the threads are done. .join() is blocking.
        [ t.join() for t in threads ]
        
        leng=len(self.status)

        return self.header+self.status[:leng - 1]+self.buttom

if __name__ == '__main__':
    
    # si noy hay parametros no hacemos nada
    if args.descripcion and args.ip:
        ping = Pinger()
        ping.thread_count = 30
        ping.hosts = args.ip.split(",")
        ping.descr = args.descripcion.split(",")

        print ping.start()
