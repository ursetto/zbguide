;; pub/sub with envelope address
;; Note that if you don't insert a sleep, the server will crash as soon
;; as a client disconnects.  Also the other client may receive tons of
;; messages afterward.  Perhaps the send buffer is filling up; haven't been
;; able to mitigate by closing socket or terminating though.

(use zmq srfi-18)

(define pub (make-socket 'pub))
(bind-socket pub "tcp://*:5563")

(let loop ()
  (send-message pub "A" send-more: #t)
  (send-message pub "We don't want to see this")
  (send-message pub "B" send-more: #t)
  (send-message pub "We would like to see this")
  (thread-sleep! 0.5)
  (loop))
