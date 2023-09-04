library(tidyr)
library(dplyr)
library(RSQLite)
library(data.table)
library(stringr)
library(gridExtra)
library(grid)
#Environmental Variables
result_file_script <- "*/INDEL-Prioritization-Pipeline/5_GetResultFiles.sh"
db_path <- file.path("*/a_census_db.db")
#Please change before run


files <- list.files(pattern = ".txt$", full.names = TRUE)


#print(files)


# read and process each file, and combine the data into one table
combined_df <- lapply(files, function(file) {
  # read the file/home
  vcf <- read.table(file, header = FALSE, comment.char = "#", sep = "\t")
  
  
  # split the 8th column into multiple columns
  new_df <- separate(vcf, 8, into = paste0("col", 1:40), sep = "\\|")
  new_df$file_name <- file
  
  
  
  new_df <- new_df %>%
    select(file_name, everything())	
  
  # return the processed data
  new_df	
}) %>% 
  
  
  bind_rows() %>% 
  select(file_name, everything())



#Split the combined columns from col1 in combined_df 


df_split <- separate(combined_df, 'col1', into = c("EVENT", "PAIRID", "SVLEN","SVTYPE","CSQ"), sep = ";")
df_split$SVLEN <- gsub("SVLEN=", "", df_split$SVLEN)
df_split$SVLEN <- as.integer(df_split$SVLEN)
df_split <-df_split %>% rename(ExistingVariant = 'col18')
df_split <- subset(df_split, V1 != "chrM") #Remove mitochondrial information
df_split <- df_split %>% 
  mutate(id = row_number())



#This block returns a data frame with information from COSMIC census database 
#############################################################################################################################33


print(db_path)
# Create a connection to SQLite database
con <- dbConnect(RSQLite::SQLite(), db_path)

# Create a new dataframe called COSV_df that contains rows where ExistingVariant contains COSV and col3 contains "HIGH" or "MODERATE"
write.csv(df_split,"zdf_split.txt", row.names= TRUE)
zdf_file_name <- unique(df_split$file_name)

write(zdf_file_name, file = "zdf_name.txt")
zdf_filename <- subset(df_split, select = c(file_name, V3))
write.table(zdf_filename, file = "zdf_filename.txt", sep = "\t", row.names = FALSE, quote = FALSE)


exit_status1 <-system(result_file_script)

if (exit_status1 == 0){
  cat("Get result files succesfully executed.\n")
  
} else {
  cat("Script execution failed. Exit status: ", exit_status1)
}
quit()
