import types
from trzsz.libs import transfer
from trzsz.libs import utils
from trzsz.__version__ import __version__
import queue
import threading

def my_import (str):
    exec (str)
    lines = str.strip ().split ("\n")
    for line in lines:
        if len (line) == 0:
            continue
        sp = line.strip ().split (" ")
        name = sp [len (sp)-1]
        print ("set globals", name)
        if name not in globals ():
            globals () [name] = locals () [name]
code = """
import types
import trzsz
from trzsz.libs import transfer
from trzsz.libs import utils
from trzsz.__version__ import __version__
import sys
import queue
import threading
"""
my_import (code)

class MyReader ():
    def __init__ (self):
        self.q = queue.Queue ()
        pass
    def read (self, size):
    #return bytes
        print ("MyReader read start")
        ret = self.q.get ()
        print ("MyReader read ret", ret)
        return ret
    def fill_data (self, data):
        self.q.put (data)
        pass

def fake_read_buffer(size):
    print ("fake_read_buffer", size)
    if utils.GLOBAL.next_read_buffer:
        return utils.GLOBAL.next_read_buffer
    while True:
        try:
            #buf = os.read(sys.stdin.fileno(), size)
            buf = utils.GLOBAL.trzsz_reader.read (size)
            break
        except Exception as err:
            if utils.is_eintr_error(err):
                continue
            raise
    if not buf:
        raise utils.TrzszError('EndOfStdin', trace=False)
    return buf

utils.read_buffer = fake_read_buffer
utils.GLOBAL.stopped = False


class TransFile:
    def __init__(self, parent):
        self.parent = parent
        self.active = False
        self.is_recv = False
        self.is_send = False
        utils.IS_RUNNING_ON_WINDOWS = False
        utils.GLOBAL.trzsz_writer = self
        self.reader = MyReader ()
        utils.GLOBAL.trzsz_reader = self.reader
    def write (self, data):
        #str to byte
        if isinstance (data, str):
            bs = data.encode ('utf-8')
            self.parent.write (bs)
        else:
            self.parent.write (data)
    def flush (self):
        pass

    def deal_read(self, data):
        #b'\x1b7\x07::TRZSZ:TRANSFER:R:1.1.5:2622246073700\r\r\n'
        #b'\x1b7\x07::TRZSZ:TRANSFER:S:1.1.5:2622264446100\r\r\n'
        example = b'\x1b7\x07::TRZSZ:TRANSFER:S:1.1.5:2622264446100\r\r\n'
        #example = b'\x1b7\x07::TRZSZ:TRANSFER:R:1.1.8:2638111531300:33861\r\r\n'
        example_match = b'\x1b7\x07::TRZSZ:TRANSFER:'

        if self.active:
            self.reader.fill_data (data)
        else:
            if len (data) >= len (example) and data.find (example_match) == 0:
                self.active = True
                if data [len (example_match):] [0:1] == b'R':
                    self.is_recv = True
                    self.is_send = False
                    print ("start send_file_thread")
                    threading.Thread (target=self.send_file_thread).start ()
                elif data [len (example_match):] [0:1] == b'S':
                    self.is_send = True
                    self.is_recv = False
                    print ("start recv_file_thread")
                    threading.Thread (target=self.recv_file_thread, args=(self, 2)).start ()
                else:
                    print ("no match")
                    return
                print ("send action")
                transfer.send_action (True, __version__, False)
    def send_file_thread (self):
        print ("send_file_thread")
        #recv config
        cfg = transfer.recv_config ()
        print (cfg)
        #send file
        print ("start send file")
        file_path = get_emacs_var("*my-eaf-term-transfer-select-file*")
        files = utils.check_paths_readable ([file_path], False)
        transfer.send_files (files)
        transfer.client_exit ("ok")
        #transfer.server_exit (transfer.recv_exit ())
        self.active = False
        pass
    def recv_file_thread (self):
        print ("recv_file_thread")
        pass

class MyStdout:
    def write (self, data):
        print ("MyStdout", data)

def my_read(self):
    #trz/tsz ouput
    while True:
        ret = self.pty.read(65536)
        print ("pty read:{}".format (ret))
        self.trans_file.deal_read (ret)
        if self.trans_file.active:
            continue
        else:
            return ret

def my_write(self, data):
    #send to trz/tsz
    if len (data) > 100:
        print ("pty write:{}".format (data [0:100]))
    else:
        print ("pty write:{}".format (data))
    self.pty.write(data)
    #if self.trans_file.ative:
    #    #todo: hold
    #    print ("trans_file ative, waiting!")
    #    pass
    #else:
    #    self.pty.write(data)

if False:
    #local test
    tf = TransFile (MyStdout ())
    tf.deal_read (b'\x1b7\x07::TRZSZ:TRANSFER:R:1.1.5:2622264446100\r\r\n')
    #tf.deal_read (b'#ACT:eJw0ysGqAjEMRuF3+ddhYOAuLnkWQeqYDsGYlLRVRHx3N87yHL43rPgOxh4gPCS7hoOxLuvyD8IWXjXv4JFTCC5PUxcwTg5CyxixhYH/CBf1kq9D9tla5DhfNY81prsYuBbrQqiRt198vgEAAP//idAtNQ==\n')
    tf.deal_read (b'#CFG:eJyrVspJzEtXslJQKqhU0lFQSipNK86sSgUKGBqYWJiamxkABUsyc1PzS0uAgkYgbkFRfkl+cn4OSFEtAGeVEsc=\n')
    tf.deal_read(b"#SUCC:1\n")
    tf.deal_read (b"#SUCC:eJwrKC3RK0hOLAAADnQDLA==\n")
    pass
if True:
    self.buffer_widget.backend.pty.write = types.MethodType (my_write, self.buffer_widget.backend.pty)
    self.buffer_widget.backend.pty.read = types.MethodType (my_read, self.buffer_widget.backend.pty)
    globals () ['MyReader']=  locals () ['MyReader']
    self.buffer_widget.backend.pty.trans_file = TransFile(self.buffer_widget.backend.pty)

    message_to_emacs ("{}".format (self.buffer_widget.backend.pty.write))
