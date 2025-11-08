
library(dplyr)
library(lubridate)
# Read the CSV file

data <- read.csv("C:\\Users\\ginid\\Desktop\\sem 4\\Data visualization\\R\\R Assignment\\selected_terroristdataset (1).csv", 
                 stringsAsFactors = FALSE, 
                 na.strings = c("", "NA", "-99"))  # Treat empty, NA, and -99 as missing


dim(data)
# Calculate the proportion of NA values per column
na_proportion <- colSums(is.na(data)) / nrow(data)
cols_to_remove <- names(data)[na_proportion >= 0.6] # Identify columns with >= 70% missing values
print("Columns with >= 60% missing values:")
print(cols_to_remove)  # Shows which columns will be removed
data <- data %>% select_if(~ sum(is.na(.)) / nrow(data) < 0.6)# Remove columns with >= 70% missing values using dplyr
colnames(data)

# Select relevant columns
data_selected <- data %>% select(eventid, iyear, imonth, iday, country_txt, region_txt, provstate,city,latitude,
                        longitude,success,summary, attacktype1_txt, targtype1_txt,targsubtype1_txt,corp1,
                        target1,natlty1_txt,gname,weaptype1_txt,weapsubtype1_txt,nkill,nwound,)


# data types changes
data_selected$eventid <- as.character(data_selected$eventid)  # ID as character
data_selected$nwound <- as.integer(as.character(data_selected$nwound))  # Convert to integer, handling NAs
data_selected$success <- as.integer(data_selected$success)    # Binary as integer
data_selected$nkill <- as.integer(ifelse(grepl("[^0-9.]", data_selected$nkill), NA, data_selected$nkill))

na_counts <- colSums(is.na(data_selected))
na_counts

# Handle missing values
data_selected <- data_selected[!is.na(data_selected$latitude), ]# remove missing values
data_selected <- data_selected[!is.na(data_selected$longitude), ]# remove missing values
data_selected$nkill[is.na(data_selected$nkill)] <- 0
data_selected$nwound[is.na(data_selected$nwound)] <- 0
data_selected$gname[is.na(data_selected$gname)] <- "Unknown"
data_selected$natlty1_txt[is.na(data_selected$natlty1_txt)] <- "Unknown"
data_selected$weapsubtype1_txt[is.na(data_selected$weapsubtype1_txt)] <- "Unknown"
data_selected$targsubtype1_txt[is.na(data_selected$targsubtype1_txt)] <- "Unknown"
data_selected$corp1[is.na(data_selected$corp1)] <- "Unknown"



#make date coloumn
data_selected$date <- make_date(year = data_selected$iyear, month = data_selected$imonth, day = data_selected$iday)

#Rename columns
rename_map <- c("eventid" = "event_id","iyear" = "year","imonth" = "month", "iday" = "day","country_txt" = "country",
  "region_txt" = "region","provstate" = "province_state","city" = "city_name","latitude" = "lat","longitude" = "lon",
  "success" = "attack_success","summary" = "incident_summary", "attacktype1_txt" = "attack_type","targtype1_txt" = "target_type",
  "targsubtype1_txt" = "target_subtype","corp1" = "corporation", "target1" = "target_name","natlty1_txt" = "nationality","gname" = "group_name",
  "weaptype1_txt" = "weapon_type","weapsubtype1_txt" = "weapon_subtype", "nkill" = "num_killed", "nwound" = "num_wounded",
  "date" = "incident_date"
)

# Apply the renaming using colnames()
for (old_name in names(rename_map)) {
  if (old_name %in% colnames(data_selected)) {
    colnames(data_selected)[colnames(data_selected) == old_name] <- rename_map[old_name]
  }
}

clean_data <- data_selected
clean_data

# Save data for reuse
saveRDS(clean_data, "C:\\Users\\ginid\\Desktop\\sem 4\\Data visualization\\R\\R Assignment\\terrorist\\clean_data.rds")

write.csv(data_selected, "cleaned_terroristdataset.csv", row.names = FALSE)
shell.exec("cleaned_terroristdataset.csv")
