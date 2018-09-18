; Authors: Reuben Kernan, Alex Taxiera
; Date: April 29, 2018
; Final Project
; Description: See document

.386
.MODEL FLAT, C
ExitProcess PROTO stdcall, dwExitCode:DWORD

_stackPush    PROTO C, Stack:DWORD, value:BYTE
_stackPop     PROTO C, Stack:DWORD
_stackDequeue PROTO C, Stack:DWORD
_enqueue      PROTO C, Queue:DWORD, value:BYTE
_dequeue      PROTO C, Queue:DWORD
_towers       PROTO C, disks:BYTE, Source:DWORD, Destination:DWORD, Auxiliary:DWORD

.DATA
_maxHeight EQU 10
_diskNum   EQU 3
;====================================================;
; Reusable Stack structure                          ;
;====================================================;
; height: Current number of things in stack         ;
; levels: Array of things in the stack              ;
;         Length is set by _maxHeight global        ;
;====================================================;
OURSTACK STRUCT
    height    BYTE 0
    levels    BYTE _maxHeight DUP(0)
OURSTACK ENDS

;====================================================;
; Reusable Queue structure, maximum elements based   ;
; on OURSTACK _maxHeight implemented using previous  ;
; stack structure as per the original bonus          ;
; assignment in Data Structures & Algorithms         ;
;====================================================;
; Input:  Stack that gets pushed to during enqueue   ;
; Output: Stack that gets popped from during dequeue ;
;====================================================;
OURQUEUE STRUCT
    Input  OURSTACK <>
    Output OURSTACK <>
OURQUEUE ENDS

.CODE

_main PROC
    ; test stack ;
    LOCAL Stack       :OURSTACK
    ; hanoi stacks ;
    LOCAL Source      :OURSTACK
    LOCAL Auxiliary   :OURSTACK
    LOCAL Destination :OURSTACK
    ; queue stack ;
    LOCAL FakeQueue   :OURSTACK
    ; test queue ;
    LOCAL Queue       :OURQUEUE

    ;======================;
    ;   Start Stack Test   ;
    ;======================;
    MOV ecx, 0
    _fill_stack:
        INC cl
        INVOKE _stackPush, ADDR Stack, cl
        CMP al, cl
        JNE _stack_fail
    CMP cl, _maxHeight
    JNE _fill_stack

    LEA esi, Stack.levels
    MOV ecx, _maxHeight
    _confirm_stack_fill:
        MOV dl, cl
        DEC ecx
        MOV eax, [esi + ecx]
        CMP al, dl
        JNE _stack_fail
        INC ecx
    LOOP _confirm_stack_fill

    ; check return value of push when stack is full ;
    INVOKE _stackPush, ADDR Stack, 1
    CMP al, -1
    JNE _stack_fail

    mov ecx, _maxHeight
    _empty_stack:
        INVOKE _stackPop, ADDR Stack
        CMP al, cl
        JNE _stack_fail
    LOOP _empty_stack

    LEA esi, Stack.levels
    MOV ecx, _maxHeight
    _confirm_stack_empty:
        DEC ecx
        MOV eax, [esi + ecx]
        CMP al, 0
        JNE _stack_fail
        INC ecx
    LOOP _confirm_stack_empty

    ; check return value of pop when stack is empty ;
    INVOKE _stackPop, ADDR Stack
    CMP al, -1
    JNE _stack_fail

    ; happy path, skip fail label ;
    JMP _hanoi_test

    ; test failed, error code 1, exit ;
    _stack_fail:
    INVOKE ExitProcess, 1
    ;======================;
    ;    End Stack Test    ;
    ;======================;


    ;======================;
    ;   Start Hanoi Test   ;
    ;======================;
    _hanoi_test:

    ; Initializing the source stack with disks ;
    MOV ecx, _diskNum
    _init:
        INVOKE _stackPush, ADDR Source, cl
    LOOP   _init

    INVOKE _towers, Source.height, ADDR Source, ADDR Destination, ADDR Auxiliary

    ; Check Final Destination ;
    LEA edi, Destination.levels
    MOV ecx, _diskNum
    MOV edx, 0
    _confirm_hanoi:
        MOV eax, [edi + edx]
        CMP al, cl
        JNE _hanoi_fail
        INC edx
    LOOP _confirm_hanoi

    ; happy path, skip fail label ;
    JMP _fake_queue_test

    ; test failed, error code 2, exit ;
    _hanoi_fail:
    INVOKE ExitProcess, 2
    ;======================;
    ;    End Hanoi Test    ;
    ;======================;


    ;======================;
    ; Start FakeQueue Test ;
    ;======================;
    _fake_queue_test:

    MOV ecx, 2
    _fill_fake_queue:
        INVOKE _stackPush, ADDR FakeQueue, cl
    LOOP _fill_fake_queue

    ; FakeQueue contains [2, 1] ;
    INVOKE _stackDequeue, ADDR FakeQueue
    cmp al, 2
    JNE _fake_queue_fail

    LEA esi, FakeQueue.levels
    MOV ecx, _maxHeight
    MOV edi, 1
    _confirm_dequeue:
        CMP cl, 1
        JNE  _expect_zero

        MOV edx, [esi]
        CMP dl, 1
        JNE _fake_queue_fail
        JMP _next

        _expect_zero:
        MOV dl, [esi + edi]
        CMP dl,  0
        JNE _fake_queue_fail

        _next:
        INC edi
    LOOP _confirm_dequeue

    ; happy path, skip fail label ;
    JMP _queue_test

    ; test failed, error code 3, exit ;
    _fake_queue_fail:
    INVOKE ExitProcess, 3
    ;======================;
    ;  End FakeQueue Test  ;
    ;======================;


    ;======================;
    ;   Start Queue Test   ;
    ;======================;
    _queue_test:

    MOV ecx, _maxHeight
    MOV edx, 1
    _fill_queue:
        INVOKE _enqueue, ADDR Queue, cl
        CMP al, dl
        JNE _queue_fail
        INC edx
    LOOP _fill_queue

    LEA esi, Queue.Input.levels
    MOV ecx, _maxHeight
    MOV edx, 0
    _confirm_queue_fill:
        MOV eax, [esi + edx]
        CMP al, cl
        JNE _queue_fail
        INC edx
    LOOP _confirm_queue_fill

    ; check return value of push when stack is full ;
    INVOKE _enqueue, ADDR Queue, 1
    CMP al, -1
    JNE _queue_fail

    MOV ecx, _maxHeight
    _empty_queue:
        INVOKE _dequeue, ADDR Queue
        CMP al, cl
        JNE _queue_fail
    LOOP _empty_queue

    LEA esi, Queue.Input.levels
    LEA edi, Queue.Output.levels
    MOV ecx, _maxHeight
    MOV edx, 0
    _confirm_queue_empty:
        MOV eax, [esi + edx]
        CMP al, 0
        JNE _queue_fail
        MOV eax, [edi + edx]
        CMP al, 0
        JNE _queue_fail
    LOOP _confirm_queue_empty

    ; check return value of pop when stack is empty ;
    INVOKE _dequeue, ADDR Queue
    CMP al, -1
    JNE _queue_fail

    ; happy path, skip fail label ;
    JMP _end

    ; test failed, error code 4, exit ;
    _queue_fail:
    INVOKE ExitProcess, 4
    ;======================;
    ;    End Queue Test    ;
    ;======================;

    ; success ;
    _end:
    INVOKE ExitProcess, 0
_main ENDP

;====================================================;
; Performs a push operation on OURSTACK              ;
;====================================================;
; Stack: Address of OURSTACK to push to              ;
; value: BYTE value to push to OURSTACK              ;
;====================================================;
; RETURNS: -1 when OURSTACK was full                 ;
;        : new height of OURSTACK after push         ;
;====================================================;

_stackPush PROC Stack:DWORD, value:BYTE
    ; setting pointer to act like specified STRUCT ;
    MOV    ebx, Stack
    ASSUME ebx:ptr OURSTACK
    
    MOV edx, _maxHeight
    CMP [ebx].height, dl
    MOV al, -1
    JE _full

    LEA edi, [ebx].levels
    XOR edx, edx
    MOV dl, [ebx].height
    MOV al, value
    MOV [edi+edx], al
    INC [ebx].height
    MOV al, [ebx].height

    _full:
    ASSUME ebx:nothing
    RET
_stackPush ENDP

;====================================================;
; Performs a pop operation on OURSTACK               ;
;====================================================;
; Stack:   Address of OURSTACK to pop from           ;
; RETURNS: -1 when OURSTACK was empty                ;
;          Value popped from OURSTACK                ;
;====================================================;

_stackPop PROC Stack:DWORD
    MOV    ebx, Stack
    ASSUME ebx:ptr OURSTACK

    CMP [ebx].height, 0
    MOV al, -1
    JE  _empty

    DEC [ebx].height
    LEA edi, [ebx].levels
    XOR edx, edx
    MOV dl, [ebx].height
    MOV al, [edi + edx]
    MOV [edi+edx], dh

    _empty:
    ASSUME ebx:nothing
    RET
_stackPop ENDP

;====================================================;
; Removes the first element from OURSTACK, as if it  ;
; were a queue, all remaining elements are moved     ;
; down the stack                                     ;
;====================================================;
; Stack:   Address of OURSTACK to remove from        ;
; RETURNS: -1 when OURSTACK was empty                ;
;          Value popped from OURSTACK                ;
;====================================================;

_stackDequeue PROC Stack:DWORD
    MOV    ebx, Stack 
    ASSUME ebx:ptr OURSTACK

    CMP [ebx].height, 0
    MOV al, -1
    JE  _empty

    LEA edi, [ebx].levels
    XOR edx, edx
    _loop:
        CMP dl, [ebx].height
        JE _last
        CMP edx, 0
        JNE _shift

        _first:
        MOV al, [edi]
        _shift:
        MOV ah, [edi + edx + 1]
        MOV [edi + edx], ah
        JMP _end
        _last:
        MOV [edi + edx], dh
        _end:
        INC dl
    CMP dl, [ebx].height
    JL  _loop

    DEC [ebx].height
    _empty:
    ASSUME ebx:nothing
    RET
_stackDequeue ENDP

;====================================================;
; Performs an enqueue operation on OURQUEUE          ;
;====================================================;
; Queue:   Address of OURQUEUE to queue to           ;
; value:   BYTE value to queue onto OURQUEUE         ;
;====================================================;
; RETURNS: -1 when OURQUEUE was full                 ;
;        : new length of OURQUEUE after queue        ;
;====================================================;

_enqueue PROC Queue:DWORD, value:BYTE
    MOV    esi, Queue 
    ASSUME esi:ptr OURQUEUE

    ; if contains _maxHeight elements ;
    MOV dl, [esi].Input.height
    ADD dl, [esi].Output.height
    CMP dl, _maxHeight
    MOV al, -1
    JE  _full

    INVOKE _stackPush, ADDR [esi].Input, value
    INC dl
    MOV al, dl

    _full:
    ASSUME esi:nothing
    RET
_enqueue ENDP

;====================================================;
; Performs a dequeue operation on OURQUEUE           ;
;====================================================;
; Queue:   Address of OURQUEUE to dequeue from       ;
;====================================================;
; RETURNS: -1 when OURQUEUE was empty                ;
;          Value dequeued from OURQUEUE              ;
;====================================================;

_dequeue PROC Queue:DWORD
    MOV    esi, Queue 
    ASSUME esi:ptr OURQUEUE

    ; if output empty ;
    CMP [esi].Output.height, 0
    JNE output_not_empty

    ; if input also empty ;
    CMP [esi].Input.height, 0
    MOV al, -1
    JE  _empty

    MOV ch, [esi].Input.height
    _transfer:
        INVOKE _stackPop, addr [esi].Input
        INVOKE _stackPush, addr [esi].Output, al
        DEC    ch
    CMP ch, 0
    JNE _transfer

    output_not_empty:
    INVOKE _stackPop, ADDR [esi].Output
    
    _empty:
    ASSUME esi:nothing
    RET
_dequeue ENDP

;====================================================;
; Recursive solution to Towers of Hanoi problem      ;
;====================================================;
; disks:       Number of disks in problem            ;
; Source:      Address of Source OURSTACK            ;
; Destination: Address of Destination OURSTACK       ;
; Auxiliary:   Address of Auxiliary OURSTACK         ;
;====================================================;

_towers PROC disks:BYTE, Source:DWORD, Destination:DWORD, Auxiliary:DWORD
    ; if one disk stop calling and swap ;
    CMP disks, 1
    JE  _swap

    ; recursive calls
    DEC disks
    INVOKE _towers, disks, Source,    Auxiliary,   Destination
    INVOKE _towers, 1,     Source,    Destination, Auxiliary
    INVOKE _towers, disks, Auxiliary, Destination, Source
    JMP _end
    
    _swap:
    INVOKE _stackPop,  Source
    INVOKE _stackPush, Destination, al
    _end:
    RET
_towers ENDP
END