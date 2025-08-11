############################################################
### Logistics
############################################################

# Required packages
library(tidyverse)

# Filename for full simulation output
RESULTS_FILEPATH <- "Output/sims_2025-08-04_18-55-22_ms1.csv"

# How many iterations for each simulated parameter set?
#   NOTE this will determine the chunk length used to summarize data
#        set it carefully!
ITERATIONS <- 1000

# Make a new output log file, which will print parameter set info
#   as the long processing function runs
write("", "Output/process_log.txt", append=FALSE)

############################################################
### calcBouts - calculate bout information for a schedule
############################################################
calcBouts <- function(schedule) {
    # Split schedule into character vector
    schedule_f <- str_split_1(schedule, "")
    schedule_m <- str_split_1(schedule, "")

    # Simplify to two states
    #   1 for focal parent, 0 otherwise
    schedule_f[schedule_f == "F"] <- 1
    schedule_f[schedule_f != 1] <- 0

    schedule_m[schedule_m == "M"] <- 1
    schedule_m[schedule_m != 1] <- 0

    # Calculate runs
    runs_f <- rle(schedule_f)
    incubation_bouts_f <- runs_f$lengths[runs_f$values=="1"] 
    foraging_bouts_f <- runs_f$lengths[runs_f$values=="0"]

    runs_m <- rle(schedule_m)
    incubation_bouts_m <- runs_m$lengths[runs_m$values=="1"] 
    foraging_bouts_m <- runs_m$lengths[runs_m$values=="0"]

    # Summarize all values
    num_incubation_bouts_f <- length(incubation_bouts_f)
    mean_incubation_bout_f <- mean(incubation_bouts_f)
    var_incubation_bout_f <- var(incubation_bouts_f)
    num_foraging_bouts_f <- length(foraging_bouts_f)
    mean_foraging_bout_f <- mean(foraging_bouts_f)
    var_foraging_bout_f <- var(foraging_bouts_f)

    num_incubation_bouts_m <- length(incubation_bouts_m)
    mean_incubation_bout_m <- mean(incubation_bouts_m)
    var_incubation_bout_m <- var(incubation_bouts_m)
    num_foraging_bouts_m <- length(foraging_bouts_m)
    mean_foraging_bout_m <- mean(foraging_bouts_m)
    var_foraging_bout_m <- var(foraging_bouts_m)

    # Return as neat tibble
    tibble(N_Incubation_Bouts_F = num_incubation_bouts_f,
           Mean_Incubation_Bout_F = mean_incubation_bout_f,
           Var_Incubation_Bout_F = var_incubation_bout_f,
           N_Foraging_Bouts_F = num_foraging_bouts_f,
           Mean_Foraging_Bout_F = mean_foraging_bout_f,
           Var_Foraging_Bout_F = var_foraging_bout_f,
           N_Incubation_Bouts_M = num_incubation_bouts_m,
           Mean_Incubation_Bout_M = mean_incubation_bout_m,
           Var_Incubation_Bout_M = var_incubation_bout_m,
           N_Foraging_Bouts_M = num_foraging_bouts_m,
           Mean_Foraging_Bout_M = mean_foraging_bout_m,
           Var_Foraging_Bout_M = var_foraging_bout_m)
} 


############################################################
### processChunk - summarize rows from long data file
############################################################
processChunk <- function(chunk, pos) {

    # Extract unique parameters to append later
    min_energy_thresh_f <- unique(chunk$Min_Energy_Thresh_F)
    max_energy_thresh_f <- unique(chunk$Max_Energy_Thresh_F)
    min_energy_thresh_m <- unique(chunk$Min_Energy_Thresh_M)
    max_energy_thresh_m <- unique(chunk$Max_Energy_Thresh_M)
    foraging_condition_mean <- unique(chunk$Foraging_Condition_Mean)
    foraging_condition_sd <- unique(chunk$Foraging_Condition_SD)

    # Check that we haven't run over any different parameter combinations
    if (any(map_lgl(list(max_energy_thresh_f, min_energy_thresh_f, 
                         max_energy_thresh_m, min_energy_thresh_m, 
                         foraging_condition_mean, foraging_condition_sd), 
                    ~ length(.) > 1))) {
        return("ERROR")
    }

    # Check that the chunk is exactly the size of the iterations
    if (nrow(chunk) != ITERATIONS) {
        return("ERROR")
    }

    # Calculate summary values
    n <- nrow(chunk) 

    # Separate values for result states
    successes <- chunk[chunk$Hatch_Result == "hatched",]
    fail_egg_time <- chunk[chunk$Hatch_Result == "egg time fail",]
    fail_egg_cold <- chunk[chunk$Hatch_Result == "egg cold fail",]
    fail_parent_dead <- chunk[chunk$Hatch_Result == "dead parent",]

    # Tally different result states
    n_successes <- nrow(successes)
    n_fail_egg_time <- nrow(fail_egg_time)
    n_fail_egg_cold <- nrow(fail_egg_cold)
    n_fail_parent_dead <- nrow(fail_parent_dead)

    # Summary values for all simulations, including both successes and failures 
    OVERALL_mean_energy_f <- mean(chunk$Mean_Energy_F)
    OVERALL_var_energy_f <- mean(chunk$Var_Energy_F)
    OVERALL_mean_energy_m <- mean(chunk$Mean_Energy_M)
    OVERALL_var_energy_m <- mean(chunk$Var_Energy_M)
    OVERALL_total_neglect <- mean(chunk$Total_Neglect)
    OVERALL_max_neglect <- mean(chunk$Max_Neglect)
    OVERALL_prop_neglect <- mean(chunk$Total_Neglect / chunk$Hatch_Days)
    OVERALL_hatch_date <- mean(chunk$Hatch_Days)

    # More internally consistent summary values for successful seasons only 
    SUCCESSFUL_mean_energy_f <- mean(successes$Mean_Energy_F)
    SUCCESSFUL_var_energy_f <- mean(successes$Var_Energy_F)
    SUCCESSFUL_mean_energy_m <- mean(successes$Mean_Energy_M)
    SUCCESSFUL_var_energy_m <- mean(successes$Var_Energy_M)
    SUCCESSFUL_tot_neglect <- mean(successes$Total_Neglect)
    SUCCESSFUL_max_neglect <- mean(successes$Max_Neglect)
    SUCCESSFUL_prop_neglect <- mean(successes$Total_Neglect / successes$Hatch_Days)
    SUCCESSFUL_hatch_date <- mean(successes$Hatch_Days)
    SUCCESSFUL_attendance_f <- mean(str_count(successes$Season_History, "F"))
    SUCCESSFUL_prop_f <- mean(str_count(successes$Season_History, "F") / successes$Hatch_Days)
    SUCCESSFUL_attendance_m <- mean(str_count(successes$Season_History, "M"))
    SUCCESSFUL_prop_m <- mean(str_count(successes$Season_History, "M") / successes$Hatch_Days)

    # Generate bout info for each successful schedule
    SUCCESSFUL_bout_info <- map_df(successes$Season_History, calcBouts) |>
                         summarize_all(mean)

    # If no bout info, manually construct empty tibble 
    #   so the chunk has the correct number of columns
    if (ncol(SUCCESSFUL_bout_info) == 0) {
        SUCCESSFUL_bout_info <- tibble(N_Incubation_Bouts_F = NA,
                                       Mean_Incubation_Bout_F = NA,
                                       Var_Incubation_Bout_F = NA,
                                       N_Foraging_Bouts_F = NA,
                                       Mean_Foraging_Bout_F = NA,
                                       Var_Foraging_Bout_F = NA,
                                       N_Incubation_Bouts_M = NA,
                                       Mean_Incubation_Bout_M = NA,
                                       Var_Incubation_Bout_M = NA,
                                       N_Foraging_Bouts_M = NA,
                                       Mean_Foraging_Bout_M = NA,
                                       Var_Foraging_Bout_M = NA)
    }    

    # Construct final dataframe
    processed <- tibble(Min_Energy_Thresh_F = min_energy_thresh_f,
                        Max_Energy_Thresh_F = max_energy_thresh_f,
                        Min_Energy_Thresh_M = min_energy_thresh_m,
                        Max_Energy_Thresh_M = max_energy_thresh_m,
                        Foraging_Condition_Mean = foraging_condition_mean,
                        Foraging_Condition_SD = foraging_condition_sd,
                        N_Total = n,
                        N_Success = n_successes,
                        N_Fail_Egg_Time = n_fail_egg_time,
                        N_Fail_Egg_Cold = n_fail_egg_cold,
                        N_Fail_Parent_Dead = n_fail_parent_dead,
                        Overall_Mean_Energy_F = OVERALL_mean_energy_f,
                        Overall_Var_Energy_F = OVERALL_var_energy_f,
                        Overall_Mean_Energy_M = OVERALL_mean_energy_m,
                        Overall_Var_Energy_M = OVERALL_var_energy_m,
                        Overall_Total_Neglect = OVERALL_total_neglect,
                        Overall_Max_Neglect = OVERALL_max_neglect,
                        Overall_Prop_Neglect = OVERALL_prop_neglect, 
                        Overall_Hatch_Date = OVERALL_hatch_date,
                        Successful_Mean_Energy_F = SUCCESSFUL_mean_energy_f,
                        Successful_Var_Energy_F = SUCCESSFUL_var_energy_f,
                        Successful_Mean_Energy_M = SUCCESSFUL_mean_energy_m,
                        Successful_Var_Energy_M = SUCCESSFUL_var_energy_m,
                        Successful_Total_Neglect = SUCCESSFUL_tot_neglect,
                        Successful_Max_Neglect = SUCCESSFUL_max_neglect,
                        Successful_Prop_Neglect = SUCCESSFUL_prop_neglect,
                        Successful_Hatch_Date = SUCCESSFUL_hatch_date,
                        Successful_Attendance_F = SUCCESSFUL_attendance_f,
                        Successful_Prop_F = SUCCESSFUL_prop_f,
                        Successful_Attendance_M = SUCCESSFUL_attendance_m,
                        Successful_Prop_M = SUCCESSFUL_prop_m) |>
             mutate(Rate_Success = N_Success/N_Total,
                    Rate_Fail_Egg_Time = N_Fail_Egg_Time/N_Total,
                    Rate_Fail_Egg_Cold = N_Fail_Egg_Cold/N_Total,
                    Rate_Fail_Parent_Dead = N_Fail_Parent_Dead/N_Total) |>
             bind_cols(SUCCESSFUL_bout_info)

    # Write process log line to output, makes it easier to catch errors if all cols are not returned
    #   (if different number cols are returned, the final bind_rows will fail for something like read_csv_chunked)
    write(paste(paste(processed[1,1:5], collapse=" "), ncol(processed)), "Output/process_log.txt", append=TRUE)
    return(processed)
}

############################################################
### Process the data and write output
############################################################

# Process data with chunk function
results_summarized <- read_csv_chunked(RESULTS_FILEPATH,
                                       DataFrameCallback$new(processChunk),
                                       chunk_size=ITERATIONS)

# Save processed output to file
write_csv(results_summarized, "Output/processed_results.csv")