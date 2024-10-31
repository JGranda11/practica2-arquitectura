.data
    space:     .asciiz " "                      # Espacio para imprimir
    newline:   .asciiz "\n"                     # Nueva línea
    Left:  .space  200                          # Arreglo izquierdo
    Right: .space  200                          # Arreglo derecho
    filename: .asciiz "numeros.txt"		#Nombre del archivo a leer
    buffer: .space 200                  # Espacio para almacenar temporalmente el contenido del archivo
    arreglo: .space 200			#Espacio para almacenar numeros
    nuevo_espacio: .space 2048
    nuevoArchivo: .asciiz "resultado.txt"

.text
main:

# Abrir archivo de entrada
        addi $v0, $zero, 13             # Syscall para abrir archivo
        la $a0, filename                # Dirección del nombre del archivo
        addi $a1, $zero, 0              # Modo de lectura (read-only)
        addi $a2, $zero, 0              # Permisos por defecto
        syscall
        add $t0, $zero, $v0             # Guardar el descriptor del archivo en $t0

        # Leer el contenido del archivo
        addi $v0, $zero, 14             # Syscall para leer archivo
        add $a0, $zero, $t0             # Descriptor de archivo en $a0
        la $a1, buffer                  # Dirección de almacenamiento del buffer
        addi $a2, $zero, 100            # Tamaño máximo de lectura en bytes
        syscall
        add $t1, $zero, $v0             # Almacenar número de bytes leídos en $t1

        # Cerrar el archivo
        addi $v0, $zero, 16             # Syscall para cerrar archivo
        add $a0, $zero, $t0             # Descriptor de archivo
        syscall

        # Configurar punteros para el parsing de números
        la $t2, buffer                  # Puntero al inicio del buffer
        add $t3, $t2, $t1               # Puntero al final del buffer
        addi $sp, $sp, -4               # Reservar espacio en la pila

parse_loop:
        # Comprobar fin del buffer
        beq $t2, $t3, end_parse         # Si llegamos al final, salir del bucle
        lb $t4, 0($t2)                  # Cargar el siguiente byte en $t4
        beq $t4, 44, store_number       # Si es una coma (','), almacenar número
        beq $t4, 10, end_parse          # Si es salto de línea, terminar
        beq $t4, 13, end_parse          # Si es retorno de carro, terminar
        sub $t4, $t4, 48                # Convertir de ASCII a número (0-9)
        sll $t6, $t5, 3     # $t6 = $t5 * 8  (desplaza 3 bits a la izquierda)
	sll $t7, $t5, 1     # $t7 = $t5 * 2  (desplaza 1 bit a la izquierda)
	add $t5, $t6, $t7   # $t5 = ($t5 * 8) + ($t5 * 2) = $t5 * 10
	add $t6, $zero, $zero  # Resetear $t6 a 0
	add $t7, $zero, $zero  # Resetear $t7 a 0
        add $t5, $t5, $t4               # Añadir el dígito actual
        addi $t2, $t2, 1                # Avanzar al siguiente byte
        j parse_loop

store_number:
        # Almacenar el número en la pila y preparar para el siguiente
        sw $t5, 0($sp)                  # Guardar número en la pila
        addi $sp, $sp, -4               # Reservar espacio para el siguiente número
        addi $t5, $zero, 0              # Reiniciar $t5 para el próximo número
        addi $t2, $t2, 1                # Avanzar al siguiente byte
        j parse_loop
        
end_parse:
        addi $sp, $sp, 4                # Ajustar la pila para iniciar la impresión
        
llenarVector:
        # Llenar el array desde la pila
        lw $t6, 0($sp)                  # Cargar número desde la pila
        beq $t6, 0, ordenar_e_imprimir               # Salir si encontramos un cero (fin de pila)
        bne $t7, $zero, indiceInicializado
        add $t7, $zero, 0               # Definir índice $t7 = 0
indiceInicializado:
 		sw $t6, arreglo($t7)             # Guardar el número en vector[i]
        
        # Imprimir el número actual
        addi $v0, $zero, 1              # Syscall para imprimir entero
        add $a0, $zero, $t6             # Número a imprimir
        syscall
        
        # Avanzar en la pila y aumentar el índice del vector
        addi $sp, $sp, 4                # Moverse al siguiente número en la pila
        addi $t7, $t7, 4                # Incrementar índice
        j llenarVector

ordenar_e_imprimir:  
    la $a0, arreglo 
    jal longitudArreglo         # a0 = dirección de vector[]
    addi $a1, $v0, 0            # a1 = n (longitud del array)
    addi $s0, $v0, 0            # a1 = n (longitud del array)
    jal mergeSort
    
    jal guardar_archivo

guardar_archivo:
    # Abrir o crear el archivo para escritura
    li $v0, 13               # syscall para abrir/crear archivo
    la $a0, nuevoArchivo          # nombre del archivo
    li $a1, 1                # modo de escritura
    li $a2, 0                # permisos por defecto
    syscall
    add $s6, $zero, $v0            # guardar el descriptor del archivo
    
    # Verificar si hubo error al abrir el archivo
    bltz $s6, salir          # si es negativo, hubo error
    
    # Inicializar variables
    la $t1, arreglo           # puntero al vector
    li $t2, 0                # índice
    la $s1, nuevo_espacio        # buffer para conversión
   
escribir_bucle:
    lw $t3, ($t1)            # cargar número actual
    beq $t3, $zero,cerrar_archivo  # si es 0, terminamos
    
    # Convertir número a string
    add $t4, $zero, $t3            # copiar número para conversión
    li $t5, 0                # contador de dígitos
    li $t6, 10               # divisor
    la $s1, nuevo_espacio        # reiniciar puntero del buffer
    
    # Si el número es negativo, manejarlo
    bgez $t4, bucle_conversion
    li $t7, 45               # ASCII del signo menos
    sb $t7, ($s1)            # guardar el signo
    addiu $s1, $s1, 1        # avanzar puntero
    sub $t4, $zero, $t4             # hacer positivo el número
    
bucle_conversion:
    divu $t4, $t6            # dividir por 10
    mfhi $t7                 # obtener residuo (último dígito)
    mflo $t4                 # obtener cociente
    addiu $t7, $t7, 48       # convertir a ASCII
    sb $t7, ($s1)            # guardar dígito
    addiu $s1, $s1, 1        # avanzar puntero
    addiu $t5, $t5, 1        # incrementar contador
    bne $t4, $zero,bucle_conversion  # si quedan dígitos, continuar
    
    # Invertir la cadena de caracteres
    la $s1, nuevo_espacio        # reiniciar puntero
    add $t7, $s1, $zero      # guardar inicio
    add $t8, $s1, $t5        # apuntar al final
    addi $t8, $t8, -1        # ajustar al último carácter
    
invertir_bucle:
    slt $at, $t7, $t8      	     # $at = 1 si $t7 < $t8, sino $at = 0
    beq $at, $zero, escribir_numero  # salta si $at es 0 (es decir, si $t7 >= $t8)
    lb $t4, ($t7)            	     # cargar carácter del inicio
    lb $t6, ($t8)            	     # cargar carácter del final
    sb $t6, ($t7)            	     # intercambiar caracteres
    sb $t4, ($t8)
    addiu $t7, $t7, 1        	     # avanzar puntero inicio
    addiu $t8, $t8, -1       	     # retroceder puntero final
    j invertir_bucle
    
escribir_numero:
    # Escribir el número en el archivo
    li $v0, 15               # syscall para escribir
    add $a0, $zero, $s6            # descriptor del archivo
    la $a1, nuevo_espacio        # buffer con el número
    add $a2, $zero, $t5            # longitud del número
    syscall
    
    # Avanzar al siguiente número
    addiu $t1, $t1, 4        # siguiente elemento del vector
    addiu $t2, $t2, 1        # incrementar índice
    
    # Verificar si hay más números para escribir la coma
    lw $t3, ($t1)            # cargar el siguiente número
    bne $t3, $zero,escribir_coma     # si no es cero, escribir la coma
    j escribir_bucle           # si es cero, terminar el bucle

escribir_coma:
    # Escribir el separador (coma y espacio)
    li $v0, 15               # syscall para escribir
    add $a0, $zero, $s6            # descriptor del archivo
    la $a1, space            # ", "
    li $a2, 2                # longitud del separador
    syscall
    
    j escribir_bucle           # volver al bucle de escritura
    
cerrar_archivo:
    li $v0, 16               # syscall para cerrar archivo
    add $a0, $zero, $s6            # descriptor del archivo
    syscall
    j salir
    
salir:


exitfinal:
    li $v0, 10               # syscall para terminar el programa
    syscall

#Calcular la longitud del arreglo
longitudArreglo:
		addi $sp, $sp, -8 		                 # Reservamos espacio en la pila
		sw $ra, 0($sp)			                 # Guardamos en la pila la posiciÃ³n de retorno
		sw $a0, 4($sp)			                 # Guardamos en la pila nuestro arreglo
		addi $t1, $zero, 0 		                 # Definimos el contador        
        
mergeSort:
    # Verificar si inicio < final
    slt  $t0, $a1, $a2     #a1-inicio  a2-final(n-1)  
    #si t0 == zero entonces a1 no es menor, entonces finaliza dado que t0 lleva cero
    beq  $t0, $zero, mergeSortReturn     #Incumplir la condición
    
    # Guardar registros en la pila
    #Debo separar 4 registros por eso debo moverme a la siguiente posición
    #Debo correr 4 registros
    addi $sp, $sp, -16 
    sw   $ra, 12($sp) #guardar ra 
    sw   $a1, 8($sp)  #guadar a1 -> inicio en la pila
    sw   $a2, 4($sp)  #guardar a2 -> final en la pila
    
    # Calcular mitad = (inicio + final) / 2
    add  $t0, $a1, $a2      #t0 = inicio + final
    srl  $t0, $t0, 1        # mitad = (inicio + final) / 2
    sw   $t0, 0($sp)        # Guardar mitad
    #mitad es un argumento para el siguiente llamado de la función
    
    # Primera llamada recursiva: mergeSort(arreglo, inicio, mitad)
    
    #move $a2, $t0           # final = mitad
    #hago uso del registro a2, dado que la pila ya me guarda a2 como final
    #entonces a2 ahora es mitad, que seria el final del siguiente llamado
    add $a2, $t0, $zero   # final = mitad
    jal  mergeSort
    
    # Segunda llamada recursiva: mergeSort(arreglo, mitad + 1, final)
    lw   $t0, 0($sp)        # Pop mitad de la pila, para usarla en este llamado
    #no afectar a $a2
    addi $a1, $t0, 1        # inicio = mitad + 1 #a1 -> va a ser un nuevo incio 
    lw   $a2, 4($sp)        # Pop final original
    jal  mergeSort
    
    # Preparar argumentos para merge
    lw   $a1, 8($sp)        # Pop inicio original
    lw   $a2, 4($sp)        # Pop final original
    lw   $a3, 0($sp)        # mitad
    jal  merge
    
    #Debo traer $ra -- para realzar el jr
    lw   $ra, 12($sp)        #liberar la pila
   
    # liberar registros y retornar
    addi $sp, $sp, 16
    
mergeSortReturn:
    jr   $ra
    #conidición de no cumplimiento del condicional en la funcion mergeSort()
    #Entregue el control a main

merge:
    # Guardar registros 
    # Separar el espacio en la pila 
    # Para este caso necesito guardar 7 registros 
    addi $sp, $sp, -28
    sw   $ra, 24($sp) #registro ra
    sw   $s0, 20($sp) #guardar inicio
    sw   $s1, 16($sp) #guardar final
    sw   $s2, 12($sp) #umbral de recorrido para la primera mitad
    sw   $s3, 8($sp) #umbral de recorrido para la segunda mitad
    sw   $s4, 4($sp) #Tomar el puntero base del vector Izquierdo
    sw   $s5, 0($sp)  #Tomar el puntero base del vector Derecho
    
    # Calcular tamaños umbrales
    sub  $s2, $a3, $a1      # n1 = mitad - inicio 
    addi $s2, $s2, 1        # n1 = mitad - inicio + 1
    sub  $s3, $a2, $a3      # n2 = final - mitad
    
    # Guardar índices originales
    add $s0, $a1, $zero     # s0 = inicio
    add $s1, $a2, $zero     # s1 = final
    
    # Copiar elementos al arreglo izquierdo
    la   $s4, Left          # s4 = dirección base de la sublista izquierda
    add $t0, $zero, $zero   # i = 0 
    add $t1, $s0, $zero     #k = inicio
    
copiarArregloIzq:
    beq  $t0, $s2, copiarArregloDerP    #beq i == n1,  si es igual salta
    #Dado que ya debe seguir con la otra mitad del arreglo
    bgt $t9, $zero, continuar
    addi $a0, $a0, -4
    addi $t9, $t9, 1
continuar:
    sll  $t2, $t1, 2                  #a $t2 = le lleva la i * 4
    add  $t2, $a0, $t2                  #puntero del arreglo general lo reasigno
    lw   $t3, 0($t2)                    #traer a un registro el valor de la lista
    sll  $t2, $t0, 2                    #luego cambio a la siguiente dirección
    add  $t2, $s4, $t2                  # y debo situarme en la sublista
    sw   $t3, 0($t2)                    #para escribir ese valor en la sublista
    addi $t0, $t0, 1                    #aumentar i en 1
    addi $t1, $t1, 1                    #Aumentar k en 1
    j    copiarArregloIzq
    
copiarArregloDerP:
    la   $s5, Right         # s5 = Dirección base de la sublista derecha
    add $t0, $zero, $zero   # i = 0
    addi $t1, $a3, 1        # k = mitad + 1
    
copiarArregloDer:
    beq  $t0, $s3, mergeArreglosP       #combinar los arreglos
    #Etapa 3 de los algoritmos de divide y venceras
    sll  $t2, $t1, 2                    #a $t2 = le lleva la i * 4
    add  $t2, $a0, $t2                  #puntero del arreglo general lo reasigno
    lw   $t3, 0($t2)                    #traer a un registro el valor de la lista
    sll  $t2, $t0, 2			  #Luego cambio a la siguiente dirección
    add  $t2, $s5, $t2                  # y debo situarme en la sublista 
    sw   $t3, 0($t2)                    #escribir el valor en la sublista 
    addi $t0, $t0, 1                    #Aumentar i en 1
    addi $t1, $t1, 1                    #Aumentar k en 1
    j    copiarArregloDer
    
mergeArreglosP:
    add $t0, $zero, $zero              # i = 0
    add $t1, $zero, $zero              # j = 0
    add $t2, $s0, $zero                # k = inicio
    
mergeArrays:
    # Verificar si se termino algun subarreglo
    beq  $t0, $s2, copiarRestanteDer   #si i == n1 (umbral para la parte izquierda)
    beq  $t1, $s3, copiarRestanteIzq   # j == n2 (umbral de la parte derecha)
    
    # Cargar y comparar elementos
    #Proceso comparativo del algoritmo
    sll  $t3, $t0, 2       
    add  $t3, $s4, $t3     #muevo el puntero para el vector izquierdo
    lw   $t3, 0($t3)       # t3 = arraegloIzquierdo[i]
    
    sll  $t4, $t1, 2
    add  $t4, $s5, $t4     #muevo el puntero para el vector derecho
    lw   $t4, 0($t4)       # t4 = arregloDerecho[j]
    
    # Comparar y copiar el elemento mayor (cambio para orden descendente)
    slt  $t5, $t3, $t4     # Cambiado para orden descendente
    beq  $t5, $zero, copiarIzquierdo   #Llamar a la etiqueta izquierda
    
copiarDerecho:
    #inicialmente k = mitad + 1
    sll  $t5, $t2, 2       #temporal5 con el valor inicial de k *4 
    add  $t5, $a0, $t5     #muevo el puntero del arreglo 
    sw   $t4, 0($t5)       #guardar el registro del puntero actual a la sublista
    addi $t1, $t1, 1         #aumentar la variable contadora j 
    j    mergeContinue
    
copiarIzquierdo:
    sll  $t5, $t2, 2         #temporal5 con el valor inicial de k *4 
    add  $t5, $a0, $t5       #muevo el puntero del arreglo 
    # $t3 puntero izquierdo
    sw   $t3, 0($t5)         #guardar el registro del puntero actual a la sublista
    addi $t0, $t0, 1         #aumentar i
    
mergeContinue:
    addi $t2, $t2, 1         #aumento en K
    j    mergeArrays
    
copiarRestanteIzq:
    beq  $t0, $s2, mergeEnd  ## i == n1
    sll  $t3, $t0, 2         # al t3 le llevo el i * 4
    #inicialmente $s4 solo tiene la dirección base de la lista izq
    add  $t3, $s4, $t3       #cambio al temporal $t3, la dirección del vector izquierdo
    lw   $t3, 0($t3)         #Para poder traerlo al banco de registros
    sll  $t4, $t2, 2         #aumentar a la siguiente dirección dado K
    add  $t4, $a0, $t4       #Para luego llevar el puntero a la siguiente posición del vector
    sw   $t3, 0($t4)         #guardar en la sublista
    addi $t0, $t0, 1         #aumentar i
    addi $t2, $t2, 1         #aumentar k
    j    copiarRestanteIzq
    
copiarRestanteDer:
    beq  $t1, $s3, mergeEnd   # j == n2
    sll  $t3, $t1, 2          # Al $t3 le llevo el i * 4
    add  $t3, $s5, $t3        # Cambio al temporal $t3, la dirección del vector derecho
    lw   $t3, 0($t3)          # Traer el valor al banco de registros
    sll  $t4, $t2, 2          #aumentar a la siguiente dirección dado K
    add  $t4, $a0, $t4        #Para luego llevar el puntero a la siguiente posición del vector
    sw   $t3, 0($t4)          #Guardar en la sublista
    addi $t1, $t1, 1          #aumentar j
    addi $t2, $t2, 1          #aumentar k
    j    copiarRestanteDer
    
mergeEnd:
    # Restaurar registros
    lw   $ra, 24($sp)
    lw   $s0, 20($sp)
    lw   $s1, 16($sp)
    lw   $s2, 12($sp)
    lw   $s3, 8($sp)
    lw   $s4, 4($sp)
    lw   $s5, 0($sp) 

    addi $sp, $sp, 28 #liberar los 7 registros necesitados
    jr   $ra

printArray:
    la   $t0, arreglo         # Dirección base del array
    lw   $t1, longitudArreglo          # Tamaño del array
    li   $t2, 0             # Contador
    
printLoop:
    beq  $t2, $t1, printEnd
    
    # Imprimir número
    li   $v0, 1
    lw   $a0, 0($t0)
    syscall
    
    # Imprimir espacio
    li   $v0, 4
    la   $a0, space
    syscall
    
    addi $t0, $t0, 4
    addi $t2, $t2, 1
    j    printLoop
    
printEnd:
    # Imprimir nueva línea
    li   $v0, 4
    la   $a0, newline
    syscall
    jr   $ra