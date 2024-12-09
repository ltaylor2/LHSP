library(tidyverse)
library(acss)

SIMS_RESULTS <- "Output/sims_2024-12-09_00-16-06.csv"

CHUNK_hatch_success <- function(chunk, pos) {
    max_energy_thresh_f <- unique(chunk$Max_Energy_Thresh_F)
    min_energy_thresh_f <- unique(chunk$Min_Energy_Thresh_F)
    max_energy_thresh_m <- unique(chunk$Max_Energy_Thresh_M)
    min_energy_thresh_m <- unique(chunk$Min_Energy_Thresh_M)
    foraging_condition_mean <- unique(chunk$Foraging_Condition_Mean)
    foraging_condition_sd <- unique(chunk$Foraging_Condition_SD)

    if (any(map_lgl(list(max_energy_thresh_f, min_energy_thresh_f, max_energy_thresh_m, min_energy_thresh_m, foraging_condition_mean, foraging_condition_sd), ~ length(.) > 1))) {
        return("ERROR")
    }
    
    hatch_success_rate <- nrow(chunk[chunk$Hatch_Result == "hatched",]) / 1000

    processed <- tibble(Max_Energy_Thresh_F = max_energy_thresh_f,
                        Min_Energy_Thresh_F = min_energy_thresh_f,
                        Max_Energy_Thresh_M = max_energy_thresh_m,
                        Min_Energy_Thresh_M = min_energy_thresh_m,
                        Foraging_Condition_Mean = foraging_condition_mean,
                        Foraging_Condition_SD = foraging_condition_sd,
                        Hatch_Success_Rate = hatch_success_rate)
    return(processed)
}

results_hatch_success <- read_csv_chunked(SIMS_RESULTS,
                                          DataFrameCallback$new(CHUNK_hatch_success),
                                          chunk_size=1000)

write_csv(results_hatch_success, "Output/processed_results_hatch_success.csv")    

CHUNK_summaries <- function(chunk, pos) {
    max_energy_thresh_f <- unique(chunk$Max_Energy_Thresh_F)
    min_energy_thresh_f <- unique(chunk$Min_Energy_Thresh_F)
    max_energy_thresh_m <- unique(chunk$Max_Energy_Thresh_M)
    min_energy_thresh_m <- unique(chunk$Min_Energy_Thresh_M)
    foraging_condition_mean <- unique(chunk$Foraging_Condition_Mean)
    foraging_condition_sd <- unique(chunk$Foraging_Condition_SD)

    if (any(map_lgl(list(max_energy_thresh_f, min_energy_thresh_f, max_energy_thresh_m, min_energy_thresh_m, foraging_condition_mean, foraging_condition_sd), ~ length(.) > 1))) {
        return("ERROR")
    }

    hatched <- chunk |>
            filter(Hatch_Result == "hatched")
    
    scaled_entropy <- mean(acss::entropy(hatched$Season_History) / log(3, base=2))

    end_energy_f <- mean(hatched$End_Energy_F)
    mean_energy_f <- mean(hatched$Mean_Energy_F)
    var_energy_f <- mean(hatched$Var_Energy_F)

    end_energy_m <- mean(hatched$End_Energy_M)
    mean_energy_m <- mean(hatched$Mean_Energy_M)
    var_energy_m <- mean(hatched$Var_Energy_M)

    tot_neglect <- mean(hatched$Total_Neglect)
    max_neglect <- mean(hatched$Max_Neglect)

    processed <- tibble(Max_Energy_Thresh_F = max_energy_thresh_f,
                        Min_Energy_Thresh_F = min_energy_thresh_f,
                        Max_Energy_Thresh_M = max_energy_thresh_m,
                        Min_Energy_Thresh_M = min_energy_thresh_m,
                        Foraging_Condition_Mean = foraging_condition_mean,
                        Foraging_Condition_SD = foraging_condition_sd,
                        End_Energy_F = end_energy_f,
                        Mean_Energy_F = mean_energy_f,
                        Var_Energy_F = var_energy_f,
                        End_Energy_M = end_energy_m,
                        Mean_Energy_M = mean_energy_m,
                        Var_Energy_M = var_energy_m,
                        Total_Neglect = tot_neglect,
                        Max_Neglect = max_neglect,
                        Scaled_Entropy = scaled_entropy)
    return(processed)
}

results_success_summaries <- read_csv_chunked(SIMS_RESULTS,
                                              DataFrameCallback$new(CHUNK_summaries),
                                              chunk_size=1000)

write_csv(results_success_summaries, "Output/processed_results_success_summaries.csv")