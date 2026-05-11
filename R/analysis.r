############################################################
### Logistics
#########################################################

# Required packages
library(tidyverse)
library(patchwork)
library(gghalves)

# Read in processed data
read_processed_dat <- function(f) {
  read_csv(f, show_col_types=FALSE) |>
  mutate(Strategy_F = paste(Min_Energy_Thresh_F, Max_Energy_Thresh_F, sep="-"),
         Strategy_M = paste(Min_Energy_Thresh_M, Max_Energy_Thresh_M, sep="-"),
         Strategy_Combination = paste(Strategy_F, Strategy_M, sep=" : "),
         Is_Empirical_Strategy = (Min_Energy_Thresh_F >= 400 & Min_Energy_Thresh_F <= 700) &
                                 (Max_Energy_Thresh_F >= 700 & Max_Energy_Thresh_F <= 900) &
                                 (Min_Energy_Thresh_M >= 400 & Min_Energy_Thresh_M <= 700) &
                                 (Max_Energy_Thresh_M >= 700 & Max_Energy_Thresh_M <= 900))
}

dat_regular <- read_processed_dat("Output/processed_regular.csv")

# Get numerical order for factoring strategies
order_strategy_f <- dat_regular |>
                 arrange(Min_Energy_Thresh_F, Max_Energy_Thresh_F) |>
                 pull(Strategy_F) |>
                 unique()
order_strategy_m <- dat_regular |>
                 arrange(Min_Energy_Thresh_M, Max_Energy_Thresh_M) |>
                 pull(Strategy_M) |>
                 unique()
dat_regular <- dat_regular |>
            mutate(Strategy_F = factor(Strategy_F, levels=order_strategy_f),
                   Strategy_M = factor(Strategy_M, levels=order_strategy_m))

# Custom plotting theme
theme_lt <- theme_bw() +
         theme(plot.title = element_text(size=12, hjust=0.5),
               axis.title = element_text(size=11),
               axis.text = element_text(size=8),
               legend.title = element_text(size=11),
               legend.text = element_text(size=8),
               panel.grid = element_blank())

EMPIRICAL_COLOR <- "#f275ee"

OF <- "Output/results_log.txt"

###############################################################
### Model fidelity
############################################################

# Empirical parameter set only
emp <- dat_regular |>
    filter(Is_Empirical_Strategy, Foraging_Condition_Mean == 162, Foraging_Condition_SD == 47)

summaryValues <- function(v, sfs=4) {
    return(paste0("Mean=", round(mean(v, na.rm=TRUE),sfs), 
                  " SD=", round(sd(v, na.rm=TRUE),sfs), 
                  " Min=", round(min(v, na.rm=TRUE),sfs), 
                  " Max=", round(max(v, na.rm=TRUE), sfs))) 
}

cat("Results log from", as.character(now()), "\n", file=OF, append=FALSE)
cat("\nModel fidelity for empirical strategies in empirical environment\n", file=OF, append=TRUE)
cat("Foraging conditions ", unique(emp$Foraging_Condition_Mean), "+-", unique(emp$Foraging_Condition_SD), "\n", file=OF, append=TRUE)
cat("Departure thresholds", unique(c(emp$Min_Energy_Thresh_F, emp$Min_Energy_Thresh_M)), "\n", file=OF, append=TRUE)
cat("Return thresholds", unique(c(emp$Max_Energy_Thresh_F, emp$Max_Energy_Thresh_M)), "\n", file=OF, append=TRUE)
cat("Success rate", summaryValues(emp$Rate_Success), "\n", file=OF, append=TRUE)
cat("Success hatch date", summaryValues(emp$Successful_Hatch_Date), "\n", file=OF, append=TRUE)
cat("Success proportion neglect", summaryValues(emp$Successful_Prop_Neglect), "\n", file=OF, append=TRUE)
cat("Mean success incubation bout (F)", summaryValues(emp$Mean_Incubation_Bout_F), "\n", file=OF, append=TRUE)
cat("Mean success incubation bout (F Trimmed)", summaryValues(emp$Mean_Incubation_Bout_F_Trimmed), "\n", file=OF, append=TRUE)
cat("Mean success incubation bout (M)", summaryValues(emp$Mean_Incubation_Bout_M), "\n", file=OF, append=TRUE)
cat("Mean success incubation bout (M Trimmed)", summaryValues(emp$Mean_Incubation_Bout_M_Trimmed), "\n", file=OF, append=TRUE)
cat("Mean success foraging bout (F)", summaryValues(emp$Mean_Foraging_Bout_F), "\n", file=OF, append=TRUE)
cat("Mean success foraging bout (F Trimmed)", summaryValues(emp$Mean_Foraging_Bout_F_Trimmed), "\n", file=OF, append=TRUE)
cat("Mean success foraging bout (M)", summaryValues(emp$Mean_Foraging_Bout_M), "\n", file=OF, append=TRUE)
cat("Mean success foraging bout (M Trimmed)", summaryValues(emp$Mean_Foraging_Bout_M_Trimmed), "\n", file=OF, append=TRUE)
cat("Mean success incubation bout (Both)", summaryValues(emp$Mean_Incubation_Bout_Both), "\n", file=OF, append=TRUE)
cat("Mean success incubation bout (Both Trimmed)", summaryValues(emp$Mean_Incubation_Bout_Both_Trimmed), "\n", file=OF, append=TRUE)
cat("Mean success foraging bout (Both)", summaryValues(emp$Mean_Foraging_Bout_Both), "\n", file=OF, append=TRUE)
cat("Mean success foraging bout (Both Trimmed)", summaryValues(emp$Mean_Foraging_Bout_Both_Trimmed), "\n", file=OF, append=TRUE)

###############################################################
### Parent strategies
############################################################

# Data from empirical environment only
emp_environment <- filter(dat_regular, Foraging_Condition_Mean == 162, Foraging_Condition_SD == 47)

# Empirical strategy boxes to highlight those places in the tile
#   We factor to align with axes in the tile plot
#       and shift boundaries to 
emp_strategy_boxes <- tibble(Strategy_F_Start = c(rep("400-700", times=4), rep("500-700", times=4), rep("600-700", times=4), rep("700-800", times=4)),
                             Strategy_F_End = c(rep("400-900", times=4), rep("500-900", times=4), rep("600-900", times=4), rep("700-900", times=4)),
                             Strategy_M_Start = c(rep(c("400-700", "500-700", "600-700", "700-800"), times=4)),
                             Strategy_M_End = c(rep(c("400-900", "500-900", "600-900", "700-900"), times=4))) |>
                   mutate(Strategy_F_Start = as.numeric(factor(Strategy_F_Start, order_strategy_f))-0.5,
                          Strategy_F_End = as.numeric(factor(Strategy_F_End, order_strategy_f))+0.5,
                          Strategy_M_Start = as.numeric(factor(Strategy_M_Start, order_strategy_m))-0.5,
                          Strategy_M_End = as.numeric(factor(Strategy_M_End, order_strategy_m))+0.5)

# Tile plot from empirical environment
plot_main_tile <- ggplot(emp_environment) +
               geom_tile(aes(x=Strategy_F, y=Strategy_M, fill=Rate_Success)) +
               geom_rect(data=emp_strategy_boxes,
                         aes(xmin=Strategy_F_Start, xmax=Strategy_F_End, 
                             ymin=Strategy_M_Start, ymax=Strategy_M_End),
                         fill="transparent", color=alpha(EMPIRICAL_COLOR,0.5)) +
               scale_fill_continuous(low="white", high="gray10", name="Success rate",
                                     limits=c(0, 1)) +
               xlab("Female strategy") +
               ylab("Male strategy") +
               theme_lt +
               theme(panel.background = element_blank(),
                     axis.text.y = element_text(size=4),
                     axis.text.x = element_text(size=4, angle=-90, hjust=0, vjust=1))

# Summarize across minimum thresholds
min_threshes <- emp_environment |>
             select(Min_Energy_Thresh_F, Min_Energy_Thresh_M, Rate_Success) |>
             pivot_longer(cols=contains("Thresh"), names_to="Sex", values_to="Min_Energy_Thresh") |>
             group_by(Min_Energy_Thresh) |>
             mutate(Mean_Rate_Success = mean(Rate_Success))
    
plot_min_threshes <- ggplot(min_threshes,
                            aes(x=Min_Energy_Thresh, y=Rate_Success)) +
                  geom_violin(aes(group=Min_Energy_Thresh, fill=Mean_Rate_Success),
                              scale="area",
                              colour="black", linewidth=0.05) +
                  stat_summary(fun=mean, geom="line", colour="black", linewidth=0.5) +
                  scale_x_continuous(breaks=seq(200, 11000, by=200)) +
                  scale_y_continuous(limits=c(0, 1), breaks=seq(0, 1, by=0.25)) +
                  scale_fill_continuous(low="white", high="gray10", name="Success rate",
                                        limits=c(0, 1)) +    
                  xlab("Departure threshold (kJ)") +
                  ylab("Success rate") +
                  theme_lt

# Summarize across maximum thresholds
max_threshes <- emp_environment |>
             select(Max_Energy_Thresh_F, Max_Energy_Thresh_M, Rate_Success) |>
             pivot_longer(cols=contains("Thresh"), names_to="Sex", values_to="Max_Energy_Thresh") |>
             group_by(Max_Energy_Thresh) |>
             mutate(Mean_Rate_Success = mean(Rate_Success))

plot_max_threshes <- ggplot(max_threshes,
                            aes(x=Max_Energy_Thresh, y=Rate_Success)) +
                  geom_violin(aes(group=Max_Energy_Thresh, fill=Mean_Rate_Success),
                              scale="area",
                              colour="black", linewidth=0.05) +
                  stat_summary(fun=mean, geom="line", colour="black", linewidth=0.5) +
                  scale_x_continuous(breaks=seq(400, 1200, by=200)) +
                  scale_y_continuous(limits=c(0, 1), breaks=seq(0, 1, by=0.25)) +  
                  scale_fill_continuous(low="white", high="gray10", name="Success rate",
                                        limits=c(0, 1)) +    
                  xlab("Return threshold (kJ)") +
                  ylab("Success rate") +
                  theme_lt

# Assemble full with tile plots
design <- "12
           13"

plot_tiles <- (plot_main_tile + labs(tag="(A)")) + 
              guide_area() + 
              ((plot_min_threshes + labs(tag="(B)")) / plot_max_threshes + 
               plot_layout(axes="collect", heights=c(1,1))) + 
              plot_layout(guides="collect", design=design, 
                          widths=c(1, 0.5), heights=c(1, 4)) &
              theme(legend.position = "bottom", legend.title.position = "top",
                    legend.title = element_text(size=11, hjust=0.5),
                    plot.tag.position = "topleft")

ggsave(filename="Plots/FIGURE_2.png", plot=plot_tiles,
       width=6.5, height=4, unit="in")
###############################################################
### Tradeoffs
############################################################
 
# Parent Energy ~ Hatch Rate

# Convex hull for empirical strategies
emp_hull_energies <- emp_environment |>
                  filter(Is_Empirical_Strategy) |>
                  slice(chull(Rate_Success, Successful_Mean_Energy_F))

plot_tradeoff_energy <- ggplot() +
                     geom_point(data=filter(emp_environment, !Is_Empirical_Strategy),
                                aes(x=Rate_Success, y=Successful_Mean_Energy_F),
                                colour = "lightgray", size=0.8, alpha=0.5) +
                     geom_point(data=filter(emp_environment, Is_Empirical_Strategy),
                                aes(x=Rate_Success, y=Successful_Mean_Energy_F),
                                colour = EMPIRICAL_COLOR, size=0.8, alpha=0.5) +
                     geom_polygon(data=emp_hull_energies,
                                  aes(x=Rate_Success, y=Successful_Mean_Energy_F),
                                  colour = EMPIRICAL_COLOR, fill="transparent",
                                  linewidth=0.3) +
                     annotate(geom="point",
                              x = mean(filter(emp_environment, Is_Empirical_Strategy)$Rate_Success),
                              y = mean(filter(emp_environment, Is_Empirical_Strategy)$Successful_Mean_Energy_F),
                              colour="#b404a2", shape="+", size=3, alpha=0.8) +
                     geom_smooth(data=emp_environment,
                                 aes(x=Rate_Success, y=Successful_Mean_Energy_F),
                                 colour = "black", se=FALSE, 
                                 method="loess", linewidth=0.4) +
                     scale_x_continuous(limits=c(0, 1), breaks=seq(0, 1.0, by=0.25)) +
                     scale_y_continuous(breaks=seq(400, 1200, by=200)) +
                     guides(colour="none") +
                     xlab("Success rate") +
                     ylab("Female energy (kJ)") +
                     theme_lt


# Hatch Date ~ Hatch Rate

# Convex hull for empirical strategies
emp_hull_hatchdate <- emp_environment |>
                   filter(Is_Empirical_Strategy) |>
                   slice(chull(Rate_Success, Successful_Hatch_Date))

# Plot Hatch Rate vs. Hatch Date (which scales with neglect) -
plot_tradeoff_date <- ggplot() +
                   geom_point(data=filter(emp_environment, !Is_Empirical_Strategy),
                              aes(x=Rate_Success, y=Successful_Hatch_Date),
                              colour = "lightgray", size=0.8, alpha=0.5) +
                   geom_point(data=filter(emp_environment, Is_Empirical_Strategy),
                              aes(x=Rate_Success, y=Successful_Hatch_Date),
                              colour = EMPIRICAL_COLOR, size=0.8, alpha=0.9) +
                   geom_polygon(data=emp_hull_hatchdate,
                                aes(x=Rate_Success, y=Successful_Hatch_Date),
                                colour = EMPIRICAL_COLOR, fill="transparent",
                                linewidth=0.3) +
                   annotate(geom="point",
                            x = mean(filter(emp_environment, Is_Empirical_Strategy)$Rate_Success),
                            y = mean(filter(emp_environment, Is_Empirical_Strategy)$Successful_Hatch_Date),
                            colour="#b404a2", shape="+", size=3, alpha=0.8) +
                   geom_smooth(data=emp_environment,
                               aes(x=Rate_Success, y=Successful_Hatch_Date),
                               colour = "black", se=FALSE, 
                               method="loess", linewidth=0.4) +
                   scale_x_continuous(limits=c(0, 1), breaks=seq(0, 1.0, by=0.25)) +
                   scale_y_continuous(limits=c(36, 58), breaks=seq(36, 58, by=4)) +
                   guides(colour="none") +
                   xlab("Success rate") +
                   ylab("Hatch date") +
                   theme_lt

# Parent Energy ~ Hatch Date

# Convex hull for empirical strategies
emp_hull_energydate <- emp_environment |>
                     filter(Is_Empirical_Strategy) |>
                     slice(chull(Successful_Hatch_Date, Successful_Mean_Energy_F))

# Plot Hatch Rate vs. Hatch Date (which scales with neglect) -
plot_tradeoff_energydate <- ggplot() +
                         geom_point(data=filter(emp_environment, !Is_Empirical_Strategy),
                                    aes(x=Successful_Hatch_Date, y=Successful_Mean_Energy_F),
                                    colour = "lightgray", size=0.8, alpha=0.5) +
                         geom_point(data=filter(emp_environment, Is_Empirical_Strategy),
                                    aes(x=Successful_Hatch_Date, y=Successful_Mean_Energy_F),
                                    colour=EMPIRICAL_COLOR, size=0.8, alpha=0.9) +
                         geom_polygon(data=emp_hull_energydate,
                                      aes(x=Successful_Hatch_Date, y=Successful_Mean_Energy_F),
                                      colour=EMPIRICAL_COLOR, fill="transparent",
                                      linewidth=0.3) +
                         annotate(geom="point",
                                  x = mean(filter(emp_environment, Is_Empirical_Strategy)$Successful_Hatch_Date),
                                  y = mean(filter(emp_environment, Is_Empirical_Strategy)$Successful_Mean_Energy_F),
                                  colour="#b404a2", shape="+", size=3, alpha=0.8) +
                         geom_smooth(data=emp_environment,
                                     aes(x=Successful_Hatch_Date, y=Successful_Mean_Energy_F),
                                     colour = "black", se=FALSE, 
                                     method="loess", linewidth=0.4) +
                         scale_x_continuous(limits=c(36, 58), breaks=seq(36, 58, by=4)) +
                         scale_y_continuous(breaks=seq(400, 1200, by=200)) +
                         guides(colour="none") +
                         xlab("Hatch date") +
                         ylab("Female energy (kJ)") +
                         theme_lt

# Assemble and print full plot
plot_tradeoffs <- plot_tradeoff_energy + plot_tradeoff_date + plot_tradeoff_energydate +
               plot_annotation(tag_levels="A", tag_prefix="(", tag_suffix=")") &
               theme(legend.position = "bottom", legend.title.position = "top",
                     legend.title = element_text(size=11, hjust=0.5),
                     plot.tag.position="topleft",
                     plot.tag=element_text(vjust=2),
                     plot.margin = margin(t=14, r=0, b=0, l=0))

ggsave(filename="Plots/FIGURE_3.png", plot=plot_tradeoffs, 
       width=6.5, height=2.3)

###############################################################
### Decline in hatch success in the environment
############################################################

# Exclude data from empirical environment, so we have smooth sample of 
#   130 - 170 by 10 (including 160)
not_emp_forgmean <- filter(dat_regular, Foraging_Condition_Mean != 162, Foraging_Condition_SD == 47)

# Fit logistic curves to find fail point
mlog_all <- glm(Rate_Success ~ Foraging_Condition_Mean, data=not_emp_forgmean, family="quasibinomial")
mlog_all_failpoint <- -coef(mlog_all)[1] / coef(mlog_all)[2]
mlog_emp <- glm(Rate_Success ~ Foraging_Condition_Mean, data=filter(not_emp_forgmean, Is_Empirical_Strategy), family="quasibinomial")
mlog_emp_failpoint <- -coef(mlog_emp)[1] / coef(mlog_emp)[2]

# Line plot of hatch rate as environment degrades
plot_decline_hatch_mean <- ggplot() +
                        geom_line(data=filter(not_emp_forgmean, !Is_Empirical_Strategy),
                                  aes(x=Foraging_Condition_Mean, y=Rate_Success, group=Strategy_Combination),
                                  colour="lightgray", alpha=0.5, linewidth=0.35) +
                        geom_line(data=filter(not_emp_forgmean, Is_Empirical_Strategy),
                                  aes(x=Foraging_Condition_Mean, y=Rate_Success, group=Strategy_Combination),
                                  colour=EMPIRICAL_COLOR, alpha=0.15, linewidth=0.1) +
                        geom_vline(xintercept = mlog_all_failpoint, colour="black", linewidth=0.25) +
                        geom_vline(xintercept = mlog_emp_failpoint, colour="#b404a2", linewidth=0.25) +
                        stat_smooth(data=filter(not_emp_forgmean, Is_Empirical_Strategy),
                                    aes(x=Foraging_Condition_Mean, y=Rate_Success), 
                                    method = "glm", method.args = list(family="quasibinomial"), formula=y~x,
                                    se=FALSE, colour="#b404a2") +
                        stat_smooth(data=not_emp_forgmean,
                                    aes(x=Foraging_Condition_Mean, y=Rate_Success), 
                                    method = "glm", method.args = list(family="quasibinomial"), formula=y~x, 
                                    se=FALSE, colour="black") +
                        xlab("Foraging mean (kJ/day)") +
                        ylab("Success rate") +
                        theme_lt

not_emp_both_summaries <- filter(dat_regular, 
                                 Foraging_Condition_SD != 47, 
                                 Foraging_Condition_Mean != 162) |>
                       group_by(Foraging_Condition_Mean, Foraging_Condition_SD) |>
                       summarize(Mean_Rate_Success = mean(Rate_Success),
                                 Var_Rate_Success = var(Rate_Success), .groups="keep")

plot_env_success <- ggplot(not_emp_both_summaries) +
                 geom_tile(aes(x=Foraging_Condition_Mean, 
                               y=Foraging_Condition_SD, 
                               fill=Mean_Rate_Success)) +
                 scale_y_continuous(limits=c(0, 110), breaks=seq(10, 100, by=20)) +
                 scale_fill_continuous(low="white", high="gray10", name="Success rate",
                                       limits=c(0, 1)) +
                 xlab("Foraging mean (kJ/day)") +
                 ylab("Foraging S.D. (kJ/day)") +
                 theme_lt +
                 theme(legend.title.position="right",
                       legend.title=element_text(size=8, angle=-90, hjust=0.5, vjust=0),
                       legend.text=element_text(size=6))

plot_env_var <- ggplot(not_emp_both_summaries) +
             geom_tile(aes(x=Foraging_Condition_Mean, 
                           y=Foraging_Condition_SD, 
                           fill=Var_Rate_Success)) +
             scale_y_continuous(limits=c(0, 110), breaks=seq(10, 100, by=20)) +
             scale_fill_continuous(low="white", high="firebrick3", 
                                   limits=c(0, 0.16),
                                   breaks=seq(0, 0.16, by=0.04), name="Var. success rate") +
             xlab("Foraging mean (kJ/day)") +
             ylab("Foraging S.D. (kJ/day)") +
             theme_lt +
             theme(legend.title.position="right",
                   legend.title=element_text(size=8, angle=-90, hjust=0.5, vjust=0),
                   legend.text=element_text(size=6))

design <- "12"

# Assemble and print full plot
plot_declines <- plot_decline_hatch_mean + 
              (plot_env_success / 
                plot_env_var +
                plot_layout(axes="collect")) +
              plot_annotation(tag_levels="A", tag_prefix="(", tag_suffix=")") + 
              plot_layout(design=design,
                          widths=c(1, 0.7)) &
              theme(legend.key.width = unit(0.1, "in"),
                    legend.key.height = unit(0.1, "in"),
                    legend.margin = margin(t=0, r=0, b=0, l=0),
                    legend.box.spacing = unit(0.06, "in"),                  
                    plot.tag.position="topleft",
                    plot.tag=element_text(vjust=-2, hjust=-1),
                    plot.margin = margin(t=2, r=4, b=2, l=4))

ggsave(filename="Plots/FIGURE_4.png", plot=plot_declines, 
       width=6.5, height=3, unit="in")

###############################################################
### Change in outcomes across environments
############################################################

# Get rates of four different outcomes 
#   (successful hatch, slow development, cold shock, dead parent)
# excluding the empirical environment, so we have a smooth sample
#   of 130 - 170 by 10 (including 160)
outcomes <- dat_regular |> 
         filter(Foraging_Condition_Mean != 162, Foraging_Condition_SD == 47) |>
         select(Strategy_Combination, Foraging_Condition_Mean, contains("Rate_")) |>
         pivot_longer(cols=contains("Rate_"), names_to="Outcome", values_to="Rate") |>
         mutate(Outcome = str_replace(Outcome, "Rate_", ""))     

plot_outcomes_smooth <- ggplot(outcomes) +
                     geom_smooth(aes(x=Foraging_Condition_Mean, y=Rate, colour=Outcome),
                                 method="loess", formula=y~x) +
                     annotate(geom="text", label="Successful", hjust=0, vjust=1, x=158, y=0.935, size=3, lineheight=1, colour="black") +
                     annotate(geom="text", label="(Fail)\nCold shock", hjust=0, vjust=1, x=132, y=0.89, size=3, lineheight=1, colour="#7570b3") + 
                     annotate(geom="text", label="(Fail)\nSlow dev.", hjust=0, vjust=1, x=154, y=0.22, size=3, lineheight=1, colour="#1b9e77") +
                     annotate(geom="text", label="(Fail)\nParent dead", hjust=0, vjust=1, x=130.5, y=0.23, size=3, lineheight=1, colour="#d95f02") +
                     scale_colour_manual(values=c("Success"="black",
                                                  "Fail_Egg_Cold"="#7570b3",
                                                  "Fail_Egg_Time"="#1b9e77",
                                                  "Fail_Parent_Dead"="#d95f02")) +
                     scale_y_continuous(limits=c(0, 1), breaks=seq(0, 1, by=0.25)) +
                     xlab("Foraging mean (kJ/day)") +
                     ylab("Outcome rate") +
                     guides(colour="none") +
                     theme_lt

plot_outcome_success <- ggplot(filter(outcomes, Outcome=="Success")) +
                     geom_line(aes(x=Foraging_Condition_Mean, y=Rate, 
                                   group=Strategy_Combination),
                               colour="black", alpha=0.25, linewidth=0.1) +
                     annotate(geom="text", label="Successful", hjust=0, vjust=1, x=130, y=1.0, size=3, lineheight=1, colour="black") +
                     scale_y_continuous(limits=c(0, 1), breaks=seq(0, 1, by=0.25)) +
                     xlab("Foraging mean (kJ/day)") +
                     ylab("Outcome rate") +
                     guides(colour="none") +
                     theme_lt

plot_outcome_cold <- ggplot(filter(outcomes, Outcome=="Fail_Egg_Cold")) +
                  geom_line(aes(x=Foraging_Condition_Mean, y=Rate, 
                                group=Strategy_Combination),
                            colour="#7570b3", alpha=0.25, linewidth=0.1)  +
                  annotate(geom="text", label="Cold\nshock", hjust=0, vjust=0, x=130, y=0, size=3, lineheight=1, colour="#7570b3") +
                  scale_y_continuous(limits=c(0, 1), breaks=seq(0, 1, by=0.25)) +
                  xlab("Foraging mean (kJ/day)") +
                  ylab("Outcome rate") +
                  guides(colour="none") +
                  theme_lt

plot_outcome_time <- ggplot(filter(outcomes, Outcome=="Fail_Egg_Time")) +
                  geom_line(aes(x=Foraging_Condition_Mean, y=Rate, 
                                group=Strategy_Combination),
                            colour="#1b9e77", alpha=0.25, linewidth=0.1)  +
                  annotate(geom="text", label="Slow\ndevelopment", hjust=0, vjust=1, x=130, y=1.0, size=3, lineheight=1, colour="#1b9e77") +
                  scale_y_continuous(limits=c(0, 1), breaks=seq(0, 1, by=0.25)) +
                  xlab("Foraging mean (kJ/day)") +
                  ylab("Outcome rate") +
                  guides(colour="none") +
                  theme_lt

plot_outcome_dead <- ggplot(filter(outcomes, Outcome=="Fail_Parent_Dead")) +
                  geom_line(aes(x=Foraging_Condition_Mean, y=Rate, 
                                group=Strategy_Combination),
                            colour="#d95f02", alpha=0.25, linewidth=0.25)  +
                  annotate(geom="text", label="Parent\ndead", hjust=0, vjust=1, x=130, y=1.0, size=3, lineheight=1, colour="#d95f02") +
                  scale_y_continuous(limits=c(0, 1), breaks=seq(0, 1, by=0.25)) +
                  xlab("Foraging mean (kJ/day)") +
                  ylab("Outcome rate") +
                  guides(colour="none") +
                  theme_lt

design <- "123
           145"

plot_outcomes <- plot_outcomes_smooth + 
              plot_outcome_success + plot_outcome_cold + 
              plot_outcome_time + plot_outcome_dead +
              plot_layout(widths=c(1, 0.5, 0.5), design = design,
                          axes="collect")
ggsave(filename="Plots/FIGURE_5.png", plot=plot_outcomes, 
       width=6.5, height=3, unit="in")

###############################################################
### Egg tolerance
############################################################

dat_eggTolerance  <- read_processed_dat("Output/processed_eggTolerance.csv") |>
                  filter(Is_Empirical_Strategy,
                         Foraging_Condition_Mean %in% c(150, 160, 170),
                         Foraging_Condition_SD == 47)

egg_strip_labeller <- function(value) {
    ifelse(value == min(as.numeric(value)),
           paste0("Foraging mean: ", value, " (kJ/day)"),
           paste0(value, " (kJ/day)"))
}

plot_egg_tolerance <- ggplot(dat_eggTolerance) +
                   geom_line(aes(x=Egg_Tolerance, y=Rate_Success, 
                                 group=Strategy_Combination),
                             colour=EMPIRICAL_COLOR, alpha=0.5) +
                   geom_smooth(aes(x=Egg_Tolerance, y=Rate_Success),
                               method="loess", formula=y~x,
                               colour="#b404a2", se=FALSE) +
                   facet_wrap(facets=vars(Foraging_Condition_Mean), nrow=1, ncol=3,
                              labeller=labeller(Foraging_Condition_Mean=egg_strip_labeller)) +
                   scale_x_continuous(breaks=1:7) +
                   xlab("Egg cold tolerance (days)") +
                   ylab("Success rate") +
                   theme_lt +
                   theme(strip.background=element_rect(colour="transparent", fill="transparent"),
                         strip.text=element_text(size=10, hjust=1))

ggsave(filename="Plots/FIGURE_6.png", plot=plot_egg_tolerance, 
       width=6.5, height=2.5, unit="in")

###############################################################
### One parent energy requirements
############################################################

dat_oneParent  <- read_processed_dat("Output/processed_oneParent.csv")

# Fit logistic curves to find fail point
mlog_oneParent <- glm(Rate_Success ~ Foraging_Condition_Mean, data=dat_oneParent, family="quasibinomial")
mlog_oneParent_failpoint <- -coef(mlog_oneParent)[1] / coef(mlog_oneParent)[2]

plot_success_oneParent <- ggplot(dat_oneParent) +
                       geom_line(aes(x=Foraging_Condition_Mean, y=Rate_Success, group=Strategy_Combination),
                                 colour=EMPIRICAL_COLOR, alpha=0.5, linewidth=0.5) +
                       geom_vline(xintercept = mlog_oneParent_failpoint, colour="#b404a2", linewidth=0.25) +
                       stat_smooth(aes(x=Foraging_Condition_Mean, y=Rate_Success), 
                                   method = "glm", method.args = list(family="quasibinomial"), formula=y~x,
                                   se=FALSE, colour="#b404a2", linewidth=0.8) +
                       scale_x_continuous(breaks=seq(100, 400, by=100)) +
                       xlab("Foraging mean (kJ/day)") +
                       ylab("Success rate\n(one parent)") +
                       theme_lt

ggsave(filename="Plots/FIGURE_S_ONEPARENT.png", plot=plot_success_oneParent,
       width=4, height=2, units="in")

###############################################################
### Sex bias 
############################################################

dat_eggCost <- read_processed_dat("Output/processed_eggCost.csv")

plot_eggCost_hatch <- ggplot(dat_eggCost) +
                   geom_line(aes(x=Egg_Cost, y=Rate_Success, 
                                 group=Strategy_Combination),
                             colour=EMPIRICAL_COLOR, alpha=0.5) +
                   geom_smooth(aes(x=Egg_Cost, y=Rate_Success),
                               method="loess", formula=y~x,
                               colour="#b404a2", se=FALSE) +
                   scale_x_continuous(breaks=seq(0, 500, by=100)) +
                   xlab("Egg cost to female (kJ)") +
                   ylab("Success rate") +
                   theme_lt

dat_eggCost_long <- dat_eggCost |>
                select(Strategy_Combination, Egg_Cost, Mean_Incubation_Bout_F_Trimmed, Mean_Incubation_Bout_M_Trimmed) |>
                pivot_longer(cols=contains("Bout"), names_to="Sex", values_to="Mean_Incubation_Bout") |>
                mutate(Sex = str_split_i(Sex, "_", 4))

eggCost_means <- dat_eggCost_long |>
              group_by(Egg_Cost, Sex) |>
              summarize(Mean_Incubation_Bout = mean(Mean_Incubation_Bout), .groups="drop_last")

plot_eggCost_bias <- ggplot() +
                  geom_half_violin(data=filter(dat_eggCost_long, Sex == "F"), 
                                    aes(x=Egg_Cost, y=Mean_Incubation_Bout, group=Egg_Cost, fill=Sex),
                                    colour="black", side="l") +
                  geom_half_violin(data=filter(dat_eggCost_long, Sex == "M"), 
                                    aes(x=Egg_Cost, y=Mean_Incubation_Bout, group=Egg_Cost, fill=Sex),
                                    colour="black", side="r") +
                  geom_point(data=filter(eggCost_means, Sex == "F"),
                             aes(x=Egg_Cost, y=Mean_Incubation_Bout),
                             colour="black", size=0.5, 
                             position=position_nudge(x=-11)) +
                  geom_point(data=filter(eggCost_means, Sex == "M"),
                             aes(x=Egg_Cost, y=Mean_Incubation_Bout),
                             colour="black", size=0.5,
                             position=position_nudge(x=11)) +
                  scale_x_continuous(breaks=seq(0, 500, by=100)) +
                  scale_y_continuous(breaks=seq(1, 9, by=2)) +
                  scale_fill_manual(values=c("F"="white", "M"="gray"),
                                    labels=c("F"="Female", "M"="Male")) +
                  xlab("Egg cost to female (kJ)") +
                  ylab("Mean incubation bout (days)") +
                  theme_lt +
                  theme(legend.position="right", 
                        legend.title=element_text(size=10),
                        legend.text=element_text(size=10))

plots_eggCost <- plot_eggCost_hatch / plot_eggCost_bias +
              plot_annotation(tag_levels="A", tag_prefix="(", tag_suffix=")") + 
              plot_layout(ncol=1, nrow=2, axes="collect")
              
ggsave(filename="Plots/FIGURE_S_EGGCOST.png", plot=plots_eggCost, 
       width=6, height=5, unit="in")


dat_swappedSexOrder <- read_processed_dat("Output/processed_swapSexOrder.csv")

dat_swappedSexOrder_long <- dat_swappedSexOrder |>
                         select(Strategy_Combination, Mean_Incubation_Bout_F_Trimmed, Mean_Incubation_Bout_M_Trimmed) |>
                         pivot_longer(cols=contains("Bout"), names_to="Sex", values_to="Mean_Incubation_Bout_Swapped") |>
                         mutate(Sex = str_split_i(Sex, "_", 4))

dat_regular_comparison_long <- dat_regular |>
                            filter(Is_Empirical_Strategy, 
                                   Foraging_Condition_Mean == 162,
                                   Foraging_Condition_SD == 47,
                                   Egg_Tolerance == 7, 
                                   Egg_Cost == 69.7) |>
                            select(Strategy_Combination, Mean_Incubation_Bout_F_Trimmed, Mean_Incubation_Bout_M_Trimmed) |>
                                              pivot_longer(cols=contains("Bout"), names_to="Sex", values_to="Mean_Incubation_Bout_Swapped") |>
                            mutate(Sex = str_split_i(Sex, "_", 4))

