;; buffer-file.el --- Devlin Ih's commands to copy buffer file names -*- lexical-binding: t; -*-
(defun dih/get-absolute-buffer-path ()
  "Show full file path of current buffer and add to kill ring."
  (interactive)
  (let ((file-path (buffer-file-name)))
    (message file-path)
    (kill-new file-path)))

(defun dih/get-absolute-buffer-path-of (buffer)
  "Prompt for buffer, show its full file path and add it to kill ring."
  (interactive "b")
  (let ((file-path (buffer-file-name (get-buffer buffer))))
    (message file-path)
    (kill-new file-path)))
