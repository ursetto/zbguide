;; Least-recently used (LRU) queue device

;; This contains the polling version of the LRU broker.
;; Polling is a blocking operation and prevents other Chicken
;; threads from running, so the front- and backends are in
;; a separate process.  See lruqueue-ends.scm.

(use zmq data-structures)
(include "zhelpers.scm")

(define +num-clients+ 10)
(define +num-workers+ 3)

(define (receive-empty-message s)
  (assert (string=? "" (receive-message* s)))
  "")

(define frontend (make-socket 'xrep))
(define backend  (make-socket 'xrep))
(bind-socket frontend "ipc://frontend.ipc")
(bind-socket backend "ipc://backend.ipc")

(define q (make-queue))

;; Handle worker activity on backend, forwarding messages to the proper
;; front-end address and queuing the (now-free) worker on the LRU queue.
;; Quits after having replied to +num-clients+ clients.
;; Worker messages look like
;; worker-addr "" client-addr "" reply      indicating client reply, OR like
;; worker-addr "" "READY"                   indicating first time connect.
(define handle-worker             ;; return #t to continue, #f to terminate
  (let ((clients +num-clients+))
    (lambda ()
      (let* ((worker-addr (receive-message* backend))
             (empty       (receive-empty-message backend))
             (client-addr (receive-message* backend)))
        ;; data-structures queue does not track length, so we don't assert < +num-workers+        
        (queue-add! q worker-addr)
        (cond ((string=? client-addr "READY") #t) ; continue
              (else
               (receive-empty-message backend)
               (let ((reply (receive-message* backend)))
                 (send-multipart-message frontend
                                         client-addr "" reply)
                 (printf "Worker ~A -> ~A  ~S\n"
                         worker-addr client-addr reply)
                 (set! clients (- clients 1))
                 (> clients 0))))))))

;; Handle client activity on frontend, routing messages to LRU worker.
;; Client messages look like:
;; client-addr "" request
;; and routed client messages look like:
;; worker-addr "" client-addr "" request
(define handle-client
  (lambda ()
    (let* ((client-addr (receive-message* frontend))
           (empty       (receive-empty-message frontend))
           (request     (receive-message* frontend))
           (worker-addr (queue-remove! q)))
      (send-multipart-message backend
                              worker-addr ""
                              client-addr "" request)
      (printf "Client ~A -> ~A  ~S\n"
              client-addr worker-addr request)      
      
      #t)))

;;; main

;; Always poll for worker activity on backend; poll front-end only if
;; we have available workers.  Note that the native C example ensures
;; that when no workers are available, we do not chew CPU while waiting
;; for one to become available.  In contrast, the Python example always
;; polls the frontend and tests for worker availability afterward,
;; which will spin.  We follow the C approach here.

(define backend-items (poll-items (list backend) '()))
(define bothend-items (poll-items (list backend frontend) '()))

(call/cc
 (lambda (finish)
   (forever
     (cond ((queue-empty? q)
            (poll backend-items #t) ;; maybe poll!
            (when (poll-items-in? backend-items 0)
              (unless (handle-worker)
                (finish #t))))
           (else
            (poll bothend-items #t)
            (when (poll-items-in? bothend-items 0)
              (unless (handle-worker)
                (finish #t)))
            (when (poll-items-in? bothend-items 1)
              (unless (handle-client)
                (finish #t))))))))

(close-socket frontend)
(close-socket backend)
(terminate-context (zmq-default-context))
