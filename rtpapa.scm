;;
;;  Custom routing Router to Papa (ROUTER to REP)
;;
(use zmq)
(include "zhelpers.scm")

;;  We will do this all in one thread to emphasize the sequence
;;  of events...

(define client (make-socket 'xrep))        ;; FIXME: ROUTER
(bind-socket client "ipc://routing.ipc")

(define worker (make-socket 'rep))
(socket-option-set! worker 'identity "A")
(connect-socket worker "ipc://routing.ipc")

;; Wait for the worker to connect so that when we send a message
;; with routing envelope, it will actually match the worker...
(thread-sleep! 1)

;; Send papa address, address stack, empty part, and request
(send-multipart-message*
 client
 "A" "address 3" "address 2" "address 1" ""
 "This is the workload")

;; Worker should just get the workload
(dump-socket worker)

;; We don't play with envelopes in the worker
(send-message worker "This is the reply")

;; Now dump what we got off the ROUTER socket...
(dump-socket client)
