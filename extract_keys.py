import re

def extract_api_keys(input_text):
    # Regular expression pattern to match API keys
    pattern = r"密钥: (AIzaSy[a-zA-Z0-9_-]{33})"
    
    # Find all matches
    api_keys = re.findall(pattern, input_text)
    
    return api_keys

# Example usage
if __name__ == "__main__":
    # Read from input.txt if available, otherwise use input()
    try:
        with open("input.txt", "r", encoding="utf-8") as file:
            text = file.read()
    except FileNotFoundError:
        print("Please paste the text containing API keys (Ctrl+D or Ctrl+Z to finish):")
        text = ""
        try:
            while True:
                text += input() + "\n"
        except EOFError:
            pass
    
    api_keys = extract_api_keys(text)
    
    # Write to output file
    with open("api_keys.txt", "w") as output_file:
        for key in api_keys:
            output_file.write(key + "\n")
    
    # Print summary
    print(f"Extracted {len(api_keys)} API keys and saved to api_keys.txt")
    
    # Print the first few keys as a preview
    if api_keys:
        print("\nFirst few API keys:")
        for i, key in enumerate(api_keys[:5]):
            print(f"{i+1}. {key}")
        if len(api_keys) > 5:
            print(f"... and {len(api_keys) - 5} more keys") 