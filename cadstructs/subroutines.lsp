;;;; Subrutinas

;;; Pedir al usuario un elemento estructural y devolver su prefijo asociado
(DEFUN cadstructs:get-structural-element ()
  (cadstructs:give-choice
    "Columna Viga Base Apeo Ménsula"
    "C"
    "Elegir elemento estructural"
  )
)


;;; Dar a elegir al usuario entre un grupo de opciones, con una por defecto
(DEFUN cadstructs:give-choice (options default message / choice)
  (INITGET options)
  (SETQ	choice
	 (GETKWORD
	   (STRCAT "\n"
		   message
		   " ["			; Dar opciones al usuario entre []
		   (VL-LIST->STRING
		     ;; Mostrar barras en vez de espacios entre opciones
		     (SUBST (ASCII "/") (ASCII " ") (VL-STRING->LIST options))
		   )
		   "] <"
		   default		; Opción predeterminada entre <>
		   ">: "
	   )
	 )
  )
  (IF (NOT choice)
    (SETQ choice default)
  )
  (SETQ choice (SUBSTR choice 1 1))
)


;;; Pedir orientación al usuario y devolver la rotación en grados
(DEFUN cadstructs:get-orientation (prefix / horizontal orientation)
  (SETQ horizontal "H")
  (IF (OR (= prefix "V") (= prefix "M")) ; Preguntar sólo para viga o ménsula
    (SETQ orientation
	   (cadstructs:give-choice
	     "Horizontal Vertical"
	     horizontal
	     "Orientación"
	   )
    )
    (SETQ orientation horizontal)
  )
  (IF (= orientation horizontal)
    0
    90
  )
)


;;; Pedir número al usuario y devolverlo para iniciar conteo
(DEFUN cadstructs:get-initial-count (/ default number)
  (SETQ default 1)
  (INITGET 4)				; Sólo enteros positivos
  (SETQ
    number (GETINT
	     (STRCAT "\nEspecificar el número inicial <"
		     (ITOA default)	; Opción predeterminada entre <>
		     ">: "
	     )
	   )
  )
  (IF (NOT number)
    (SETQ number default)
  )
  number
)


;;; Cambiar a una capa específica según el prefijo dado
(DEFUN cadstructs:make-layer (prefix / p name)
  (SETQ p (STRCASE prefix))
  (SETQ	name (COND
	       ((= p "C") "Columnas")
	       ((OR (= p "V") (= p "M")) "Vigas")
	       ((= p "B") "Bases")
	       ((= p "A") "Apeos")
	     )
  )
  ;; Cambiar capa, creándola si es necesario
  (COMMAND "._layer" "M" name "")
  (PRINC)				; Terminar sin devolver nada
)


;;; Establecer estilo y altura de texto
(DEFUN cadstructs:text-style (name / height)
  (SETQ height (CDR (ASSOC 40 (TBLSEARCH "STYLE" name))))

  (IF (OR (NOT height) (= height 0.0))
    (PROGN
      ;; Pedir al usuario una altura positiva
      (INITGET (+ 1 2))
      (SETQ height (GETDIST "\nAltura de texto: "))
    )
  )

  ;; Configurar el estilo
  (COMMAND "._style" name "Arial" height 1 0 "N" "N")

  (PRINC)				; Terminar sin devolver nada
)


;;; Insertar texto de la forma prefijo+número con una rotación dada
(DEFUN cadstructs:insert-names (prefix number rotation / point suffix)
  (SETQ suffix "")
  (WHILE (OR (IF (cadstructs:exchange-prefix prefix)
	       ;; Permitir claves sólo para viga o ménsula
	       (INITGET "Cambiar Invertir")
	     )
	     (SETQ point (GETPOINT (cadstructs:prompt-name-insertion prefix)))
	 )
    (COND ((= point "Cambiar")
	   ;; Intercambiar prefijos
	   (SETQ prefix (cadstructs:exchange-prefix prefix))
	  )
	  ((= point "Invertir")
	   ;; Añade un sufijo "i" para indicar viga o ménsula invertida
	   (IF (= suffix "i")
	     (PROGN
	       (SETQ suffix "")
	       (PRINC (STRCAT "\n" prefix " no invertida."))
	     )
	     (PROGN
	       (SETQ suffix "i")
	       (PRINC (STRCAT "\n" prefix " invertida."))
	     )
	   )
	  )
	  (T
	   (PROGN
	     ;; Crear y ubicar texto en el punto establecido
	     (COMMAND "._text"
		      "MC"
		      point
		      rotation
		      (STRCAT prefix (ITOA number) suffix)
	     )
	     (SETQ number (1+ number))	; incrementar sufijo del texto
	   )
	  )
    )
  )
)


;;; Intercambiar prefijos de Viga y Ménsula
(DEFUN cadstructs:exchange-prefix (prefix)
  (COND	((= prefix "V") "M")
	((= prefix "M") "V")
  )
)


;;; Mostrar mensaje para insertar nombre de acuerdo al prefijo dado
(DEFUN cadstructs:prompt-name-insertion	(prefix / new-prefix)
  (SETQ new-prefix (cadstructs:exchange-prefix prefix))
  (STRCAT "\nUbicación de texto"
	  "\nEscribir un punto o hacer clic en el dibujo"
	  (IF new-prefix
	    (STRCAT
	      " o [Cambiar \"" prefix "\" por \"" new-prefix "\"/Invertir]" "")
	    ""
	  )
	  ": "
  )
)


;;; Cargar los bloques dinámicos personalizados y devolver T si hubo éxito, nil caso contrario.
(DEFUN cadstructs:load-custom-blocks-p (/ suffix path support-path)
  (SETQ suffix "\\cadstructs\\bloques.dwg")
  ;; Buscar bloques en archivo local
  (SETQ path (STRCAT (VLA-GET-PATH (active-document)) suffix))
  (IF (cadstructs:load-blocks-from-file-path-p path)
    T
    (PROGN
      ;; Buscar bloques en el directorio Support
      (SETQ support-path (VLA-GET-SUPPORTPATH (VLA-GET-FILES (VLA-GET-PREFERENCES (acad-object)))))
      (SETQ path (STRCAT (cadstructs:get-first-word-before-char support-path ";") suffix))
      (cadstructs:load-blocks-from-file-path-p path)
    )
  )
)


;;; Buscar archivo de bloques en la ruta dada y devolver T si pudo cargarse con éxito.
(DEFUN cadstructs:load-blocks-from-file-path-p
       (path / document block blocks recipient-block repeated blocks-array)
  (PRINC "\nBuscando el archivo\n ")
  (PRINC path)

  (IF (FINDFILE path)
    (PROGN
      (SETQ document (VLA-OPEN (VLA-GET-DOCUMENTS (acad-object)) path))
      (PRINC "\nEncontrado.\nCargando bloques...")
      ;; Cargar los bloques del documento en una lista
      (VLAX-FOR	block (VLA-GET-BLOCKS document)
	(IF
	  (= (VL-CATCH-ALL-APPLY	; Workaround: model and paper space don't have
	       'VLA-GET-ISDYNAMICBLOCK	; this property on AutoCAD 2006
	       (LIST block)
	     )
	     :VLAX-TRUE
	  )
	   (PROGN
	     (SETQ blocks (APPEND blocks (LIST block)))

	     ;; Chequear si hay repeticiones en el documento destinatario
	     (VLAX-FOR recipient-block (VLA-GET-BLOCKS (active-document))
	       (IF (= (VLA-GET-NAME recipient-block) (VLA-GET-NAME block))
		 (SETQ repeated (APPEND repeated (LIST (VLA-GET-NAME block))))
	       )
	     )
	   )
	)
      )
      ;; El método copyObjects requiere safearray para funcionar
      (SETQ blocks-array
	     (VLAX-MAKE-SAFEARRAY VLAX-VBOBJECT (CONS 0 (1- (LENGTH blocks))))
      )
      (VLAX-SAFEARRAY-FILL blocks-array blocks)
      (VLA-COPYOBJECTS document blocks-array (VLA-GET-BLOCKS (active-document)))
      (VLA-CLOSE document :VLAX-FALSE)
      (PRINC " Listo.")

      ;; Advertir sobre nombres de bloques repetidos
      (IF repeated
	(PROGN
	  (PRINC "\nAlgunos bloques no se cargaron porque ya existen en el proyecto\n ")
	  (PRIN1 repeated)
	  (PRINC ".\nPueden renombrarse, y ejecutar a continuación el comando")
	  (PRINC " (cadstructs:load-blocks-and-check) para intentar cargarlos nuevamente."
	  )
	)
      )

      T					; Carga exitosa. Devolver verdadero.
    )
    (PROGN
      (PRINC "\nNo se encontró.")
      nil				; Carga fallida. Devolver "falso".
    )
  )
)


;;; Seleccionar e intercambiar bloques y nombres de estructuras
(DEFUN cadstructs:exchange-structures (struct1 struct2 / cmdsave selection-set object name)
  (SETQ cmdsave (GETVAR "cmdecho"))
  (SETVAR "cmdecho" 0)

  ;; Tratar grupo de comandos como uno solo para deshacer más fácilmente
  (COMMAND "._undo" "begin")

  ;; Pedir al usuario que seleccione objetos para procesarlos
  (VLA-SELECTONSCREEN
    (SETQ selection-set (cadstructs:add-safe-selection-set))
  )
  (VLAX-FOR object selection-set
    (SETQ name (VLA-GET-OBJECTNAME object))
    (COND
      ((AND (= name "AcDbBlockReference")
	    (= (VLA-GET-ISDYNAMICBLOCK object) :VLAX-TRUE)
       )
       (cadstructs:exchange-structure-blocks object struct1 struct2)
      )
      ((= name "AcDbText")
       (cadstructs:exchange-structure-names object struct1 struct2)
      )
    )
  )
  (VLA-DELETE selection-set)

  ;; Declarar fin del grupo de comandos
  (COMMAND "._undo" "end")

  (SETVAR "cmdecho" cmdsave)
  (PRINC)
)


;;; Añadir conjunto de selección en forma segura y devolverlo
(DEFUN cadstructs:add-safe-selection-set (/ sets id)
  (SETQ sets (VLA-GET-SELECTIONSETS (active-document)))
  (SETQ id "CADSTRUCTS_SSET")

  ;; Borrar conjunto de selección, si existe
  (VL-CATCH-ALL-APPLY
    'VLA-DELETE
    (LIST (VL-CATCH-ALL-APPLY 'VLA-ITEM (LIST sets id)))
  )

  ;; Crear uno vacío con el mismo id
  (VLA-ADD sets id)
)


;;; Tomar y cambiar datos de un bloque por otro
(DEFUN cadstructs:exchange-structure-blocks (block struct1 struct2 / name prefix pairs new-block)
  (SETQ name (VLA-GET-EFFECTIVENAME block))
  (IF (SETQ name (COND ((= struct2 "Apeo")
			(COND ((= name "Columna") "Apeo")
			      ((= name "Apeo") "Columna")
			      ((= name "Columna cilíndrica") "Apeo cilíndrico")
			      ((= name "Apeo cilíndrico") "Columna cilíndrica")
			)
		       )
		       ((= struct2 "Base")
			(SETQ pairs '(("Ancho" "Ancho de columna") ("Alto" "Alto de columna")))
			(COND ((= name "Columna") "Base céntrica-esquinera")
			      ((= name "Base céntrica-esquinera") "Columna")
			)
		       )
		 )
      )
    (PROGN
      (SETQ prefix (cadstructs:get-first-word-before-char name " "))
      (cadstructs:make-layer (SUBSTR prefix 1 1)) ; Crear nueva capa, si es necesario
      (SETQ new-block			; Insertar nuevo bloque sobre el anterior
	     (VLA-INSERTBLOCK
	       (VLA-OBJECTIDTOOBJECT
		 (VLA-GET-DOCUMENT block)
		 (VLA-GET-OWNERID block)
	       )
	       (VLA-GET-INSERTIONPOINT block)
	       name
	       (VLA-GET-XSCALEFACTOR block)
	       (VLA-GET-YSCALEFACTOR block)
	       (VLA-GET-ZSCALEFACTOR block)
	       (VLA-GET-ROTATION block)
	     )
      )
      ;; Copiar propiedades del bloque anterior y borrarlo
      (VLA-PUT-LAYER new-block (STRCAT prefix "s"))
      (cadstructs:copy-dynamic-properties block new-block pairs)
      (VLA-DELETE block)
    )
  )
)


;;; Obtiene la primer palabra antes de un caracter dado
(DEFUN cadstructs:get-first-word-before-char (text character)
  (CAR (cadstructs:split-in-two-at-first-match text character))
)



(DEFUN cadstructs:split-in-two-at-first-match (text character / i)
  (SETQ i (VL-STRING-POSITION (ASCII character) text))
  (APPEND (LIST (SUBSTR text 1 i))
	  (IF i
	    (LIST (SUBSTR text (1+ i)))
	  )
  )
)


;;; Copiar propiedades de un bloque dinámico a otro
(DEFUN cadstructs:copy-dynamic-properties
       (from to allowed-pairs / pair flattened-list allowed-pair key)
  (FOREACH pair	allowed-pairs
    (SETQ flattened-list (APPEND flattened-list pair))
  )
  (SETQ	from (cadstructs:get-writable-dynamic-properties from flattened-list)
	to   (cadstructs:get-writable-dynamic-properties to flattened-list)
  )
  (FOREACH pair	from
    (SETQ key (CAR pair))
    (IF	allowed-pairs
      (FOREACH allowed-pair allowed-pairs
	(COND ((= key (CAR allowed-pair)) (SETQ key (CADR allowed-pair)))
	      ((= key (CADR allowed-pair)) (SETQ key (CAR allowed-pair)))
	)
      )
    )
    (IF	key
      (VLA-PUT-VALUE (CDR (ASSOC key to)) (VLA-GET-VALUE (CDR pair)))
    )
  )
)


;;; Devolver lista de pares (nombre . referencia) con propiedades modificables de bloque dinámico
(DEFUN cadstructs:get-writable-dynamic-properties
       (block allowed-properties / properties i property property-pairs)
  (SETQ	properties
	 (VLAX-SAFEARRAY->LIST
	   (VLAX-VARIANT-VALUE (VLA-GETDYNAMICBLOCKPROPERTIES block))
	 )
	i 0
  )
  (REPEAT (LENGTH properties)
    (SETQ property (NTH i properties))
    (IF	(AND (= (VLA-GET-SHOW property) :VLAX-TRUE)
	     (OR (NOT allowed-properties)
		 (VL-POSITION (VLA-GET-PROPERTYNAME property) allowed-properties)
	     )
	)
      (SETQ property-pairs
	     (APPEND
	       property-pairs
	       (LIST (CONS (VLA-GET-PROPERTYNAME property)
			   property
		     )
	       )
	     )
      )
    )
    (SETQ i (1+ i))
  )
  property-pairs
)


(DEFUN cadstructs:exchange-structure-names
       (object struct1 struct2 / text second-char-code first-char layer)
  (SETQ text (VLA-GET-TEXTSTRING object))
  (SETQ second-char-code (ASCII (SUBSTR text 2 1)))

  ;; Verificar que el segundo caracter sea un dígito
  (IF (AND (<= second-char-code 57) (>= second-char-code 48))
    (PROGN
      (SETQ first-char (SUBSTR text 1 1))
      ;; Modificar texto de acuerdo a su primer caracter
      (IF (SETQ	layer (COND ((= first-char (SUBSTR struct1 1 1)) (STRCAT struct2 "s"))
			    ((= first-char (SUBSTR struct2 1 1)) (STRCAT struct1 "s"))
		      )
	  )
	(PROGN
	  (SETQ first-char (SUBSTR layer 1 1))
	  (VLA-PUT-TEXTSTRING object (STRCAT first-char (SUBSTR text 2)))
	  (cadstructs:make-layer first-char)
	  (VLA-PUT-LAYER object layer)
	)
      )
    )
  )
)
