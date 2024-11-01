#!/bin/bash
# Downloads models from Hugging Face. Supports the following scenarios:
# - Model repos where each branch is a different quantization level (e.g., Turbodep exl2)
# - GGUF Model repos with individual GGUF files for multiple quantization levels in the main branch
# - Standard model repos where there's a single model in the main branch
#
# Usage:
#   ./download-model.sh [-r revision] [-l local_dir] [-m model] [-g gguf]
#
# Dependencies: HuggingFace CLI
#   - pip install -U "huggingface_hub[cli]"
#
# Options:
#   -r revision: The revision of the model (or GGUF quant filename) to download (default: main)
#   -l local_dir: The local directory to download the model to (default: /nvme/LLMs/)
#   -m model: The name of the model to download
#   -g gguf: Download a GGUF model (ensure that -r is provided)
#
# Examples:
#   Download a standard model:
#     ./download-model.sh -m model_name
#
#   Download a specific revision of a model:
#     ./download-model.sh -m model_name -r revision
#
#   Download a GGUF model:
#     ./download-model.sh -g true -m model_name -r quant_filename

gguf="false"

while getopts ":r:g:m:l:h" opt; do
case $opt in
    r)
    revision="$OPTARG"
    ;;
    m)
      model="$OPTARG"
      ;;
    l)
      local_dir="$OPTARG"
      ;;
    g)
     gguf="$OPTARG"
     ;;
    h)
      echo "Usage: $0 [-r revision] [-l local_dir] [-m model]"
      echo "-r revision: The revision of the model (or GGUF quant filename) to download (default: main)"
      echo "-l local_dir: The local directory to download the model to (default: /nvme/LLMs/)"
      echo "-m model: The name of the model to download"
      echo "-g true: Download a GGUF model (ensure that -r is provided)"
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
    esac
done

revision="${revision:-main}"
model_with_underscore=$(echo $model | tr '/' '_')
local_dir="${local_dir:-/nvme/LLMs/${model_with_underscore}_$revision}"

# Check if huggingface-cli is installed
if ! command -v huggingface-cli &> /dev/null
then
    echo -e "\n   huggingface-cli could not be found. Please install it using the following command:"
    echo -e "   pip install -U 'huggingface_hub[cli]'\n"
    exit 1
fi

# Download non-GGUF model
if [ $gguf != "true" ]; then
echo -e "Downloading $model to $local_dir\n"
huggingface-cli download \
    "$model" \
    --revision "$revision" \
    --local-dir-use-symlinks False \
    --local-dir "$local_dir"
exit 0
fi

# Download GGUF model
echo -e "Downloading GGUF of $model to $local_dir\n"
huggingface-cli download \
    "$model" \
    "$revision" \
    --local-dir-use-symlinks False \
    --local-dir "$local_dir"

exit 0
