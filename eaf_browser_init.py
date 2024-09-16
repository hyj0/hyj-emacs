import sys
import os
import types


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

self.buffer_widget._caret_at_line = types.MethodType(_my_caret_at_line, self.buffer_widget)

message_to_emacs(":{}".format(self.buffer_widget))
message_to_emacs("eaf_browser_init ok pid={}".format(os.getpid()))
