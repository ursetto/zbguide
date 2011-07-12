(use zmq srfi-18)

(define ctrl (make-socket 'sub))
(define vent (make-socket 'pull))
(define sink (make-socket 'push))

(socket-option-set! ctrl 'subscribe "KILL")
(connect-socket ctrl "tcp://localhost:5559")
(connect-socket vent "tcp://localhost:5557")
(connect-socket sink "tcp://localhost:5558")

(define tctrl
  (make-thread (lambda ()
                 (receive-message* ctrl))))

(define tvent
  (make-thread (lambda ()
                 (let loop ((n 0))          ;; include zero msg
                   (let ((msg (receive-message* vent)))
                     (display ".")
                     (flush-output)
                     (thread-sleep! (/ (string->number msg) 1000))
                     (send-message sink "")
                     (loop (+ n 1)))))))

(thread-start! tctrl)
(thread-start! tvent)
(thread-join! tctrl)     ;; finish once we receive KILL msg on ctrl

#|
(close-socket ctrl)
(close-socket vent)
(close-socket sink)
(terminate-context (zmq-default-context))
|#
