library(tidyverse)
library(acss)

SIMS_RESULTS <- "Output/sims_2025-07-25_19-36-17_neglectMax.csv"

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

    end_energy_m <- mean(df$End_Energy_M)
    mean_energy_m <- mean(df$Mean_Energy_M)
    var_energy_m <- mean(df$Var_Energy_M)

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
    max_energy_thresh_f <- unique(chunk$Max_Energy_Thresh_F)
    min_energy_thresh_f <- unique(chunk$Min_Energy_Thresh_F)
    max_energy_thresh_m <- unique(chunk$Max_Energy_Thresh_M)
    min_energy_thresh_m <- unique(chunk$Min_Energy_Thresh_M)
    foraging_condition_mean <- unique(chunk$Foraging_Condition_Mean)
    foraging_condition_sd <- unique(chunk$Foraging_Condition_SD)
    foraging_condition_kick <- unique(chunk$Foraging_Condition_Kick)

    if (any(map_lgl(list(max_energy_thresh_f, min_energy_thresh_f, 
                         max_energy_thresh_m, min_energy_thresh_m, 
                         foraging_condition_mean, foraging_condition_sd, foraging_condition_kick), 
                    ~ length(.) > 1))) {
        return("ERROR")
    }

    if (nrow(chunk) != 1000) {
        return("ERROR")
    }

    yesHatched <- summarizeSubset(chunk[chunk$Hatch_Result == "hatched",], didHatch=TRUE)
    noHatched <- summarizeSubset(chunk[chunk$Hatch_Result != "hatched",], didHatch=FALSE)

    processed <- bind_rows(yesHatched, noHatched)
    return(processed)
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