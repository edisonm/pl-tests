;; Author: Edison Mera Menendez
;; Hook to point at the given ERROR using one keystroke

(defun look-at-message ()
  (save-excursion 
    (let (error-filename error-line error-column)
      (search-backward-regexp "[^a-ZA-Z0-9\\/\._-]")
      (forward-char 1)
      (let ((beg (point)))
	(search-forward-regexp "[^a-ZA-Z0-9\\/\._-]")
	(backward-char 1)
	(setq error-filename (buffer-substring-no-properties beg (point))))
      (if (file-exists-p error-filename)
	  (let ()
            (search-forward-regexp "[ :]")
	    (let ((beg (point)))
	      (search-forward-regexp "[^0-9]")
	      (backward-char 1)
	      (setq error-line (string-to-number
				(buffer-substring-no-properties beg (point)))))
            (if (search-forward-regexp "[ :]")
                (let ()
                  (let ((beg (point)))
                    (search-forward-regexp "[^0-9]")
                    (backward-char 1)
                    (setq error-column (string-to-number
                                        (buffer-substring-no-properties beg (point)))))
                  (forward-char 1)))
	    ;; (if (get-file-buffer error-filename)
	    ;; 	(switch-to-buffer-other-window (get-file-buffer error-filename))
	    ;;   (find-file-other-window error-filename))
	    (find-file-other-window error-filename)
	    (goto-line error-line)
	    (move-to-column error-column)
	    ;; (message (concat "FILE=" error-filename
	    ;; 		     ", LINE=" (number-to-string error-line)
	    ;; 		     ", COLUMN=" (number-to-string error-column)))
	    )
	)
      )
    )
  )

(defun look-at-message-browse ()
  (let ((oldbuf (current-buffer)))
    (look-at-message)
    (switch-to-buffer-other-window oldbuf))
  )

(defun look-at-message-go ()
  (interactive)
  (look-at-message)
  )

(defun look-at-message-show ()
  (interactive)
  (look-at-message-browse)
  )

(defun look-at-message-next ()
  (interactive)
  (look-at-message-browse)
  (next-line)
  )

(defun look-at-message-previous ()
  (interactive)
  (look-at-message-browse)
  (previous-line)
  )

(global-set-key "\C-c`" 'look-at-message-show)
(global-set-key "\C-cg" 'look-at-message-go)
(global-set-key "\C-cn" 'look-at-message-next)
(global-set-key "\C-cp" 'look-at-message-previous)
