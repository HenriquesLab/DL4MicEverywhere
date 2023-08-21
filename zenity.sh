intro_window() {
    zenity --question \
                --title="Intro" \
                --text="Information will appear and you need to give it." \
                --ok-label="Next" \
                --cancel-label="Cancel"
    INTRO_RC=$?
    if [ $INTRO_RC -eq 0 ]; then
        config_window
    else
        exit 1
    fi
}

config_window() {
    CONFIG_PATH=$(zenity --file-selection \
        --title "Select configuration.yaml" \
        --file-filter="*.yaml")
    CONFIG_RC=$?
    if [ $CONFIG_RC -eq 0 ]; then
        data_window
    elif [ $CONFIG_RC -eq 1 ]; then
        intro_window
    else
        exit 1
    fi
}

data_window() {
    DATA_PATH=$(zenity --file-selection \
       --title "Select data_path" \
       --directory)
    DATA_RC=$?
    if [ $DATA_RC -eq 0 ]; then
        continue_window
    elif [ $DATA_RC -eq 1 ]; then
        config_window
    else
        exit 1
    fi
}

continue_window() {

    if [ -z $GPU_FLAG_RC ]; then
        GPU_FLAG_RC=0
    fi

    if [ $GPU_FLAG_RC -eq 0 ]; then
        gpu_output="No"
    else
        gpu_output="Yes"
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

    extra_config_text="GPU: ${gpu_output}\nLocal notebook: ${notebook_output}\nLocal requirements: ${requirements_output}"

    CONTINUE=$(zenity --info \
       --title="Continue" \
       --text="Information will appear and you need to give it.\nExtra configurations:\n${extra_config_text}" \
       --ok-label="Back" \
       --extra-button="GPU" \
       --extra-button="Local notebook" \
       --extra-button="Local requirements" \
       --extra-button="Done")
    CONTINUE_RC=$?
    if [ "$CONTINUE" = "GPU" ]; then
        gpu_window
    elif [ "$CONTINUE" = "Local notebook" ]; then
        notebook_window
    elif [ "$CONTINUE" = "Local requirements" ]; then
        requirements_window
    elif [ $CONTINUE_RC -eq 1 ] || [ "$CONTINUE" = "Done" ]; then
        true
    elif [ $CONTINUE_RC -eq 0 ]; then
        data_window
    fi
}

gpu_window() {
    zenity --question \
        --title="GPU?"\
        --text="Do you want GPU." \
        --ok-label="Yes" \
        --cancel-label="No"
    GPU_FLAG_RC=$?
    echo $GPU_FLAG_RC
    GPU_FLAG_RC=$(expr 1 - $GPU_FLAG_RC )
    echo $GPU_FLAG_RC
    continue_window
}

notebook_window() {
    NOTEBOOK_PATH=$(zenity --file-selection \
       --title "Select Notebook.ipynb" \
       --file-filter="*.ipynb")
    continue_window
}

requirements_window() {
    REQUIREMENTS_PATH=$(zenity --file-selection \
       --title "Select requirements.txt" \
       --file-filter="*.txt")
    continue_window
}

intro_windows