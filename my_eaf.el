
;(setenv "LIBGL_ALWAYS_SOFTWARE" "1")

(add-to-list 'load-path "~/.emacs.d/site-lisp/emacs-application-framework/")
(require 'eaf)

(when t
  (setq eaf-proxy-type "http")
  (setq eaf-proxy-host "127.0.0.1")
  (setq eaf-proxy-port "8118"))

;(setq eaf-enable-debug t)
(setq eaf-browser-translate-language "zh")
(setq eaf-browser-continue-where-left-off t)
(setq eaf-browser-default-search-engine "duckduckgo")
(setq eaf-browser-blank-page-url "https://duckduckgo.com")

(require 'eaf)
(require 'eaf-file-manager)
(require 'eaf-terminal)
(require 'eaf-system-monitor)
(require 'eaf-browser)
(require 'eaf-video-player)
(require 'eaf-file-browser)
(require 'eaf-music-player)
(require 'eaf-image-viewer)
(require 'eaf-pyqterminal)
(require 'eaf-pdf-viewer)
(require 'eaf-git)
(require 'eaf-demo)


(defvar *my-eaf-browser-raw-mode-list* nil)
(setq *my-eaf-browser-raw-mode-list* nil)

(defun my-eaf-browser-set-raw-mode ()
  (interactive)
  (add-to-list '*my-eaf-browser-raw-mode-list* (list eaf--buffer-id 1))
  ;(message "%S" (my-eaf-fix-key eaf-browser-keybinding))
  (my-eaf-exec-pycode "if not self.input_mode:\n\tself.input_mode = True")
  (eaf--toggle-caret-browsing nil)
  nil
  )
(defun my-eaf-browser-clear-raw-mode ()
  (interactive)
  (let ((item (assoc eaf--buffer-id *my-eaf-browser-raw-mode-list*)))
    (if item
	(setq *my-eaf-browser-raw-mode-list*
	      (mapcar (lambda (one)
			(if (string= eaf--buffer-id (car one))
			    (list eaf--buffer-id 0)
			  one))
		      *my-eaf-browser-raw-mode-list*))
      (add-to-list '*my-eaf-browser-raw-mode-list* (list eaf--buffer-id 0))))
  (eaf--toggle-caret-browsing nil)
  nil
  )
(defun my-eaf-browser-is-raw-mode ()
  (interactive)
  (let ((flg (car (my-assoc eaf--buffer-id *my-eaf-browser-raw-mode-list* ))))
    (if (and flg (= flg 1))
	t
      nil)))

(defun my-eaf-fix-key (key-bind)
  (mapcar (lambda (one)
	    (if (my-eaf-browser-is-raw-mode)
		(if (and (> (length (car one)) 1)  (string-match-p "-" (car one)))
		    (cons (car one) 'eaf-send-key-sequence)
		  (cons (car one) 'eaf-send-key))
	      one)
	    )
	  key-bind))

(add-hook 'eaf-mode-hook
	  (lambda ()
	    (message "eaf-mode-hook !! mode=%s"
		     (symbol-name major-mode))
	    (evil-local-mode -1)
	    )
	  )


(require 'evil)
(add-to-list 'evil-emacs-state-modes 'eaf-mode)
(add-to-list 'evil-emacs-state-modes 'eaf-pdf-outline-mode)

(add-hook 'kill-emacs-hook
          (lambda ()
            (message "Emacs is about to exit. Running EAF cleanup code...")
	    (eaf-browser-restore-buffers)
	    ))

(defun my-eaf-browser-reopen ()
  (interactive)
  (when eaf-browser-continue-where-left-off
    (let  ((browser-restore-file-path
	    (concat eaf-config-location
                    (file-name-as-directory "browser")
                    (file-name-as-directory "history")
                    "restore.txt")))
      (when (file-exists-p browser-restore-file-path)
	(let ((lines (with-temp-buffer
		       (insert-file-contents browser-restore-file-path)
		       (buffer-string))))
	  (dolist (line (split-string lines "\n"))
	    (when (>  (length line) 0)
	      (message "init:open %s" line)
	      (sleep-for 1)
	      (eaf-open-browser line))))
	))))

;(my-eaf-browser-reopen)
(require 'url)

(defun my-rename-buffer (org-fun name &optional un)
  ;(message "rename buffer %S to %S" (buffer-name) name)
  (when (and (eq major-mode 'eaf-mode) )
    (setq name (concat "eaf-" name))
    (when (string= eaf--buffer-app-name "browser")
      (setq name (concat name "-" (url-host (url-generic-parse-url (eaf-get-path-or-url))) ":" (format "%d" (url-port (url-generic-parse-url (eaf-get-path-or-url))))))
      (when (string-match-p "note.youdao.com" (eaf-get-path-or-url))
	(my-eaf-exec-pycode "if not self.input_mode:\n\tself.input_mode = True"))
      (when (string-match-p "10.13.0.174:6901" (eaf-get-path-or-url))
	(my-eaf-browser-set-raw-mode)))
    (when (string= eaf--buffer-app-name "pyqterminal")
      (setq name (concat name "-" (eaf-get-path-or-url)))))
  (when t
    (funcall org-fun name un))
  )


(advice-add 'rename-buffer :around #'my-rename-buffer)
;(advice-remove 'rename-buffer 'my-rename-buffer)


;open url at new buffer
(defun my-eaf-open-browser (org-fun url &optional args)
  (if (eq 'eaf-mode major-mode)
      (eaf-open (eaf-wrap-url url) "browser" args t)
    (funcall org-fun url args)))

(advice-add 'eaf-open-browser :around #'my-eaf-open-browser)
;(advice-remove 'eaf-open-browser #'my-eaf-open-browser)


(defun eaf-open-browser-with-history ()
  "A wrapper around `eaf-open-browser' that provides browser history candidates.

If URL is an invalid URL, it will use `eaf-browser-default-search-engine' to search URL as string literal.

This function works best if paired with a fuzzy search package."
  (interactive)
  (let* ((browser-history-file-path
          (concat eaf-config-location
                  (file-name-as-directory "browser")
                  (file-name-as-directory "history")
                  "log.txt"))
         (history-pattern "^\\(.+\\)??\\(.+\\)??\\(.+\\)$")
         (history-file-exists (file-exists-p browser-history-file-path))
	 (history-candidates (if history-file-exists
			  (mapcar
                           (lambda (h) (when (string-match history-pattern h)
					 (format "[%s] ?? %s" (match-string 1 h) (match-string 2 h))))
                           (with-temp-buffer (insert-file-contents browser-history-file-path)
					     (split-string (buffer-string) "\n" t)))
			nil))
         (history (ivy-read
                   "[EAF/browser] Search || URL || History: "
		   (lambda (str)
		     (let ((candidates history-candidates)
			   (start-time (float-time (current-time))))
		       (or
			(when (< (length str) 1)
			  candidates)
			(if nil
			    (append
			     (seq-filter (lambda (s)
					   (if (> (- (float-time (current-time)) start-time) 0.6)
					       nil
					     (string-match-p (regexp-quote str) s)))
					 candidates)
			     (sort (seq-filter (lambda (s)
						 (if  (> (- (float-time (current-time)) start-time) 0.6)
						     nil
						   (string-match-p (add-star-between-str2 (regexp-quote str)) s)))
					       candidates)
				   #'my-string-len<))
			  (progn
			    (mapcar
			     (lambda (one)
			       (nth 1 one))
			     (sort
			      (cl-remove-if 'null (mapcar (lambda (s)
							    (if (> (- (float-time (current-time)) start-time) 0.2)
								nil
							      (let ((ret (my-string-match (add-star-between-str2 str) s)))
								(if ret
								    (list (cdr ret) s)
								  nil))))
							  history-candidates))
			      (lambda (a b)
				(< (car a) (car b)))))
			    )))))
		   :dynamic-collection t))
         (history-url (eaf-is-valid-web-url (when (string-match "??\s\\(.+\\)$" history)
                                              (match-string 1 history)))))
    ;(message "%S" history-candidates)
    (setq *eaf-history-candidate* history-candidates)
    (cond (history-url (eaf-open-browser history-url))
          ((eaf-is-valid-web-url history) (eaf-open-browser history))
          (t (eaf-search-it history)))))



(defun fuzzy-find-buffer (pattern)
  "Fuzzy find buffer matching PATTERN."
  (interactive "sBuffer name pattern: ")
  (let ((buffers (buffer-list))
        (matched-buffers '()))
    (dolist (buffer buffers)
      (when (string-match-p pattern (buffer-name buffer))
        (push buffer matched-buffers)))
    matched-buffers))


(defun my-eaf-exec-pycode (pycode)
  (setq *my-eaf-pycode* pycode)
  (eaf-call-sync "eval_function" eaf--buffer-id "exec_pycode" "return"))


(dolist (one eaf-browser-keybinding)
  (eaf--make-py-proxy-function (cdr one)))

(eaf-bind-key eaf-send-key "<f2>" eaf-browser-keybinding)
(eaf-bind-key eaf-send-key "<f4>" eaf-browser-keybinding)
(eaf-bind-key eaf-send-key "<f9>" eaf-browser-keybinding)
(eaf-bind-key eaf-send-key "<f8>" eaf-browser-keybinding)
(eaf-bind-key eaf-send-key "<f7>" eaf-browser-keybinding)

(eaf-bind-key eaf-send-key-sequence "C-o" eaf-browser-keybinding)
(eaf-bind-key eaf-send-key-sequence "C-f" eaf-browser-keybinding)

(eaf-bind-key eaf-py-proxy-yank_text "C-v" eaf-browser-keybinding)
(eaf-bind-key eaf-send-key-sequence "C-e" eaf-browser-keybinding)
(eaf-bind-key eaf-py-proxy-copy_text "C-c" eaf-browser-keybinding)
(eaf-bind-key eaf-send-key-sequence "S-<insert>" eaf-browser-keybinding)

(eaf-bind-key eaf-send-key-sequence "M-<left>" eaf-browser-keybinding)
(eaf-bind-key eaf-send-key-sequence "M-<right>" eaf-browser-keybinding)

(eaf-bind-key eaf-send-key-sequence "M-RET" eaf-browser-keybinding)
(eaf-bind-key eaf-send-key-sequence "C-/" eaf-browser-keybinding)

;(eaf-create-send-sequence-function "meta-ret" "M-RET")
;(eaf-bind-key eaf-send-meta-ret-sequence "M-RET" eaf-browser-keybinding)
;(eaf-create-send-sequence-function "meta-lk" "M-<left>")
;(eaf-bind-key eaf-send-meta-lk-sequence "M-[" eaf-browser-keybinding)
;(eaf-create-send-sequence-function "meta-rk" "M-<right>")
;(eaf-bind-key eaf-send-meta-rk-sequence "M-]" eaf-browser-keybinding)
;
(eaf-bind-key eaf-send-key-sequence "C-S-f" eaf-browser-keybinding)
(eaf-bind-key eaf-send-key-sequence "C-S-r" eaf-browser-keybinding)


(add-to-list 'load-path (concat (my-home-dir) "key-echo/"))
(require 'key-echo)
(key-echo-enable)
(defvar *shift-key-last-time* (float-time (current-time)))


(defun delete-key-echo-processs ()
  (dolist (p (cdr (delq nil (mapcar (lambda (p)
				      (when (string-match-p "*key-echo*" (process-name p))
					p))
				    (process-list)))))
    (message "kill key-echo process:%S" p)
    (kill-process p)))

(run-at-time 5 t 'delete-key-echo-processs)


(defun key-echo-shift-to-switch-input-method (key)
  (interactive)
  ;(message "key-echo:%S" key)
  (when (string-equal key "Key.shift")
    (when (and  (eq major-mode 'eaf-mode) (string= eaf--buffer-app-name "browser"))
					;(message "key-echo:%S" key)
      (my-eaf-exec-pycode (concat
			   "self.my_send_key_press('<shift>')\n"
			   "self.my_send_key_release('<shift>')\n"
			   )))))

(setq key-echo-single-key-trigger-func 'key-echo-shift-to-switch-input-method)



(defvar *input-method-last-buffer* nil)
(defvar *input-method-key-down* nil)
(defvar *input-method-string* "")

;input method enter to send row string
(defun my-key-echo-key-press-func (key)
					;(message "press:%s" key)
  (when (and current-input-method (eq major-mode 'eaf-mode))
					;(message "press:%S %S" key (type-of key))
    (when (not (eq (current-buffer) *input-method-last-buffer*))
      (setq *input-method-string* "")
      (setq *input-method-last-buffer* (current-buffer))
      (setq *input-method-key-down* nil))
    (cond
     ((and (stringp key) (string-match-p "Key.enter" key))
      (progn
	(message "send to eaf:%s" *input-method-string*)
	(mapc (lambda (c)
		(eaf-call-sync "send_key" eaf--buffer-id (format "%c" c)))
	      *input-method-string*)
	(setq *input-method-string* "")))
     ((and (stringp key) (string-match-p "Key.esc" key))
      (setq *input-method-string* ""))
     ((and (stringp key) (string-match-p "Key.space" key))
      (setq *input-method-string* ""))
     ((and (stringp key) (string-match-p "Key." key))
      (setq *input-method-key-down* t))
     ((symbolp key)
      (let ((c (substring (symbol-name key) 0 1)))
	(cond
	 ((string-match-p c "0123456789")
	  (setq *input-method-string* ""))
	 (t
	  (when (not *input-method-key-down*)
					;(message "add *input-method-string* :%s" c)
	    (setq *input-method-string* (format "%s%s" *input-method-string* c)))))))
     (t (message "not match:%s" key))
     )
    ))

(defun my-key-echo-key-release-func (key)
  ;(message "release:%s" key)
  (when (and current-input-method (eq major-mode 'eaf-mode))
    ;(message "release:%s" key)
    (cond
     ((and (stringp key) (string-match-p "Key.enter" key))
      nil)
     ((and (stringp key) (string-match-p "Key.shift" key))
      nil)
     ((and (stringp key) (string-match-p "Key." key))
      (setq *input-method-key-down* nil)))
    ))

(when nil
  (with-current-buffer (car (fuzzy-find-buffer "note.you"))
					;(my-key-echo-key-release-func "Key.Ctrl")
    (my-key-echo-key-press-func 'l)
    (my-key-echo-key-press-func "Key.enter")))



(setq key-echo-key-press-func 'my-key-echo-key-press-func)
(setq key-echo-key-release-func 'my-key-echo-key-release-func)


(setq eaf-browser-enable-autofill t)


(defun my-eaf-c-c-copy (&rest args)
  (interactive)
  ;(message "C-c")
  (my-eaf-exec-pycode "self.copy_text()")
  ;(eaf-send-key-sequence)
  )
;(eaf-bind-key my-eaf-c-c-copy "C-c" eaf-browser-keybinding)

(let* ((pyfile (concat  "~/.emacs.d/hyj-emacs/eaf_browser_init.py"))
       (pycode (with-temp-buffer
		  (insert-file-contents pyfile)
		  (buffer-string))))
  (setq *eaf-browser-init-pycode* pycode))

;(global-set-key (kbd "<f3>") 'eaf-open-browser-with-history)

(defun kill-all-eaf-buffer ()
  (interactive)
  (dolist (one (fuzzy-find-buffer ""))
    (with-current-buffer one
      (when (eq major-mode 'eaf-mode)
	(kill-buffer one)))))

(defun my-eaf-browser-autofill-password ()
  (interactive)
  (my-eaf-exec-pycode "self.my_autofill()"))

(defun select-some (lst)
  (condition-case err
      (completing-read "select:" lst)
    (error
     (progn
       (message "select-some err:%S" (error-message-string err))
       nil))
    (quit
     (progn
       (message "user cancel!")
       nil)
     )))


(defun my-send-string-to-eaf (str buffer-name)
  (with-current-buffer (car (fuzzy-find-buffer buffer-name))
    (mapc (lambda (c)
	    (if (string= "\n" (format "%c" c))
		(eaf-send-return-key)
	      (eaf-call-sync "send_key"
			     eaf--buffer-id
			     (format "%c" c))))
	  str)))

(add-to-list 'load-path (concat (my-home-dir) "popweb"))
(add-to-list 'load-path (concat (my-home-dir) "popweb/extension/dict"))
(require 'popweb)
(require 'popweb-dict)

(defun eaf-translate-text (text)
  (with-temp-buffer
    (insert text)
    (write-region (point-min) (point-max) "/tmp/eaf-translate.txt" nil 'no-message))
  (let ((res (shell-command-to-string "proxychains trans en:zh -input /tmp/eaf-translate.txt 2>/dev/null ")))
    (with-temp-buffer
      (insert res)
      (kill-ring-save (point-min) (point-max))
      )
    (tooltip-show (format "%s" res))
    res))

(defun eaf-translate-text-short (text)
  (popweb-dict-bing-input text))

(defvar *eaf-translate-crow-process* nil)

(defun eaf-translate-text-long (text)
  "crow conf at ~/.config/crow-translate/crow-translate.conf use https://codeberg.org/aryak/mozhi#instances"
  (with-temp-buffer
					;(insert "<meta name='google' content='notranslate'/>")
    (insert text)
    (write-region (point-min) (point-max) "/tmp/eaf-translate.txt" nil 'no-message))
  (let ((res "")
	(cur-pos 0))
    (when (= 0 (length res))
					;(message-box "run here")
      (when (get-buffer "crow")
	(with-current-buffer "crow"
	  (erase-buffer)))
      (let ((cmd  "proxychains crow -t 'zh' --j -e 'bing' -f /tmp/eaf-translate.txt 2>/tmp/crow.err "))
	(when (and (processp *eaf-translate-crow-process*)
		 (string= "run" (process-status *eaf-translate-crow-process*)))
	    (kill-process *eaf-translate-crow-process*))
	;(message cmd)
	(setq *eaf-translate-crow-process* (start-process-shell-command "crow" "crow" cmd)))
      (let ((brk nil))
	(while (not brk)
	  (with-current-buffer "crow"
	    (let ((str (buffer-string)))
	      (if (string-match-p "}" str)
		  (progn
		    (setq res (substring str 0 (+ 1  (string-match-p "}" str))))
		    (setq brk t))
		(sleep-for 0 200)))))
	res)
      )
    (let ((transed (my-assoc 'translated-text (json-read-from-string res))))
      (with-temp-buffer
	(insert transed)
	(kill-ring-save (point-min) (point-max))
	)
					;(message-box (format "%s" transed))
      (tooltip-show (format "%s" (my-string-multi-line transed 70)))
      transed)))

(defun my-string-multi-line (str size)
  (let ((res "")
	(brk nil))
    (while str
      (setq res (concat res (substring str 0 (min size (length str))) "\n"))
      (if (> (length str) size)
	  (setq str (substring str size))
	(setq str nil)))
    res))

(defun eaf-translate-text (text)
  (if (or t (length> text 20))
      (eaf-translate-text-long text)
    (eaf-translate-text-short text)))


(setq eaf-pyqterminal-color-schema
  ;; Tango Dark
  '(("blue" "#3465a4")
    ("brown" "#fce94f")
    ("cyan" "#06989a")
    ("cursor" "#666666")
    ("green" "#4e9a06")
    ("magenta" "#75507b")
    ("red" "#cc0000")
    ("yellow" "#c4a000")
    ("brightblack" "#555753")
    ("brightblue" "#729fcf")
    ("brightbrown" "#c4a000")
    ("brightcyan" "#34e2e2")
    ("brightgreen" "#8ae234")
    ("brightmagenta" "#ad7fa8")
    ("brightred" "#ef2929")
    ("brightwhite" "#729fcf")
    ("brightyellow" "#c4a000")))


(defun my-eaf-kasm-input ()
  (interactive)
  (let ((str (read-string "input:")))
    (kill-new str)
    ))


(defvar *my-cur-edit-clipboard-buffer* nil)

;(eaf-open-browser "file:///home/hyj/.emacs.d/hyj-emacs/xe-clipboard-index.html")

(defun my-eaf-open-clipboard-url ()
  (when (not (fuzzy-find-buffer "eaf-??è´´æ?¿æ?è¯?é¡µé??"))
    (let ((cur-buffer (current-buffer))
	  (cur-window (get-buffer-window (current-buffer))))
      (eaf-open-browser "file:///home/hyj/.emacs.d/hyj-emacs/xe-clipboard-index.html")
      (while (not (fuzzy-find-buffer "eaf-??è´´æ?¿æ?è¯?é¡µé??"))
	(sleep-for 0.2))
      (with-current-buffer  (car (fuzzy-find-buffer "eaf-??è´´æ?¿æ?è¯?é¡µé??"))
	(switch-to-buffer cur-buffer)))))


(defun edit-clipboard ()
  (interactive)
  (setq *my-cur-edit-clipboard-buffer* (current-buffer))
  (let ((clipboard-content (current-kill 0)))
    (message "clipboard-content=%S" clipboard-content)
    (let ((buffer (get-buffer-create "*clipboard*")))
      (with-current-buffer buffer
        (erase-buffer)
        (insert clipboard-content)
        (set-buffer-modified-p nil)
	(evil-insert-state)
	(when (not current-input-method)
	  (toggle-input-method))
	)
      (display-buffer buffer '(display-buffer-below-selected
                               (allow-no-window . nil) ; Ensure a window is created
                               (inhibit-same-window . t) ; Prevent using the same window
                               (window-height . 5))) ; Adjust height as needed
      (select-window (get-buffer-window buffer))
      (message "Edit clipboard content and press C-c C-c to save.")
      (local-set-key (kbd "C-c C-c") 'save-clipboard)
      )))

(defun save-clipboard ()
  (interactive)
  (let ((content (buffer-string)))
    (gui-set-selection 'CLIPBOARD content)
    (kill-new content)
    (set-buffer-modified-p nil)
    (let ((buffer (get-buffer "*clipboard*")))
      (when buffer
	(delete-window (get-buffer-window buffer))
        (kill-buffer buffer)
	(sync-clipboard-eaf))))
  (message "Clipboard updated!"))

(defun sync-clipboard-eaf ()
  (my-eaf-open-clipboard-url)
  (with-current-buffer (car (fuzzy-find-buffer "eaf-??è´´æ?¿æ?è¯?é¡µé??"))
    (my-eaf-exec-pycode "
f = open (\"/tmp/loop-paste-file.txt\")
content = f.read ()
f.close ()
content = repr (content)
self.set_clipboard_text(content)
content = f\"document.evaluate('/html/body/div/textarea', document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.value = {content}\"
print (content)
print (self.buffer_widget.execute_js (content))
click = \"document.evaluate('/html/body/div/button[3]', document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue.click()\"
print(click)
self.buffer_widget.execute_js (click)")))



(defun my-eaf-load-novnc-paste-js ()
  (my-eaf-exec-pycode "
import os
if not hasattr(self, 'novnc_paste_js'):
    f = open (os.path.expanduser('~') + '/' + '.emacs.d/hyj-emacs/eaf_novnc_paste.js')
    js = f.read ()
    f.close ()
    self.buffer_widget.execute_js (js)
    self.novnc_paste_js = 1
else:
    print('novnc_paste_js has load!')
")
  (sleep-for 0.2))

(defvar *my-eaf-browser-novnc-list* nil)

(defvar *my-eaf-browser-novnc-input* "")

(defun my-eaf-send-key ()
  "Directly send key to EAF Python side."
  (interactive)
  (let ((key  (key-description (this-command-keys-vector))))
					;(message "eaf-send-key %S" key)
    (if (and (or  (string-match-p "eaf-noVNC" (buffer-name (current-buffer)))
		  (string-match-p "KasmVNC" (buffer-name (current-buffer))))
	     (chinese-string-p key)
	     (or
	      (member eaf--buffer-id *my-eaf-browser-novnc-list*)
	      (= 1
		 (progn
		   (setq *my-eaf-pycode-result* 0)
		   (my-eaf-exec-pycode "ret = self.buffer_widget.execute_js('document.querySelector(\"canvas\");')
ret = 1 if ret is not None else 0
print(ret)
set_emacs_var('*my-eaf-pycode-result*', ret)")
		   (sleep-for 0.05)
		   *my-eaf-pycode-result*))))
	(progn
	  (when (not (member eaf--buffer-id *my-eaf-browser-novnc-list*))
	    (my-eaf-load-novnc-paste-js)
	    (add-to-list  '*my-eaf-browser-novnc-list*  eaf--buffer-id))
	  (setq *my-eaf-browser-novnc-input* (concat *my-eaf-browser-novnc-input* key))
	  (run-with-idle-timer
	   0.2
	   nil
	   (lambda ()
	     (when (> (length *my-eaf-browser-novnc-input*) 0)
	       (message "at %S %s" (current-buffer) *my-eaf-browser-novnc-input*)
	       (let ((input *my-eaf-browser-novnc-input*))
		 (setq *my-eaf-browser-novnc-input* "")
		 (my-eaf-exec-pycode
		  (format "
content = '%s'
content = f\"sendString ('{content}')\"
self.buffer_widget.execute_js (content)
" input))
					;(sleep-for 0.01)
		 ))))
	  (eaf-call-sync "send_key" eaf--buffer-id key))
      (eaf-call-sync "send_key" eaf--buffer-id key))))


(defun chinese-string-p (str)
  (and (stringp str)
       (> (length str) 0)
       (string-match-p "\\`[^\x00-\xff]+\\'" str)))

(defun eaf-send-key ()
  "Directly send key to EAF Python side."
  (interactive)
  (let ((key  (key-description (this-command-keys-vector))))
    ;(message "eaf-send-key %S" key)
    (eaf-call-sync "send_key" eaf--buffer-id key)))


(defun eaf-send-key ()
  "Directly send key to EAF Python side."
  (interactive)
  (my-eaf-send-key))


(when nil
					;test
  (with-current-buffer (car (fuzzy-find-buffer "Kube"))
    (my-eaf-exec-pycode (with-temp-buffer
			  (insert-file-contents "~/eaf_patch.py")
			  (buffer-string))))
  (with-current-buffer (car (fuzzy-find-buffer "Kube"))
    (my-eaf-exec-pycode (with-temp-buffer
			  (insert-file-contents "~/.emacs.d/hyj-emacs/eaf_browser_init.py")
			  (buffer-string))))

  (with-current-buffer (car (fuzzy-find-buffer "Kube"))
    (my-eaf-exec-pycode "message_to_emacs('caret_browsing_mode={}'.format(self.url))"))

  (with-current-buffer (car (fuzzy-find-buffer "Kube"))
    (my-eaf-exec-pycode *eaf-browser-init-pycode*)
    )
  (eaf--toggle-caret-browsing t)
  )


(when nil

  (with-current-buffer (car (fuzzy-find-buffer "kasm"))
    (my-eaf-exec-pycode "print(\":{}\".format(QT_KEY_DICT))"))

   (with-current-buffer (car (fuzzy-find-buffer "kasm"))
      (my-eaf-exec-pycode (with-temp-buffer
			    (insert-file-contents "~/.emacs.d/hyj-emacs/eaf_patch.py")
			    (buffer-string))))


  (progn
    (let* ((pyfile (concat  "~/.emacs.d/hyj-emacs/eaf_browser_init.py"))
	   (pycode (with-temp-buffer
		     (insert-file-contents pyfile)
		     (buffer-string))))
      (setq *eaf-browser-init-pycode* pycode))

    (with-current-buffer (car (fuzzy-find-buffer "kasm"))
      (my-eaf-exec-pycode (with-temp-buffer
			    (insert-file-contents "~/.emacs.d/hyj-emacs/eaf_browser_init.py")
			    (buffer-string)))))

  (progn
    (with-current-buffer (car (fuzzy-find-buffer "kasm"))
      (my-eaf-exec-pycode "self.my_send_key_press('<shift>')"))
    (sleep-for 0.5)

    (with-current-buffer (car (fuzzy-find-buffer "kasm"))
      (my-eaf-exec-pycode "self.my_send_key_press('S')"))
    (sleep-for 0.5)

    (with-current-buffer (car (fuzzy-find-buffer "kasm"))
      (my-eaf-exec-pycode "self.my_send_key_release('S')"))
    (sleep-for 0.5)

    (with-current-buffer (car (fuzzy-find-buffer "kasm"))
      (my-eaf-exec-pycode "self.my_send_key_release('<shift>')"))
    )


  (progn
    (with-current-buffer (car (fuzzy-find-buffer "kasm"))
      (my-eaf-exec-pycode "self.my_send_key_press('s')"))
    (sleep-for 0.5)


    (with-current-buffer (car (fuzzy-find-buffer "kasm"))
      (my-eaf-exec-pycode "self.my_send_key_release('s')"))
    )


  (progn
    (with-current-buffer (car (fuzzy-find-buffer "kasm"))
      (my-eaf-exec-pycode "self.my_send_key_press('<escape>')"))
    (sleep-for 0.5)


    (with-current-buffer (car (fuzzy-find-buffer "kasm"))
      (my-eaf-exec-pycode "self.my_send_key_release('<escape>')"))
    )

  )

(when nil
  (defun my-eaf--build-process-environment-disable-security (orig-func &rest args)
    "Wrap ORIG-FUNC to add QTWEBENGINE_CHROMIUM_FLAGS to the process environment."
    (let ((environments (apply orig-func args)))
      (when (eq system-type 'gnu/linux)
	(add-to-list 'environments "QTWEBENGINE_CHROMIUM_FLAGS=--disable-web-security" t))
      environments))

  (defun eaf-open-browser-nosafe (url &optional args)
    "Open EAF browser with security disabled for URL with optional ARGS.
This is intended as a quick fix, e.g., for Google login."
    (interactive "M[EAF/browser] URL: ")
    (advice-add 'eaf--build-process-environment :around #'my-eaf--build-process-environment-disable-security)
    (eaf-open (eaf-wrap-url url) "browser" args)
    (advice-remove 'eaf--build-process-environment #'my-eaf--build-process-environment-disable-security))

(eaf-open-browser-nosafe "https://aistudio.google.com/prompts/new_chat")
)


(when nil
  (progn
    (add-to-list 'load-path "~/.emacs.d/hyj-emacs/holo-layer")
    (require 'holo-layer)
    (setq holo-layer-enable-debug t)
    (setq holo-layer-enable-cursor-animation t)
    (holo-layer-enable)

    )
  )
