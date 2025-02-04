(require 'company)

(defvar *my-company-prefix* nil)

(defun my-company-capf-around (org-fun command &optional arg &rest _args)
  ;(message "my-company-capf-around=%s %s %s" command arg _args)
  (let ((ret (apply org-fun command arg _args)))
    ;(message "my-company-capf-around ret=%s" ret)
    ret))

(defun my-company-capf-around (org-fun command &optional arg &rest _args)
					;(message "my-company-capf-around=%s %s %s" command arg _args)
  (let ((ret (funcall org-fun command arg _args)))
					;(message "my-company-capf-around ret=%s" ret)
    (if (and  (eq 'prefix command) (not (eq nil  ret)) (not (eq ret 'stop))
	      (not  (eq major-mode 'scheme-mode)) (not (eq major-mode 'c-mode)) (not (eq major-mode 'c++-mode)))
	(let ((ret1 (add-star-between-str ret)))
	  (message "prefix %s-->%s" ret ret1)
	  (setq *my-company-prefix* (list ret ret1))
	  ret1)
      ret)))


(advice-add 'company-capf :around #'my-company-capf-around)
(advice-add 'company-dabbrev-code :around #'my-company-capf-around) ;for scm
(advice-remove 'company-dabbrev-code  'my-company-capf-around)

(debug-on-entry 'my-company-capf-around)
(cancel-debug-on-entry 'my-company-capf-around)


(defun my-company--insert-candidate (candidate)
  (when (> (length candidate) 0)
    (setq candidate (substring-no-properties candidate))
    ;; XXX: Return value we check here is subject to change.
    (if (eq (company-call-backend 'ignore-case) 'keep-prefix)
        (insert (company-strip-prefix candidate))
      (unless (equal company-prefix candidate)
	(message "company-prefix=%s" company-prefix)
	(if (eq nil *my-company-prefix*)
	    (delete-region (- (point) (length company-prefix)) (point))
          (delete-region (- (point) (length (car *my-company-prefix*))) (point)))
	(setq *my-company-prefix* nil)
        (insert candidate)))))

(defun my-company--insert-candidate-around (org-fun &rest _args)
  (message "my-company--insert-candidate-around=%s prefix=%s" _args (prin1-to-string *my-company-prefix*))
  (if (and  *my-company-prefix* (stringp (car *my-company-prefix*)))
      (progn
	(apply 'my-company--insert-candidate _args)
	(setq *my-company-prefix* nil))
    (let ((ret (apply org-fun  _args)))
      (message "my-company--insert-candidate-around ret=%s" ret)
      ret)))

(advice-add 'company--insert-candidate :around #'my-company--insert-candidate-around)

(debug-on-entry 'company--insert-candidate)
(cancel-debug-on-entry 'company--insert-candidate)



(defun my-string-len< (x y)
  "Like `string<', but operate on CARs when given cons cells."
  ;(message "my-string-len< x=%S y=%S" x y)
  (let ((len-x (length x))
	(len-y (length y)))
    (if (= len-x len-y)
	(ivy-string< x y)
      (< len-x len-y))))

(when nil
   (cond ((< len-x len-y) -1)
	    ((> len-y len-x) 1)
	    (t (string< x y))
	    ))

;org
(setq ivy-sort-functions-alist
	     '((read-file-name-internal . ivy-sort-file-function-default)
	       (t . my-string-len<)))

(setq ivy-sort-functions-alist
      '((t . my-string-len<)))


(setq ivy-sort-functions-alist
      '((execute-extended-command . my-string-len<)
	(describe-function . my-string-len<)
	(t . my-string-len<)))
;(setq completing-read-function 'ivy-completing-read)


					;(ivy-read "Select a letter: " '("bb" "c" "a") :sort t)
					;(ivy-read "Select a letter: " '("bb" "c" "a") :sort #'my-string-len<)

(setq company-minimum-prefix-length 6)

(defun my-company-trans (lst)
  (sort lst 'my-string-len<))

(setq company-transformers '(my-company-trans))

(when (not (fboundp 'string-replace))
  (defun string-replace (what with in)
    (replace-regexp-in-string (regexp-quote what) with in nil 'literal)))


(defun add-star-between-str (str)
  (if (stringp str)
      (let ((ret
	     (mapconcat
	      'identity
	      (split-string str "" t) "*")))
	(message "ret=%s" ret)
	(if (or (= 1 (length ret))
		(and (> (length ret) 0) (string-equal "/" (substring ret 0 1))))
	    ret
	  (concat "*" (string-replace "**" "*" (string-replace "***" "*" ret)))))
    str))

(when (os-is-linux)
    (with-eval-after-load 'eglot
      (add-to-list 'eglot-server-programs
		   '(scheme-mode . ("scheme" "--script" "/data/projector/CLionProjects/scheme-langserver/run.ss" "/data/projector/scheme-langserver.log"))
		   )))

(require 'eglot)
(when (os-is-linux)
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs
		 (cons 'c++-mode  (split-string "sudo docker exec -i lsp-docker ccls"))
		 ;(cons 'c++-mode (split-string "/data/projector/clion-2023.1.6/bin/clion.sh lsp-server ."))
		 ;(cons 'c++-mode '("127.0.0.1" 8989))
		 )))
(when (os-is-linux)
  (with-eval-after-load 'eglot
    (add-to-list 'eglot-server-programs
		 (cons 'c-mode  (split-string "sudo docker exec -i lsp-docker ccls"))
		 ;(cons 'c-mode (split-string "/data/projector/clion-2023.1.6/bin/clion.sh lsp-server ."))
		 ;(cons 'c-mode '("127.0.0.1" 8989))
		 )))
(require 'ivy-posframe)
(ivy-posframe-mode 1)


(when t
  (setq tramp-ssh-controlmaster-options "-o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -o ProxyCommand='nc -X 5 -x 127.0.0.1:1080 %%h %%p'")
					;tramp complete in eshell
  (defun my-complete-tramp-authinfo ()
    (interactive)
    (let ((sp  (mapcar (lambda (one) (format "/%s:%s@%s:~/" (plist-get one :port) (plist-get one :user) (plist-get one :host)))  (auth-source-search :max 1000 ))))
      (insert  (completing-read "authinfo:" sp))))
  (add-hook 'eshell-mode-hook
	    (lambda ()
	      (eshell/alias "ll" "ls -al")))
  )
