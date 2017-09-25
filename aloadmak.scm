;; -*- coding: utf-8 -*-
;;
;; aloadmak.scm
;; 2017-9-25 v1.00
;;
;; ＜内容＞
;;   Gauche で autoload のコードを生成するためのモジュールです。
;;   use を autoload に変更してロードを遅延したい場合に使用できます。
;;
;;   詳細については、以下のページを参照ください。
;;   https://github.com/Hamayama/aloadmak
;;
(define-module aloadmak
  (use gauche.test)
  (export
    aloadmak))
(select-module aloadmak)

;; gauche.test の内部手続きを使用
(define toplevel-closures
  (with-module gauche.test toplevel-closures))
(define closure-grefs
  (with-module gauche.test closure-grefs))
(define dangling-gref?
  (with-module gauche.test dangling-gref?))

;; autoload のコードを生成する
;;   module     対象モジュールを表すシンボル
;;   use-module 対象モジュール内で使用するモジュールを表すシンボル
(define (aloadmak module use-module)
  ;; モジュールの取得(内部処理用)
  (define (get-module module)
    (cond ((symbol? module)
           (or (find-module module)
               (error "no such module" module)))
          (else
           (error "symbol required, but got" module))))

  ;; シンボルを検索して、autoload のコードを生成する
  (let* ((mod          (get-module module))
         (use-mod      (get-module use-module))
         (use-mod-syms (module-exports use-mod))
         (mod-syms     '()))
    ;; 検索1 - 対象モジュールのシンボルを検索
    (hash-table-for-each (module-table mod)
                         (lambda (sym val)
                           (if (memq sym use-mod-syms)
                             (push! mod-syms sym))))
    ;; 検索2 - 対象モジュールの export シンボルを検索 (rename対応)
    (when (pair? (module-exports mod))
      (let ((m (make-module #f)))
        (eval `(import ,module) m)
        (eval `(extend) m)
        (for-each (lambda (sym)
                    (if (memq sym use-mod-syms)
                      (push! mod-syms sym)))
                  (module-exports mod))))
    ;; 検索3 - 対象モジュールのクロージャ内を検索
    (for-each
     (lambda (closure)
       (for-each (lambda (arg)
                   (let* ((gref (car arg))
                          ;(numargs (cadr arg))
                          ;(src-code (caddr arg))
                          (sym (~ gref 'name)))
                     (if (memq sym use-mod-syms)
                       (push! mod-syms sym))))
                 ;; for Gauche v0.9.5 compatibility
                 ;; for Gauche v0.9.4 compatibility
                 ;; for Gauche v0.9.3.3 compatibility
                 (if (global-variable-bound? 'gauche.internal '%closure-env->list)
                   ($ append-map closure-grefs
                      $ cons closure
                      $ filter closure?
                      $ (with-module gauche.internal %closure-env->list) closure)
                   (closure-grefs closure))))
     (toplevel-closures mod))
    ;; autoload のコードを生成して返す
    `(autoload ,module
               ,@(delete-duplicates
               ;; for Gauche v0.9.4 compatibility
               ;; for Gauche v0.9.3.3 compatibility
               ;(sort mod-syms)
               ;(sort mod-syms string<? x->string)
               (sort mod-syms (lambda (a b) (string<? (x->string a) (x->string b))))
               ))))

