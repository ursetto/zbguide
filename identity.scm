;; Demonstrate identities as used by the request-reply pattern.
;; Run this program by itself.

(use zmq srfi-4)
(include "zhelpers.scm")

(define sink (make-socket 'xrep))     ;; 'router
(bind-socket sink "inproc://example")

;; First allow 0MQ to set the identity
(define anon (make-socket 'req))
(connect-socket anon "inproc://example")
(send-message anon "ROUTER uses a generated UUID")
(dump-socket sink)

;; Then set the identity ourself
(define ident (make-socket 'req))
(socket-option-set! ident 'identity "Hello")
(connect-socket ident "inproc://example")
(send-message ident "ROUTER socket uses REQ's socket identity")
(dump-socket sink)

#|
[017] #${00c5a2b59a7f484694967cc73b5c9afaf7}
[000]
[028] ROUTER uses a generated UUID
----------------------------------------
[005] Hello
[000]
[040] ROUTER socket uses REQ's socket identity
|#
