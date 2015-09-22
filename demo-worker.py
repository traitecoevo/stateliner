import zmq
import json
import logging
import numpy as np
import subprocess
import random
import string

HELLO = b'0'
HEARTBEAT = b'1'
REQUEST = b'2'
JOB = b'3'
RESULT = b'4'
GOODBYE = b'5'

def random_string():
    return "".join(random.choice(string.lowercase) for x in range(10))

def nll(x):
    # negative log likelihood of standard normal distribution
    return 0.5 * x.dot(x)

def handle_job(job_type, job_data):
    sample = list(map(float, job_data.split(b':')))
    return nll(np.asarray(sample))

def send_hello(socket, nJobTypes):

    # job range in this case 0-nJobs (inclusive)
    jobTypesStr = '0:{}'.format(nJobTypes).encode('ascii')

    logging.info("Sending HELLO message...")
    socket.send_multipart([b"", HELLO, jobTypesStr])

def job_loop(socket):
    while True:
        logging.info("Getting job...")
        r = socket.recv_multipart()
        logging.info("Got job!")

        assert len(r) == 5

        subject, job_type, job_id, job_data = r[1:]

        assert subject == JOB

        result = handle_job(job_type, job_data)

        logging.info("Sending result...")
        rmsg = [b"", RESULT, job_id, str(result).encode('ascii')]
        socket.send_multipart(rmsg)
        logging.info("Sent result {0}!".format(job_id))

def main():
    # Initiate logging
    #logging.basicConfig(level=logging.DEBUG)
    logging.basicConfig(level=logging.CRITICAL)

    # Launch stateline-client
    #random address
    addr = "ipc:///tmp/sl_worker_" + random_string() + ".socket"
    host = "stateline:5555"

    logging.info('Starting client')
    client_proc = subprocess.Popen(['/usr/local/bin/stateline-client', '-w', addr, '-n', host])
    logging.info('Started client')

    # Load configuration
    with open('demo-config.json', 'r') as f:
        config = json.load(f)

    nJobTypes = config['nJobTypes']

    # Start minion
    ctx = zmq.Context()
    socket = ctx.socket(zmq.DEALER)

    logging.info("Connecting to {0}...".format(addr))
    socket.connect(addr)
    logging.info("Connected!")

    send_hello(socket, nJobTypes)
    job_loop(socket)

if __name__ == "__main__":
    main()
