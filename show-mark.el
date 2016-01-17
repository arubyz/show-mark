;;; show-mark.el --- Global minor mode to indicate the mark in the fringe with an arrow

;; Copyright (C) 2016 <arubyz@gmail.com>

;; Author: <arubyz@gmail.com>
;; Keywords: convenience, frames

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Defines `show-mark-mode', a global minor mode for graphical Emacs.  When
;; enabled, this mode shows a custom arrow bitmap in the fringe of every window
;; which can show it.  This arrow is set (via `post-command-hook') to the
;; current location of `mark' in the buffer shown in each window.
;;
;; To use:
;;  (require 'show-mark)
;;  (show-mark-mode +1)
;;
;; Inspired by:
;; - http://www.emacswiki.org/emacs/TheFringe
;; - http://www.emacswiki.org/emacs/FringeMark
;; - https://github.com/milkypostman/fringemark

;;; Code:

(require 'cl-lib)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Customizations
;;

(defgroup show-mark-mode ()
"Customization group for global minor mode `show-mark-mode'")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Public interface
;;

;;;###autoload
(define-minor-mode show-mark-mode
  ;; The default docstring is good enough
  nil
  
  ;; This mode doesn't need a mode-line indicator string
  :lighter nil

  ;; Customization group
  :group 'show-mark-mode

  ;; The mode is global
  :global t
  
  ;; When turning the mode on ...
  (when (bound-and-true-p show-mark-mode)
    (unless window-system
      (error "show-mark-mode requires graphical frames"))
    (show-mark:-update-all-markers)
    (add-hook 'post-command-hook 'show-mark:-update-current-marker))

  ;; When turning the mode off ...
  (unless (bound-and-true-p show-mark-mode)
    (remove-hook 'post-command-hook 'show-mark:-update-current-marker)
    (show-mark:-kill-all-markers)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Internals
;;

;; Marker variable to track our custom fringe arrow
(add-to-list 'overlay-arrow-variable-list
             (defvar-local *show-mark:-bol-marker nil
"Marker for `point-at-bol' starting at `mark', local to each buffer."))

;; Custom fringe arrow bitmap
(put '*show-mark:-bol-marker 'overlay-arrow-bitmap
     (define-fringe-bitmap 'show-mark:-hollow-right-arrow
       [128 192 96 48 24 48 96 192 128]
       9 8 'center))

(cl-defun show-mark:-update-current-marker ()
"Updates the current buffer's value of `*show-mark:-bol-marker' based on the
current value of `mark'."
  (unless (or (minibufferp)
              (not (mark))
              (zerop (fringe-columns 'left)))
    (let ((mark-bol (save-excursion
                      (goto-char (mark))
                      (point-at-bol))))
      (if (markerp *show-mark:-bol-marker)
          (set-marker *show-mark:-bol-marker mark-bol)
        (setq *show-mark:-bol-marker (save-excursion
                                       (goto-char mark-bol)
                                       (point-marker)))))))

(cl-defun show-mark:-update-all-markers ()
"Updates the value of `*show-mark:-bol-marker' in all buffers."
  (cl-loop for buffer being the buffers
           do (with-current-buffer buffer
                (show-mark:-update-current-marker))))

(cl-defun show-mark:-kill-all-markers ()
"Clears the value of `*show-mark:-bol-marker' in all buffers."
  (cl-loop for buffer being the buffers
           do (with-current-buffer buffer
                (setq *show-mark:-bol-marker nil))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(provide 'show-mark)
;;; show-mark.el ends here

