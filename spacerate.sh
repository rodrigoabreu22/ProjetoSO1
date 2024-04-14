#!/bin/bash
                             #Declaração de arrays
declare -A output1           #array que guarda o output de uma execução do script (spacecheck.sh)
declare -A output2           #array que guarda o output de uma execução do script (spacecheck.sh)
declare -A removed_output    #array que guarda os diretorios e atribui valor true aos removidos
declare -A new_output        #array que guarda os diretorios do segundo ficheiro e atribui o valor true aos novos ficheiros
declare -a files             #array que guarda os ficheiros passados como argumento
declare -A final_output      #array que guarda o output final

                             #Declaração de variáveis
declare r=false              #por default a ordem não é invertida
declare a=false              #por default os ficheiros não estão ordenados por nome
declare type_sort="-k1,1nr"  #tipo de ordenação, por omissão é ordenado por ordem decrescente de tamanho


validate_files() { #esta função valida os ficheiros passados como argumentos
        count=0

        for arg in "$@"; do
                if [ -f "$arg" ]; then #verifica se é ficheiro
                        count=$((count + 1)) #incrementa o counter 
                        files+=("$arg") #armazena cada ficheiro num array
                fi
        done
        if [ ! $count -eq 2 ]; then #verifica que o numero de ficheiros tem de ser exatamente 2
                echo "Não existem exatamente 2 argumentos do tipo ficheiro."
        exit 1
        fi
}


args(){ #Esta função lida com os argumentos 
        while getopts "ra" arg 2>/dev/null; do 
                   case $arg in
                        r)
                                r=true  #ativa a inversão da ordenação
                                ;;
                        a)
                                a=true #ativa a ordenação por ordem alfabetica
                                ;;
                        \?)
                                echo "Insira argumentos válidos. " >&2 #lida com argumentos inválidos
                                exit 1
                                ;;
                        esac
        done
}

typesort(){ #esta função define o tipo de ordenção tendo em conta o valor das variaveis definido na função args
        if [ "$r" == true ]; then
                if [ "$a" == true ]; then
                        type_sort="-k2,2r" #filtro por nome com a ordem invertida
                else
                        type_sort="-k1,1n" #filtro por tamanho por ordem crescente
                fi
        else
                if [ "$a" == true ]; then
                        type_sort="-k2,2" #filtro por nome com a ordem invertida
                fi
        fi
}

outputStorer(){
        skip_line1=true 

        while IFS= read -r linha || [[ -n "$linha" ]]; do #leitura do ficheiro 1 linha a linha
                if [ "$skip_line1" = true ]; then #ignorar primeira linha
                        skip_line1=false #as proximas linhas vão ser lidas
                        continue
                        
                else
                        size=$(echo "$linha" | cut -d\  -f1) #linha dividida em 2, atribuindo a primeira parte à variável size
                        name=$(echo "$linha" | cut -d\  -f2-) #linha dividida em 2, atribuindo a segunda parte à variável name
                        output1[$name]=$size #guarda se num array associativo o nome do diretorio e o respetivo tamanho
                        removed_output[$name]=true #guarda-se o nome do diretorio no array "removed_output" com variavel true
                fi
        done < "${files[0]}"

        skip_line1=true #é necessário ignorar a primeira linha outra vez para a leitura do ficheiro 2 linha a linha

        while IFS= read -r linha || [[ -n "$linha" ]]; do
                if [ "$skip_line1" = true ]; then #ignorar primeira linha
                        skip_line1=false #as proximas linhas vão ser lidas
                        continue
                else    
                        size2=$(echo "$linha" | cut -d\  -f1) #linha dividida em 2, atribuindo a primeira parte à variável size2
                        name2=$(echo "$linha" | cut -d\  -f2-) #linha dividida em 2, atribuindo a segunda parte à variável name
                        output2[$name2]=$size2 #guarda se num array associativo o nome do diretorio e o respetivo tamanho
                        for name1 in "${!output1[@]}"; do
                                if [ "$name1" == "$name2" ]; then
                                        removed_output[$name2]=false #se houver diretorios em comum em ambos os ficheiros, o ficheiro não foi removido (false)
                                else    
                                        new_output[$name2]=true #assumimos os diretorios diferentes do ficheiro 2 como novos (true)
                                fi
                        done
                fi
        done < "${files[1]}"
}

outputComparer(){ #vai comparar o conteudo dos 2 ficheiros e adicionar de forma correta os valores ao array final_output
        for name1 in "${!output1[@]}"; do
                sizeout1=${output1[$name1]}
                removed=${removed_output[$name1]}
                if [ "$removed" == true ]; then
                        difference=$(( 0 - $sizeout1 )) #subtrai-se o tamanho total do diretorio caso este tenha sido removido
                        final_output[$name1]=$difference 
                else 
                        for name2 in "${!output2[@]}"; do  
                                sizeout2=${output2[$name2]}
                                if [ "$name2" == "$name1" ]; then 
                                        difference=$(( $sizeout2 - $sizeout1 ))  #calcula da variação do tamanho de cada diretorio
                                        final_output[$name2]=$difference
                                        new_output[$name2]=false #como os nome diretorios são iguais, $name2 não é diretorio novo (false)
                                fi
                        done
                fi
        done
        for name2 in "${!new_output[@]}"; do
                if [ ${new_output[$name2]} == true ]; then
                        final_output[$name2]=${output2[$name2]} #adicionar os diretorios novos  e o respetivo tamanho ao final_output
                fi
        done
}

printer(){
        printf "SIZE NAME\n" #cabeçalho
        for key in "${!final_output[@]}"; do
                printf "%s %s\n" "${final_output["$key"]}" "$key" 
        done | sort "$type_sort"| while read -r line; do #ordenção do final_output com base na variavel $type_sort definida anteriormente
                size=$(echo "$line" | awk '{print $1}') 
                name=$(echo "$line" | cut -d" " -f2-) #dividão da linha atribuindo os respetivos valores à variaveis
                if [ "${new_output[$name]}" == true ]; then #condições para o caso do ficheiro ser novo ou ter sido removido
                        printf "%s %s NEW\n" "$size" "$name"
                elif [ "${removed_output[$name]}" == true ]; then
                        printf "%s %s REMOVED\n" "$size" "$name"
                else 
                        printf "%s %s\n" "$size" "$name"
                fi
        done
}

spacerate(){ #main, passa apenas os argumentos necessárioa cada função e executa-as
        validate_files "$@"
        args "$@"
        outputStorer 
        outputComparer 
        typesort
        printer 
}

spacerate "$@" #execução do programa
