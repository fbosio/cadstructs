;;;; Comandos personalizados

;;; Recibir un prefijo y generar nombres de la forma letra+número.
;; Incrementar número automáticamente con cada texto nuevo.
(DEFUN C:NOMBRAR (/ saved prefix number rotation)
  (SETQ
    saved (LIST (CONS 'cmd (GETVAR "cmdecho")) (CONS 'error *error*))
  )
  (SETVAR "cmdecho" 0)			; Ocultar las llamadas a comandos
  ;; Sobreescribir manejo de errores para poder cancelar en silencio
  (DEFUN *error* (msg)
    (IF	(= msg "Function cancelled")
      (PRINC "*Cancel*")
      (PRINC msg)
    )
    (PRINC)				; Terminar sin devolver nada
  )

  ;; Pedir datos al usuario
  (SETQ prefix (cadstructs:get-structural-element))
  (SETQ rotation (cadstructs:get-orientation prefix))
  (SETQ number (cadstructs:get-initial-count))

  ;; Preparar documento para el dibujo
  (cadstructs:make-layer prefix)
  (cadstructs:text-style "NOMBRES")

  ;; Insertar texto hasta finalizar o cancelar el comando
  (cadstructs:insert-names prefix number rotation)

  ;; Reestablecer configuración
  (SETVAR "cmdecho" (CDR (ASSOC 'cmd saved)))
  (SETQ *error* (CDR (ASSOC 'error saved)))
  (PRINC)				; Terminar sin devolver nada
)


;;; Insertar bloques de losa incrementando automáticamente la numeraciónn
(DEFUN C:LOSA (/ cmdsave block-name default-inital-count count point)
  (SETQ cmdsave (GETVAR "cmdecho"))
  (SETVAR "cmdecho" 0)			; Ocultar las llamadas a comandos

  ;; Chequear que exista el bloque
  (SETQ block-name "Losa")
  (IF (TBLSEARCH "BLOCK" block-name)
    (PROGN
      (COMMAND "._layer" "M" "Losas" "")
      ;; Pedir número al usuario para conteo
      (SETQ default-inital-count 1)
      (SETQ count (GETINT (STRCAT "\nNúmero inicial de losa <" (ITOA default-inital-count) ">: ")))
      (IF (NOT count)
	(SETQ count default-inital-count)
      )
      ;; Pedir puntos al usuario para ubicar los bloques de losa
      (WHILE (SETQ point (GETPOINT "\nEscribir un punto o hacer clic en el dibujo: "))
	(COMMAND "._insert" block-name point 1 1 0 count)
	(SETQ count (1+ count))
      )
    )
    (PROGN
      (PRINC (STRCAT "\nNo existe ningún bloque llamado \""
		     block-name
		     "\".\nDebe ser importado primero para poder usarlo."
	     )
      )

      ;; Intentar carga de bloques dinámicos personalizados
      (IF (cadstructs:load-custom-blocks-p)
	;; Si se logra, llamar al comando en forma recursiva para comenzar de nuevo
	(C:LOSA)
      )
    )
  )

  (SETVAR "cmdecho" cmdsave)
  (PRINC)				; Terminar sin devolver nada
)


;;; Intercambiar columnas y apeos
(DEFUN C:COLAP ()
  (cadstructs:exchange-structures "Columna" "Apeo")
)


;;; Intercambiar columnas y bases
(DEFUN C:COLBAS ()
  (cadstructs:exchange-structures "Columna" "Base")
)


;;; Poner título a una o varias plantas
(DEFUN C:TITULAR (/ title point)
  (SETQ cmdsave (GETVAR "cmdecho"))
  (SETVAR "cmdecho" 0)

  ;; Insertar títulos mientras se especifiquen título y posición
  (COMMAND "._layer" "M" "Títulos" "")
  (cadstructs:text-style "Títulos")
  (WHILE (AND
	   (/= ""
	       (SETQ title
		      (VL-STRING-TRIM " " (GETSTRING T "Ingresar título de la planta: "))
	       )
	   )
	   (SETQ point (GETPOINT "\nEscribir un punto o hacer clic en el dibujo: "))
	 )
    (COMMAND "._text" "MC" point 0 title)
  )

  (SETVAR "cmdecho" cmdsave)
  (PRINC)
)
