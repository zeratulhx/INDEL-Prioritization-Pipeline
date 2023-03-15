import os

# Set the directory path
input_dir = "/path/to/directory"

# Set the summary file path
summary_file = "summary.txt"

# Open the summary file for writing
with open(summary_file, "w") as output:

    # Loop through all files in the directory
    for filename in os.listdir(input_dir):
        
        # Check if the file is a text file
        if filename.endswith(".txt"):
            
            # Check if the file is not the summary file
            if filename != summary_file:
                
                # Open the file for reading
                with open(os.path.join(input_dir, filename), "r") as input_file:
                    
                    # Loop through each line in the file
                    for line in input_file:
                        
                        # Check if the line contains "MODERATE" or "HIGH"
                        if "MODERATE" in line or "HIGH" in line:
                            
                            # Write the line to the summary file
                            output.write(line)
