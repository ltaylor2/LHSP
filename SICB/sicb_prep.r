# Logistics
library(tidyverse)

# Read and format data
dat <- read_csv("Output/processed_results_summarized.csv") |>
    mutate(Strategy = paste0(Min_Energy_Thresh_F, "-", Max_Energy_Thresh_F, "/", Min_Energy_Thresh_M, "-", Max_Energy_Thresh_M), .before=1)

strategyOrder <- dat |> 
              arrange(Min_Energy_Thresh_F, Max_Energy_Thresh_F, Min_Energy_Thresh_M, Max_Energy_Thresh_M) |>
              pull(Strategy) |>
              unique()

dat$Strategy <- factor(dat$Strategy, levels=strategyOrder)

# Example strategy
# example_strategy <- dat |>
#                  filter(Foraging_Condition_Mean == 150, !Foraging_Condition_Kick) |>
#                  filter(Did_Hatch) |>
#                  mutate(Hatch_Success = N / 1000) |>
#                  mutate(Diff_From_50 = abs(0.5 - Hatch_Success)) |>
#                  slice_min(order_by = Diff_From_50) |>
#                  pull(Strategy)

dat_example_strategy <- read_csv("Output/processed_results_example_strategy.csv")

# Plot example for empirical foraging condition

example_strings <- dat_example_strategy |>
                select(Iteration, Hatch_Result, Foraging_Condition_Mean, Foraging_Condition_Kick, Season_History) |>
                separate(Season_History, into=as.character(0:61), sep="") |>
                pivot_longer(cols=-c(Iteration, Hatch_Result, Foraging_Condition_Mean, Foraging_Condition_Kick), names_to="Day", values_to="State") |>
                filter(Day != 0) |>
                mutate(Day = as.numeric(Day)) |>
                filter(!is.na(State))

state_colors <- c("F"="#1f78b4",
                  "M"="#b2df8a",
                  "N"="#e41a1c")

plot_iteration_examples_pair <- ggplot(filter(example_strings, Foraging_Condition_Mean==150, Iteration %in% c(1, 3))) +
                             geom_raster(aes(x=Day, y=Iteration, fill=State, alpha=Hatch_Result=="hatched")) +
                             scale_fill_manual(values=c(state_colors), na.value="white", 
                                               labels=c("F"="Female", "M"="Male", "N"="Neglect")) +
                             scale_y_continuous(breaks=c(1,3), labels=c(1,3)) +
                             scale_alpha_manual(values=c("TRUE"=1, "FALSE"=0.5)) +
                             guides(alpha="none") +
                             theme_classic()
ggsave(filename="SICB/PLOT_iteration_pair.png", plot_iteration_examples_pair, width=4, height=2)

plot_iteration_examples_nokick <- ggplot(filter(example_strings, Foraging_Condition_Mean==150, !Foraging_Condition_Kick)) +
                                geom_raster(aes(x=Day, y=Iteration, fill=State, alpha=Hatch_Result=="hatched")) +
                                scale_fill_manual(values=c(state_colors), na.value="white", 
                                                  labels=c("F"="Female", "M"="Male", "N"="Neglect")) +
                                scale_alpha_manual(values=c("TRUE"=1, "FALSE"=0.25)) +
                                guides(alpha="none") +
                                theme_classic()
ggsave(filename="SICB/PLOT_iteration_examples_nokick.png", plot_iteration_examples_nokick, width=4, height=2.5)

plot_iteration_examples_withkick <- ggplot(filter(example_strings, Foraging_Condition_Mean==150)) +
                                geom_raster(aes(x=Day, y=Iteration, fill=State, alpha=Hatch_Result=="hatched")) +
                                facet_wrap(facet=vars(Foraging_Condition_Kick), nrow=2, labeller=as_labeller(c("0"="Regular environment", "1"="Perturbed environment"))) +
                                scale_fill_manual(values=c(state_colors), na.value="white", 
                                                  labels=c("F"="Female", "M"="Male", "N"="Neglect")) +
                                scale_alpha_manual(values=c("TRUE"=1, "FALSE"=0.25)) +
                                guides(alpha="none") +
                                theme_classic()
ggsave(filename="SICB/PLOT_iteration_examples_withkick.png", plot_iteration_examples_withkick, width=4, height=5)

tempLabelFunction <- function(l) {
    if (l == "0") { return("Regular environment") }
    if (l == "1") { return("Perturbed environment") }
    return(paste(l, "kJ/day"))
}
plot_iteration_examples_multiple_environments <- ggplot(example_strings) +
                                              geom_raster(aes(x=Day, y=Iteration, fill=State, alpha=Hatch_Result=="hatched")) +
                                              facet_grid(rows=vars(Foraging_Condition_Kick), 
                                                         cols=vars(Foraging_Condition_Mean), 
                                                         labeller=tempLabelFunction) +
                                              scale_fill_manual(values=c(state_colors), na.value="white", 
                                                                labels=c("F"="Female", "M"="Male", "N"="Neglect")) +
                                              scale_alpha_manual(values=c("TRUE"=1, "FALSE"=0.25)) +
                                              guides(alpha="none") +
                                              theme_classic()
ggsave(filename="SICB/PLOT_iteration_examples_multipleenvironments.png", plot_iteration_examples_multiple_environments, width=10, height=5)
