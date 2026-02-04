(in-package :wpctl)

;; formatters.
(add-screen-mode-line-formatter #\P 'modeline)
;; (add-screen-mode-line-formatter #\M 'source-modeline)

(defparameter *step* 5)
(defparameter *check-interval* 1)

(defparameter *modeline-fmt* "%b(%v)"
  "The default value for displaying wpctl information on the modeline")

(defparameter *source-modeline-fmt* "%b(%v)"
  "The default value for displaying wpctl source information on the modeline")

(defparameter *formatters-alist*
  '((#\b  ml-bar)
    (#\v  ml-volume)))

(defparameter *wpctl-path* "/usr/bin/wpctl")
(defparameter *mixer-command* "pavucontrol")

(defparameter *default-sink-id* "@DEFAULT_AUDIO_SINK@")
(defparameter *default-source-id* "@DEFAULT_AUDIO_SOURCE@")

(defvar *default-sink-volume*)
(defvar *default-sink-mute*)
(defvar *default-source-volume*)
(defvar *default-source-mute*)

(defvar *volume-regex* (ppcre:create-scanner "Volume: (\\d+\\.\\d+)"))
(defvar *mute-regex* (ppcre:create-scanner "Volume: \\d+\\.\\d+ \\[MUTED\\]"))

(defun run (args &optional (wait-output nil))
  (if wait-output
      (with-output-to-string (s)
        (sb-ext:run-program *wpctl-path* args :wait t :output s))
      (sb-ext:run-program *wpctl-path* args :wait nil)))

(defun volume-up (device-id step)
  (run (list "set-volume" device-id (format nil "~D%+" step))))

(defun volume-down (device-id step)
  (run (list "set-volume" device-id (format nil "~D%-" step))))

(defun set-volume (device-id value)
  (run (list "set-volume" device-id (format nil "~D%" value))))

(defun get-volume (device-id)
  (truncate (* 100 (parse-float (aref (nth-value 1
                                                 (ppcre:scan-to-strings *volume-regex*
                                                                        (run (list "get-volume" device-id) t)))
                                      0)))))

(defun get-mute (device-id)
  (and (ppcre:scan *mute-regex*
                   (run (list "get-volume" device-id) t))
       t))

(defun unmute (device-id)
  (run (list "set-mute" device-id "0")))

(defun mute (device-id)
  (run (list "set-mute" device-id "1")))

(defun toggle-mute (device-id)
  (run (list "set-mute" device-id "toggle")))

(defun open-mixer ()
  (run-shell-command *mixer-command*))

(defun ml-bar (volume muted)
  (concat "\["
          (stumpwm:bar (if muted 0 (min 100 volume)) 5 #\X #\=)
          "\]"))

(defun ml-volume (volume muted)
  (if muted "MUT" (format nil "~a\%" volume)))


(defun modeline (ml)
  (declare (ignore ml))
  (let ((ml-str (format-expand *formatters-alist*
                               *modeline-fmt*
                               *default-sink-volume* *default-sink-mute*)))
    (if (fboundp 'stumpwm::format-with-on-click-id) ;check in case of old stumpwm version
        (format-with-on-click-id ml-str :ml-wpctl-on-click nil)
        ml-str)))

(defun source-modeline (ml)
  (declare (ignore ml))
  (let ((ml-str (format-expand *formatters-alist*
                               *source-modeline-fmt*
                               *default-source-volume* *default-source-mute*)))
    (if (fboundp 'stumpwm::format-with-on-click-id) ;check in case of old stumpwm version
        (format-with-on-click-id ml-str :ml-wpctl-source-on-click nil)
        ml-str)))

(defun update-sink-volume ()
  (setf *default-sink-volume* (get-volume *default-sink-id*)))

(defun update-sink-mute ()
  (setf *default-sink-mute* (get-mute *default-sink-id*)))

(defun update-source-volume ()
  (setf *default-source-volume* (get-volume *default-source-id*)))

(defun update-source-mute ()
  (setf *default-source-mute* (get-mute *default-source-id*)))

(defun update-info ()
  (update-sink-volume)
  (update-sink-mute)
  (update-source-volume)
  (update-source-mute))

(defun init ()
  (update-info)
  (run-with-timer 0 *check-interval* #'update-info))

(defcommand wpctl-volume-up () ()
  "Increase the volume by N points"
  (volume-up *default-sink-id* *step*)
  (update-sink-volume))

(defcommand wpctl-volume-down () ()
  "Decrease the volume by N points"
  (volume-down *default-sink-id* *step*)
  (update-sink-volume))

(defcommand wpctl-mute () ()
  "Mute"
  (mute *default-sink-id*)
  (update-sink-mute))

(defcommand wpctl-unmute () ()
  "Unmute"
  (unmute *default-sink-id*)
  (update-sink-mute))

(defcommand wpctl-toggle-mute () ()
  "Toggle Mute"
  (toggle-mute *default-sink-id*)
  (update-sink-mute))

(defcommand wpctl-set-volume (value) ((:string "Volume percentage:"))
  "Set volume"
  (set-volume *default-sink-id* value)
  (update-sink-volume))

(defcommand wpctl-source-volume-up () ()
  "Increase the volume by N points"
  (volume-up *default-source-id* *step*)
  (update-source-volume))

(defcommand wpctl-source-volume-down () ()
  "Decrease the volume by N points"
  (volume-down *default-source-id* *step*)
  (update-source-volume))

(defcommand wpctl-source-mute () ()
  "Source mute"
  (mute *default-source-id*)
  (update-source-mute))

(defcommand wpctl-source-unmute () ()
  "Source unmute"
  (unmute *default-source-id*)
  (update-source-mute))

(defcommand wpctl-source-toggle-mute () ()
  "Toggle source Mute"
  (toggle-mute *default-source-id*)
  (update-source-mute))

(defcommand wpctl-source-set-volume (value) ((:string "Volume percentage:"))
  "Set source volume"
  (set-volume *default-source-id* value)
  (update-source-volume))

;; modeline mouse interaction

(defun ml-on-click (code id &rest rest)
  (declare (ignore rest))
  (declare (ignore id))
  (let ((button (stumpwm::decode-button-code code)))
    (case button
      ((:left-button)
       (wpctl-toggle-mute))
      ((:right-button)
       (open-mixer))
      ((:wheel-up)
       (wpctl-volume-up))
      ((:wheel-down)
       (wpctl-volume-down))))
  (stumpwm::update-all-mode-lines))

(defun source-ml-on-click (code id &rest rest)
  (declare (ignore rest))
  (declare (ignore id))
  (let ((button (stumpwm::decode-button-code code)))
    (case button
      ((:left-button)
       (wpctl-source-toggle-mute))
      ((:right-button)
       (open-mixer))
      ((:wheel-up)
       (wpctl-source-volume-up))
      ((:wheel-down)
       (wpctl-source-volume-down))))
  (stumpwm::update-all-mode-lines))

(when (fboundp 'stumpwm::register-ml-on-click-id) ;check in case of old stumpwm version
  (register-ml-on-click-id :ml-wpctl-on-click #'ml-on-click)
  (register-ml-on-click-id :ml-wpctl-source-on-click #'source-ml-on-click))
