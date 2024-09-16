
(defun my-eaf-term-select-buffer ()
  (if (and (eq 'eaf-mode major-mode) (string= "EAF/pyqterminal" mode-name))
      (buffer-name)
    (completing-read "term:" (delq nil (mapcar (lambda (b)
						 (with-current-buffer b
						   (if (and (eq 'eaf-mode major-mode) (string= "EAF/pyqterminal" mode-name))
						       (buffer-name b)
						     nil)))
					       (buffer-list))))))

(defun my-eaf-term-transfer-load ()
  (with-current-buffer (my-eaf-term-select-buffer)
    (my-eaf-exec-pycode (read-file-content "~/.emacs.d/hyj-emacs/my_eaf_term.py"))))

(defun my-eaf-term-transfer-select-file ()
  (setq *my-eaf-term-transfer-select-file* nil)
  (let ((file (read-file-name "Fselect file:")))
    (setq *my-eaf-term-transfer-select-file* file)))

(defun my-eaf-term-sendfile-to-remote ()
  (interactive)
  (with-current-buffer (my-eaf-term-select-buffer)
    (my-eaf-term-transfer-load)
    (my-eaf-term-transfer-select-file)
    (eaf-call-sync "send_key" eaf--buffer-id "trz -b\n")))

(when nil
  (my-eaf-term-transfer-load)
  (my-eaf-term-sendfile-to-remote)
  (with-current-buffer (my-eaf-term-select-buffer)
    (my-eaf-exec-pycode "eval_in_emacs('read-file-name', [\"file\"])\nprint(11112)"))
  (with-current-buffer (my-eaf-term-select-buffer)
    (my-eaf-exec-pycode "print('{}'.format (self.buffer_widget.backend.pty.trans_file.deal_data('abd')))"))
  (with-current-buffer (my-eaf-term-select-buffer)
    (eaf-call-async "send_key" eaf--buffer-id "ls \n"))
  )
