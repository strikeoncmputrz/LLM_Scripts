#!/bin/bash

# Default values
model_name="LoneStriker_Hermes-3-Llama-3.1-70B-6.0bpw-h6-exl2_main"
models_path="/nvme/LLMs"
load_endpoint="/v1/model/load"
unload_endpoint="/v1/model/unload"
tabby_host="http://tabby-url:5000"
unload=1
api_key="[your-api-key]"

# Parse arguments
while [ "$#" -gt 0 ]; do
  case $1 in
    -h|--help)
      echo "Load a model in TabbyAPI via using curl"
      echo "Usage: $0 [options]"
      echo
      echo "Options:"
      echo "  -a, --api-key      Specify tabbyAPI key (optional)"
      echo "  -c, --cache-mode   Specify a cache mode (optional)"
      echo "  -d, --draft-model  Specify a draft model name (optional)"
      echo "  -e, --experts      Specify the number of experts per token (optional)"
      echo "  -g, --gpu-split    Specify a list of VRAM allocations (optional e.g. 14 15 15)"
      echo "  -H, --tabby-host   Specify tabbyAPI host (optional)"
      echo "  -h, --help         Display this help menu (optional)"
      echo "  -l, --seq-length   Specify a maximum sequence length (optional)"
      echo "  -m, --model        Specify a model name (optional, default: turboderp_Mixtral-8x7B-instruct-exl2_8.0bpw)"
      echo "  -n, --no-unload    Don't unload a model before loading this one (optional)"
      echo "  -p, --prompt       Specify a prompt template (optional)"
      echo "  -r, --autores      Specify a list of reserved VRAM allocations for autosplit (optional e.g. 96 96 96)"
      echo "  -s, --model-size   Display the size of each model directory in models_path (optional)"
      echo "  -t, --tensor-parallel   Enable tensor parallel (optional)"
      echo "  -q, --draft-cache  Specify the cache mode for the draft model (optional)"
      exit 0
      ;;
    -a|--api-key)
      api_key=$2
      shift 2
      ;;
    -c|--cache-mode)
      cache_mode=$2
      shift 2
      ;;
    -d|--draft-model)
      draft_model_name=$2
      shift 2
      ;;
    -e|--experts)
      num_experts_per_token=$2
      shift 2
      ;;
    -g|--gpu-split)
        gpu_split=$2
        shift 2
        ;;
    -H|--tabby-host)
      tabby_host=$2
      shift 2
      ;;
    -l|--seq-length)
      max_seq_len=$2
      shift 2
      ;;
    -m|--model)
      model_name=$2
      shift 2
      ;;
    -n|--no-unload)
      unload=0
      shift
      ;;
    -p|--prompt)
      prompt_template=$2
      shift 2
      ;;
    -r|--autosplit-reserve)
        autosplit_reserve=$2
        shift 2
      ;;
    -s|--model-size)
      # Check if the models_path directory exists
      if [ -d "${models_path}" ]; then
        # Determine the size on disk of each subdirectory in models_path
        du -sh "${models_path:?}/"*
      else
        echo "Error: The directory '${models_path}' does not exist."
        exit 1
      fi
      exit 0
      ;;
    -t|--tensor-parallel)
        tensor_parallel=1
        shift
      ;;
    -q|--draft-cache)
        draft_cache_mode=$2
        shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

unload_model() {
   curl -X POST -H "Content-Type: application/json"\
    -H "Authorization: Bearer $api_key"\
    "$tabby_host$unload_endpoint"
}

load_model() {
    local request_body="{
      \"name\": \"$model_name\"";

    if [ -n "$num_experts_per_token" ]; then
        request_body+=",
        \"num_experts_per_token\": $num_experts_per_token";
    fi
    if [ -n "$cache_mode" ]; then
        request_body+=", \"cache_mode\": \"$cache_mode\"";
    fi
    if [ -n "$max_seq_len" ]; then
        request_body+=", \"max_seq_len\": $max_seq_len";
    fi

    # Convert bash array to JSON list for gpu_split
    if [ -n "$gpu_split" ]; then
        IFS=$' \t\n' read -ra gpu_split_array <<< "$gpu_split"
        request_body+=", \"gpu_split\": ["$(IFS=,; echo "${gpu_split_array[*]}")"]";
    fi

    # Add gpu autosplit when gpu_split isn't specified
    if [ -z "$gpu_split" ]; then
        request_body+=", \"gpu_split_auto\": true";
    fi

    # Add tensor parallel if specified
    if [ -n "$tensor_parallel" ]; then
        request_body+=", \"tensor_parallel\": true";
    fi

    # Convert bash array to JSON list for autosplit_reserve only if it's specified and gpu_split is false
    if [ -n "$autosplit_reserve" ] && [ -z "$gpu_split" ]; then
        IFS=$' \t\n' read -ra autosplit_reserve_array <<< "$autosplit_reserve"
        request_body+=", \"autosplit_reserve\": ["$(IFS=,; echo "${autosplit_reserve_array[*]}")"]";
    fi

    # Add draft model if specified
    if [ -n "$draft_model_name" ]; then
        request_body+=", \"draft\": {
            \"draft_model_name\": \"$draft_model_name\",
            \"draft_gpu_split\": [3, 3, 3, 3, 3, 3]";
        if [ -n "$draft_cache_mode" ]; then
            request_body+=", \"draft_cache_mode\": \"$draft_cache_mode\"";
        fi
        request_body+="}";
    fi

    request_body+='}';

    echo -e "$request_body" | jq '.'

    curl -X POST -H "Content-Type: application/json" \
        -H "Authorization: Bearer $api_key" \
        -d "$request_body" "$tabby_host$load_endpoint";
}

# Execute
if [ "$unload" -eq 1 ]; then
   unload_model
   echo -e "\nUnloaded Model \n"
fi

echo -e "\n Loading $model_name \n"
echo
load_model
echo
exit 0
