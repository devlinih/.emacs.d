;; dates.el --- Devlin Ih's silly commands to insert dates -*- lexical-binding: t; -*-

;;; Maybe I should have a macro that you input an alist of (NAME . FORMAT) and
;;; it generates all these functions. If I ever need a ton of formats I might
;;; do that idk.

(defun dih/date-format-string (date-format)
  "Return date format string in DATE-FORMAT"
  (cond ((string= date-format "ISO")       "%Y-%m-%d")
        ((string= date-format "USA Short") "%m/%d/%Y")
        ((string= date-format "USA Long")  "%B %e, %Y")))


(defun dih/insert-date (date-format)
  "Insert current date.

If running interactively, prompts for a desired format."
  (interactive
   (list (completing-read "Date Format: " '("USA Long" "USA Short" "ISO"))))
  (insert (format-time-string (dih/date-format-string date-format))))


(defun dih/insert-date-iso ()
  "Insert ISO date YYYY-MM-DD"
  (dih/insert-date "ISO"))


(defun dih/insert-date-usa-short ()
  "Insert USA date MM/DD/YYYY"
  (dih/insert-date "USA Short"))


(defun dih/insert-date-usa-long ()
  "Insert USA date Month Day, YYYY"
  (dih/insert-date "USA Long"))
