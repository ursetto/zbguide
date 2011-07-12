(use zmq)

(define front (make-socket 'sub))
(define back (make-socket 'pub))

(connect-socket front "tcp://localhost:5556")
(bind-socket back "tcp://*:8100")

(socket-option-set! front 'subscribe "")

(let loop ()
  (let next-part ()
    (let ((msg (receive-message* front))
          (more? (socket-option front 'rcvmore)))
      (send-message back msg send-more: more?)
      (when more? (next-part))))
  (loop))
