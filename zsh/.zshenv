export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

preappend_path () {
        case ":$PATH:" in
                *:"$1":*)
                        ;;
                *)
                        export PATH="$1:$PATH"
    esac
}

source_folder(){
        local folder="${1%/}"
        [[ "$folder" != /* ]] && folder="$HOME/$folder"
        if [ -d $folder ]; then
                files_to_source=($folder/*(N))
                for file_to_source in "${(@o)files_to_source[@]}"; do
                        if [[ $file_to_source != *.disabled && -r $file_to_source ]]; then
                                {source $file_to_source || print -u2 "⚠️ Failed to init $file_to_source"}
                        fi
                done
        else
                print -u2 "⚠️ Failed to source folder $folder, does not exist"
        fi
}
