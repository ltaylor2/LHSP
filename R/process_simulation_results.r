library(tidyverse)
library(acss)

SIMS_RESULTS <- "Output/sims_2024-12-09_14-45-26.csv"

summarizeSubset <- function(df, didHatch) {

    max_energy_thresh_f <- unique(df$Max_Energy_Thresh_F)
    min_energy_thresh_f <- unique(df$Min_Energy_Thresh_F)
    max_energy_thresh_m <- unique(df$Max_Energy_Thresh_M)
    min_energy_thresh_m <- unique(df$Min_Energy_Thresh_M)
    foraging_condition_mean <- unique(df$Foraging_Condition_Mean)
    foraging_condition_sd <- unique(df$Foraging_Condition_SD)
    foraging_condition_kick <- unique(df$Foraging_Condition_Kick)

    n = nrow(df)

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

    ret <- tibble(Max_Energy_Thresh_F = max_energy_thresh_f,
                  Min_Energy_Thresh_F = min_energy_thresh_f,
                  Max_Energy_Thresh_M = max_energy_thresh_m,
                  Min_Energy_Thresh_M = min_energy_thresh_m,
                  Foraging_Condition_Mean = foraging_condition_mean,
                  Foraging_Condition_SD = foraging_condition_sd,
                  Foraging_Condition_Kick = foraging_condition_kick,
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
    foraging_condition_kick <- unique(df$Foraging_Condition_Kick)

    if (any(map_lgl(list(max_energy_thresh_f, min_energy_thresh_f, 
                         max_energy_thresh_m, min_energy_thresh_m, 
                         foraging_condition_mean, foraging_condition_sd, foraging_condition_kicked), 
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

CHUNK_subset <- function(chunk, pos) {
    filter(chunk, Foraging_Condition_Mean == 150, Iterations== 1)
}

results_subset <- read_csv_chunked(SIMS_RESULTS,
                                   DataFrameCallback$new(CHUNK_subset),
                                   chunk_size=1000)


temp <- results_subset |>
     mutate(Strategy = paste0(Min_Energy_Thresh_F, "-", Max_Energy_Thresh_F, "/", Min_Energy_Thresh_M, "-", Max_Energy_Thresh_M)) |>
     select(Strategy, Foraging_Condition_Mean, Foraging_Condition_Kick, Season_History) |>
     separate(Season_History, into=as.character(-1:60), sep="") |>
     pivot_longer(cols=as.character(-1:60), names_to="Day", values_to="State") |>
     filter(Day != "-1") |>
     mutate(Day = as.numeric(Day))

plot_raster <- ggplot(temp) +
            geom_raster(aes(x=Day, y=Strategy, fill=State)) +
            scale_fill_manual(values=c("M"="lightblue", "F"="darkblue", "N"="red", "NA"="lightgray")) +
            facet_wrap(facet=vars(Foraging_Condition_Kick)) +
            theme_minimal() +
            theme(axis.title.y=element_blank(),
                  axis.text.y=element_blank(),
                  strip.background=element_rect(fill="white", colour="white"),
                  panel.background=element_rect(fill="white"),
                  plot.background=element_rect(fill="white"))
ggsave(plot_raster, filename="Output/plot_raster_temp.png", width=3, height=10)
