(use zmq srfi-18)

(define wx (make-socket 'sub))
(define vent (make-socket 'pull))
(define sink (make-socket 'push))

(socket-option-set! wx 'subscribe "60047 ")
(connect-socket wx   "tcp://localhost:5556")
(connect-socket vent "tcp://localhost:5557")
(connect-socket sink "tcp://localhost:5558")

(define twx
  (make-thread (lambda ()
                 (let loop ()
                   (print "weather msg: " (receive-message* wx))
                   (loop)))))

(define tvent
  (make-thread (lambda ()
                 (let loop ((n 0))          ;; include zero msg
                   (let ((msg (receive-message* vent)))
                     (print "worker  msg: " msg)
                     (thread-sleep! (/ (string->number msg) 1000))
                     (send-message sink (number->string n))   ;; msg # for debugging
                     (loop (+ n 1)))))))

(thread-start! twx)
(thread-start! tvent)
(thread-join! twx)
(thread-join! tvent)
#|
(close-socket wx)
(close-socket vent)
(close-socket sink)
(terminate-context (zmq-default-context))
|#
