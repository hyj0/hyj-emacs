
(setenv "LIBGL_ALWAYS_SOFTWARE" "1")

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
	 ((string-match-p "a" "0123456789")
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

(global-set-key (kbd "<f3>") 'eaf-open-browser-with-history)

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
  (completing-read "select:" lst))


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

(defun eaf-translate-text-long (text)
  (with-temp-buffer
    ;(insert "<meta name='google' content='notranslate'/>")
    (insert text)
    (write-region (point-min) (point-max) "/tmp/eaf-translate.txt" nil 'no-message))
  (let ((res (shell-command-to-string "proxychains crow -t 'zh' --j -e 'bing' -f /tmp/eaf-translate.txt 2>/dev/null ")))
    (let ((transed (my-assoc 'translated-text (json-read-from-string res))))
      (with-temp-buffer
	(insert transed)
	(kill-ring-save (point-min) (point-max))
	)
      (tooltip-show (format "%s" transed))
      transed)))

(defun eaf-translate-text (text)
  (if (length> text 20)
      (eaf-translate-text-long text)
    (eaf-translate-text-short text)))


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
