.section .rodata
invalidinput: .string "invalid input!\n"
.text
.global pstrlen
    .type   pstrlen, @function
pstrlen:                            #gets Pstring* pstr and returns the length of the string
    movzbq (%rdi),%rax              #means: x=*p so we get the first char, the length
    ret                             #return the length
    
    
    .type   replaceChar, @function
#gets (Pstring* pstr, char oldChar, char newChar)
#               rdi         rsi             rdx
#replaces each oldChar with newChar
#the new and old chars are not '/0' (we can assume that)
#returns pointer to pstr
.global replaceChar
    .type   replaceChar, @function
replaceChar:
    movq    %rdi,%rax               #saving the adress of pstr to the return value
    incq    %rax

    movzbq  (%rdi),%rcx             #rcx gets the length of the string, we can loop - byte of rcx is cl
    cmpb    $0,%cl                  #if the length is 0 - jump to DONE
    je      .DONE51

    xorq    %r8,%r8                 #setting counter to 0
    .LOOP51:
        addq    $1,%r8              #at first add one to the counter, the first char will be at the first place        
        incq    %rdi                #adding 1 to the addres of rdi
        
        cmpb    (%rdi),%sil         #comp between str[i] and oldChar
        jne .DIFF51                 #if they are different(jne=jump not equal), jump to where we add 1 to counter
        
        movb    %dl,(%rdi)          #if they are not diff put the new char in rdi[i]
        cmpq    %r8,%rcx            #if counter=length -> done
        je .DONE51
        
    .DIFF51:   
        cmpq %rcx,%r8               #if r8<=rcx if counter<=length goto loop
        jle .LOOP51
    .DONE51:
        ret

    .type   pstrijcpy, @function      
#gets (Pstring* dst, Pstring* src, char i, char j)
#               rdi           rsi     rdx     rcx
#replaces each oldChar with newChar
#returns pointer to dst
#assume - the length of dst will not change after copy
.global pstrijcpy
    .type   pstrijcpy, @function
pstrijcpy:
    cmpq    %rcx,%rdx               #if i-j>0 , i>j (works) ok, if not jump to invalid52
    jg      .INVINP52

    movq    %rdi,%rax               #saving the adress of dst to the return value
    incq    %rax                    #moving the rax to be the start of the word without the length
 
    movzbq  (%rsi),%r8              #r8 gets the length of the string2
    cmpq    %r8,%rcx                #if j-str2length>0 jump
    jg      .INVINP52
    
    movzbq  (%rdi),%r8              #r8 gets the length of the string1
    cmpq    %r8,%rcx                #if j-str1length>0 jump
    jg      .INVINP52
   
    movq    $-1,%r9                 #counter r9 will srart from 0
    .LOOP52:
        incq    %r9                 #first iter rdi and rsi is pointing to place[0] exactly the first char of the word
        incq    %rdi
        incq    %rsi
        cmpq    %rdx,%r9            #if counter<i , go to the start of the loop and increament rdi
        jl     .LOOP52
        cmpq    %rcx,%r9            #if counter>j, go to done!
        jg      .DONE52
        movzbq  (%rsi),%rbx         #move the char in rsi to rbx (like temp)
        movb    %bl,(%rdi)          #move the char to rdi
        jmp     .LOOP52
    
    .INVINP52:
        movq    $invalidinput,%rdi
        movq    $0,%rax
        call    printf              #print invalid input
    
    .DONE52:
        ret

    .type   swapCase, @function      
#gets (Pstring* pstr)
#           rdi
#replaces each upperCase to lower and each lowerCase to upper
#no change other ascii chars (A:65-Z:90,a:97-z:122)
#returns pointer to dst
.global swapCase
    .type   swapCase, @function
swapCase:
    movq    %rdi,%rax           #saving the adress of pstr to the return value
    incq    %rax
    
    cmpq $0,(%rdi)              #if the first char is 0 then jump to done
    je .DONE53
    
    movzbq (%rdi),%r8           #rcx gets the length of the string, we can loop
    incq    %rdi
    movq $1,%r9                 #counter will start from 1
                     
    .LOOP53:
        cmpb $65,(%rdi)         #if char<65 goto INC the index
        jl .INC53
        #we know char>=65
        cmpb $90,(%rdi)         #if char<=90 goto change upper
        jle .CHANGEUPPER53
        #we know char>90
        cmpb $97,(%rdi)         #if char<97 its not an english letter - skip and increase index
        jl .INC53
        #the char>=97
        cmpb $122,(%rdi)        #if char>122 goto INC
        jg .INC53
        #now we know char is>=97 and<=122
        subb $32,(%rdi)         #subtract 32 to get uppercase
        jmp .INC53              #increas index
     
     .CHANGEUPPER53:
        addb $32,(%rdi)         #changing the upper to lower by adding 32 to the ascii value
     
     .INC53:
        incq    %r9             #increase the counter
        incq    %rdi            #increase the index of the word
        
        cmpq    %r8,%r9         #if counter<=length - loop
        jle .LOOP53
     
     #else, go to DONE
     .DONE53:
        ret
   
     .type   pstrijcmp, @function      
#gets (Pstring* pstr1, Pstring* pstr2, char i, char j)
#               rdi             rsi       rdx     rcx
#replaces each oldChar with newChar
#returns int by lexicographic value: 1 if str1ij>str2ij
#-1 if str1ij<str2ij, 0 if str1ij=str2ij
#-2 if ij are not compatible
#assume - the length of dst will not change after copy 
.global pstrijcmp
    .type   pstrijcmp, @function               
pstrijcmp:
    #callee saves
    #pushq   %r8                 
    #pushq   %r9 
                    
    cmpq    %rcx,%rdx           #if i-j>0 , i>j (works) ok, if not jump to invalid52
    jg      .INVINP54
    
    movq    %rdi,%rax           #saving the adress of dst to the return value
    incq    %rax                #moving the rax to be the start of the word without the length
  
    movzbq  (%rsi),%r8          #r8 gets the length of the string2
    cmpq    %r8,%rcx            #if j-str2length>0 jump
    jge      .INVINP54
    
    movzbq  (%rdi),%r8          #r8 gets the length of the string1
    cmpq    %r8,%rcx            #if j-str1length>0 jump
    jge      .INVINP54
    
    
    movq    $-1,%r9             #counter r9 will srart the LOOP from 0
    .LOOP54:
        incq    %r9             #first iter it will be 0
        incq    %rdi            #first iter it will be the start of the word str1
        incq    %rsi            #first iter it will be the start of the word str2
        
        cmpq    %r9,%rdx        #if ctr<i go to loop dont check things
        jg      .LOOP54         
        cmpq    %r9,%rcx        #if ctr>j means every char between i and j is similar so go to IJSAME
        jl      .IJSAME

        #r10->str2[i], r8->str1[i]
        movzbq  (%rdi),%r8      #extract the char from the current place in str1
        movzbq  (%rsi),%r10     #extract the char from the current place in str1
        
        cmpq    %r8,%r10        
        jg      .STR2           #if str2>str1
        jl      .STR1           #if str2<str1
        je      .LOOP54         #if equals go to loop
        
    #str2>str1 
    .STR2:
        movq $-1,%rax           #return -1
        ret
    
    #str2<str1    
    .STR1:
        movq $1,%rax            #return 1
        ret

    .INVINP54:       
        movq    $invalidinput,%rdi
        movq    $0,%rax
        call    printf          #print invalid input
        movq    $-2,%rax        #return -2
        ret
    
    .IJSAME:
        movq    $0,%rax
        ret
    