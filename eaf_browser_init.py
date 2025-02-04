import sys
import os
sys.path.append (os.path.join(os.path.expanduser("~"), ".emacs.d/site-lisp/emacs-application-framework"))

import os
import types
from PyQt6.QtWebEngineCore import QWebEnginePage

from core.utils import *
from core.buffer import QT_KEY_DICT
from PyQt6.QtCore import QEvent, Qt
from PyQt6.QtGui import  QKeyEvent

def my_import2 (str):
    g = {}
    l = {}
    exec (str, g, l)
    lines = str.strip ().split ("\n")
    for line in lines:
        if len (line) == 0:
            continue
        sp = line.strip ().split (" ")
        name = sp [len (sp)-1]
        print ("setting globals", name)
        if name not in globals ():
            print ("set globals", name)
            globals () [name] = l [name]
code = """
from core.utils import post_event
from core.buffer import QT_KEY_DICT
from PyQt6.QtCore import QEvent
from PyQt6.QtCore import Qt
from PyQt6.QtGui import  QKeyEvent
"""
my_import2 (code)

def _myadd_password_entry(self):
    if self.pw_autofill_raw is None:
        self.pw_autofill_raw = self.buffer_widget.read_js_content("pw_autofill.js")

    self.buffer_widget.eval_js(self.pw_autofill_raw.replace("%1", "''"))
    password, form_data = self.buffer_widget.execute_js("retrievePasswordFromPage();")
    if password != "":
        from urllib.parse import urlparse
        print ("_myadd_password_entry!!!", self.url, password, form_data, urlparse(self.url).hostname)
        self.autofill.add_entry(urlparse(self.url).hostname, password, form_data)
        message_to_emacs("Successfully recorded this page's password!")
        return True
    else:
        message_to_emacs("There is no password present in this page!")
        return False

self.add_password_entry = types.MethodType (_myadd_password_entry, self)


def _my_caret_at_line(self, marker):
    '''Enable caret by marker'''
    self.load_marker_file()
    self.eval_js("Marker.gotoMarker('%s', (e) => window.getSelection().collapse(e, 0))" % str(marker))
    self.cleanup_links_dom()

    markEnabled = self.execute_js("CaretBrowsing.markEnabled")
    # reset to clear caret state so the next sentence can be marked
    if markEnabled:
        self.eval_js("CaretBrowsing.shutdown();")

    message_to_emacs("check caret_toggle_browsing")
    if not self.buffer.caret_browsing_mode:
        message_to_emacs("do caret_toggle_browsing")
        self.buffer.caret_toggle_browsing()
    self.buffer.caret_enable_mark()
    self.buffer.caret_next_sentence()
    self.buffer.caret_browsing_mode = True

    eval_in_emacs('eaf--toggle-caret-browsing', ["'t"])

def my_autofill(self):
    if self.pw_autofill_raw is None:
        self.pw_autofill_raw = self.buffer_widget.read_js_content("pw_autofill.js")

    from urllib.parse import urlparse
    result = self.autofill.get_entries(urlparse(self.url).hostname, -1)
    new_id = 0
    lst = []
    maps = {}
    for row in result:
        new_id = row[0]
        password = row[2]
        form_data = row[3]
        lst.append ([form_data, password, new_id])
        maps [form_data] = password
    print ("lst=", lst)
    if len (lst) == 0:
        return
    elif len (lst) == 1:
        res = lst [0] [0]
    else:
        res = get_emacs_func_result ("select-some", [lst])
    print ("res=", res, maps [res])
    self.buffer_widget.eval_js(self.pw_autofill_raw.replace("%1", res))
    self.buffer_widget.eval_js('autofillPassword("%s");' % maps [res])


class MyWebEnginePage(QWebEnginePage):
    def __init__(self, root):
        super().__init__()
        self.root = root

    def acceptAuthentication(self, request, auth):
        print ("acceptAuthentication!!!")
        # todo: get password from database
        auth.setUser("kasm_user")
        auth.setPassword("password")
    def certificateErrorDeal (self, error):
        print ("certificateErrorDeal", error.url ())
        error.acceptCertificate ()
        return True

self.my_page = MyWebEnginePage (self)
self.buffer_widget.page ().authenticationRequired.connect(self.my_page.acceptAuthentication)
self.buffer_widget.page ().certificateError.connect (self.my_page.certificateErrorDeal)

message_to_emacs('page={}'.format(self.buffer_widget.page ()))


self.buffer_widget._caret_at_line = types.MethodType(_my_caret_at_line, self.buffer_widget)
self.my_autofill = types.MethodType (my_autofill, self)

# key
for number in range(1, 36):
    QT_KEY_DICT["<f"+str(number)+">"] = eval("Qt.Key.Key_F{}".format(number))
QT_KEY_DICT["<shift>"] = Qt.Key.Key_Shift

def my_send_key_press(self, event_string):
    from core.buffer import QT_TEXT_DICT
    text = QT_TEXT_DICT.get(event_string, event_string)
    if event_string not in QT_KEY_DICT:
        key_press = QKeyEvent(QEvent.Type.KeyPress, Qt.Key.Key_unknown, Qt.KeyboardModifier.NoModifier, text)
    else:
        key_press = QKeyEvent(QEvent.Type.KeyPress, QT_KEY_DICT[event_string], Qt.KeyboardModifier.NoModifier, text)
    for widget in self.get_key_event_widgets():
        post_event(widget, key_press)
self.my_send_key_press = types.MethodType(my_send_key_press, self)



def my_send_key_release(self, event_string):
    from core.buffer import QT_KEY_DICT
    if event_string not in QT_KEY_DICT:
        return
    key_press = QKeyEvent(QEvent.Type.KeyRelease, QT_KEY_DICT[event_string], Qt.KeyboardModifier.NoModifier, "")
    for widget in self.get_key_event_widgets():
        post_event(widget, key_press)
self.my_send_key_release = types.MethodType(my_send_key_release, self)

def my_send_key(self, event_string):
    ''' Fake key event.'''
        # Init.
    modifier = Qt.KeyboardModifier.NoModifier

    if event_string == "<backtab>" or (len(event_string) == 1 and event_string.isupper()):
        modifier = Qt.KeyboardModifier.ShiftModifier

    if modifier == Qt.KeyboardModifier.ShiftModifier:
        self.my_send_key_press('<shift>')
    # NOTE: don't ignore text argument, otherwise QWebEngineView not respond key event.
    self.my_send_key_press(event_string)
    self.my_send_key_release(event_string)
    if modifier == Qt.KeyboardModifier.ShiftModifier:
        self.my_send_key_release('<shift>')

    self.send_key_filter(event_string)
def send_key_old(self, event_string):
    ''' Fake key event.'''
    # Init.
    print("send_key", event_string)
    from core.buffer import QT_TEXT_DICT
    text = QT_TEXT_DICT.get(event_string, event_string)
    modifier = Qt.KeyboardModifier.NoModifier

    if True:
        self.my_send_key(event_string)
        return

    if event_string == "<backtab>" or (len(event_string) == 1 and event_string.isupper()):
        modifier = Qt.KeyboardModifier.ShiftModifier
        self.my_send_key(event_string)
        return

    # NOTE: don't ignore text argument, otherwise QWebEngineView not respond key event.
    try:
        key_press = QKeyEvent(QEvent.Type.KeyPress, QT_KEY_DICT[event_string], modifier, text)
    except:
        key_press = QKeyEvent(QEvent.Type.KeyPress, Qt.Key.Key_unknown, modifier, text)

    for widget in self.get_key_event_widgets():
        post_event(widget, key_press)

    self.send_key_filter(event_string)

self.send_key = types.MethodType(send_key_old, self)
self.my_send_key = types.MethodType(my_send_key, self)

def my_send_key_sequence(self, event_string):
    ''' Fake key sequence.'''

    QT_MODIFIER_KEY = {
        "C": Qt.Key.Key_Control,
        "M": Qt.Key.Key_Alt,
        "S": Qt.Key.Key_Shift,
        "s": Qt.Key.Key_Meta,
    }
    from core.buffer import QT_TEXT_DICT,QT_MODIFIER_DICT
    print("send_key_sequence", event_string)
    event_list = event_string.split("-")

    if len(event_list) > 1:
        widget = self.buffer_widget.focusProxy()
        last_char = event_list[-1]
        last_key = last_char.lower() if len(last_char) == 1 else last_char

        modifier_keys = [QT_MODIFIER_KEY.get(modifier) for modifier in event_list[0:-1]]
        modifier_flags = Qt.KeyboardModifier.NoModifier
        for modifier in modifier_keys:
            key_event = QKeyEvent(QEvent.Type.KeyPress, modifier, Qt.KeyboardModifier.NoModifier, "")
            post_event(widget, key_event)

        text = QT_TEXT_DICT.get(last_key, last_key)

        key_event = QKeyEvent(QEvent.Type.KeyPress, QT_KEY_DICT[last_key], modifier_flags, text)
        post_event(widget, key_event)

        key_event = QKeyEvent(QEvent.Type.KeyRelease, QT_KEY_DICT[last_key], modifier_flags, text)
        post_event(widget, key_event)

        modifier_keys.reverse()
        for modifier in modifier_keys:
            key_event = QKeyEvent(QEvent.Type.KeyRelease, modifier, Qt.KeyboardModifier.NoModifier, "")
            post_event(widget, key_event)


self.send_key_sequence = types.MethodType(my_send_key_sequence, self)

print("eaf_browser_init ok")
message_to_emacs(":{}".format(self.buffer_widget))
message_to_emacs("eaf_browser_init ok pid={}".format(os.getpid()))
