# Set the input file path
input_file = "/stornext/Bioinf/data/lab_davidson/robson.b/Project/Pipeline/summary.txt"

# Set the summary file path
insertion_file = "/stornext/Bioinf/data/lab_davidson/robson.b/Project/Pipeline/insertions.txt""

# Open the input file for reading
with open(input_file, "r") as input:

    # Open the summary file for writing
    with open(insertion_file, "w") as output:

        # Loop through each line in the input file
        for line in input:

            # Check if the line contains "MODERATE" or "HIGH"
            if "inframe_insertion" in line:
                
                # Write the file name and line to the summary file
                output.write(f"{input_file}: {line}")
