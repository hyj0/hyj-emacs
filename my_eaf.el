
(setenv "LIBGL_ALWAYS_SOFTWARE" "1")

(add-to-list 'load-path "~/.emacs.d/site-lisp/emacs-application-framework/")
(require 'eaf)

(when t
  (setq eaf-proxy-type "http")
  (setq eaf-proxy-host "127.0.0.1")
  (setq eaf-proxy-port "8118"))

(setq eaf-enable-debug t)
(setq eaf-browser-translate-language "zh")
(setq eaf-browser-continue-where-left-off t)
(setq eaf-browser-default-search-engine "duckduckgo")
(setq eaf-browse-blank-page-url "https://duckduckgo.com")


(require 'eaf-git)
(require 'eaf-system-monitor)
(require 'eaf-mindmap)
(require 'eaf-map)
(require 'eaf-js-video-player)
(require 'eaf-markmap)
(require 'eaf-org-previewer)
(require 'eaf-demo)
(require 'eaf-airshare)
(require 'eaf-music-player)
(require 'eaf-markdown-previewer)
(require 'eaf-jupyter)
(require 'eaf-file-browser)
(require 'eaf-video-player)
(require 'eaf-file-manager)
(require 'eaf-pyqterminal)
(require 'eaf-vue-tailwindcss)
(require 'eaf-image-viewer)
(require 'eaf-terminal)
(require 'eaf-vue-demo)
(require 'eaf-netease-cloud-music)
(require 'eaf-pdf-viewer)
(require 'eaf-camera)
(require 'eaf-2048)
(require 'eaf-browser)
(require 'eaf-file-sender)

(add-hook 'eaf-mode-hook
	  (lambda ()
	    (message "eaf-mode-hook !! mode=%s"
		     (symbol-name major-mode))
	    (evil-local-mode -1)
	    )
	  )


(require 'evil)
(add-to-list 'evil-emacs-state-modes 'eaf-mode)

(eaf-create-send-sequence-function "ctrl-v" "C-v")
(eaf-create-send-sequence-function "ctrl-c-ctrl-c" "C-c C-c")

(eaf-bind-key eaf-send-ctrl-v-sequence "C-v" eaf-browser-keybinding)
(eaf-bind-key eaf-send-ctrl-c-ctrl-c-sequence "C-c" eaf-browser-keybinding)

;(eaf-open-browser "https://duckduckgo.com")


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

(defun my-rename-buffer (org-fun name &optional un)
  (message "rename buffer %S to %S" (buffer-name) name)
  (when (eq major-mode 'eaf-mode)
    (setq name (concat "eaf-" name)))
  (when t
    (funcall org-fun name un))
  )

(advice-add 'rename-buffer :around #'my-rename-buffer)
;(advice-remove 'rename-buffer 'my-rename-buffer)
