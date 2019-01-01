.section	.rodata	#read only data section
scanStr:  .string "%s\0"
scanChar0to255:  .string "%hhu"
scanInt: .string "%d"

.text
.globl	main	#the label "main" is used to state the initial point of this program
	.type	main, @function	# the label "main" representing the beginning of a function
main:
        movq    %rsp, %rbp       
        pushq   %rbp		       #save the old frame pointer
        movq    %rsp,%rbp	       #create the new frame pointer
        
        #saving callee reg we will use here
        pushq   %r13
        pushq   %r15
        
        #scanning unsigned char to %r10 
        subq    $1,%rsp                 #allocating space for a char - the length
        movq    %rsp, %rsi
        movq    $scanChar0to255, %rdi   #scanning unsigned char to the stack
        movq    $0, %rax       
        call    scanf                   #now the char number is the lowest and only in the stack
        movzbq  (%rsp), %r10            #length is on %r10 - temporary
    
        #allocating the length of the string, and the \0 will override the char of the length that we saved
        subq    %r10,%rsp               #allocate length
        movq    %rsp, %rsi              #moving the adress of rsp to scanf    
        push    %r10                    #caller save 
        movq    $scanStr, %rdi          #scanning string
        movq    $0, %rax
        call    scanf
        pop     %r10
        #movq    %rsp,%r12               #save the adress of the start of the first word on r12
        
        #saving the length below the first letter of the word
        subq    $1,%rsp                 #allocate 1 more byte to save the length under the string
        movq    %rsp,%r13               #rsp -> the first str length is on r13
        movb    %r10b,(%rsp)            #length goes to the value of rsp

        ##########################################
        # 1st string scanned with length         #
        # now we move on to scan the 2nd string  #
        ##########################################
        
        #scanning unsigned char to %r10 
        subq    $1,%rsp                 #allocating space for a char - the length
        movq    %rsp, %rsi
        movq    $scanChar0to255, %rdi   #scanning unsigned char to the stack
        movq    $0, %rax       
        call    scanf                   #now the char number is the lowest and only in the stack
        movzbq  (%rsp), %r10            #length is on %r10 - temporary
        
        #allocating the length of the string, and the \0 will override the char of the length that we saved
        subq    %r10,%rsp               #allocate length
        movq    %rsp, %rsi              #moving the adress of rsp to scanf    
        push    %r10                    #caller save 
        movq    $scanStr, %rdi          #scanning string
        movq    $0, %rax
        call    scanf
        pop     %r10
        #movq    %rsp,%r14               #save the adress of the start of the first word on r12
        
        #saving the length below the first letter of the word
        subq    $1,%rsp                 #allocate 1 more byte to save the length under the string
        movq    %rsp,%r15               #rsp -> the first str length is on r13
        movb    %r10b,(%rsp)            #length goes to the value of rsp       

        #scanning the integer of the option
        leaq    -4(%rsp),%rsp           #alloc 4 bytes to get int
        movq    $scanInt,%rdi
        movq    %rsp,%rsi
        movq    $0, %rax
        call    scanf
        movl    (%rsp),%edx             #int is on rdx - 3rd parameter to send the func
        movq    %r13,%rdi               #&length of first number -> rdi
        movq    %r15,%rsi               #&length of second number ->rsi

        #bringing back to life the callee reg
        pop     %r15
        pop     %r13
        
        call    funcselect
        
        
        
        movq    $0,%rax
        movq    %rbp, %rsp
        pop     %rbp
        ret
        