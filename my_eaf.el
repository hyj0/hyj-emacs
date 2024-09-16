
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


(add-hook 'eaf-mode-hook
	  (lambda ()
	    (message "eaf-mode-hook !! mode=%s"
		     (symbol-name major-mode))
	    (evil-local-mode -1)
	    )
	  )


(require 'evil)
(add-to-list 'evil-emacs-state-modes 'eaf-mode)

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
      (setq name (concat name "-" (url-host (url-generic-parse-url (eaf-get-path-or-url))) ":" (format "%d" (url-port (url-generic-parse-url (eaf-get-path-or-url))))))))
  (when t
    (funcall org-fun name un))
  )

(concat "" (format "%d" (url-port (url-generic-parse-url "https://note.youdao.com/web/#/file/recent/note/WEBc0834d1bc3a0f1f39c8f6e1b4f5781c1/" ))))

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

(eaf-create-send-sequence-function "ctrl-v" "C-v")

(eaf-bind-key eaf-send-ctrl-v-sequence "C-v" eaf-browser-keybinding)

;(eaf-open-browser "https://duckduckgo.com")

(setq eaf-browser-enable-autofill t)


(defun my-eaf-c-c-copy (&rest args)
  (interactive)
  (message "C-c")
  (my-eaf-exec-pycode "self.copy_text()")
  )
(eaf-bind-key my-eaf-c-c-copy "C-c" eaf-browser-keybinding)

(let* ((pyfile (concat  "~/.emacs.d/hyj-emacs/eaf_browser_init.py"))
       (pycode (with-temp-buffer
		  (insert-file-contents pyfile)
		  (buffer-string))))
  (setq *eaf-browser-init-pycode* pycode))


(eaf-bind-key my-eaf-c-c-copy "C-h" eaf-browser-keybinding)

(global-set-key (kbd "<f4>") 'eaf-open-browser-with-history)

(defun kill-all-eaf-buffer ()
  (interactive)
  (dolist (one (fuzzy-find-buffer ""))
    (with-current-buffer one
      (when (eq major-mode 'eaf-mode)
	(kill-buffer one)))))

(when nil
;test
  (with-current-buffer (car (fuzzy-find-buffer "Kube"))
    (my-eaf-exec-pycode (with-temp-buffer
			  (insert-file-contents "~/eaf_patch.py")
			  (buffer-string))))

  (with-current-buffer (car (fuzzy-find-buffer "Kube"))
    (my-eaf-exec-pycode "message_to_emacs('caret_browsing_mode={}'.format(self.url))"))

  (with-current-buffer (car (fuzzy-find-buffer "Kube"))
    (my-eaf-exec-pycode *eaf-browser-init-pycode*)
    )
  (eaf--toggle-caret-browsing t)
  )
