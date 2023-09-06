(asdf:defsystem #:wpctl
  :description "PipeWire (WirePlumber) volume and microphone control module for StumpWM"
  :author "Dmitrii Kosenkov"
  :license  "GPLv3"
  :version "0.1.0"
  :serial t
  :depends-on (#:stumpwm #:parse-float #:cl-ppcre)
  :components ((:file "package")
               (:file "wpctl")))
