;; Don't use straight on Windows
(unless (equal system-type 'windows-nt)
  (setq package-enable-at-startup nil))

