;;;  -*- coding: utf-8; mode: emacs-lisp; -*-
;;; puppet-pi-mode.el

;; Author: t9md <taqumd -at- gmail.com>
;; Keywords: puppet
;; Prefix: puppet-pi

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;; 
;; Puppet ( http://www.puppetlabs.com/ ) provides command line documentation
;; reference tool called `pi' from version 0.25.
;; puppet-pi-mode enable you to query `type' documentation from emacs buffer.
;; 
;; Tested on Emacs 22

;;; Customizable Options:
;; 
;; if you don't want select pi-buffer , set below
;; (setq puppet-pi-disable-select-window t)
;;

;;; Sample config:
;; 
;; (require 'puppet-pi-mode)
;; (add-hook 'puppet-mode-hook
;; 		  (lambda ()
;; 			(local-set-key "\C-c\C-d" 'puppet-pi-query)))
;; 
;; then you can search pi from emacs puppet-mode buffer with C-cC-d.
;;

;;; Todo:
;; Setup pi query keywords from the resoult of 'pi --list'.
;; Cache the result of pi query.

(defvar puppet-pi-disable-select-window nil
  "*Option to disable to select other window.")


(require 'font-lock)

(defconst puppet-pi-buffer-name "*puppet-pi*"
  "buffer name which result apear")

(defvar puppet-pi-disable-select-window nil
  "*Option to disable to select other window.")

(defvar puppet-pi-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "q" 'puppet-pi-close-window)
    (define-key map "s" 'puppet-pi-query)	
    map)
  "Key map used in puppet-pi-mode buffers.")

(defun puppet-pi-query ()
  "query for word with pi"
  (interactive)
  (let ((query
		 (completing-read
		  "Which type? "
		  (list "augeas" "computer" "cron" "exec" "file" "filebucket" "group" "host" "k5login"
				"macauthorization" "mailalias" "maillist" "mcx" "mount" "nagios_command" "nagios_contact" "nagios_contactgroup"
				"nagios_host" "nagios_hostdependency" "nagios_hostescalation" "nagios_hostextinfo" "nagios_hostgroup" "nagios_service"
				"nagios_servicedependency" "nagios_serviceescalation" "nagios_serviceextinfo" "nagios_servicegroup" "nagios_timeperiod"
				"notify" "package" "resources" "schedule" "selboolean" "selmodule" "service" "ssh_authorized_key" "sshkey" "tidy" "user"
				"yumrepo" "zfs" "zone" "zpool")  nil t ))
		(pi-buf (get-buffer-create puppet-pi-buffer-name)))
	(set-buffer pi-buf)
	(puppet-pi-mode)
	(setq buffer-read-only nil)
	(erase-buffer)
	(call-process "pi" nil puppet-pi-buffer-name t query "-p")
	(setq buffer-read-only t)
	(goto-char (point-min))
	(font-lock-fontify-buffer)
	(puppet-pi-display-buffer)))

(defun puppet-pi-display-buffer ()
  "display pi result"
  (unwind-protect
	  (let* ((buf (set-buffer puppet-pi-buffer-name))
			 (w1 (selected-window))
			 (w2 (get-buffer-window buf)))
		(if w2
			(select-window w2)
		  (setq w2 (select-window
					(if (one-window-p)
						(split-window w1)
					  (next-window))))
		  (set-window-buffer w2 buf))
		(if puppet-pi-disable-select-window (select-window w1)))))

(defun puppet-pi-close-window ()
  "delete window"
  (interactive)
  (let ((w (get-buffer-window puppet-pi-buffer-name))
		(b (get-buffer puppet-pi-buffer-name))
		)
    (if w
		(progn
		  (bury-buffer b)
		  (set-window-buffer w (other-buffer))
		  (select-window (next-window))))))

(setq puppet-pi-font-lock-keywords
	  (list
	   '("\\(Parameters\\|Providers\\)?\n-+$"
		 0 font-lock-function-name-face)
	   '("\\(\\*\\*.*\\*\\*\\)"
		 1 font-lock-variable-name-face)
	   '("``\\(.*?\\)``"
		 1 font-lock-keyword-face)	
	   '(".*?\n=+$"
		 0 font-lock-warning-face)))

(defun puppet-pi-mode ()
  (interactive)
  (setq mode-name "Puppet-pi")
  (setq major-mode 'puppet-pi-mode)
  (or (boundp 'font-lock-variable-name-face)
      (setq font-lock-variable-name-face font-lock-type-face))
  (set (make-local-variable 'font-lock-keywords) puppet-pi-font-lock-keywords)
  (set (make-local-variable 'font-lock-multiline) t)
  (set (make-local-variable 'font-lock-defaults)
       '((puppet-pi-font-lock-keywords) nil nil))
  (use-local-map puppet-pi-mode-map)
  (run-hooks 'puppet-pi-mode-hook))

(provide 'puppet-pi-mode)
