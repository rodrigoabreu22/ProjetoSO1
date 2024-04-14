#!/bin/bash
                                                #DECLARAÇÃOO DE ARRAYS/DICIONÁRIOS
declare -A dict                                 #dicionário que contém como chaves os diretórios e como values o espaço ocupado pelos ficheiros    
declare -a allfiles                             #array que contém todos os ficheiros já analisados pela função dicarr
declare -a dire                                 #array que contém todos os inputs do utilizador
declare -a prefix_before                        #array que contém todos os prefixos iniciais (com repetição)
declare -a sort_prefix                          #array que contém todos os prefixos (sem repetição)

                                                #DECLARAÇÃO DE VARIÁVEIS
declare a=false                                 #assume true se (-a) for um argumento
declare r=false                                 #assume true se (-r) for um argumento
declare size=false                              #assume true se (-s) for um argumento
declare sufix=false                             #assume true se (-n) for um argumento
declare has_l=false                             #assume true se (-l) for um argumento
declare fd=false                                #assume true se (-d) for um argumento
declare files=false                             #assume true se (-s, -n ou -d) forem argumentos
declare inputs="$@"                             #todos os inputs do utilizador
declare f=""            
declare l=0
declare s=0                                     
declare n_linhas=0                              
declare n=""                                    
declare date1=$(date "+%b %d %H:%M")
declare today=$(date +'%Y%m%d')
countargs=0


errordetector(){
	local check="$1"
        if [[ ! ( "$l" =~ ^[0-9]+$ ) &&  "$has_l" == true || ! ( "$s" =~ ^[0-9]+$ ) &&  "$size" == true ]]; then
                echo "Error: Tem a certeza que o target do -l ou -s só contem um ou mais dígitos"
                exit 1
        elif [[ -n "$n" && "$n" =~ [0-9] && "$sufix" == true ]]; then
                echo "Error: Tem a certeza que o target do -n é uma string"
                exit 1
        elif ! date -d "$d" &>/dev/null && [[ "$fd" == true ]]; then
                echo "Error: Tem a certeza que o target do -d é uma data válida (não te esqueças das aspas)"
                exit 1
        else
                for ((i = $countargs; i < ${#dire[@]}; i++)); do
                        if [ ! -d "${dire[i]}" ]; then
                                echo "Error: '${dire[i]}' ------ diretório inválido"
                                echo "Aviso: Tenha a certeza que os diretórios são os últimos argumentos que escreve"
                                exit 1
                        fi
                done
        fi

}

dicarr(){
        local current_directory="$1"
        local full_name="${current_directory}"
        if [ -d "$full_name" ]; then
                        if [[ ! -n ${dict["$full_name"]} ]]; then
                                find "$full_name" -maxdepth 1 -type f -print0 2>/dev/null > discard.txt
                                if [ $? -eq 1 ]; then
                                        dict["$full_name"]=-1
                                        return 1
                                else
                                        dict[$full_name]=0
                                fi
                        fi
        else
                local disk_usage=$(du -b "$current_directory" | awk '{print $1}')
                if [[ ! " ${allfiles[*]} " =~ " $full_name " ]];then
                        for key in "${!dict[@]}"; do
                                if [[ " $full_name " == *"$key"* ]]; then
                                                if [ "$files" = true ]; then
                                                        if [ "$sufix" = true ]; then
                                                                if [ -f "$full_name" ] && [[ "$full_name" =~ ^$n$ ]]; then
                                                                        ((dict[$key] += disk_usage))
                                                                fi
                                                        fi
                                                        if [ "$fd" = true ]; then
                                                                LC_TIME=en_US.UTF-8 last_modified=$(date -d "$(stat -c %y "$full_name")" "+%b %d %H:%M")
                                                                LC_TIME=en_US.UTF-8 timestamp1=$(date -d "$last_modified" "+%s")
                                                                LC_TIME=en_US.UTF-8 timestamp2=$(date -d "$date1" "+%s")
                                                                if [ "$timestamp1" \< "$timestamp2" ]; then
                                                                        ((dict[$key] += disk_usage))
                                                                fi
                                                        fi
                                                        if [ "$size" = true ]; then
                                                                if [ ! "$disk_usage" -lt "$s" ]; then
                                                                        ((dict[$key] += disk_usage))
                                                                fi
                                                        fi
                                                else
                                                        ((dict[$key] += disk_usage))
                                                fi
                                fi
                        done
                        allfiles+=("$full_name")
                fi
        fi
        while IFS= read -r -d '' subdir; do
                dicarr "$subdir"
        done < <(find "$current_directory" -maxdepth 1 -mindepth 1 -print0)
}

args(){
        while getopts ":n:d:s:ral:" arg; do
                   case $arg in
                        n)
                                n=$OPTARG
                                sufix=true
                                errordetector "$n"
                                files=true
                                countargs=$((countargs + 2))
                                ;;
                        d)
                                d=$OPTARG
                                fd=true
                                errordetector "$d"
                                LC_TIME=en_US.UTF-8 date1=$(date -d "$d" "+%b %d %H:%M")
                                files=true
                                countargs=$((countargs + 4))
                                ;;
                        s)
                                s=$OPTARG
                                size=true
                                errordetector "$s"
                                files=true
                                countargs=$((countargs + 2))
                                ;;
                        r)
                                r=true
                                countargs=$((countargs + 1))
                                ;;
                        a)
                                a=true
                                countargs=$((countargs + 1))
                                ;;
                        l)
                                l=$OPTARG
                                has_l=true
                                errordetector "$l"
                                countargs=$((countargs + 2))
                                ;;
                        \?)
                                echo "Um dos argumentos não existe" >&2
                                exit
                                ;;
                        :)
                                echo "Opção -$OPTARG requer um argumento." >&2
                                exit
                                ;;
                        esac
        done
}

printhere(){
        printf "Size Name $today $inputs\n"
        n_linhas=${#dict[@]}
        if [ "$has_l" = true ]; then  
                if [ "$l" -le "$n_linhas" ]; then
                        n_linhas=$l
                fi
        fi
        if [ "$r" = true ]; then
                if [ "$a" = true ]; then
                        for key in "${!dict[@]}"; do printf "%s %s\n" "${dict["$key"]}" "$key"; done | sort -k2,2r | while read -r line; do
                                if [[ $sum == $n_linhas ]];then
                                        break
                                fi
                                space=$(echo "$line" | awk '{print $1}')
                                dir=$(echo "$line" | cut -d" " -f2-)
                                printF "$dir" "$space"
                                sum=$((sum + 1))
                        done
                else
                        for key in "${!dict[@]}"; do printf "%s %s\n" "${dict["$key"]}" "$key"; done | sort -k1,1n | while read -r line; do
                                if [[ $sum == $n_linhas ]];then
                                        break
                                fi
                                space=$(echo "$line" | awk '{print $1}')
                                dir=$(echo "$line" | cut -d" " -f2-)
                                printF "$dir" "$space"
                                sum=$((sum + 1))
                        done
                fi
        else 
                if [ "$a" = true ]; then
                        for key in "${!dict[@]}"; do printf "%s %s\n" "${dict["$key"]}" "$key"; done | sort -k2,2 | while read -r line; do
                                if [[ $sum == $n_linhas ]];then
                                        break
                                fi
                                space=$(echo "$line" | awk '{print $1}')
                                dir=$(echo "$line" | cut -d" " -f2-)
                                printF "$dir" "$space"
                                sum=$((sum + 1))
                        done
                else
                        for key in "${!dict[@]}"; do printf "%s %s\n" "${dict["$key"]}" "$key"; done | sort -k1,1nr | while read -r line; do
                                if [[ $sum == $n_linhas ]];then
                                        break
                                fi
                                space=$(echo "$line" | awk '{print $1}')
                                dir=$(echo "$line" | cut -d" " -f2-)
                                printF "$dir" "$space"
                                sum=$((sum + 1))
                        done
                fi
        fi
}

printF(){
        local path="$1"
        local disk="$2"
        if [ "$disk" == "-1" ]; then
                disk="NA"
        fi
        for c in "${sort_prefix[@]}"; do
                if [[ "$path" == *"$c"* ]]; then
                        prefix=$c
                fi
        done
        path="${path#$prefix}"
        path="${path#/}"
        printf "%s %s\n" "$disk" "$path"
}

spacecheck(){
        args "$@"
        for f in "$@"; do
                dire+=($f)
                errordetector "diretório?"
                if [ -d "$f" ]; then
                        prefix_before+=("$(dirname "$(realpath -e "$f")")")
                        dicarr "$(realpath -e "$f")" "$s" "$n" "$fd"
                fi
        done
        for p in "${prefix_before[@]}"; do
                found=false
                for c in "${sort_prefix[@]}"; do
                        if [[ "$p" == *"$c"* ]]; then
                                found=true
                                break
                        fi
                done
                if [ "$found" == false ]; then
                        sort_prefix+=("$p")
                fi
        done
        printhere "$@"
}

spacecheck "$@"
