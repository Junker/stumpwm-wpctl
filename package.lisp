(defpackage :wpctl
  (:use #:cl :stumpwm #:parse-float)
  (:export #:*default-sink-id*
           #:*default-source-id*
           #:volume-up
           #:volume-down
           #:set-volume
           #:get-volume
           #:get-mute
           #:mute
           #:unmute
           #:toggle-mute
           #:modeline
           #:ml-bar
           #:ml-volume
           #:*step*
           #:*modeline-fmt*
           #:*source-modeline-fmt*))
