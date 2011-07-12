(use zmq srfi-18)

(define front (make-socket 'xrep))  ;; FIXME: should be 'router
(define back  (make-socket 'xreq))  ;; FIXME: should be 'dealer

(bind-socket front "tcp://*:5559")
(bind-socket back  "tcp://*:5560")

(define-syntax forever
  (syntax-rules () ((forever e0 e1 ...)
                    (let loop () e0 e1 ... (loop)))))

(define (route)
  (forever
   (let more ()
     (let ((msg (receive-message* front))
           (more? (socket-option front 'rcvmore)))
       (printf "routing ~s more? ~a\n" msg more?)
       (send-message back msg send-more: more?)
       (when more? (more))))))
(define (deal)
  (forever
   (let more ()
     (let ((msg (receive-message* back))
           (more? (socket-option back 'rcvmore)))
       (printf "dealing ~s more? ~a\n" msg more?)
       (send-message front msg send-more: more?)
       (when more? (more))))))

(let ((rt (make-thread route))
      (dt (make-thread deal)))
  (thread-start! rt)
  (thread-start! dt)
  (thread-join! rt)
  (thread-join! dt))

