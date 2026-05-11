############################################################
### Logistics
############################################################

# Required packages
library(data.table)
library(parallel)
library(pbapply)
library(stringr)

# Filename for full simulation output
RESULTS_SUFFIX <- "ms-1000iter"

SIM_TYPES <- c("regular", "eggTolerance", "eggCost", "swapSexOrder", "oneParent")

############################################################
### calcBouts - calculate bout information for a schedule
############################################################
calcBouts <- function(schedule) {

    chars <- strsplit(schedule, "")[[1]]

    # Female: F=1, else 0
    schedule_f <- ifelse(chars == "F", "1", "0")
    # Male: M=1, else 0
    schedule_m <- ifelse(chars == "M", "1", "0")

    # Calculate runs
    runs_f <- rle(schedule_f)
    incubation_bouts_f <- runs_f$lengths[runs_f$values=="1"] 
    foraging_bouts_f <- runs_f$lengths[runs_f$values=="0"]

    runs_m <- rle(schedule_m)
    incubation_bouts_m <- runs_m$lengths[runs_m$values=="1"] 
    foraging_bouts_m <- runs_m$lengths[runs_m$values=="0"]

    # Trim first and last bouts to reduce sensitivity to arbitrary start/end conditions

    # Get the type of each first and last bout per parent
    first_f <- schedule_f[1]
    last_f  <- schedule_f[length(schedule_f)]
    first_m <- schedule_m[1]
    last_m  <- schedule_m[length(schedule_m)]

    # New trimmed version, initially same as the old
    incubation_bouts_f_trimmed <- incubation_bouts_f
    foraging_bouts_f_trimmed   <- foraging_bouts_f
    incubation_bouts_m_trimmed <- incubation_bouts_m
    foraging_bouts_m_trimmed   <- foraging_bouts_m

    # Trim the corresponding bouts for females
    if (first_f == "1") incubation_bouts_f_trimmed <- incubation_bouts_f_trimmed[-1]
    if (last_f  == "1" && length(incubation_bouts_f_trimmed) > 0) incubation_bouts_f_trimmed <- incubation_bouts_f_trimmed[-length(incubation_bouts_f_trimmed)]
    if (first_f == "0") foraging_bouts_f_trimmed   <- foraging_bouts_f_trimmed[-1]
    if (last_f  == "0" && length(foraging_bouts_f_trimmed) > 0) foraging_bouts_f_trimmed   <- foraging_bouts_f_trimmed[-length(foraging_bouts_f_trimmed)]

    # Trim the corresponding bouts for males
    if (first_m == "1") incubation_bouts_m_trimmed <- incubation_bouts_m_trimmed[-1]
    if (last_m  == "1" && length(incubation_bouts_m_trimmed) > 0) incubation_bouts_m_trimmed <- incubation_bouts_m_trimmed[-length(incubation_bouts_m_trimmed)]
    if (first_m == "0") foraging_bouts_m_trimmed   <- foraging_bouts_m_trimmed[-1]
    if (last_m  == "0" && length(foraging_bouts_m_trimmed) > 0) foraging_bouts_m_trimmed <- foraging_bouts_m_trimmed[-length(foraging_bouts_m_trimmed)]

    # If trimming removed everything, reset to NA
    if (length(incubation_bouts_f_trimmed) == 0) incubation_bouts_f_trimmed <- NA
    if (length(foraging_bouts_f_trimmed)   == 0) foraging_bouts_f_trimmed   <- NA
    if (length(incubation_bouts_m_trimmed) == 0) incubation_bouts_m_trimmed <- NA
    if (length(foraging_bouts_m_trimmed)   == 0) foraging_bouts_m_trimmed   <- NA

    # Summarize all values
    list(Mean_Incubation_Bout_Both         = mean(c(incubation_bouts_f, incubation_bouts_m)),
         Mean_Incubation_Bout_Both_Trimmed = mean(c(incubation_bouts_f_trimmed, incubation_bouts_m_trimmed), na.rm = TRUE),
         Mean_Foraging_Bout_Both           = mean(c(foraging_bouts_f, foraging_bouts_m)),
         Mean_Foraging_Bout_Both_Trimmed   = mean(c(foraging_bouts_f_trimmed, foraging_bouts_m_trimmed), na.rm = TRUE),
         N_Incubation_Bouts_F              = length(incubation_bouts_f),
         Mean_Incubation_Bout_F            = mean(incubation_bouts_f),
         Mean_Incubation_Bout_F_Trimmed    = mean(incubation_bouts_f_trimmed, na.rm = TRUE),
         Var_Incubation_Bout_F             = var(incubation_bouts_f),
         N_Foraging_Bouts_F                = length(foraging_bouts_f),
         Mean_Foraging_Bout_F              = mean(foraging_bouts_f),
         Mean_Foraging_Bout_F_Trimmed      = mean(foraging_bouts_f_trimmed, na.rm = TRUE),
         Var_Foraging_Bout_F               = var(foraging_bouts_f),
         N_Incubation_Bouts_M              = length(incubation_bouts_m),
         Mean_Incubation_Bout_M            = mean(incubation_bouts_m),
         Mean_Incubation_Bout_M_Trimmed    = mean(incubation_bouts_m_trimmed, na.rm = TRUE),
         Var_Incubation_Bout_M             = var(incubation_bouts_m),
         N_Foraging_Bouts_M                = length(foraging_bouts_m),
         Mean_Foraging_Bout_M              = mean(foraging_bouts_m),
         Mean_Foraging_Bout_M_Trimmed      = mean(foraging_bouts_m_trimmed, na.rm = TRUE),
         Var_Foraging_Bout_M               = var(foraging_bouts_m))
}

############################################################
### processGroup - summarize one parameter combination
############################################################
processGroup <- function(chunk) {

    # Group keys for parameters from first row to prepend to output
    keys <- chunk[1, .(Min_Energy_Thresh_F, Max_Energy_Thresh_F,
                       Min_Energy_Thresh_M, Max_Energy_Thresh_M,
                       Foraging_Condition_Mean, Foraging_Condition_SD,
                       Egg_Tolerance, Egg_Cost, Num_Parents)]

    n <- nrow(chunk)

    # Subset by result state
    successes        <- chunk[Hatch_Result == "hatched"]
    fail_egg_time    <- chunk[Hatch_Result == "egg time fail"]
    fail_egg_cold    <- chunk[Hatch_Result == "egg cold fail"]
    fail_parent_dead <- chunk[Hatch_Result == "dead parent"]

    n_successes        <- nrow(successes)
    n_fail_egg_time    <- nrow(fail_egg_time)
    n_fail_egg_cold    <- nrow(fail_egg_cold)
    n_fail_parent_dead <- nrow(fail_parent_dead)

    # Overall summaries (all iterations)
    OVERALL_mean_energy_f  <- mean(chunk$Mean_Energy_F)
    OVERALL_var_energy_f   <- mean(chunk$Var_Energy_F)
    OVERALL_mean_energy_m  <- mean(chunk$Mean_Energy_M)
    OVERALL_var_energy_m   <- mean(chunk$Var_Energy_M)
    OVERALL_total_neglect  <- mean(chunk$Total_Neglect)
    OVERALL_max_neglect    <- mean(chunk$Max_Neglect)
    OVERALL_prop_neglect   <- mean(chunk$Total_Neglect / chunk$Hatch_Days)
    OVERALL_hatch_date     <- mean(chunk$Hatch_Days)

    # Successful-only summaries
    SUCCESSFUL_mean_energy_f  <- mean(successes$Mean_Energy_F)
    SUCCESSFUL_var_energy_f   <- mean(successes$Var_Energy_F)
    SUCCESSFUL_mean_energy_m  <- mean(successes$Mean_Energy_M)
    SUCCESSFUL_var_energy_m   <- mean(successes$Var_Energy_M)
    SUCCESSFUL_tot_neglect    <- mean(successes$Total_Neglect)
    SUCCESSFUL_max_neglect    <- mean(successes$Max_Neglect)
    SUCCESSFUL_prop_neglect   <- mean(successes$Total_Neglect / successes$Hatch_Days)
    SUCCESSFUL_hatch_date     <- mean(successes$Hatch_Days)
    SUCCESSFUL_attendance_f   <- mean(str_count(successes$Season_History, "F"))
    SUCCESSFUL_prop_f         <- mean(str_count(successes$Season_History, "F") / successes$Hatch_Days)
    SUCCESSFUL_attendance_m   <- mean(str_count(successes$Season_History, "M"))
    SUCCESSFUL_prop_m         <- mean(str_count(successes$Season_History, "M") / successes$Hatch_Days)

    # Bout info across successful schedules, parallelized
    if (n_successes > 0) {
        bout_list <- lapply(successes$Season_History, calcBouts)
        bout_dt   <- rbindlist(lapply(bout_list, as.list))
        SUCCESSFUL_bout_info <- as.list(bout_dt[, lapply(.SD, mean, na.rm = TRUE)])
    } else {
        SUCCESSFUL_bout_info <- list(Mean_Incubation_Bout_Both = NA, 
                                     Mean_Incubation_Bout_Both_Trimmed = NA,
                                     Mean_Foraging_Bout_Both = NA,   
                                     Mean_Foraging_Bout_Both_Trimmed = NA,
                                     N_Incubation_Bouts_F = NA,      
                                     Mean_Incubation_Bout_F = NA,
                                     Mean_Incubation_Bout_F_Trimmed = NA,
                                     Var_Incubation_Bout_F = NA,
                                     N_Foraging_Bouts_F = NA,
                                     Mean_Foraging_Bout_F = NA,
                                     Mean_Foraging_Bout_F_Trimmed = NA,
                                     Var_Foraging_Bout_F = NA,
                                     N_Incubation_Bouts_M = NA,
                                     Mean_Incubation_Bout_M = NA,
                                     Mean_Incubation_Bout_M_Trimmed = NA, 
                                     Var_Incubation_Bout_M = NA,
                                     N_Foraging_Bouts_M = NA,        
                                     Mean_Foraging_Bout_M = NA,
                                     Mean_Foraging_Bout_M_Trimmed = NA,
                                     Var_Foraging_Bout_M = NA)
    }

    # Assemble output row
    result <- data.table(N_Total                   = n,
                         N_Success                 = n_successes,
                         N_Fail_Egg_Time           = n_fail_egg_time,
                         N_Fail_Egg_Cold           = n_fail_egg_cold,
                         N_Fail_Parent_Dead        = n_fail_parent_dead,
                     
                         Overall_Mean_Energy_F     = OVERALL_mean_energy_f,
                         Overall_Var_Energy_F      = OVERALL_var_energy_f,
                         Overall_Mean_Energy_M     = OVERALL_mean_energy_m,
                         Overall_Var_Energy_M      = OVERALL_var_energy_m,
                         Overall_Total_Neglect     = OVERALL_total_neglect,
                         Overall_Max_Neglect       = OVERALL_max_neglect,
                         Overall_Prop_Neglect      = OVERALL_prop_neglect,
                         Overall_Hatch_Date        = OVERALL_hatch_date,
                     
                         Successful_Mean_Energy_F  = SUCCESSFUL_mean_energy_f,
                         Successful_Var_Energy_F   = SUCCESSFUL_var_energy_f,
                         Successful_Mean_Energy_M  = SUCCESSFUL_mean_energy_m,
                         Successful_Var_Energy_M   = SUCCESSFUL_var_energy_m,
                         Successful_Total_Neglect  = SUCCESSFUL_tot_neglect,
                         Successful_Max_Neglect    = SUCCESSFUL_max_neglect,
                         Successful_Prop_Neglect   = SUCCESSFUL_prop_neglect,
                         Successful_Hatch_Date     = SUCCESSFUL_hatch_date,
                         Successful_Attendance_F   = SUCCESSFUL_attendance_f,
                         Successful_Prop_F         = SUCCESSFUL_prop_f,
                         Successful_Attendance_M   = SUCCESSFUL_attendance_m,
                         Successful_Prop_M         = SUCCESSFUL_prop_m)

    result[, Rate_Success          := N_Success / N_Total]
    result[, Rate_Fail_Egg_Time    := N_Fail_Egg_Time / N_Total]
    result[, Rate_Fail_Egg_Cold    := N_Fail_Egg_Cold / N_Total]
    result[, Rate_Fail_Parent_Dead := N_Fail_Parent_Dead / N_Total]

    result <- cbind(keys, result, as.data.table(SUCCESSFUL_bout_info))

    return(result)
}

############################################################
### Process data call
############################################################
process_data_file <- function(type, suffix) {
    cat(paste("Reading", type, "data...\n"))

    dat <- fread(paste0("Output/sims_", type, "_", suffix, ".csv"))

    GROUP_KEYS <- c("Min_Energy_Thresh_F", "Max_Energy_Thresh_F",
                    "Min_Energy_Thresh_M", "Max_Energy_Thresh_M",
                    "Foraging_Condition_Mean", "Foraging_Condition_SD",
                    "Egg_Tolerance", "Egg_Cost", "Num_Parents")

    # Split into list of data.tables, one per parameter combination
    groups <- split(dat, by = GROUP_KEYS, keep.by = TRUE)
    
    # Remove full data so we don't keep full and split data in active memory both
    rm(dat)
    gc()

    # Process all groups in parallel
    cl <- makeCluster(detectCores() - 1)
    clusterExport(cl, c("calcBouts", "processGroup"))
    clusterEvalQ(cl, { library(data.table); library(stringr) })
    results_list <- pblapply(groups, processGroup, cl = cl)
    stopCluster(cl)

    results_summarized <- rbindlist(results_list, use.names = TRUE)

    # Save output
    cat(paste("Writing", type, "output...\n"))
    fwrite(results_summarized, paste0("Output/processed_", type, ".csv"))
    cat("Done\n")
}

############################################################
### Run
############################################################

for (type in SIM_TYPES) { process_data_file(type, RESULTS_SUFFIX) }
