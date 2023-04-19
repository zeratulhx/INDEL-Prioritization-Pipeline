library(tidyr)
library(dplyr)
library(RSQLite)
library(data.table)
library(stringr)
library(gridExtra)
library(grid)


set_current_wd <- readline("Enter the path to the working directory: ")

print(paste("The working directory is now set to:", set_current_wd))

# List all the text files in the directory
files <- list.files(set_current_wd, pattern = "\\.txt$", full.names = TRUE)

# read and process each file, and combine the data into one table
combined_df <- lapply(files, function(file) {
  # read the file/home
  vcf <- read.table(file, header = FALSE, comment.char = "#", sep = "\t")
  
  # split the 8th column into multiple columns
  new_df <- separate(vcf, 8, into = paste0("col", 1:40), sep = "\\|")
  
  # add the file name as another column
  new_df$file_name <- file
  
  # return the processed data
  new_df
  }) %>% 
  
  bind_rows() %>%
  mutate(file_name = basename(file_name)) %>% 
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

db_path <- file.path(set_current_wd, "a_census_db.db")

# Create a connection to SQLite database
con <- dbConnect(RSQLite::SQLite(), db_path)

# Create a new dataframe called COSV_df that contains rows where ExistingVariant contains COSV and col3 contains "HIGH" or "MODERATE"
COSV_df <- df_split %>% filter(grepl("COSV", ExistingVariant) & col3 %in% c("HIGH", "MODERATE"))

if (nrow(COSV_df) == 0) {
  stop("No existing variants with HIGH or MODERATE impact in samples. Aborting.")
}

# Define a function to extract the COSV ID from the ExistingVariant column
extract_COSV <- function(variant) {
  COSV_id <- gsub(".*(COSV\\d+).*", "\\1", variant)
  return(COSV_id)
}

# Apply the extract_COSV function to the ExistingVariant column of COSV_df using lapply
COSV_ids <- unlist(lapply(COSV_df$ExistingVariant, extract_COSV))

get_gene_info <- function(COSV_id, db_conn) {
  query <- paste0("SELECT `Gene name`,`Primary histology`, `Histology subtype 1`, `Histology subtype 2`,`Resistance mutation`, `Mutation somatic status`, GENOMIC_MUTATION_ID FROM a_census_table WHERE GENOMIC_MUTATION_ID = '", COSV_id, "'")
  gene_info <- dbGetQuery(db_conn, query)
  gene_info$`Histology subtype 2` <- as.character(gene_info$`Histology subtype 2`)
  # Convert other columns as needed
  return(gene_info)
}


# Apply the get_gene_info function to each COSV_id in the COSV_ids list using lapply, and combine the resulting data frames using bind_rows()
gene_info_census_df <- bind_rows(lapply(COSV_ids, get_gene_info, db_conn = con))

# Disconnect from the SQLite database
dbDisconnect(con)



#This block searches through the COSV_df and connects it to information in the gene_info_census dataframe using nested lists. 
##########################################################################################################################

# Loop through each row in COSV_df
for (i in 1:nrow(COSV_df)) {
  # Get the values of file_name and ExistingVariant for this row
  file_name <- COSV_df[i, "file_name"]
  ExistingVariant <- unlist(strsplit(as.character(COSV_df[i, "ExistingVariant"]), ";"))
  
  # Separate out COSV IDs if there are multiple of them in the same cell
  ExistingVariant <- unlist(strsplit(ExistingVariant, "&"))
  
  # Remove any "rs" values that are not cosmic values
  ExistingVariant <- ExistingVariant[grepl("^COSV", ExistingVariant)]
  
  # Search for matching rows in gene_info_census_df based on each COSV value
  matching_rows <- list()
  for (j in 1:length(ExistingVariant)) {
    matching_rows[[j]] <- subset(gene_info_census_df, grepl(ExistingVariant[j], GENOMIC_MUTATION_ID))
  }
  
  # Combine the matching rows into a single dataframe
  if (length(matching_rows) > 0) {
    matching_df <- do.call(rbind, matching_rows)
  } else {
    matching_df <- data.frame()
  }
  
  # Create a list containing file_name, ExistingVariant, and matching_rows
  merged_list[[i]] <- list(file_name = file_name, ExistingVariant = ExistingVariant, matching_df = matching_df)
}

# Combine the lists in merged_list into a dataframe
merged_df <- data.frame(do.call(rbind, merged_list))


#This block gets the unique genomic mutation IDs and associated histology subtype 1, primary histology, and gene symbol
#######################################################################################################################

unique_ids <- gene_info_census_df %>% 
  distinct(GENOMIC_MUTATION_ID, .keep_all = TRUE) %>% 
  select(GENOMIC_MUTATION_ID, `Histology subtype 1`, `Primary histology`, `Gene name`) %>%
  mutate(Genomic_Mutation_and_Histology = GENOMIC_MUTATION_ID)

# Get the counts of each histology subtype 1, primary histology, gene symbol and gene name combination
counts <- unique_ids %>% 
  count(`Histology subtype 1`, `Primary histology`, `Gene name`) %>%
  arrange(desc(n))

# Create a data frame to store the results
results_df <- data.frame(Row_Num = integer(),
                         Histology_subtype = character(),
                         Primary_histology = character(),
                         Gene_name = character(),
                         Genomic_Mutation = character(),
                         Count = integer(),
                         stringsAsFactors = FALSE,
                         row.names = NULL)

# Populate the data frame with the results
for (i in seq_len(nrow(counts))) {
  histology_subtype <- counts$`Histology subtype 1`[i]
  primary_histology <- counts$`Primary histology`[i]
  gene_name <- counts$`Gene name`[i]
  subset_df <- unique_ids %>%
    filter(`Histology subtype 1` == histology_subtype & `Primary histology` == primary_histology & `Gene name` == gene_name)
  genomic_mutations <- paste(subset_df$Genomic_Mutation_and_Histology, collapse = ", ")
  count <- counts$n[i]
  results_df <- rbind(results_df, data.frame(Row_Num = i,
                                             Histology_subtype = histology_subtype,
                                             Primary_histology = primary_histology,
                                             Gene_name = gene_name,
                                             COSV_Census_ID = genomic_mutations,
                                             Count = count,
                                             stringsAsFactors = FALSE))
}


# Replace Histology_subtype with row numbers
results_df$Row_Num <- seq_len(nrow(results_df))
results_df_gene_summary <- results_df[c("Row_Num", "Primary_histology",  "Histology_subtype", "Gene_name", "COSV_Census_ID" , "Count")]

# use separate_rows() to split the cells in "COSV_Census_ID" column
df_summary_split <- separate_rows(results_df_gene_summary, COSV_Census_ID, sep = ",")

id_list_COSV_Census_ID <- unique(df_summary_split$COSV_Census_ID)

result_df <- data.frame(unique_cosv_census_id = character(),
                        file_name = character(),
                        stringsAsFactors = FALSE)


#Generate data frame of samples that match the COSV ID
########################################################################################################################

id_list_COSV_Census_ID <- unique(df_summary_split$COSV_Census_ID)

result_df <- data.frame(unique_cosv_census_id = character(),
                        file_name = character(),
                        stringsAsFactors = FALSE)

for (i in id_list_COSV_Census_ID) {
  
  # check if the i value is a split COSV value
  if (grepl("&", i)) {
    # split the COSV value into separate values
    i_split <- str_split(i, "&", simplify = TRUE)[, 1:2]
    # create a regular expression to match either of the split values
    i_regex <- paste0("^", i_split, "$", collapse = "|")
    cat("Regex for", i, ":", i_regex, "\n")
    # subset df_split using the regular expression
    df_temp <- df_split[str_detect(df_split$col18, i_regex), ]
  } else {
    # if the i value is a single COSV value, simply subset df_split
    df_temp <- df_split[df_split$col18 == i, ]
  }
  
  if (nrow(df_temp) > 0) {
    result_df <- rbind(result_df, data.frame(unique_cosv_census_id = i, 
                                             file_name = df_temp$file_name,
                                             stringsAsFactors = FALSE))
  }
}


# Loop over the id_list_COSV_Census_ID
# Create an empty data frame to store the matching rows

matching_rows_df <- data.frame()

my_list_trimmed <- lapply(id_list_COSV_Census_ID, trimws)

for (i in my_list_trimmed) {
  result <- grepl(i, df_split$ExistingVariant)
  matching_rows <- df_split[result, ]
  if (nrow(matching_rows) > 0) {
    matching_rows$i <- i
    matching_rows_df <- rbind(matching_rows_df, matching_rows)
  }
}


matching_Id_df <- subset(matching_rows_df, select = c(file_name, i, col4))

matching_Id_df <- matching_Id_df[order(matching_Id_df$file_name), ]


#Save results of interest to PDF
#########################################################################################################3

#Generate highest histology count from results_df_summary_split

# Find the highest count Primary_histology and Histology_subtype
max_primary_histology <- results_df_gene_summary$Primary_histology[which.max(results_df_gene_summary$Count)]
max_subtype <- results_df_gene_summary$Histology_subtype[which.max(results_df_gene_summary$Count)]

# Create the PDF and add the title

pdf(file.path(set_current_wd, "results_summary.pdf"), height = 20, width = 38)

grid.text(paste("The highest histology by COSV id count is: ", max_primary_histology, " and the highest histology subtype by unique COSV id count is: ", max_subtype, ".\n All COSV identifiers included here are linked to mutations in genes listed in the Cancer Gene Census (http://cancer.sanger.ac.uk/census)\n 'The Cancer Gene Census (CGC) is an ongoing effort to catalogue those genes which contain mutations that have been causally implicated in cancer and explain how dysfunction of these genes drives cancer.\n The content, the structure, and the curation process of the Cancer Gene Census was described and published in Nature Reviews Cancer'"), x=0.5, y=0.95, gp=gpar(fontsize=20))
grid.table(results_df_gene_summary)

# Define the number of rows per page
rows_per_page <- 30

# Get the total number of rows in the data frame
total_rows <- nrow(matching_Id_df)

# Calculate the number of pages required to display all rows
num_pages <- ceiling(total_rows / rows_per_page)

# Loop through each page
for (i in 1:num_pages) {
  # Subset the data frame to the appropriate rows for this page
  start_row <- (i - 1) * rows_per_page + 1
  end_row <- min(start_row + rows_per_page - 1, total_rows)
  page_df <- matching_Id_df[start_row:end_row, ]
  
  # Create a table grob for the page
  table_grob <- tableGrob(page_df)
  
  # Draw the table on a new PDF page
  grid.newpage()
  grid.text(paste("Samples linked to genes in the Cancer Census database. Page ", i), x=0.5, y=0.95, gp=gpar(fontsize=20))
  grid.draw(table_grob)
}

# Close the PDF file
dev.off()



