(use zmq)
(use random-bsd)
(use (only srfi-18 thread-sleep!))

(define s (make-socket 'push))
(bind-socket s "tcp://*:5557")

(print "Press Enter when the workers are ready:")
(read-char)
(print "Sending tasks to workers...")

;; The first message is "0" and signals start of batch
(send-message s "0")

(define +ntasks+ 100)

(let loop ((task +ntasks+) (msec 0))
  (if (= 0 task)
      (print "Total expected cost: " msec "ms")
      (let ((workload (+ 1 (random 100))))              ;; Random workload from 1 to 100ms
        (send-message s (number->string workload))
        (loop (- task 1)
              (+ msec workload)))))

;; Give 0MQ time to deliver
;; (thread-sleep! 1)
;; Try zmq_close / zmq_term instead; haven't demonstrated it makes a difference yet
(close-socket s)
(terminate-context (zmq-default-context))

