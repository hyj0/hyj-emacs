;
(require 'org)
(require 'ox-md nil t)
(require 'appt)

(setq org-confirm-babel-evaluate nil)

(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . t)
   (python . t)
   (shell . t)
   (C . t)
   (sql . t)
   (sqlite . t)
   (js . t)
   (http . t)
   (java . t)
   (mysql . t)
   ))

(define-key org-mode-map (kbd "<f5>") 'org-ctrl-c-ctrl-c)


(add-hook 'org-mode-hook 'visual-line-mode)

(defun my-eaf-org-preview ()
  (interactive)
  ;get current buffer file path
  (let ((file-path (buffer-file-name)))
    (if file-path
	(progn
	  ;(my-window-record)
          (eaf-open file-path))
      (message "Buffer not visiting a file")))
  )

(evil-define-key 'normal org-mode-map (kbd "<tab>") 'org-cycle)

(defun my-org-add-src ()
  (interactive)
  (let ((lang (completing-read "lang:" (mapcar (lambda (l)
						  (format "%S" (car l)))
						org-babel-load-languages))))
    (insert (format "#+begin_src %s\n\n#+end_src" lang))
    ;point to pre line
    (forward-line -1)))


(require 'swagg)

(setq swagg-rest-block-prelude "#+begin_src http :pretty json\n")
(setq swagg-rest-block-postlude "\n#+end_src")

(require 'org-id)
(setq org-id-link-to-org-use-id t)
(message "my_org loaded")


(eval-after-load "org"
  '(require 'ox-md nil t))



;; 议程文件路径
(setq org-agenda-files '("~/agenda.org"))

;; 启用 appt 提醒
(appt-activate t)
(setq appt-time-msg-list nil)
(org-agenda-to-appt)
(add-hook 'org-finalize-agenda-hook 'org-agenda-to-appt)
(run-at-time t 60 'appt-check)

(defun my-xml-format-buffer ()
  "格式化XML buffer"
  (interactive)
  (shell-command-on-region (point-min) (point-max)
                           "xmllint --format -" nil t))
