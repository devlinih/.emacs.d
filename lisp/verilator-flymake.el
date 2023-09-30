;;; verilator-flymake.el --- A verilator Flymake backend  -*- lexical-binding: t; -*-

;; Based on the sample ruby annotated backend example
;; https://www.gnu.org/software/emacs/manual/html_node/flymake/An-annotated-example-backend.html

(defvar-local verilator--flymake-proc nil)

(defun verilator-flymake (report-fn &rest _args)
  ;; Not having a verilator installed is a serious problem which should cause
  ;; the backend to disable itself, so an error is signaled.
  (unless (executable-find
           "verilator") (error "Cannot find a suitable verilator"))
  ;; If a live process launched in an earlier check was found, that
  ;; process is killed.  When that process's sentinel eventually runs,
  ;; it will notice its obsoletion, since it have since reset
  ;; `verilator-flymake-proc' to a different value

  (when (process-live-p verilator--flymake-proc)
    (kill-process verilator--flymake-proc))

  ;; Save the current buffer, the narrowing restriction, remove any
  ;; narrowing restriction.
  (let ((source (current-buffer)))
    (save-restriction
      (widen)
      ;; Reset the `verilator--flymake-proc' process to a new process
      ;; calling the verilator tool.
      (setq
       verilator--flymake-proc
       (make-process
        :name "verilator-flymake" :noquery t :connection-type 'pipe
        ;; Make output go to a temporary buffer.
        :buffer (generate-new-buffer " *verilator-flymake*")
        :command '("verilator" "--lint-only" "-Wall" "--quiet-exit")
        :sentinel
        (lambda (proc _event)
          ;; Check that the process has indeed exited, as it might
          ;; be simply suspended.
          ;;
          (when (memq (process-status proc) '(exit signal))
            (unwind-protect
                ;; Only proceed if `proc' is the same as
                ;; `verilator--flymake-proc', which indicates that
                ;; `proc' is not an obsolete process.
                (if (with-current-buffer source (eq proc verilator--flymake-proc))
                    (with-current-buffer (process-buffer proc)
                      (goto-char (point-min))
                      ;; Parse the output buffer for diagnostic's
                      ;; messages and locations, collect them in a list
                      ;; of objects, and call `report-fn'.
                      (cl-loop
                       while (search-forward-regexp
                              "^\\(?:.*.sv\\|-\\):\\([0-9]+\\): \\(.*\\)$"
                              nil t)
                       for msg = (match-string 2)
                       for (beg . end) = (flymake-diag-region
                                          source
                                          (string-to-number (match-string 1)))
                       for type = (if (string-match "^warning" msg)
                                      :warning
                                    :error)
                       collect (flymake-make-diagnostic source
                                                        beg
                                                        end
                                                        type
                                                        msg)
                       into diags
                       finally (funcall report-fn diags)))
                  (flymake-log :warning "Canceling obsolete check %s"
                               proc))
              ;; Cleanup the temporary buffer used to hold the
              ;; check's output.
              ;;
              (kill-buffer (process-buffer proc)))))))
      ;; Send the buffer contents to the process's stdin, followed by
      ;; an EOF.
      ;;
      (process-send-region verilator--flymake-proc (point-min) (point-max))
      (process-send-eof verilator--flymake-proc))))

(defun verilator-setup-flymake-backend ()
  (add-hook 'flymake-diagnostic-functions 'verilator-flymake nil t))

(add-hook 'verilog-mode-hook 'verilator-setup-flymake-backend)
