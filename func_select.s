.section	.rodata	#read only data section
 .align 8
 
.L10:
 #quad - 8 bytes
 .quad .L0 #case 50:
 .quad .L1 #case 51
 .quad .L2 #case 52
 .quad .L3 #case 53
 .quad .L4 #case 54
 .quad .INVALIDOP #invalid option
 
scanStr:  .string "%s\0"
scanChar0to255:  .string "%hhu"
getChar: .string "%c"

invalidoptionmsg: .string "invalid option!\n"


pstrlenmsg: .string "first pstring length: %hhu, second pstring length: %hhu\n"
replaceCharmsg: .string "old char: %c, new char: %c, first string: %s, second string: %s\n"
pstrijcpymsg: .string "length: %d, string: %s\n"
swapCasemsg: .string "length: %d, string: %s\n"
pstrijcmpmsg: .string "compare result: %d\n"

getDummy: .string "%c"
getOldNewChars: .string "%c %c"


.text
.global funcselect
    .type   funcselect, @function  
funcselect:
    #no need to move the rbp to the rsp now because we are not allocating anything
        #str1length-rdi, str2length-rsi
        leaq -50(%rdx),%rdx             #rdx = rdx-50     
        cmpq $4,%rdx                    #if rdx>4  jump to the error
        jg .INVALIDOP
        cmpq $0,%rdx                    #if rdx<0  jump to the error
        jl  .INVALIDOP
                
        jmp *.L10(,%rdx,8)              #go to the place 8*rdx - in the array
        
    #pstrlen
    .L0:
        #caller save -> saving the adresses of str1 and str2 
        pushq   %rsi
       
        call    pstrlen                 #rdi has the adress to str1 length
        movq    %rax,%rsi               #length goes to %rsi
         
        pop     %rdi                    #pop 2nd string
        pushq   %rsi                    #caller save push result of pstrlen to backup                  
        
        call    pstrlen                 #with rdi->2nd str
        movq    $pstrlenmsg,%rdi        #1st param of printf is string message
        pop     %rsi                    #geting the result of str1length from the stack
        movq    %rax,%rdx               #return val of pstrlen str2 -> third parameter rdx/dl-1byte       
        movq    $0,%rax
        call    printf	
        	       
        jmp     .DONEALL
    #replaceChar
    .L1:
        #our goal is:
        #gets (Pstring* pstr, char oldChar, char newChar)
        #               rdi         rsi             rdx
        #replaces each oldChar with newChar
        
        #caller save -> saving the adresses of str1 and str2 
        pushq   %rdi            
        pushq   %rsi
        
        #scanning dummy
        subq    $1,%rsp                 #allocating byte for the "enter" after we scan a number that representing the func (50-54)
        movq    %rsp, %rsi              #old char will get to the bottom of the stack - to rsp
        movq    $getChar, %rdi
        movq    $0, %rax
        call    scanf                   #doing nothing with "\n"
        
        #allocating one more byte to collect the old and new chars from the user (already have 1byte of \n to override)
        movq    %rsp,%rdx               #"new char" will be in rdx which is 1 byte above rsp
        subq    $1,%rsp                 #alloc for the "old char"
        
        #lower number->old char,  upper->new char
        movq    %rsp,%rsi               #we get "old char" so it's the lower adress to rsi
        movq    $getOldNewChars, %rdi   #the string that we send them
        movq    $0, %rax
        call    scanf
        
        #extracting old and new char from the stack and &str2 at the end
        movzbq  (%rsp),%rsi             #moving the "oldchar" to rsi
        incq    %rsp
        movzbq  (%rsp),%rdx             #moving "new char" to rdx
        incq    %rsp                    #2 bytes freed of old and new char
        pop     %rdi                    #pop &str2length
        
        #saving regs
        pushq   %rsi                    #saving the old char caller reg
        pushq   %rdx                    #saving the new char caller reg
        
        call    replaceChar
        movq    %rax,%r8                #the 5th arg is the second string adress
        
        #load the paramateres from the stack for replaceChar function
        pop     %rdx                    #gets the new char
        pop     %rsi                    #gets the old char
        pop     %rdi                    #gets the &str1length        
        
        #saving caller reg before calling the func
        pushq   %r8                     #&str2len
        pushq   %rdx                    #new char
        pushq   %rsi                    #old char
        pushq   %rdi                    #&str1length
        
        call    replaceChar       
        #preparing for printing
        movq    $replaceCharmsg,%rdi     
        pop     %rcx                    #rcx gets the &str1length   
        movq    %rax,%rcx               #the return value of the replace char will be in rcx - 4th argument (override rcx in purpose)
        pop     %rsi                    #poping the old char
        pop     %rdx                    #poping the new char
        pop     %r8                     #poping &str2
        
        movq    $0,%rax
        call    printf                  #print order old->rsi new->rdx str1->rcx str2->r8
        
        jmp     .DONEALL
        #ret

    #pstrijcpy
    .L2:
        #callee save
        pushq   %rbx                    #we use it so we need to bring it back at the end
        #caller save -> saving the adresses of str1 and str2 
        pushq   %rsi                    #str2
        pushq   %rdi                    #str1  
               
        #scanning dummy
        subq    $1,%rsp                 #allocating byte for the "enter" after we scan a number that representing the func (50-54)
        movq    %rsp, %rsi              #old char will get to the bottom of the stack - to rsp
        movq    $getChar, %rdi
        movq    $0, %rax
        call    scanf                   #doing nothing with "\n"
        
        #we get "i"
        movq    %rsp,%rsi               
        movq    $scanChar0to255, %rdi   
        movq    $0, %rax
        call    scanf
        movzbq  (%rsp),%rbx             #we want "i" to be in rbx for now
        
        #getting dummy \n
        subq    $1,%rsp                 #allocating more space for "/n"
        movq    %rsp, %rsi
        movq    $getDummy, %rdi
        movq    $0, %rax
        call    scanf
        
        #getting "j" now
        movq    %rsp,%rsi              
        movq    $scanChar0to255, %rdi 
        movq    $0, %rax
        call    scanf
        
        movzbq  %bl,%rdx                #getting i from rbx to rdx
        movzbq  (%rsp),%rcx             #we want "j" to be in rcx
        addq    $2,%rsp                 #free 2 chars i,j memory
        
        pop     %rdi                    #rdi is str1
        pop     %rsi                    #rsi is str2
        
        #saving the str1 and str2
        pushq   %rsi
        pushq   %rdi

        call    pstrijcpy
        cmpq    $0,%rax                 
        je      .DONEALL
        movq    %rax,%rdx               #the string is the 3rd parameter for printf
        
        #movq    %r13,%rdi              #calling pstrlen
        pop     %rdi
        push    %rdx
        call    pstrlen                 #rdi has the str1 adress 
        movzbq  %al,%rsi                #returns the length which is the 2nd parameter for printf
        movq    $pstrijcpymsg,%rdi      #the 1st param for printf 
        pop     %rdx
        movq    $0,%rax
        call    printf
        
        
        #movq    %r14,%rdx           #the string is the 3rd parameter for printf
        pop     %rdi                    #rdi gets the adress to str2 from the stack
        pushq   %rdi                    #caller saving
        call    pstrlen    
        movq    $pstrijcpymsg,%rdi  #the 1st param for printf
        movzbq  %al,%rsi            #the length is the 2nd parameter for printf
        pop     %rdx
        incq    %rdx
        movq    $0,%rax
        call    printf

        #callee save back to life
        pop     %rbx
        #pstrijcpymsg: .string "length: %d, string: %s\n"
        jmp     .DONEALL
        #pstrijcpy
        #ret
        
    #swapCase
    .L3:
        #swapCasemsg: .string "rsi: length: %d, rdx: string: %s\n"
        
        #caller save -> saving the adresses of str1 and str2 
        pushq   %rsi                    #str2
        pushq   %rdi                    #str1  
        
        call    swapCase                #rdi has &str1
        movq    %rax,%rdx               #rdx has the %str1
        
        #saving caller reg
        pop     %rdi                    #gets &s1
        pushq   %rdx                    #save &s1 without length char
        call    pstrlen
        movq    $swapCasemsg,%rdi
        movzbq  %al,%rsi
        pop     %rdx                    #insert to rdx 3rd param for printf the &s1 no length
        movq    $0,%rax
        call    printf
        
        #string2 is playing here
        pop     %rdi                    #gets s2 with length
        push    %rdi                    #backup for pstrlen func
        call    swapCase
        movq    %rax,%rdx               #insert to rdx 3rd param for printf the &s1 no length
        pop     %rdi
        pushq   %rdx                    #bckup the &s2 without length
        call    pstrlen                 #with s2
        movq    $swapCasemsg,%rdi
        movzbq  %al,%rsi
        pop     %rdx                    #insert to rdx 3rd param for printf the &s2 no length
        movq    $0,%rax
        call    printf
        
        #replaces each upperCase to lower and each lowerCase to upper
        #swapcase
        jmp     .DONEALL
        #ret
        
    #pstrijcmp
    .L4:
        #callee save
        pushq   %rbx                    #we use it so we need to bring it back
        
        #caller save -> saving the adresses of str1 and str2 
        pushq   %rsi                    #str2
        pushq   %rdi                    #str1  
               
        #scanning dummy
        subq    $1,%rsp                 #allocating byte for the "enter" after we scan a number that representing the func (50-54)
        movq    %rsp, %rsi              #old char will get to the bottom of the stack - to rsp
        movq    $getChar, %rdi
        movq    $0, %rax
        call    scanf                   #doing nothing with "\n"
        
        #we get "i"
        movq    %rsp,%rsi               
        movq    $scanChar0to255, %rdi   
        movq    $0, %rax
        call    scanf
        movzbq  (%rsp),%rbx             #we want "i" to be in rbx for now
        
        #getting dummy \n
        subq    $1,%rsp                 #allocating more space for "/n"
        movq    %rsp, %rsi
        movq    $getDummy, %rdi
        movq    $0, %rax
        call    scanf
        
        #getting "j" now
        movq    %rsp,%rsi              
        movq    $scanChar0to255, %rdi 
        movq    $0, %rax
        call    scanf
        
        movzbq  %bl,%rdx                # "i" from rbx to rdx
        movzbq  (%rsp),%rcx             # "j" to be in rcx
        addq    $2,%rsp                 #free 2 chars i,j memory
        
        pop     %rdi                    #rdi is str1
        pop     %rsi                    #rsi is str2

        call    pstrijcmp
        #cmpq    $0,%rax                 
        #je      .FINISH
        movq    $pstrijcmpmsg,%rdi
        movq    %rax,%rsi               #compare result to rsi
        movq    $0,%rax
        call    printf

        #callee save back to life
        pop     %rbx
        #pstrijcmp
        jmp     .DONEALL
        ret

    #invalid option
    .INVALIDOP:
        movq	$invalidoptionmsg,%rdi	    #passing the string the first parameter for printf.
        movq	$0,%rax
        call	printf	
        #jmp     .DONEALL	
        #ret
    
    
    .DONEALL:    
    movq	       $0, %rax                
    movq	       %rbp, %rsp	#restore old stack pointer to free the memory
    popq       %rbp		#restore old frame pointer (the caller function frame)
    ret				#return to caller function (OS)  
