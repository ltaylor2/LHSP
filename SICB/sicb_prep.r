# Logistics
library(tidyverse)
library(patchwork)

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
exampleCategories <- c("Regular environment\n(150 kJ/day)", 
                       "Degraded environment\n(140 kJ/day)")
assignExampleCategory <- function(fMean, fKick=0) {
    if (fMean == 150 & fKick == 0) { return (exampleCategories[1]) }
    if (fMean == 140 & fKick == 0) { return (exampleCategories[2]) }
    return("Other")
}

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

example_strings_cut <- dat_example_strategy |>
                    filter(Foraging_Condition_Mean==140) |>
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
                        scale_y_discrete(limits=c("I452", "I0", "I497", "I37"),
                                         labels=c("I452"="Hatched", "I0"="Overall neglect - Fail", 
                                                  "I497"="Continuous neglect - Fail", "I37"="Dead parent - Fail")) +
                        scale_alpha_manual(values=c("TRUE"=1, "FALSE"=0.25)) +
                        guides(alpha="none") +
                        ylab("Outcome") +
                        theme_classic()
ggsave(filename="SICB/PLOT_season_examples.png", plot_iteration_examples, width=5, height=2)

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

# Variation in strategies
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
plot_success_neglect <- ggplot(filter(dat_hs, Foraging_Condition_Mean == 150)) +
                     geom_point(aes(x=Success, y=Total_Neglect_Success), colour="gray") +
                     geom_smooth(aes(x=Success, y=Total_Neglect_Success), colour="black", 
                                 method="loess", linewidth = 1, se=FALSE) +
                     scale_x_continuous(breaks=seq(0, 1, by=0.25),
                                        labels=c("0", "0.25", "0.50", "0.75", "1")) +                                 
                     xlab("Hatch success rate") +
                     ylab("Total egg neglect (successful only)") +
                     theme_classic()
plot_success_energy <- ggplot(filter(dat_hs, Foraging_Condition_Mean == 150)) +
                    geom_point(aes(x=Success, y=Mean_Parent_Energy_Success), colour="gray") +
                    geom_smooth(aes(x=Success, y=Mean_Parent_Energy_Success), colour="black", 
                                method="loess", linewidth = 1, se=FALSE) +
                    scale_x_continuous(breaks=seq(0, 1, by=0.25),
                                       labels=c("0", "0.25", "0.50", "0.75", "1")) +                                 
                    xlab("Hatch success rate") +
                    ylab("Mean parent energy (successful only)") +
                    theme_classic()
plot_success_entropy <- ggplot(filter(dat_hs, Foraging_Condition_Mean == 150)) +
                     geom_point(aes(x=Success, y=Scaled_Entropy_Success), colour="gray") +
                     geom_smooth(aes(x=Success, y=Scaled_Entropy_Success), colour="black", 
                                 method="loess", linewidth = 1, se=FALSE) +
                     scale_x_continuous(breaks=seq(0, 1, by=0.25),
                                        labels=c("0", "0.25", "0.50", "0.75", "1")) +                                 
                     xlab("Hatch success rate") +
                     ylab("Schedule entropy (successful only)") +
                     theme_classic()
plots_success <- plot_success_neglect + plot_success_energy + plot_success_entropy +
              plot_layout(axes="collect")
ggsave(filename="SICB/PLOT_success_metrics.png", width=9, height=3, unit="in")

# TODO HERE FINISH
ggplot(filter(dat_hs, Foraging_Condition_Mean==150)) +
    geom_point(aes(y=Scaled_Entropy_Success, x=Total_Neglect_Success, colour=Success))
# Changing environments
best_strategies <- dat_hs |>
                filter(Foraging_Condition_Mean == 150 & Foraging_Condition_Kick==0) |>
                slice_max(prop=0.10, order_by=Success) |>
                pull(Strategy_Overall)

logFit_all <- glm(Success ~ Foraging_Condition_Mean, data=filter(dat_hs, Foraging_Condition_Kick==0), family="quasibinomial")
switchPoint_all <- -1 * coef(logFit_all)["(Intercept)"] / coef(logFit_all)["Foraging_Condition_Mean"]
plot_environmental_condition <- ggplot(filter(dat_hs, Foraging_Condition_Kick==0)) +
                             geom_line(aes(x=Foraging_Condition_Mean, y=Success, group=Strategy_Overall), 
                                       colour="lightgray", alpha=0.5) +
                             stat_smooth(aes(x=Foraging_Condition_Mean, y=Success, colour="All"), formula = "y ~ x", method = "glm", 
                                         method.args = list(family="quasibinomial"), se = FALSE) +
                             geom_vline(xintercept=switchPoint_all, colour="black", alpha=0.5, linewidth=1.75) + 
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

dat_hs_long <- dat_hs |>
            pivot_longer(cols=c(Fail_Dead_Parent, Fail_Egg_Neglect_Max, Fail_Egg_Neglect_Cumulative, Success),
                         names_to="Outcome", values_to="Rate")

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

plot_outcomes_perturbed <- ggplot(dat_hs_long) +
                        stat_smooth(geom="line",
                                    aes(x=Foraging_Condition_Mean, y=Rate, colour=Outcome), 
                                    se=FALSE, method="loess", linewidth=1.2) +
                        facet_wrap(facets=vars(Foraging_Condition_Kick)) +
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
ggsave(filename="SICB/plot_environmental_condition_outcomes_perturbed.png", plot_outcomes_perturbed, width=6, height=4)

plot_outcomes_best <- ggplot(filter(dat_hs_long, Foraging_Condition_Kick==0)) +
                   stat_smooth(geom="line",
                               aes(x=Foraging_Condition_Mean, y=Rate, colour=Outcome, alpha="All"), 
                               se=FALSE, method="loess", linewidth=1.2) +
                   stat_smooth(geom="line",
                               data=filter(dat_hs_long, Foraging_Condition_Kick==0, Strategy_Overall %in% best_strategies),
                               aes(x=Foraging_Condition_Mean, y=Rate, colour=Outcome, alpha="Best"), 
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
                   scale_alpha_manual(values=c("Best"=1, "All"=0.15)) +
                   guides(colour=guide_legend(title="Outcome"), alpha="none") +
                   ylab("Outcome rate") +
                   xlab("Foraging environment (kJ/day)") +
                   theme_classic()
       
ggsave(filename="SICB/plot_environmental_condition_outcomes_best.png", plot_outcomes_best, width=6, height=4)

entropies <- dat |>
          filter(Foraging_Condition_Kick==0, Foraging_Condition_Mean==150) |>
          mutate(Weighted_Entropy = Scaled_Entropy * N) |>
          group_by(Strategy_Overall) |> 
          summarize(Weighted_Entropy = sum(Weighted_Entropy) / 1000)

dat_hs_relation <- dat_hs |>
                filter(Foraging_Condition_Kick==0, Foraging_Condition_Mean==150 | Foraging_Condition_Mean==140) |>
                pivot_wider(id_cols=c(Strategy_Overall), names_from=Foraging_Condition_Mean, values_from=c(Success, Fail_Dead_Parent, Fail_Egg_Neglect_Max)) |>
                left_join(select(filter(dat_hs, Foraging_Condition_Kick==1, Foraging_Condition_Mean==150), Strategy_Overall, Success_Perturbed=Success, Fail_Dead_Parent_Perturbed=Fail_Dead_Parent), by="Strategy_Overall") |>
                left_join(entropies, by="Strategy_Overall") |>
                mutate(Degraded_Penalty = Success_150 - Success_140,
                       Perturbed_Penalty = Success_150 - Success_Perturbed)

plot_success_death_relation <- ggplot(dat_hs_relation) +
                            geom_point(aes(x=Success_150, y=Fail_Dead_Parent_150), colour="gray") +
                            geom_smooth(aes(x=Success_150, y=Fail_Dead_Parent_150),
                                        se=FALSE, colour="black") +
                            scale_y_continuous(limits=c(0, 0.2)) +
                            xlab("Hatch success rate\nRegular environment (150 kJ/day)") +
                            ylab("Parent death rate\nRegular environment (150 kJ/day)") +
                            theme_classic()

plot_success_death_relation_degraded <- ggplot(dat_hs_relation) +
                                     geom_point(aes(x=Success_150, y=Fail_Dead_Parent_140), colour="gray") +
                                     geom_smooth(aes(x=Success_150, y=Fail_Dead_Parent_140),
                                                 se=FALSE, colour="black") +
                                     scale_y_continuous(limits=c(0, 0.2)) +
                                     xlab("Hatch success rate\nRegular environment (150 kJ/day)") +
                                     ylab("Parent death rate\nDegraded environment (140 kJ/day)") +
                                     theme_classic()

plots_success_death_relation <- plot_success_death_relation + plot_success_death_relation_degraded +
                             plot_layout(axes="collect", guides="collect")

ggsave(filename="SICB/plot_success_death_relation.png", plots_success_death_relation, width=10, height=4)

# Hatch success penalities in degraded and perturbed environments  
plot_success_degraded <- ggplot(dat_hs_relation) +
                      geom_abline(intercept=0, slope=1, colour="gray") +
                      geom_point(aes(x=Success_150, y=Success_140), colour="gray") +
                      geom_smooth(aes(x=Success_150, y=Success_140), colour="black", se=FALSE) +
                      scale_x_continuous(limits=c(0, 1)) +
                      scale_y_continuous(limits=c(0, 1)) +
                      xlab("Success in regular environment\n(150 kJ/day)") +
                      ylab("Success in degraded environment\n(140 kJ/day)") +
                      theme_classic()
plot_success_perturbed <- ggplot(dat_hs_relation) +
                       geom_abline(intercept=0, slope=1, colour="gray") +
                       geom_point(aes(x=Success_150, y=Success_Perturbed), colour="gray") +
                       geom_smooth(aes(x=Success_150, y=Success_Perturbed), colour="black", se=FALSE) +
                       scale_x_continuous(limits=c(0, 1)) +
                       scale_y_continuous(limits=c(0, 1)) +
                       xlab("Success in regular environment\n(150 kJ/day)") +
                       ylab("Success in perturbed environment\n(150->0 kJ/day, days 20-22)") +
                       theme_classic()
plots_success_degraded_perturbed <- plot_success_degraded + plot_success_perturbed +
                                 plot_layout(axes="collect")
ggsave(filename="SICB/plot_success_degraded_perturbed.png", plots_success_degraded_perturbed, width=7, height=4)

plot_success_penalty_degraded <- ggplot(dat_hs_relation) +
                              geom_point(aes(x=Success_150, y=Degraded_Penalty), colour="gray") +
                              geom_smooth(aes(x=Success_150, y=Degraded_Penalty), colour="black", se=FALSE) +
                              scale_x_continuous(limits=c(0, 1)) +
                              scale_y_continuous(limits=c(0, 1)) +
                              xlab("Success in regular environment\n(150 kJ/day)") +
                              ylab("Penalty from degraded environment") +
                              theme_classic()
plot_success_penalty_perturbed <- ggplot(dat_hs_relation) +
                              geom_point(aes(x=Success_150, y=Perturbed_Penalty), colour="gray") +
                              geom_smooth(aes(x=Success_150, y=Perturbed_Penalty), colour="black", se=FALSE) +
                              scale_x_continuous(limits=c(0, 1)) +
                              scale_y_continuous(limits=c(0, 1)) +
                              xlab("Success in regular environment\n(150 kJ/day)") +
                              ylab("Penalty from perturbed environment") +
                              theme_classic()
plots_success_penalty_degraded_perturbed <- plot_success_penalty_degraded + plot_success_penalty_perturbed +
                                         plot_layout(axes="collect")
ggsave(filename="SICB/plots_success_penalty_degraded_perturbed.png", plots_success_penalty_degraded_perturbed, width=7, height=4)

plot_penalities <- ggplot(dat_hs_relation) +
                geom_point(aes(x=Degraded_Penalty, y=Perturbed_Penalty, size=Success_150), 
                           colour="black", fill="lightgray", alpha=0.25, shape=21) +
                geom_smooth(aes(x=Degraded_Penalty, y=Perturbed_Penalty), colour="black", se=FALSE,
                            method="lm") +
                scale_x_continuous(limits=c(0, 0.75)) +
                scale_y_continuous(limits=c(0, 0.60)) +
                scale_size_continuous(limits=c(0, 1), breaks=seq(0, 1, by=0.25)) +
                guides(size=guide_legend(title="Success in\nregular environment",
                                         override.aes=list(alpha=0.5))) +
                xlab("Degraded penalty") +
                ylab("Perturbed penalty") +
                theme_classic()
ggsave(filename="SICB/plot_penalties.png", plot_penalities, width=7, height=4)

plot_penalities_top50 <- ggplot(filter(dat_hs_relation, Success_150>0.5)) +
                      geom_point(aes(x=Degraded_Penalty, y=Perturbed_Penalty, size=Success_150), 
                                 colour="black", fill="lightgray", alpha=0.25, shape=21) +
                      geom_smooth(aes(x=Degraded_Penalty, y=Perturbed_Penalty), colour="black", se=FALSE,
                                  method="lm") +
                      scale_x_continuous(limits=c(0, 0.75)) +
                      scale_y_continuous(limits=c(0, 0.60)) +
                      scale_size_continuous(limits=c(0, 1), breaks=seq(0.50, 1, by=0.25)) +
                      guides(size=guide_legend(title="Success in\nregular environment",
                                               override.aes=list(alpha=0.5))) +
                      xlab("Degraded penalty") +
                      ylab("Perturbed penalty") +
                      theme_classic()
ggsave(filename="SICB/plot_penalties_top50.png", plot_penalities_top50, width=7, height=4)

penalty_lm <- lm(Perturbed_Penalty ~ Degraded_Penalty, data=filter(dat_hs_relation, Success_150>0.5))
penalty_residuals <- filter(dat_hs_relation, Success_150>0.5) |>
                  select(Strategy_Overall, Success_150, Degraded_Penalty, Perturbed_Penalty, Success_150_Scaled_Entropy) |>
                  mutate(Perturbed_Predicted = predict(penalty_lm)) |>
                  mutate(Perturbed_Penalty_Residual = Perturbed_Penalty - Perturbed_Predicted)
plot_penalities_residualLines <- ggplot(penalty_residuals) +
                              geom_point(aes(x=Degraded_Penalty, y=Perturbed_Penalty, size=Success_150), 
                                         colour="black", fill="lightgray", alpha=0.25, shape=21) +
                              geom_smooth(aes(x=Degraded_Penalty, y=Perturbed_Penalty), colour="black", se=FALSE,
                                          method="lm") +
                              geom_segment(aes(x=Degraded_Penalty, xend=Degraded_Penalty, y=Perturbed_Penalty, yend=Perturbed_Predicted),
                                           colour="orange", alpha=0.5) +
                              scale_x_continuous(limits=c(0, 0.75)) +
                              scale_y_continuous(limits=c(0, 0.60)) +
                              scale_size_continuous(limits=c(0, 1), breaks=seq(0.50, 1, by=0.25)) +
                              guides(size=guide_legend(title="Success in\nregular environment",
                                                       override.aes=list(alpha=0.5))) +
                              xlab("Degraded penalty") +
                              ylab("Perturbed penalty") +
                              theme_classic()
ggsave(filename="SICB/plot_penalties_residualLines.png", plot_penalities_residualLines, width=7, height=4)

plot_penalties_residualPoints <- ggplot(penalty_residuals) +
                              geom_hline(yintercept=0, colour="black", alpha=0.5, linewidth=1.75) + 
                              geom_point(aes(x=Success_150, y=Perturbed_Penalty_Residual), 
                                         colour="black", fill="orange", alpha=0.25, shape=21) +
                              geom_smooth(aes(x=Success_150, y=Perturbed_Penalty_Residual), colour="black", se=FALSE) +
                              xlab("Success in regular environment (150 kJ/day)") +
                              ylab("Residual of perturbed penalty") +
                              theme_classic()
ggsave(filename="SICB/plot_penalties_residualPoints.png", plot_penalties_residualPoints, width=5, height=4)

# Entropies to explain perturbed residual
plot_penalties_entropies <- ggplot(penalty_residuals) +
                         geom_point(aes(x=Success_150_Scaled_Entropy, y=Perturbed_Penalty_Residual), 
                                    colour="black", fill="orange", alpha=0.5, shape=21) +
                         geom_smooth(aes(x=Success_150_Scaled_Entropy, y=Perturbed_Penalty_Residual), colour="black", se=FALSE) +
                         xlab("Schedule entropy in regular environment") +
                         ylab("Residual of perturbed penalty") +
                         theme_classic()
ggsave(filename="SICB/plot_penalties_residualPoints_entropies.png", plot_penalties_entropies, width=5, height=4)

plot_degraded_perturbed_penalties <- ggplot(dat_hs_relation) +
                                  geom_point(aes(x=Success_150-Success_Perturbed, y=Success_150-Success_140, size=Success_150), 
                                             colour="black", fill="gray", alpha=0.3, shape=21) +
                                  geom_smooth(aes(x=Success_150-Success_Perturbed, y=Success_150-Success_140), 
                                              method="lm", colour="black", se=FALSE) +
                                  guides(size=guide_legend(title="Success in\nregular environment")) +
                                  xlab("Penalty from degraded environment") +
                                  ylab("Penalty from perturbed environment") +
                                  theme_classic()
ggsave(filename="SICB/plot_degraded_perturbed_penalties.png", plot_degraded_perturbed_penalties, width=7, height=5)


# HERE -- QUANTIFYING SENSITIVITIES, CORRELATING SENSITIVITIES, ASKING IF ENTROPY EXPLAINS ONE AND NOT THE OTHER
# Sensitivty to degrading and perturbing

calcSensitivityDegrading <- function(s, segment=FALSE) {
    strat <- dat_hs |>
          filter(Strategy_Overall == s, Foraging_Condition_Kick==0)
    logFit <- glm(Success ~ Foraging_Condition_Mean, data=strat, family="quasibinomial")
    inflectionPoint <- -1 * logFit$coefficients["(Intercept)"] / logFit$coefficients["Foraging_Condition_Mean"]
    tangentPoint <- predict(logFit, data.frame(Foraging_Condition_Mean = inflectionPoint), type = "response")
    maxSlope <- logFit$coefficients["Foraging_Condition_Mean"]/4
    markSegment <- tibble(x=(inflectionPoint-2):(inflectionPoint+2)) |>
                mutate(y = tangentPoint + maxSlope * (x - inflectionPoint))
    if (segment) { return(markSegment) }
    return(maxSlope)
}

calcSensitivityPerturbing <- function(s) {
    dat_hs |>
          filter(Strategy_Overall == s) |>
          select(Strategy_Overall, Foraging_Condition_Mean, Foraging_Condition_Kick, Success) |>
          mutate(Foraging_Condition_Kick=paste0("Kick_", Foraging_Condition_Kick)) |>
          pivot_wider(id_cols=c(Strategy_Overall, Foraging_Condition_Mean), names_from=Foraging_Condition_Kick, values_from=Success) |>
          mutate(Effect_Kick = Kick_0 - Kick_1) |>
          pull(Effect_Kick) |>
          max()
}

sensitivities <- tibble(Strategy_Overall = unique(dat_hs$Strategy_Overall)) |>
              mutate(Sensitivity_Degrading = map_dbl(Strategy_Overall, calcSensitivityDegrading),
                     Sensitivity_Perturbing = map_dbl(Strategy_Overall, calcSensitivityPerturbing)) |>
              left_join(dat_hs_relation, by="Strategy_Overall")

write_csv(sensitivities, "temp.csv")

ggplot(filter(sensitivities, Strategy_Overall %in% best_strategies)) +
    geom_point(aes(x=Sensitivity_Degrading, y=Sensitivity_Perturbing)) +
    geom_smooth(aes(x=Sensitivity_Degrading, y=Sensitivity_Perturbing), method="lm")

ggplot(filter(sensitivities, Strategy_Overall %in% best_strategies)) +
    geom_point(aes(x=Success_150, y=Sensitivity_Degrading)) +
    geom_smooth(aes(x=Success_150, y=Sensitivity_Degrading), method="lm")

ggplot(filter(sensitivities, Strategy_Overall %in% best_strategies)) +
    geom_point(aes(x=Success_150, y=Sensitivity_Perturbing)) +
    geom_smooth(aes(x=Success_150, y=Sensitivity_Perturbing), method="lm")

ggplot(filter(sensitivities, Strategy_Overall %in% best_strategies)) +
    geom_point(aes(x=Weighted_Entropy, y=Sensitivity_Perturbing)) +
    geom_smooth(aes(x=Weighted_Entropy, y=Sensitivity_Perturbing), method="lm")

ggplot(filter(sensitivities, Strategy_Overall %in% best_strategies)) +
    geom_point(aes(x=Weighted_Entropy, y=Sensitivity_Degrading)) +
    geom_smooth(aes(x=Weighted_Entropy, y=Sensitivity_Degrading), method="lm")

lm(Sensitivity_Degrading ~ Success_150 + Weighted_Entropy, 
   data=filter(sensitivities, Strategy_Overall %in% best_strategies)) |> 
   summary()

# plot_entropy_examples <- ggplot(example_strings_cut) +
#                       geom_raster(aes(x=Day, y=Iteration, fill=State, alpha=Hatch_Result=="hatched")) +
#                       geom_text(aes(x=Day, y=Iteration, label=State), size=1.25) +
#                       scale_fill_manual(values=c(state_colors), na.value="white", 
#                                         labels=c("F"="Female", "M"="Male", "N"="Neglect")) +
#                       scale_y_discrete(limits=c("I73", "I0", "I48", "I208"),
#                                        labels=c("I73"="Hatched", "I0"="Overall neglect - Fail", 
#                                                 "I48"="Continuous neglect - Fail", "I208"="Dead parent - Fail")) +
#                       scale_alpha_manual(values=c("TRUE"=1, "FALSE"=0.25)) +
#                       guides(alpha="none") +
#                       ylab("Outcome") +
#                       theme_classic()
# ggsave(filename="SICB/plot_entropy_examples.png", plot_entropy_examples, width=5, height=2)

# plot_entropy_examples_nofill <- ggplot(example_strings_cut) +
#                              geom_text(aes(x=Day, y=Iteration, label=State), size=1.25) +
#                              scale_fill_manual(values=c(state_colors), na.value="white", 
#                                                labels=c("F"="Female", "M"="Male", "N"="Neglect")) +
#                              scale_y_discrete(limits=c("I73", "I0", "I48", "I208"),
#                                               labels=c("I73"="Hatched", "I0"="Overall neglect - Fail", 
#                                                        "I48"="Continuous neglect - Fail", "I208"="Dead parent - Fail")) +
#                              scale_alpha_manual(values=c("TRUE"=1, "FALSE"=0.25)) +
#                              guides(alpha="none") +
#                              ylab("Outcome") +
#                              theme_classic()
# ggsave(filename="SICB/plot_entropy_examples_nofill.png", plot_entropy_examples_nofill, width=5, height=2)

# ggplot(dat_hs_relation) +
#                       geom_point(aes(x=Success_150_Scaled_Entropy, y=Perturbed_Penalty))
# plot_penalties_entropies <- ggplot(penalty_residuals) +
#                          geom_point(aes(x=Success_150_Scaled_Entropy, y=Perturbed_Penalty_Residual), 
#                                     colour="black", fill="orange", alpha=0.5, shape=21) +
#                          geom_smooth(aes(x=Success_150_Scaled_Entropy, y=Perturbed_Penalty_Residual), colour="black", se=FALSE) +
#                          xlab("Schedule entropy in regular environment") +
#                          ylab("Residual of perturbed penalty") +
#                          theme_classic()
# ggsave(filename="SICB/plot_penalties_residualPoints_entropies.png", plot_penalties_entropies, width=5, height=4)



