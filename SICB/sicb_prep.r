# Logistics
library(tidyverse)
library(patchwork)
library(plotly)

# Read and format data
SIMS_VERSION <- "Perturbed3"
dat <- read_csv(paste0("Output/processed_results_summarized_", SIMS_VERSION, ".csv")) |>
    filter(Foraging_Condition_Kick == 0) |>
    mutate(Strategy_F = paste0(Min_Energy_Thresh_F, "-", Max_Energy_Thresh_F),
           Strategy_M = paste0(Min_Energy_Thresh_M, "-", Max_Energy_Thresh_M), .before=1) |>
    mutate(Strategy_Overall = paste0(Strategy_F, "/", Strategy_M), .before=1)

strategyOrder_F <- dat |> 
                 arrange(Min_Energy_Thresh_F, Max_Energy_Thresh_F) |>
                 pull(Strategy_F) |>
                 unique()
dat$Strategy_F <- factor(dat$Strategy_F, levels=strategyOrder_F)

strategyOrder_M <- dat |> 
                 arrange(Min_Energy_Thresh_M, Max_Energy_Thresh_M) |>
                 pull(Strategy_M) |>
                 unique()
dat$Strategy_M <- factor(dat$Strategy_M, levels=strategyOrder_M)

strategyOrder_Overall <- dat |> 
              arrange(Min_Energy_Thresh_F, Max_Energy_Thresh_F, Min_Energy_Thresh_M, Max_Energy_Thresh_M) |>
              pull(Strategy_Overall) |>
              unique()
dat$Strategy_Overall <- factor(dat$Strategy_Overall, levels=strategyOrder_Overall)

# Example strategy
# example_strategy <- dat |>
#                  filter(Foraging_Condition_Mean == 150, !Foraging_Condition_Kick) |>
#                  filter(Did_Hatch) |>
#                  mutate(Hatch_Success = N / 1000) |>
#                  mutate(Diff_From_50 = abs(0.5 - Hatch_Success)) |>
#                  slice_min(order_by = Diff_From_50) |>
#                  pull(Strategy_Overall)
dat_example_strategy <- read_csv(paste0("Output/processed_results_example_strategy_", SIMS_VERSION, ".csv")) |>
                     filter(Foraging_Condition_Kick==0)

# Season history examples
exampleCategories <- c("Regular environment\n(160 kJ/day)", 
                       "Degraded environment\n(140 kJ/day)")
assignExampleCategory <- function(fMean, fKick=0) {
    if (fMean == 160 & fKick == 0) { return (exampleCategories[1]) }
    if (fMean == 140 & fKick == 0) { return (exampleCategories[2]) }
    return("Other")
}


example_strings_cut <- dat_example_strategy |>
                    filter(Foraging_Condition_Mean==140) |>
                    filter(Iteration != 452) |>
                    select(Iteration, Hatch_Result, Foraging_Condition_Mean, Hatch_Days, Season_History) |>
                    group_by(Hatch_Result) |>
                    slice_min(n=1, order_by=Hatch_Days, with_ties=FALSE) |>
                    mutate(Iteration = paste0("I", as.character(Iteration))) |>
                    separate(Season_History, into=as.character(0:61), sep="") |>
                    pivot_longer(cols=-c(Iteration, Hatch_Result, Foraging_Condition_Mean, Hatch_Days), names_to="Day", values_to="State") |>
                    filter(Day != 0) |>
                    mutate(Day = as.numeric(Day)) |>
                    filter(!is.na(State))

state_colors <- c("F"="gray80",
                  "M"="gray20",
                  "N"="indianred2")

plot_iteration_examples <- ggplot(example_strings_cut) +
                        geom_raster(aes(x=Day, y=Iteration, fill=State, alpha=Hatch_Result=="hatched")) +
                        scale_fill_manual(values=c(state_colors), na.value="white", 
                                          labels=c("F"="Female", "M"="Male", "N"="Neglect")) +
                        scale_y_discrete(limits=c("I534", "I0", "I497", "I37"),
                                         labels=c("I534"="Egg Hatched - Success", "I0"="Overall neglect - Fail", 
                                                  "I497"="Continuous neglect - Fail", "I37"="Dead parent - Fail")) +
                        scale_alpha_manual(values=c("TRUE"=1, "FALSE"=0.25)) +
                        guides(alpha="none") +
                        ylab("Outcome") +
                        theme_classic()
ggsave(filename="SICB/PLOT_season_examples.png", plot_iteration_examples, width=5, height=2)

example_strings <- dat_example_strategy |>
                select(Iteration, Hatch_Result, Foraging_Condition_Mean, Foraging_Condition_Kick, Hatch_Days, Season_History) |>
                mutate(Example_Category = map2_chr(Foraging_Condition_Mean, Foraging_Condition_Kick, assignExampleCategory)) |>
                filter(Example_Category != "Other") |>
                mutate(Example_Category = factor(Example_Category, levels=exampleCategories)) |>
                separate(Season_History, into=as.character(0:61), sep="") |>
                pivot_longer(cols=-c(Iteration, Hatch_Result, Example_Category, Foraging_Condition_Mean, Hatch_Days, Foraging_Condition_Kick), names_to="Day", values_to="State") |>
                filter(Day != 0) |>
                mutate(Day = as.numeric(Day)) |>
                filter(!is.na(State))

plot_iteration_examples_all <- ggplot(example_strings) +
                            geom_raster(aes(x=Day, y=Iteration, fill=State, alpha=Hatch_Result=="hatched")) +
                            facet_wrap(facet=vars(Example_Category), nrow=1) +
                            scale_fill_manual(values=c(state_colors), na.value="white", 
                                              labels=c("F"="Female", "M"="Male", "N"="Neglect")) +
                            scale_alpha_manual(values=c("TRUE"=1, "FALSE"=0)) +
                            guides(alpha="none") +
                            theme_classic()
ggsave(filename="SICB/PLOT_iteration_examples_all.png", plot_iteration_examples_all, width=6, height=4)

# Strategy comparisons in regular environment
successMetrics <- dat |>
               filter(Did_Hatch) |>
               group_by(Strategy_Overall, Foraging_Condition_Mean) |>
               summarize(Foraging_Condition_Mean=Foraging_Condition_Mean,
                         Total_Neglect_Success = mean(Total_Neglect),
                         Scaled_Entropy_Success = mean(Scaled_Entropy),
                         Scaled_Entropy_N_Adjusted_Success = mean(Scaled_Entropy_N_Adjusted),
                         Mean_Energy_F_Success = mean(Mean_Energy_F),
                         Mean_Energy_M_Success = mean(Mean_Energy_M)) |>
               mutate(Mean_Parent_Energy_Success = (Mean_Energy_F_Success + Mean_Energy_M_Success)/2)

dat_hs <- read_csv(paste0("Output/processed_results_hatch_success_", SIMS_VERSION, ".csv")) |>
       filter(Foraging_Condition_Kick==0) |>
       mutate(Example_Category = map_chr(Foraging_Condition_Mean, assignExampleCategory)) |>
       mutate(Example_Category = factor(Example_Category, levels=exampleCategories)) |>
       mutate(Strategy_F = paste0(Min_Energy_Thresh_F, "-", Max_Energy_Thresh_F),
              Strategy_M = paste0(Min_Energy_Thresh_M, "-", Max_Energy_Thresh_M), .before=1) |>
       mutate(Strategy_Overall = paste0(Strategy_F, "/", Strategy_M), .before=1) |>
       left_join(successMetrics, by=c("Strategy_Overall", "Foraging_Condition_Mean"))

strategyOrder_F <- dat_hs |> 
                arrange(Min_Energy_Thresh_F, Max_Energy_Thresh_F) |>
                pull(Strategy_F) |>
                unique()
dat_hs$Strategy_F <- factor(dat_hs$Strategy_F, levels=strategyOrder_F)

strategyOrder_M <- dat_hs |> 
                arrange(Min_Energy_Thresh_M, Max_Energy_Thresh_M) |>
                pull(Strategy_M) |>
                unique()
dat_hs$Strategy_M <- factor(dat_hs$Strategy_M, levels=strategyOrder_M)

strategyOrder_Overall <- dat_hs |> 
                      arrange(Min_Energy_Thresh_F, Max_Energy_Thresh_F, Min_Energy_Thresh_M, Max_Energy_Thresh_M) |>
                      pull(Strategy_Overall) |>
                      unique()
dat_hs$Strategy_Overall <- factor(dat_hs$Strategy_Overall, levels=strategyOrder_Overall)

plot_strategy_combos <- ggplot(filter(dat_hs, Example_Category != "Other")) +
                     geom_raster(aes(x=Strategy_F, y=Strategy_M, fill=Success)) +
                     facet_wrap(facets=vars(Example_Category), nrow=1) +
                     scale_fill_gradient(low="white", high="black", limits=c(0, 1)) +
                     xlab("Female strategy") +
                     ylab("Male strategy") +
                     guides(fill=guide_legend(title="Hatch success rate")) +
                     theme_classic() +
                     theme(axis.text.x=element_blank(),
                           axis.text.y=element_text(hjust=1),
                           legend.title=element_text(hjust=0.5),
                           strip.text=element_text(size=12))
ggsave(filename="SICB/PLOT_strategy_combos.png", plot_strategy_combos, width=12, height=6)

# Min vs. max threshold comparisons
hs_min_threshes <- dat_hs |> 
                pivot_longer(cols=c(Min_Energy_Thresh_F, Min_Energy_Thresh_M), names_to="Sex", values_to="Min_Energy_Thresh") |>
                mutate(Sex = map_chr(Sex, ~ tail(str_split_1(., "_"), n=1))) |>
                select(Sex, Min_Energy_Thresh, Foraging_Condition_Mean, Success)
hs_max_threshes <- dat_hs |> 
                pivot_longer(cols=c(Max_Energy_Thresh_F, Max_Energy_Thresh_M), names_to="Sex", values_to="Max_Energy_Thresh") |>
                mutate(Sex = map_chr(Sex, ~ tail(str_split_1(., "_"), n=1))) |>
                select(Sex, Max_Energy_Thresh, Foraging_Condition_Mean, Success)
hs_diff_threshes <- dat_hs |> 
                 mutate(Diff_Energy_Thresh_F = Max_Energy_Thresh_F - Min_Energy_Thresh_F,
                        Diff_Energy_Thresh_M = Max_Energy_Thresh_M - Min_Energy_Thresh_M) |>
                 pivot_longer(cols=c(Diff_Energy_Thresh_F, Diff_Energy_Thresh_M), names_to="Sex", values_to="Diff_Energy_Thresh") |>
                 mutate(Sex = map_chr(Sex, ~ tail(str_split_1(., "_"), n=1))) |>
                 select(Sex, Diff_Energy_Thresh, Foraging_Condition_Mean, Success)

plot_hs_min_threshes <- ggplot(filter(hs_min_threshes, Sex=="F")) +
                     geom_boxplot(aes(x=Min_Energy_Thresh, y=Success, group=Min_Energy_Thresh), position=position_dodge()) +
                     facet_wrap(facets=vars(Foraging_Condition_Mean), labeller=as_labeller(~paste(., "kJ/day")), nrow=1) +
                     scale_x_continuous(breaks=seq(200, 1000, by=200)) +
                     xlab("Hunger threshold (females)") +
                     ylab("Hatch success rate") +
                     ggtitle("Foraging environment") +
                     theme_classic() +
                     theme(plot.title=element_text(hjust=0.5))
ggsave(filename="SICB/PLOT_hs_min_threshes.png", plot_hs_min_threshes, width=12, height=6)

plot_hs_max_threshes <- ggplot(filter(hs_max_threshes, Sex=="F")) +
                     geom_boxplot(aes(x=Max_Energy_Thresh, y=Success, group=Max_Energy_Thresh), position=position_dodge()) +
                     facet_wrap(facets=vars(Foraging_Condition_Mean), labeller=as_labeller(~paste(., "kJ/day")), nrow=1) +
                     scale_x_continuous(breaks=seq(300, 1000, by=200)) +
                     xlab("Satiation threshold (females)") +
                     ylab("Hatch success rate") +
                     ggtitle("Foraging environment") +
                     theme_classic() +
                     theme(plot.title=element_text(hjust=0.5))
ggsave(filename="SICB/PLOT_hs_max_threshes.png", plot_hs_max_threshes, width=12, height=6)

plot_hs_diff_threshes <- ggplot(filter(hs_diff_threshes, Sex=="F")) +
                     geom_boxplot(aes(x=Diff_Energy_Thresh, y=Success, group=Diff_Energy_Thresh), position=position_dodge()) +
                     facet_wrap(facets=vars(Foraging_Condition_Mean), labeller=as_labeller(~paste(., "kJ/day")), nrow=1) +
                     scale_x_continuous(breaks=seq(100, 800, by=200)) +
                     xlab("Difference in thresholds (females)\n[Satiation - Hunger]") +
                     ylab("Hatch success rate") +
                     ggtitle("Foraging environment") +
                     theme_classic() +
                     theme(plot.title=element_text(hjust=0.5))
ggsave(filename="SICB/PLOT_hs_diff_threshes.png", plot_hs_diff_threshes, width=12, height=6)

# Sex comparisons
plot_hs_min_thresh_withsex <- ggplot(hs_min_threshes) +
                           geom_boxplot(aes(x=Min_Energy_Thresh, y=Success, group=interaction(Min_Energy_Thresh, Sex), colour=Sex), 
                                        position=position_dodge(width=75)) +
                           facet_wrap(facets=vars(Foraging_Condition_Mean), labeller=as_labeller(~paste(., "kJ/day")), nrow=1) +
                           scale_x_continuous(breaks=seq(200, 1000, by=200)) +
                           scale_colour_manual(values=c("F"="black", "M"="darkgray"), labels=c("F"="Female", "M"="Male")) +
                           xlab("Hunger threshold") +
                           ylab("Hatch success rate") +
                           ggtitle("Foraging environment") +
                           theme_classic() +
                           theme(plot.title=element_text(hjust=0.5))
ggsave(filename="SICB/PLOT_hs_min_thresh_withsex.png", plot_hs_min_thresh_withsex, width=12, height=6)

sex_comparisons_min_thresh <- hs_min_threshes |>
                           group_by(Sex, Min_Energy_Thresh, Foraging_Condition_Mean) |>
                           summarize(Mean_Success = mean(Success)) |>
                           pivot_wider(id_cols=c(Min_Energy_Thresh, Foraging_Condition_Mean), names_from=Sex, values_from=Mean_Success)
sex_comparisons_max_thresh <- hs_max_threshes |>
                           group_by(Sex, Max_Energy_Thresh, Foraging_Condition_Mean) |>
                           summarize(Mean_Success = mean(Success)) |>
                           pivot_wider(id_cols=c(Max_Energy_Thresh, Foraging_Condition_Mean), names_from=Sex, values_from=Mean_Success)

plot_sex_comparisons_min_thresh <- ggplot(sex_comparisons_min_thresh) +
                                geom_hline(yintercept=0, linewidth=1, colour="black", alpha=0.25) +
                                geom_point(aes(x=Min_Energy_Thresh, y=M-F), colour="gray") +
                                geom_smooth(aes(x=Min_Energy_Thresh, y=M-F), colour="black", se=FALSE) +
                                facet_wrap(facet=vars(Foraging_Condition_Mean), nrow=1, labeller=as_labeller(~paste(., "kJ/day"))) +
                                xlab("Hunger threshold") +
                                ylab("Difference in success (Male - Female)") +
                                ggtitle("Foraging environment") +
                                theme_classic() +
                                theme(plot.title=element_text(hjust=0.5))
ggsave(filename="SICB/PLOT_sex_comparisons_min_thresh.png", plot_sex_comparisons_min_thresh, width=12, height=6)

strategy_variations <- dat_hs |>
                    group_by(Strategy_F, Foraging_Condition_Mean) |>
                    summarize(Mean_Success=mean(Success),
                              SD_Success=sd(Success),
                              Min_Success=min(Success),
                              Max_Success=max(Success)) |>
                    mutate(Success_Range = Max_Success-Min_Success) |>
                    group_by(Foraging_Condition_Mean) |>
                    arrange(Mean_Success) |>
                    mutate(Rank_Success = row_number())

combo_success <- dat_hs |>
              left_join(strategy_variations, by=c("Strategy_F", "Foraging_Condition_Mean"))

plot_combination_success_points <- ggplot(combo_success) +
                                geom_point(aes(x=Mean_Success, y=Success), 
                                           size=0.5, colour="gray") +
                                facet_wrap(facets=vars(Foraging_Condition_Mean), nrow=1,
                                           labeller=as_labeller(~paste(., "kJ/day"))) +
                                scale_x_continuous(limits=c(0, 1), breaks=seq(0.1, 0.9, by=0.2)) +
                                xlab("Overall success of female strategy") +
                                ylab("Success with different partners") +
                                ggtitle("Foraging environment") +
                                theme_classic() +
                                theme(plot.title=element_text(hjust=0.5),
                                      panel.background=element_rect(colour="black"),
                                      panel.spacing.x=unit(0.1, units="in"))
ggsave(filename="SICB/PLOT_combination_success_points.png", width=9, height=3, unit="in")

plot_combination_success_lines <- ggplot(strategy_variations) +
                               geom_segment(data=strategy_variations,
                                        aes(x=Mean_Success, xend=Mean_Success, 
                                            y=Min_Success, yend=Max_Success, group=Strategy_F)) +
                               facet_wrap(facets=vars(Foraging_Condition_Mean), nrow=1,
                                          labeller=as_labeller(~paste(., "kJ/day"))) +
                               scale_x_continuous(limits=c(0, 1), breaks=seq(0.1, 0.9, by=0.2)) +
                               xlab("Overall success of female strategy") +
                               ylab("Success with different partners") +
                               ggtitle("Foraging environment") +
                               theme_classic() +
                               theme(plot.title=element_text(hjust=0.5),
                                     panel.background=element_rect(colour="black"),
                                     panel.spacing.x=unit(0.1, units="in"))
ggsave(filename="SICB/PLOT_combination_success_lines.png", width=9, height=3, unit="in")

overall_success_ranges <- dat_hs |>
                       group_by(Foraging_Condition_Mean) |>
                       summarize(Min_Success = min(Success),
                                 Max_Success = max(Success)) |>
                       mutate(Success_Range = Max_Success - Min_Success)
plot_combination_success_range <- ggplot(strategy_variations) +
                               geom_hline(data=overall_success_ranges,
                                          aes(yintercept=Success_Range),
                                          colour="black", alpha=0.25, linewidth=1.25) +
                               geom_point(aes(x=Mean_Success, y=Success_Range), colour="black") +
                               facet_wrap(facets=vars(Foraging_Condition_Mean), nrow=1,
                                          labeller=as_labeller(~paste(., "kJ/day"))) +
                               scale_x_continuous(limits=c(0, 1), breaks=seq(0.1, 0.9, by=0.2)) +
                               xlab("Overall success of female strategy") +
                               ylab("Success range across partners") +
                               ggtitle("Foraging environment") +
                               theme_classic() +
                               theme(plot.title=element_text(hjust=0.5), 
                                     panel.background=element_rect(colour="black"),
                                     panel.spacing.x=unit(0.1, units="in"))
ggsave(filename="SICB/PLOT_combination_success_range.png", width=9, height=3, unit="in")

# What makes a strategy combination good?
plot_success_neglect <- ggplot(filter(dat_hs, Foraging_Condition_Mean == 160)) +
                     geom_point(aes(x=Success, y=Total_Neglect_Success), colour="gray") +
                     geom_smooth(aes(x=Success, y=Total_Neglect_Success), colour="black", 
                                 method="loess", linewidth = 1, se=FALSE) +
                     scale_x_continuous(breaks=seq(0, 1, by=0.25),
                                        labels=c("0", "0.25", "0.50", "0.75", "1")) +                                 
                     xlab("Hatch success rate") +
                     ylab("Total egg neglect") +
                     theme_classic()
plot_success_energy <- ggplot(filter(dat_hs, Foraging_Condition_Mean == 160)) +
                    geom_point(aes(x=Success, y=Mean_Parent_Energy_Success), colour="gray") +
                    geom_smooth(aes(x=Success, y=Mean_Parent_Energy_Success), colour="black", 
                                method="loess", linewidth = 1, se=FALSE) +
                    scale_x_continuous(breaks=seq(0, 1, by=0.25),
                                       labels=c("0", "0.25", "0.50", "0.75", "1")) +                                 
                    xlab("Hatch success rate") +
                    ylab("Mean parent energy") +
                    theme_classic()
plot_success_entropy <- ggplot(filter(dat_hs, Foraging_Condition_Mean == 160)) +
                     geom_point(aes(x=Success, y=Scaled_Entropy_Success), colour="gray") +
                     geom_smooth(aes(x=Success, y=Scaled_Entropy_Success), colour="black", 
                                 method="loess", linewidth = 1, se=FALSE) +
                     scale_x_continuous(breaks=seq(0, 1, by=0.25),
                                        labels=c("0", "0.25", "0.50", "0.75", "1")) +                                 
                     xlab("Hatch success rate") +
                     ylab("Schedule entropy") +
                     theme_classic()
plots_success <- plot_success_neglect + plot_success_energy + plot_success_entropy +
              plot_layout(axes="collect")
ggsave(filename="SICB/PLOT_success_metrics.png", width=9, height=3, unit="in")

plot_entropy_neglect_comparison <- ggplot(filter(dat_hs, Foraging_Condition_Mean %in% 140:160)) +
                                geom_point(aes(y=Total_Neglect_Success, 
                                               x=Scaled_Entropy_Success, 
                                               colour=Success)) +
                                facet_wrap(facets=vars(Foraging_Condition_Mean), labeller=as_labeller(~paste(., "kJ/day"))) +
                                scale_x_continuous(limits=c(0.6, 1)) +
                                scale_y_continuous(limits=c(0, 15)) +
                                scale_colour_gradient(low="#eca8a8", high="black") +
                                guides(colour=guide_legend(title="Hatch success rate")) +
                                xlab("Schedule entropy\n(successful seasons only)") +
                                ylab("Total egg neglect\n(successful seasons only)") +
                                ggtitle("Foraging environment") +
                                theme_classic() +
                                theme(plot.title=element_text(hjust=0.5))
ggsave(filename="SICB/PLOT_entropy_neglect_comparisons.png", width=8, height=5, unit="in")
                                
# Changing environments
best_strategies <- dat_hs |>
                filter(Foraging_Condition_Mean == 160 & Foraging_Condition_Kick==0) |>
                slice_max(prop=0.10, order_by=Success) |>
                pull(Strategy_Overall)

plot_environmental_condition_simple <- ggplot(filter(dat_hs, Foraging_Condition_Kick==0)) +
                                    geom_line(aes(x=Foraging_Condition_Mean, y=Success, group=Strategy_Overall), 
                                              colour="lightgray", alpha=0.5) +
                                    stat_smooth(aes(x=Foraging_Condition_Mean, y=Success, colour="All"), formula = "y ~ x", method = "glm", 
                                                method.args = list(family="quasibinomial"), se = FALSE) +
                                    geom_vline(xintercept=160, colour="black", linetype="dashed") + 
                                    scale_colour_manual(values=c("All"="black", "Best"="blue"),
                                                        labels=c("All"="All", "Best"="Top 10")) +
                                    guides(colour=guide_legend(title="Strategies")) +
                                    xlab("Foraging environment (kJ/day)") +
                                    ylab("Hatch success rate") +
                                    theme_classic() +
                                    theme(legend.key.width=rel(1.5))
ggsave(filename="SICB/PLOT_environmental_condition_simple.png", plot_environmental_condition_simple, width=6, height=5)

logFit_all <- glm(Success ~ Foraging_Condition_Mean, data=filter(dat_hs, Foraging_Condition_Kick==0), family="quasibinomial")
switchPoint_all <- -1 * coef(logFit_all)["(Intercept)"] / coef(logFit_all)["Foraging_Condition_Mean"]
plot_environmental_condition <- ggplot(filter(dat_hs, Foraging_Condition_Kick==0)) +
                             geom_line(aes(x=Foraging_Condition_Mean, y=Success, group=Strategy_Overall), 
                                       colour="lightgray", alpha=0.5) +
                             stat_smooth(aes(x=Foraging_Condition_Mean, y=Success, colour="All"), formula = "y ~ x", method = "glm", 
                                         method.args = list(family="quasibinomial"), se = FALSE) +
                             geom_vline(xintercept=switchPoint_all, colour="black", alpha=0.5, linewidth=1.75) + 
                             geom_vline(xintercept=160, colour="black", linetype="dashed") + 
                             scale_colour_manual(values=c("All"="black", "Best"="blue"),
                                                 labels=c("All"="All", "Best"="Top 10")) +
                             guides(colour=guide_legend(title="Strategies")) +
                             xlab("Foraging environment (kJ/day)") +
                             ylab("Hatch success rate") +
                             theme_classic() +
                             theme(legend.key.width=rel(1.5))
ggsave(filename="SICB/PLOT_environmental_condition.png", plot_environmental_condition, width=6, height=5)

logFit_best <- glm(Success ~ Foraging_Condition_Mean, data=filter(dat_hs, Foraging_Condition_Kick==0, Strategy_Overall %in% best_strategies), family="quasibinomial")
switchPoint_best <- -1 * coef(logFit_best)["(Intercept)"] / coef(logFit_best)["Foraging_Condition_Mean"]
plot_environmental_condition_withbest <- ggplot(filter(dat_hs, Foraging_Condition_Kick == 0)) +
                                      geom_line(aes(x=Foraging_Condition_Mean, y=Success, group=Strategy_Overall), 
                                                colour="lightgray", alpha=0.5) +
                                      stat_smooth(aes(x=Foraging_Condition_Mean, y=Success, colour="All"), formula = "y ~ x", method = "glm", 
                                                  method.args = list(family="quasibinomial"), se = FALSE) +
                                      stat_smooth(data=filter(dat_hs, Foraging_Condition_Kick==0, Strategy_Overall %in% best_strategies),
                                                  aes(x=Foraging_Condition_Mean, y=Success, colour="Best"), formula = "y ~ x", method = "glm", 
                                                  method.args = list(family="quasibinomial"), se = FALSE) +
                                      geom_vline(xintercept=switchPoint_all, colour="black", alpha=0.5, linewidth=1.75) + 
                                      geom_vline(xintercept=switchPoint_best, colour="blue", alpha=0.5, linewidth=1.75) + 
                                      geom_vline(xintercept=160, colour="black", linetype="dashed") + 
                                      scale_colour_manual(values=c("All"="black", "Best"="blue"),
                                                          labels=c("All"="All", "Best"="Top 10")) +
                                      guides(colour=guide_legend(title="Strategies")) +
                                      xlab("Foraging environment (kJ/day)") +
                                      ylab("Hatch success rate") +
                                      theme_classic() +
                                      theme(legend.key.width=rel(1.5))
ggsave(filename="SICB/PLOT_environmental_condition_withbest.png", plot_environmental_condition_withbest, width=6, height=5)

logFit_all_perturbed <- glm(Success ~ Foraging_Condition_Mean, data=filter(dat_hs, Foraging_Condition_Kick==1), family="quasibinomial")
switchPoint_all_perturbed <- -1 * coef(logFit_all_perturbed)["(Intercept)"] / coef(logFit_all_perturbed)["Foraging_Condition_Mean"]
logFit_best_perturbed <- glm(Success ~ Foraging_Condition_Mean, data=filter(dat_hs, Foraging_Condition_Kick==1, Strategy_Overall %in% best_strategies), family="quasibinomial")
switchPoint_best_perturbed <- -1 * coef(logFit_best_perturbed)["(Intercept)"] / coef(logFit_best_perturbed)["Foraging_Condition_Mean"]
plot_environmental_condition_perturbed <- ggplot(filter(dat_hs, Foraging_Condition_Kick==0)) +
                                       geom_line(data=filter(dat_hs, Foraging_Condition_Kick==1),
                                                 aes(x=Foraging_Condition_Mean, y=Success, group=Strategy_Overall), 
                                                 colour="lightgray", alpha=0.25) +
                                       stat_smooth(data=filter(dat_hs, Foraging_Condition_Kick==1),
                                                   aes(x=Foraging_Condition_Mean, y=Success, colour="All", linetype="Perturbed"), 
                                                   formula = "y ~ x", method = "glm", 
                                                   method.args = list(family="quasibinomial"), se = FALSE) +
                                       stat_smooth(data=filter(dat_hs, Foraging_Condition_Kick==1, Strategy_Overall %in% best_strategies),
                                                   aes(x=Foraging_Condition_Mean, y=Success, colour="Best", linetype="Perturbed"), 
                                                   formula = "y ~ x", method = "glm", 
                                                   method.args = list(family="quasibinomial"), se = FALSE) +
                                       geom_vline(xintercept=switchPoint_all, colour="black", alpha=0.5, linewidth=1.75) + 
                                       geom_vline(xintercept=switchPoint_best, colour="blue", alpha=0.5, linewidth=1.75) + 
                                       geom_vline(xintercept=switchPoint_all_perturbed, colour="black", alpha=0.5, linewidth=1.2, linetype="dashed") + 
                                       geom_vline(xintercept=switchPoint_best_perturbed, colour="blue", alpha=0.5, linewidth=1.2, linetype="dashed") + 
                                       scale_colour_manual(values=c("All"="black", "Best"="blue"),
                                                           labels=c("All"="All", "Best"="Top 10")) +
                                       scale_linetype_manual(values=c("Regular"="solid", "Perturbed"="dashed"),
                                                             limits=c("Perturbed"),
                                                             labels=c("Environment\nperturbed")) +
                                       guides(colour=guide_legend(title="Strategies"), 
                                              linetype=guide_legend(title="",
                                                                    override.aes=list(colour=c("black")))) +
                                       xlab("Foraging environment (kJ/day)") +
                                       ylab("Hatch success rate") +
                                       theme_classic() +
                                       theme(legend.key.width=rel(1.5))
                                      
ggsave(filename="SICB/PLOT_environmental_condition_perturbed.png", plot_environmental_condition_perturbed, width=6, height=5)

# Changing outcomes as the envioronment declines
dat_hs_long <- dat_hs |>
            pivot_longer(cols=c(Fail_Dead_Parent, Fail_Egg_Neglect_Max, Fail_Egg_Neglect_Cumulative, Success),
                         names_to="Outcome", values_to="Rate")

plot_outcomes_simple <- ggplot(filter(dat_hs_long, Foraging_Condition_Kick == 0, Outcome=="Success")) +
              stat_smooth(geom="line",
                          aes(x=Foraging_Condition_Mean, y=Rate, colour=Outcome), 
                          se=FALSE, method="loess", linewidth=1.2) +
              scale_colour_manual(values=c("Success"="black",
                                           "Fail_Egg_Neglect_Max"="#3f3fd6",
                                           "Fail_Egg_Neglect_Cumulative"="#69c2d8",
                                           "Fail_Dead_Parent"="#a82a2a"),
                                  limits=c("Success", 
                                           "Fail_Egg_Neglect_Max", 
                                           "Fail_Egg_Neglect_Cumulative",
                                           "Fail_Dead_Parent"),
                                   labels=c("Success"="Hatched",
                                            "Fail_Egg_Neglect_Max"="Fail - Continuous neglect",
                                            "Fail_Egg_Neglect_Cumulative"="Fail - Overall neglect",
                                            "Fail_Dead_Parent"="Fail - Dead parent")) +
              guides(colour=guide_legend(title="Outcome")) +
              ylab("Outcome rate") +
              xlab("Foraging environment (kJ/day)") +
              theme_classic()
ggsave(filename="SICB/plot_environmental_condition_outcomes_simple.png", plot_outcomes_simple, width=6, height=4)

plot_outcomes <- ggplot(filter(dat_hs_long, Foraging_Condition_Kick == 0)) +
              stat_smooth(geom="line",
                          aes(x=Foraging_Condition_Mean, y=Rate, colour=Outcome), 
                          se=FALSE, method="loess", linewidth=1.2) +
              scale_colour_manual(values=c("Success"="black",
                                           "Fail_Egg_Neglect_Max"="#3f3fd6",
                                           "Fail_Egg_Neglect_Cumulative"="#69c2d8",
                                           "Fail_Dead_Parent"="#a82a2a"),
                                  limits=c("Success", 
                                           "Fail_Egg_Neglect_Max", 
                                           "Fail_Egg_Neglect_Cumulative",
                                           "Fail_Dead_Parent"),
                                   labels=c("Success"="Hatched",
                                            "Fail_Egg_Neglect_Max"="Fail - Continuous neglect",
                                            "Fail_Egg_Neglect_Cumulative"="Fail - Overall neglect",
                                            "Fail_Dead_Parent"="Fail - Dead parent")) +
              guides(colour=guide_legend(title="Outcome")) +
              ylab("Outcome rate") +
              xlab("Foraging environment (kJ/day)") +
              theme_classic()
ggsave(filename="SICB/plot_environmental_condition_outcomes.png", plot_outcomes, width=6, height=4)

example_strings_continuous_neglect <- dat_example_strategy |>
                                   mutate(Example_Category = map2_chr(Foraging_Condition_Mean, Foraging_Condition_Kick, assignExampleCategory)) |>
                                   filter(Example_Category == exampleCategories[1] & Hatch_Result == "hatched" |
                                          Example_Category == exampleCategories[2] & Hatch_Result == "egg cold fail",
                                          Season_Length < 60) |>
                                   select(Iteration, Example_Category, Hatch_Result, Season_History) |>
                                   mutate(Example_Category = factor(Example_Category, levels=exampleCategories)) |>
                                   group_by(Example_Category) |>
                                   slice_sample(n=2) |>
                                   separate(Season_History, into=as.character(0:61), sep="") |>
                                   pivot_longer(cols=-c(Iteration, Hatch_Result, Example_Category), names_to="Day", values_to="State") |>
                                   filter(Day != 0) |>
                                   mutate(Day = as.numeric(Day)) |>
                                   filter(!is.na(State)) |>
                                   mutate(Iteration = paste0("I", Iteration))

plot_neglect_examples <- ggplot(example_strings_continuous_neglect) +
                      geom_raster(aes(x=Day, y=Iteration, fill=State, alpha=Hatch_Result=="hatched")) +
                      scale_fill_manual(values=c(state_colors), na.value="white", 
                                        labels=c("F"="Female", "M"="Male", "N"="Neglect")) +
                      facet_wrap(facets=vars(Example_Category), nrow=2, scales="free_y") +
                      scale_alpha_manual(values=c("TRUE"=1, "FALSE"=0.5)) +
                      guides(alpha="none") +
                      ylab("Outcome") +
                      theme_classic() +
                      theme(axis.title.y=element_blank(),
                            axis.text.y=element_blank())
ggsave(filename="SICB/PLOT_neglect_examples.png", plot_neglect_examples, width=5, height=3)

# Best strategy ranks
strategy_ranks <- dat_hs |>
               group_by(Foraging_Condition_Mean) |>
               arrange(-Success) |>
               mutate(Rank = row_number()) |>
               select(Foraging_Condition_Mean, Strategy_Overall, Success, Rank) |>
               arrange(Foraging_Condition_Mean, Rank)

plot_strategy_ranks <- ggplot(strategy_ranks) +
    geom_line(aes(x=Foraging_Condition_Mean, y=Rank, group=Strategy_Overall), alpha=0.5) +
    scale_y_continuous(limits=c(1, 100)) +
    xlab("Foraging environment (kJ/day)") +
    ylab("Strategy rank (lower = better, top 100 only)") +
    theme_classic()
ggsave(filename="SICB/PLOT_strategy_ranks.png", plot_strategy_ranks, width=5, height=5)

# Generous strategies in good environments expose parents to mortality risks in bad environments
dat_hs_relation <- dat_hs |>
                filter(Foraging_Condition_Kick==0, Foraging_Condition_Mean==160 | Foraging_Condition_Mean==140) |>
                pivot_wider(id_cols=c(Strategy_Overall), names_from=Foraging_Condition_Mean, values_from=c(Success, Fail_Dead_Parent, Fail_Egg_Neglect_Max))

plot_success_death_relation <- ggplot(dat_hs_relation) +
                            geom_point(aes(x=Success_160, y=Fail_Dead_Parent_140), colour="gray") +
                            geom_smooth(aes(x=Success_160, y=Fail_Dead_Parent_140),
                                        se=FALSE, colour="black", method="loess") +
                            scale_y_continuous(limits=c(0, 0.2)) +
                            xlab("Hatch success rate\nRegular environment (160 kJ/day)") +
                            ylab("Parent death rate\nDegraded environment (140 kJ/day)") +
                            theme_classic()
ggsave(filename="SICB/PLOT_success_death_relation.png", plot_success_death_relation, width=5, height=5)

# How does entropy change as environment degrades
plot_entropy_environment <- ggplot(dat_hs) +
                         geom_line(aes(x=Foraging_Condition_Mean, y=Scaled_Entropy_Success, group=Strategy_Overall), colour="gray") +
                         geom_smooth(aes(x=Foraging_Condition_Mean, y=Scaled_Entropy_Success), colour="black", method="loess", se=FALSE) +
                         xlab("Foragign environment (kJ/day)") +
                         ylab("Scaled entropy\n(successful seasons only)") +
                         theme_classic()
ggsave(filename="SICB/PLOT_entropy_environment.png", plot_entropy_environment, width=5, height=5)


plot_strategy_entropy <- ggplot(filter(dat_hs, Example_Category != "Other")) +
                      geom_raster(aes(x=Strategy_F, y=Strategy_M, fill=Scaled_Entropy_Success)) +
                      facet_wrap(facets=vars(Example_Category), nrow=1) +
                      scale_fill_gradient(low="white", high="black", limits=c(0, 1), na.value="#eb6b6b") +
                      xlab("Female strategy") +
                      ylab("Male strategy") +
                      guides(fill=guide_legend(title="Schedule entropy\n(successful seasons only)")) +
                      theme_classic() +
                      theme(axis.text.x=element_blank(),
                            axis.text.y=element_text(hjust=1),
                            legend.title=element_text(hjust=0.5),
                            strip.text=element_text(size=12))
ggsave(filename="SICB/PLOT_strategy_entropy.png", plot_strategy_entropy, width=12, height=6)

