intro_window() {

    # Mandatory arguments
    if [ -z $CONFIG_PATH ]; then
        config_output="-"
    else
        config_output=$CONFIG_PATH
    fi

    if [ -z $DATA_PATH ]; then
        data_output="-"
    else
        data_output=$DATA_PATH
    fi

    # Optional arguments
    if [ -z $GPU_FLAG_RC ]; then
        GPU_FLAG_RC=0
    fi

    if [ $GPU_FLAG_RC -eq 0 ]; then
        gpu_output="<span foreground='red'>No</span>" # "<b>No</No>"
    else
        gpu_output="<span foreground='green'>Yes</span>" #"<b>Yes</b>"
    fi

    if [ -z $NOTEBOOK_PATH ]; then
        notebook_output="-"
    else
        notebook_output=$NOTEBOOK_PATH
    fi

    if [ -z $REQUIREMENTS_PATH ]; then
        requirements_output="-"
    else
        requirements_output=$REQUIREMENTS_PATH
    fi

    req_config_text="\tConfiguration file: <b>${config_output}</b>\n\tData folder: <b>${data_output}</b>"
    extra_config_text="\t(optional) GPU: <b>${gpu_output}</b>\n\t(optional) Local notebook: <b>${notebook_output}</b>\n\t(optional) Local requirements: <b>${requirements_output}</b>"

    CONTINUE=$(zenity --info \
       --no-wrap \
       --title="Continue" \
       --text="<big><b>Welcome to DL4Mic_everywhere!</b></big>\nBellow you have the data you need to provide. The paths to both the configuration yaml file and data folder are mandatory.\nThe rest of them are optional, by default the GPU usage is set as <b>No</b> and if no local paths are specified to the notebook and\nrequirementes files, they will be downloaded using the URLs from the configuration yaml file.\n\nValues of the arguments: \n${req_config_text}\n${extra_config_text}\n" \
       --ok-label="Cancel" \
       --extra-button="Configuration file" \
       --extra-button="Data folder" \
       --extra-button="GPU" \
       --extra-button="Local notebook" \
       --extra-button="Local requirements" \
       --extra-button="Done")
    CONTINUE_RC=$?
    if [ "$CONTINUE" = "Configuration file" ]; then
        config_window
    elif [ "$CONTINUE" = "Data folder" ]; then
        data_window
    elif [ "$CONTINUE" = "GPU" ]; then
        gpu_window
    elif [ "$CONTINUE" = "Local notebook" ]; then
        notebook_window
    elif [ "$CONTINUE" = "Local requirements" ]; then
        requirements_window
    elif [ "$CONTINUE" = "Done" ]; then
        if [ -z $CONFIG_PATH ]; then
            zenity --error \
                   --text="You need to specify a path to the configuration file."
            intro_window
        elif [ -z $DATA_PATH ]; then
            zenity --error \
                   --text="You need to specify a path to the data folder."
            intro_window
        else
            echo "Succes!!"
            exit
        fi
    elif [ $CONTINUE_RC -eq 0 ] ||  [ $CONTINUE_RC -eq 1 ]; then
        echo "OUT"
        exit
    else
        echo "An unexpected error has occurred."
        exit
    fi
}

config_window() {
    CONFIG_PATH=$(zenity --file-selection \
        --title "Select configuration.yaml" \
        --file-filter="*.yaml")
    intro_window
}

data_window() {
    DATA_PATH=$(zenity --file-selection \
       --title "Select data_path" \
       --directory)
    intro_window
}

gpu_window() {
    zenity --question \
        --title="GPU?"\
        --text="Do you want GPU." \
        --ok-label="Yes" \
        --cancel-label="No"
    GPU_FLAG_RC=$?
    GPU_FLAG_RC=$(expr 1 - $GPU_FLAG_RC )
    intro_window
}

notebook_window() {
    NOTEBOOK_PATH=$(zenity --file-selection \
       --title "Select Notebook.ipynb" \
       --file-filter="*.ipynb")
    intro_window
}

requirements_window() {
    REQUIREMENTS_PATH=$(zenity --file-selection \
       --title "Select requirements.txt" \
       --file-filter="*.txt")
    intro_window
}

intro_window