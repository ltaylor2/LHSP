library(tidyverse)
library(acss)

RESULTS_FILEPATH <- "Output/sims_2025-08-04_18-55-22_ms1.csv"

calcBouts <- function(schedule) {
    # split schedule into character vector
    schedule_f <- str_split_1(schedule, "")
    schedule_m <- str_split_1(schedule, "")

    # simplify to two states
    #   1 for focal parent, 0 otherwise
    schedule_f[schedule_f == "F"] <- 1
    schedule_f[schedule_f != 1] <- 0

    schedule_m[schedule_m == "M"] <- 1
    schedule_m[schedule_m != 1] <- 0

    # calculate runs
    runs_f <- rle(schedule_f)
    incubation_bouts_f <- runs_f$lengths[runs_f$values=="1"] 
    foraging_bouts_f <- runs_f$lengths[runs_f$values=="0"]

    runs_m <- rle(schedule_m)
    incubation_bouts_m <- runs_m$lengths[runs_m$values=="1"] 
    foraging_bouts_m <- runs_m$lengths[runs_m$values=="0"]

    # summarize all values
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

    # return as neat tibble
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

processChunk <- function(chunk, pos, iterations) {

    # Extract unique parameters to append later
    max_energy_thresh_f <- unique(chunk$Max_Energy_Thresh_F)
    min_energy_thresh_f <- unique(chunk$Min_Energy_Thresh_F)
    max_energy_thresh_m <- unique(chunk$Max_Energy_Thresh_M)
    min_energy_thresh_m <- unique(chunk$Min_Energy_Thresh_M)
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
    if (nrow(chunk) != iterations) {
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
    OVERALL_var_energy_f <- mean(chunk$Var_Energy_M)
    OVERALL_tot_neglect <- mean(chunk$Total_Neglect)
    OVERALL_max_neglect <- mean(chunk$Max_Neglect)
    OVERALL_mean_hatch_date <- mean(chunk$Hatch_Days)

    # More internally consistent summary values for successful seasons only 
    SUCCESSFUL_mean_energy_f <- mean(successes$Mean_Energy_F)
    SUCCESSFUL_var_energy_f <- mean(successes$Var_Energy_F)
    SUCCESSFUL_mean_energy_m <- mean(successes$Mean_Energy_M)
    SUCCESSFUL_var_energy_f <- mean(successes$Var_Energy_M)
    SUCCESSFUL_tot_neglect <- mean(successes$Total_Neglect)
    SUCCESSFUL_max_neglect <- mean(successes$Max_Neglect)
    SUCCESSFUL_mean_hatch_date <- mean(successes$Hatch_Days)
    SUCCESSFUL_proportion_neglect <- mean(successes$Total_Neglect / successes$Hatch_Days)
    SUCCESSFUL_attendance_f <- mean(str_count(successes$Season_History, "F"))
    SUCCESSFUL_proportion_f <- mean(str_count(successes$Season_History, "F") / successes$Hatch_Days)
    SUCCESSFUL_attendance_m <- mean(str_count(successes$Season_History, "M"))
    SUCCESSFUL_proportion_m <- mean(str_count(successes$Season_History, "M") / successes$Hatch_Days)

    # TODO CALCULATE ALL THE SUCCESSFUL BOUT INFO AND SUMMARIZE, THEN APPEND, THEN RETURN ALL
    bouts_info <- map_df()
    return(processed)

}
summarizeSubset <- function(df, didHatch) {
    min_energy_thresh_f <- unique(df$Min_Energy_Thresh_F)
    max_energy_thresh_f <- unique(df$Max_Energy_Thresh_F)
    min_energy_thresh_m <- unique(df$Min_Energy_Thresh_M)
    max_energy_thresh_m <- unique(df$Max_Energy_Thresh_M)
    foraging_condition_mean <- unique(df$Foraging_Condition_Mean)
    foraging_condition_sd <- unique(df$Foraging_Condition_SD)
    foraging_condition_kick <- unique(df$Foraging_Condition_Kick)
    eggNeglectMax <- unique(df$Egg_Neglect_Max)

    n = nrow(df)

    season_length <- mean(nchar(df$Season_History))
    
    scaled_entropies <- acss::entropy(df$Season_History) / log(3, base=2)
    scaled_entropy <- mean(scaled_entropies)

    scaled_entropies_n_adjusted <- scaled_entropies / (1 - str_count(df$Season_History, "N") / str_count(df$Season_History))
    scaled_entropy_n_adjusted <- mean(scaled_entropies_n_adjusted)

    end_energy_f <- mean(df$End_Energy_F)
    mean_energy_f <- mean(df$Mean_Energy_F)
    var_energy_f <- mean(df$Var_Energy_F)
    tot_neglect <- mean(df$Total_Neglect)
    max_neglect <- mean(df$Max_Neglect)

    ret <- tibble(Min_Energy_Thresh_F = min_energy_thresh_f,
                  Max_Energy_Thresh_F = max_energy_thresh_f,
                  Min_Energy_Thresh_M = min_energy_thresh_m,
                  Max_Energy_Thresh_M = max_energy_thresh_m,
                  Foraging_Condition_Mean = foraging_condition_mean,
                  Foraging_Condition_SD = foraging_condition_sd,
                  Foraging_Condition_Kick = foraging_condition_kick,
                  Egg_Neglect_Max = eggNeglectMax,
                  Did_Hatch = didHatch,
                  N = n,
                  End_Energy_F = end_energy_f,
                  Mean_Energy_F = mean_energy_f,
                  Var_Energy_F = var_energy_f,
                  End_Energy_M = end_energy_m,
                  Mean_Energy_M = mean_energy_m,
                  Var_Energy_M = var_energy_m,
                  Total_Neglect = tot_neglect,
                  Max_Neglect = max_neglect,
                  Season_Length = season_length,
                  Scaled_Entropy = scaled_entropy,
                  Scaled_Entropy_N_Adjusted = scaled_entropy_n_adjusted)
    return(ret)
}

CHUNK_summaries <- function(chunk, pos) {
}

results_summarized <- read_csv_chunked(SIMS_RESULTS,
                                       DataFrameCallback$new(CHUNK_summaries),
                                       chunk_size=1000)

write_csv(results_summarized, "Output/processed_results_summarized.csv")


CHUNK_hatch_success <- function(chunk, pos) {
    max_energy_thresh_f <- unique(chunk$Max_Energy_Thresh_F)
    min_energy_thresh_f <- unique(chunk$Min_Energy_Thresh_F)
    max_energy_thresh_m <- unique(chunk$Max_Energy_Thresh_M)
    min_energy_thresh_m <- unique(chunk$Min_Energy_Thresh_M)
    foraging_condition_mean <- unique(chunk$Foraging_Condition_Mean)
    foraging_condition_sd <- unique(chunk$Foraging_Condition_SD)
    foraging_condition_kick <- unique(chunk$Foraging_Condition_Kick)
    egg_neglect_max <- unique(chunk$Egg_Neglect_Max)

    if (any(map_lgl(list(max_energy_thresh_f, min_energy_thresh_f, 
                         max_energy_thresh_m, min_energy_thresh_m, 
                         foraging_condition_mean, foraging_condition_sd, foraging_condition_kick,
                         egg_neglect_max), 
                    ~ length(.) > 1))) {
        return("ERROR")
    }

    if (nrow(chunk) != 1000) {
        return("ERROR")
    }

    processed <- chunk |>
              group_by(Min_Energy_Thresh_F, Max_Energy_Thresh_F,
                       Min_Energy_Thresh_M, Max_Energy_Thresh_M,
                       Foraging_Condition_Mean, Foraging_Condition_SD,
                       Foraging_Condition_Kick, Egg_Neglect_Max, Hatch_Result) |>
              tally() |>
              mutate(Rate = n/1000) |>
              pivot_wider(id_cols=c(Min_Energy_Thresh_F, Max_Energy_Thresh_F, Min_Energy_Thresh_M, Max_Energy_Thresh_M,
                                    Foraging_Condition_Mean, Foraging_Condition_SD, Foraging_Condition_Kick,
                                    Egg_Neglect_Max),
                          names_from=Hatch_Result, values_from=Rate)
    return(processed)
}

results_hatch_success <- read_csv_chunked(SIMS_RESULTS,
                                          DataFrameCallback$new(CHUNK_hatch_success),
                                          chunk_size=1000) |>
                      select(Min_Energy_Thresh_F, Max_Energy_Thresh_F, Min_Energy_Thresh_M, Max_Energy_Thresh_M,
                             Foraging_Condition_Mean, Foraging_Condition_SD, Foraging_Condition_Kick,
                             Egg_Neglect_Max, 
                             Success="hatched", Fail_Dead_Parent="dead parent", 
                             Fail_Egg_Neglect_Max="egg cold fail", Fail_Egg_Neglect_Cumulative="egg time fail") |>
                      mutate(Success = replace_na(Success, 0),
                             Fail_Dead_Parent = replace_na(Fail_Dead_Parent, 0),
                             Fail_Egg_Neglect_Max = replace_na(Fail_Egg_Neglect_Max, 0),
                             Fail_Egg_Neglect_Cumulative = replace_na(Fail_Egg_Neglect_Cumulative, 0))
                      
write_csv(results_hatch_success, "Output/processed_results_hatch_success.csv")

CHUNK_example <- function(chunk, pos) {
    filter(chunk, 
           Min_Energy_Thresh_F == 400,
           Max_Energy_Thresh_F == 500,
           Min_Energy_Thresh_M == 700,
           Max_Energy_Thresh_M == 900)
}

results_example <- read_csv_chunked(SIMS_RESULTS,
                                    DataFrameCallback$new(CHUNK_example),
                                    chunk_size=10000)
write_csv(results_example, "Output/processed_results_example_strategy.csv")

CHUNK_empirical <- function(chunk, pos) {
    filter(chunk, 
           Foraging_Condition_Mean == 160,
           Min_Energy_Thresh_F %in% c(400, 500, 600), 
           Max_Energy_Thresh_F %in% c(700, 800, 900),
           Min_Energy_Thresh_M %in% c(400, 500, 600), 
           Max_Energy_Thresh_M %in% c(700, 800, 900))
}

# results_empirical <- read_csv_chunked(SIMS_RESULTS,
#                                     DataFrameCallback$new(CHUNK_empirical),
#                                     chunk_size=10000)

# write_csv(results_empirical, "Output/processed_results_empirical_strategy.csv")