;;
;; Test aloadmak
;;

(add-load-path "." :relative)
(add-load-path "1000_test" :relative)
(use gauche.test)

(test-start "aloadmak")
(use aloadmak)
(test-module 'aloadmak)

(test-section "aloadmak")
(test* "aloadmak-1"
       '(autoload moduleB procB1 procB2 varB1 varB2)
       (aloadmak 'moduleA 'moduleB))

;; summary
(format (current-error-port) "~%~a" ((with-module gauche.test format-summary)))

(test-end)

