(defpackage :wpctl
  (:use #:cl :stumpwm #:parse-float)
  (:export #:init
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
           #:*check-interval*
           #:*default-sink-id*
           #:*default-source-id*
           #:*mixer-command*
           #:*wpctl-path*
           #:*step*
           #:*modeline-fmt*
           #:*source-modeline-fmt*))
