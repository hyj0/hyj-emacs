
(defun my-database-init ()
  (when (not (fuzzy-find-buffer "eaf-demo"))
    (let ((buff-name (buffer-name)))
      (eaf-open-demo)
      (switch-to-buffer buff-name)))
  (my-database-exec-pycode (with-temp-buffer
			     (insert-file-contents "~/.emacs.d/hyj-emacs/my_database.py")
			     (buffer-string))))

(defun my-database-get-connect-info ()
  (my-database-exec-pycode "message_to_emacs('{}'.format(self.database))"))

(defun my-database-connect (host port user passwd database)
  (let ((key (format "%s-%d-%s-%s" host port user database)))
    (my-database-exec-pycode (concat "import mysql.connector\n"
				     "from mysql.connector import Error\n"
				     (format "self.database[%S]=mysql.connector.connect(host=%S, port=%d, user=%S, password=%S, database=%S)" key host port user passwd database)))
    ;(my-database-exec-pycode (format "message_to_emacs('{}'.format(self.database[%S]))" key))
    key
    )
  )


(defun my-database-exec-pycode (pycode)
  (with-current-buffer "eaf-demo"
    (my-eaf-exec-pycode pycode)))

(defun my-assoc (name obj)
  (cdr (assoc name obj)))

(defun my-database-query-sql (key sql)
  (setq *db_key* key)
  (setq *db_sql* sql)
  (setq *db_result* nil)
  (my-database-exec-pycode (concat "self.db_query()"))
  ;(sleep-for 0 1000)
  (while (not *db_result*)
    (sit-for 0.2))
  (let ((res (json-read-from-string (if t
					(with-temp-buffer
					  (insert-file-contents "/tmp/db_result.json")
					  (buffer-string))
				      *db_result*))))
    (when (not (= 0 (my-assoc 'code res)))
      (error (format "query err:%s" (my-assoc 'msg res))))
    (my-assoc 'data res))
  )

(defun my-database-query-sql2 (key sql)
  (my-assoc 'rows (my-database-query-sql key sql)))


(defun my-database-query-sql2l (key sql)
  "return list as rows"
  (mapcar (lambda (row) row) (my-assoc 'rows (my-database-query-sql key sql))))


(defvar *my-eaf-command* "")
(defvar *my-eaf-pycode-result* nil)

(defun my-eaf-run-command (cmd)
  (my-database-init)
  (setq *my-eaf-command* cmd)
  (setq *my-eaf-pycode-result* nil)
  (my-database-exec-pycode (with-temp-buffer
			     (insert-file-contents (concat (my-home-dir) "my_eaf_command.py"))
			     (buffer-string)))
  (while (not *my-eaf-pycode-result*)
    (sleep-for 0.3))
  *my-eaf-pycode-result*)



(defun eaf-open-office (file)
  "View Microsoft Office FILE as READ-ONLY PDF."
  (interactive "f[EAF/office] Open Office file as PDF: ")
  (if (executable-find "libreoffice")
      (let* ((file-md5 (eaf-get-file-md5 file))
             (basename (file-name-base file))
             (pdf-file (format "/tmp/%s.pdf" file-md5))
             (pdf-argument (format "%s.%s_office_pdf" basename (file-name-extension file))))
        (if (file-exists-p pdf-file)
            (eaf-open pdf-file "pdf-viewer" pdf-argument)
          (message "Converting %s to PDF, EAF will start shortly..." file)
	  (let ((cmd-ret (my-eaf-run-command (concat (mapconcat (lambda (s)
								  (format "%s " s))
								(list "libreoffice" "--headless" "--convert-to" "pdf" (format "'%s'" (file-truename file)) "--outdir" "/tmp"))
						     "\n"))))
            (if (= cmd-ret 0)
		(progn
		  (rename-file (format "/tmp/%s.pdf" basename) pdf-file)
		  (eaf-open pdf-file "pdf-viewer" pdf-argument))
	      (error "run cmd err ret=%d" cmd-ret)
              ))))
    (error "[EAF/office] libreoffice is required convert Office file to PDF!")))



(when nil
  (my-database-init)
  (setq key (my-database-connect "127.0.0.1" 3309 "root" "123456" "test"))
  (my-database-get-connect-info)
  (setq res (my-database-query-sql key "select * from retailer limit 3"))
  (setq res (my-database-query-sql key "select * from retailer_ext limit 1"))
  (cdr (assoc 'retailer_id (aref (cdr (assoc 'rows (cdr (assoc 'data res)))) 0)))
  )
