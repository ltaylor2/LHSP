############################################################
### Logistics
#########################################################

# Required packages
library(tidyverse)
library(patchwork)

# Read in processed data
dat <- read_csv("Output/processed_results.csv") |>
    mutate(Strategy_F = paste(Min_Energy_Thresh_F, Max_Energy_Thresh_F, sep="-"),
           Strategy_M = paste(Min_Energy_Thresh_M, Max_Energy_Thresh_M, sep="-"),
           Strategy_Combination = paste(Strategy_F, Strategy_M, sep=" : "),
           Is_Empirical_Strategy = (Min_Energy_Thresh_F >= 400 & Min_Energy_Thresh_F <= 700) &
                                   (Max_Energy_Thresh_F >= 700 & Max_Energy_Thresh_F <= 900) &
                                   (Min_Energy_Thresh_M >= 400 & Min_Energy_Thresh_M <= 700) &
                                   (Max_Energy_Thresh_M >= 700 & Max_Energy_Thresh_M <= 900))


# Get numerical order for factoring strategies
order_strategy_f <- dat |>
                 arrange(Min_Energy_Thresh_F, Max_Energy_Thresh_F) |>
                 pull(Strategy_F) |>
                 unique()
order_strategy_m <- dat |>
                 arrange(Min_Energy_Thresh_M, Max_Energy_Thresh_M) |>
                 pull(Strategy_M) |>
                 unique()
dat <- dat |>
    mutate(Strategy_F = factor(Strategy_F, levels=order_strategy_f),
           Strategy_M = factor(Strategy_M, levels=order_strategy_m))

# Custom plotting theme
theme_lt <- theme_bw() +
         theme(plot.title = element_text(size=12, hjust=0.5),
               axis.title = element_text(size=12),
               axis.text = element_text(size=8),
               legend.title = element_text(size=12),
               legend.text = element_text(size=8),
               panel.grid = element_blank())

EMPIRICAL_COLOR <- "#a16161"

###############################################################
### Parent strategies
############################################################

# Data from empirical environment only
emp_environment <- filter(dat, Foraging_Condition_Mean == 162)

# Comparison environments
comp_bad <- filter(dat, Foraging_Condition_Mean == 140)
comp_good <- filter(dat, Foraging_Condition_Mean == 170)

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
                         fill="transparent", color=EMPIRICAL_COLOR) +
               scale_fill_continuous(low="white", high="gray10", name="Hatch success rate",
                                     limits=c(0, 1)) +
               xlab("Female strategy") +
               ylab("Male strategy") +
               ggtitle("Empirical environment\n(162 kJ/day)") +
               theme_lt +
               theme(panel.background = element_blank(),
                     axis.text.y = element_text(size=6),
                     axis.text.x = element_text(size=6, angle=35, hjust=1, vjust=1))

# Tile plot for visual comparison with bad environment
plot_bad_tile <- ggplot(comp_bad) +
              geom_tile(aes(x=Strategy_F, y=Strategy_M, fill=Rate_Success)) +
              geom_rect(data=emp_strategy_boxes,
                        aes(xmin=Strategy_F_Start, xmax=Strategy_F_End, 
                            ymin=Strategy_M_Start, ymax=Strategy_M_End),
                        fill="transparent", color=EMPIRICAL_COLOR, linewidth=0.2) +
              scale_fill_continuous(low="white", high="gray10", name="Hatch success rate",
                                    limits=c(0, 1)) +
              xlab("Female strategy") +
              ylab("Male strategy") +
              ggtitle("Bad environment\n(140 kJ/day)") +
              theme_lt +
              theme(panel.background = element_blank(),
                    axis.text = element_blank(),
                    plot.title = element_text(size=12),
                    axis.title = element_text(size=6))

# Tile plot for visual comparison with good environment
plot_good_tile <- ggplot(comp_good) +
               geom_tile(aes(x=Strategy_F, y=Strategy_M, fill=Rate_Success)) +
               geom_rect(data=emp_strategy_boxes,
                         aes(xmin=Strategy_F_Start, xmax=Strategy_F_End, 
                             ymin=Strategy_M_Start, ymax=Strategy_M_End),
                         fill="transparent", color=EMPIRICAL_COLOR, linewidth=0.2) +
               scale_fill_continuous(low="white", high="gray10", name="Hatch success rate",
                                     limits=c(0, 1)) +
               xlab("Female strategy") +
               ylab("Male strategy") +
               ggtitle("Good environment\n(170 kJ/day)") +
               theme_lt +
               theme(panel.background = element_blank(),
                     axis.text = element_blank(),
                     plot.title = element_text(size=12),
                     axis.title = element_text(size=6))

# Assemble full with tile plots
design <- "12
           12
           13
           13
           14"

plot_tiles <- plot_main_tile + plot_bad_tile + plot_good_tile + guide_area() +
           plot_layout(guides="collect", design=design, widths=c(0.75, 0.25)) +
           plot_annotation(tag_levels="A", tag_prefix="(", tag_suffix=")") &
           theme(legend.position = "bottom", legend.title.position = "top",
                 legend.title = element_text(size=12, hjust=0.5),
                 plot.tag.position=c(0.03, 0.98))
ggsave(filename="Plots/FIGURE_2.png", plot=plot_tiles, width=7.5, height=6)

###############################################################
### Energy variation - pair or individual
############################################################

###############################################################
### Sexual differences
############################################################

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
                              colour="red", shape="+", size=3, alpha=0.8) +
                     geom_smooth(data=emp_environment,
                                 aes(x=Rate_Success, y=Successful_Mean_Energy_F),
                                 colour = "black", se=FALSE, 
                                 method="loess", linewidth=0.4) +
                     scale_x_continuous(limits=c(0, 1), breaks=seq(0, 1.0, by=0.25)) +
                     scale_y_continuous(breaks=seq(500, 1000, by=100)) +
                     guides(colour="none") +
                     xlab("Hatch success rate") +
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
                              colour = EMPIRICAL_COLOR, size=0.8, alpha=0.5) +
                   geom_polygon(data=emp_hull_hatchdate,
                                aes(x=Rate_Success, y=Successful_Hatch_Date),
                                colour = EMPIRICAL_COLOR, fill="transparent",
                                linewidth=0.3) +
                   annotate(geom="point",
                            x = mean(filter(emp_environment, Is_Empirical_Strategy)$Rate_Success),
                            y = mean(filter(emp_environment, Is_Empirical_Strategy)$Successful_Hatch_Date),
                            colour="red", shape="+", size=3, alpha=0.8) +
                   geom_smooth(data=emp_environment,
                               aes(x=Rate_Success, y=Successful_Hatch_Date),
                               colour = "black", se=FALSE, 
                               method="loess", linewidth=0.4) +
                   scale_x_continuous(limits=c(0, 1), breaks=seq(0, 1.0, by=0.25)) +
                   scale_y_continuous(limits=c(38, 56), breaks=seq(40, 55, by=5)) +
                   guides(colour="none") +
                   xlab("Hatch success rate") +
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
                                    colour=EMPIRICAL_COLOR, size=0.8, alpha=0.5) +
                         geom_polygon(data=emp_hull_energydate,
                                      aes(x=Successful_Hatch_Date, y=Successful_Mean_Energy_F),
                                      colour=EMPIRICAL_COLOR, fill="transparent",
                                      linewidth=0.3) +
                         annotate(geom="point",
                                  x = mean(filter(emp_environment, Is_Empirical_Strategy)$Successful_Hatch_Date),
                                  y = mean(filter(emp_environment, Is_Empirical_Strategy)$Successful_Mean_Energy_F),
                                  colour="red", shape="+", size=3, alpha=0.8) +
                         geom_smooth(data=emp_environment,
                                     aes(x=Successful_Hatch_Date, y=Successful_Mean_Energy_F),
                                     colour = "black", se=FALSE, 
                                     method="loess", linewidth=0.4) +
                         scale_x_continuous(limits=c(38, 56), breaks=seq(40, 55, by=5)) +
                         scale_y_continuous(breaks=seq(500, 1000, by=100)) +
                         guides(colour="none") +
                         xlab("Hatch date") +
                         ylab("Female energy (kJ)") +
                         theme_lt

plot_tradeoff_energydate_colored <- ggplot() +
                                 geom_point(data=filter(emp_environment, !Is_Empirical_Strategy),
                                            aes(x=Successful_Hatch_Date, y=Successful_Mean_Energy_F,
                                                colour=Rate_Success),
                                            size=0.8, alpha=0.5) +
                                 scale_x_continuous(limits=c(38, 56), breaks=seq(40, 55, by=5)) +
                                 scale_y_continuous(breaks=seq(500, 1000, by=100)) +
                                 scale_colour_gradient() +
                                 guides(colour="none") +
                                 xlab("Hatch date") +
                                 ylab("Female energy (kJ)") +
                                 theme_lt

# Assemble and print full plot
plot_tradeoffs <- plot_tradeoff_energy + plot_tradeoff_date + plot_tradeoff_energydate + plot_tradeoff_energydate_colored
               plot_annotation(tag_levels="A", tag_prefix="(", tag_suffix=")") &
               theme(legend.position = "bottom", legend.title.position = "top",
                     legend.title = element_text(size=12, hjust=0.5),
                     plot.tag.position=c(0.02, 1.0))
ggsave(filename="Plots/FIGURE_3.png", plot=plot_tradeoffs, width=7.5, height=2.5)

###############################################################
### Decline in hatch success in the environment
############################################################

# Exclude data from empirical environment, so we have smooth sample of 
#   130 - 170 by 10 (including 160)
not_emp <- filter(dat, Foraging_Condition_Mean != 162)

# Fit logistic curves to find fail point
mlog_all <- glm(Rate_Success ~ Foraging_Condition_Mean, data=not_emp, family="quasibinomial")
mlog_all_failpoint <- -coef(mlog_all)[1] / coef(mlog_all)[2]
mlog_emp <- glm(Rate_Success ~ Foraging_Condition_Mean, data=filter(not_emp, Is_Empirical_Strategy), family="quasibinomial")
mlog_emp_failpoint <- -coef(mlog_emp)[1] / coef(mlog_emp)[2]

# Line plot of hatch rate as environment degrades
plot_decline_hatch <- ggplot() +
                   geom_line(data=filter(not_emp, !Is_Empirical_Strategy),
                             aes(x=Foraging_Condition_Mean, y=Rate_Success, group=Strategy_Combination),
                             colour="lightgray", alpha=0.5, linewidth=0.35) +
                   geom_line(data=filter(not_emp, Is_Empirical_Strategy),
                             aes(x=Foraging_Condition_Mean, y=Rate_Success, group=Strategy_Combination),
                             colour=EMPIRICAL_COLOR, alpha=0.15, linewidth=0.1) +
                   geom_vline(xintercept = mlog_all_failpoint, colour="black", linewidth=0.25) +
                   geom_vline(xintercept = mlog_emp_failpoint, colour=EMPIRICAL_COLOR, linewidth=0.25) +
                   stat_smooth(data=filter(not_emp, Is_Empirical_Strategy),
                               aes(x=Foraging_Condition_Mean, y=Rate_Success), 
                               method = "glm", method.args = list(family="quasibinomial"), 
                               se=FALSE, colour=EMPIRICAL_COLOR) +
                   stat_smooth(data=not_emp,
                               aes(x=Foraging_Condition_Mean, y=Rate_Success), 
                               method = "glm", method.args = list(family="quasibinomial"), 
                               se=FALSE, colour="black") +
                   xlab("Environmental condition (kJ/day)") +
                   ylab("Hatch success rate") +
                   theme_lt
    
# Line plot of changing parent energy as environment degrades
plot_decline_energy <- ggplot() +
                   geom_line(data=filter(not_emp, !Is_Empirical_Strategy),
                             aes(x=Foraging_Condition_Mean, y=Successful_Mean_Energy_F, group=Strategy_Combination),
                             colour="lightgray", alpha=0.5, linewidth=0.25) +
                   geom_line(data=filter(not_emp, Is_Empirical_Strategy),
                             aes(x=Foraging_Condition_Mean, y=Successful_Mean_Energy_F, group=Strategy_Combination),
                             colour=EMPIRICAL_COLOR, alpha=0.15, linewidth=0.1) +
                   geom_smooth(data=not_emp, 
                               aes(x=Foraging_Condition_Mean, y=Successful_Mean_Energy_F),
                               method="lm", colour="black") +
                   geom_smooth(data=filter(not_emp, Is_Empirical_Strategy), 
                               aes(x=Foraging_Condition_Mean, y=Successful_Mean_Energy_F),
                               method="lm", colour=EMPIRICAL_COLOR) +
                   scale_y_continuous(breaks=seq(400, 1200, by=300)) +
                   xlab("Environmental condition (kJ/day)") +
                   ylab("Female energy (kJ)") +
                   theme_lt +
                   theme(panel.background = element_blank(),
                         plot.title = element_text(size=10),
                         axis.title = element_text(size=8),
                         axis.text = element_text(size=8))

# Line plot of changing hatch date as environment degrades
plot_decline_date <- ggplot() +
                   geom_line(data=filter(not_emp, !Is_Empirical_Strategy),
                             aes(x=Foraging_Condition_Mean, y=Successful_Hatch_Date, group=Strategy_Combination),
                             colour="lightgray", alpha=0.5, linewidth=0.25) +
                   geom_line(data=filter(not_emp, Is_Empirical_Strategy),
                             aes(x=Foraging_Condition_Mean, y=Successful_Hatch_Date, group=Strategy_Combination),
                             colour=EMPIRICAL_COLOR, alpha=0.15, linewidth=0.1) +
                   geom_smooth(data=not_emp, 
                               aes(x=Foraging_Condition_Mean, y=Successful_Hatch_Date),
                               method="lm", colour="black") +
                   geom_smooth(data=filter(not_emp, Is_Empirical_Strategy), 
                               aes(x=Foraging_Condition_Mean, y=Successful_Hatch_Date),
                               method="lm", colour=EMPIRICAL_COLOR) +
                   xlab("Environmental condition (kJ/day)") +
                   ylab("Hate date") +
                   theme_lt +
                   theme(panel.background = element_blank(),
                         plot.title = element_text(size=10),
                         axis.title = element_text(size=8),
                         axis.text = element_text(size=8))

# Assemble and print full plot
design <- "12
           13"

plot_declines <- plot_decline_hatch + plot_decline_energy + plot_decline_date +
              plot_layout(widths=c(1, 0.7), design=design, axes="collect") +
              plot_annotation(tag_levels="A", tag_prefix="(", tag_suffix=")") &
              theme(plot.tag.position=c(0.01, 1.01))
              
ggsave(filename="Plots/FIGURE_4.png", plot=plot_declines, width=6, height=3.5)

###############################################################
### Fail point and sensitivity
############################################################

# Custom function to calculate the fail points for a strategy across environments
getFailPoint <- function(strategy, data) {
    # Get this strategy across all environments
    #   filtering out the empirical environment (162)
    #   so we get a smooth set from 130 - 170 by 10, including 160
    strat_dat <- data |>
              filter(Strategy_Combination == strategy, 
                     Foraging_Condition_Mean != 162)

    # Quasibinomial regression to get logistic (i.e., switch-like) curve
    mlog <- glm(Rate_Success ~ Foraging_Condition_Mean, data=strat_dat, family="quasibinomial")

    # Fail point is when logistic curve hits 0.5
    failpoint <- -coef(mlog)[1] / coef(mlog)[2]

    return(tibble(Strategy_Combination = strategy, Fail_Point = failpoint))
}

# Calculate fail points and join to the rest of the data
failpoints <- map_dfr(unique(dat$Strategy_Combination), ~ getFailPoint(., data=dat)) |>
           right_join(dat, by="Strategy_Combination") |>
           filter(Foraging_Condition_Mean == 162)

# Histogram of fail points

plot_failpoints <- ggplot() +
                geom_histogram(data=failpoints, 
                               aes(x=Fail_Point), 
                               colour="black", fill="lightgray",
                               binwidth=2, alpha=0.8) +
                geom_histogram(data=filter(failpoints, Is_Empirical_Strategy), 
                               aes(x=Fail_Point), 
                               colour="black", fill=EMPIRICAL_COLOR,
                               binwidth=2, alpha=0.75) +
                scale_x_continuous(breaks=seq(144, 168, by=4)) +               
                xlab("Environmental fail point (kJ/day)") +
                ylab("Num. strategies") +
                theme_lt

emp_hull_resilience_energy <- failpoints |>
                           filter(Is_Empirical_Strategy) |>
                           slice(chull(Successful_Mean_Energy_F, Fail_Point))
plot_resilience_energy <- ggplot() +
                       geom_point(data=filter(failpoints, !Is_Empirical_Strategy),
                                  aes(x=Successful_Mean_Energy_F, y=Fail_Point),
                                  colour="lightgray", size=0.5, alpha=0.5) +
                       geom_point(data=filter(failpoints, Is_Empirical_Strategy),
                                  aes(x=Successful_Mean_Energy_F, y=Fail_Point),
                                  colour=EMPIRICAL_COLOR, size=0.5, alpha=0.5) +
                       geom_polygon(data=emp_hull_resilience_energy,
                                    aes(x=Successful_Mean_Energy_F, y=Fail_Point),
                                    colour=EMPIRICAL_COLOR, fill="transparent",
                                    linewidth=0.3) +
                       annotate(geom="point",
                                x = mean(filter(failpoints, Is_Empirical_Strategy)$Successful_Mean_Energy_F),
                                y = mean(filter(failpoints, Is_Empirical_Strategy)$Fail_Point),
                                colour="red", shape="+", size=3, alpha=0.8) +
                       geom_smooth(data=failpoints,
                                   aes(x=Successful_Mean_Energy_F, y=Fail_Point),
                                   colour="black", se=FALSE,
                                   method="loess", linewidth=0.4) +
                       scale_y_continuous(limits=c(140, 170), breaks=seq(145, 165, by=10)) +               
                       xlab("Mean female energy (kJ)") +
                       ylab("Environmental fail point (kJ/day)") +
                       theme_lt +
                       theme(axis.title=element_text(size=8),
                             axis.text=element_text(size=6),
                             plot.title=element_text(size=8))

emp_hull_resilience_date <- failpoints |>
                           filter(Is_Empirical_Strategy) |>
                           slice(chull(Successful_Hatch_Date, Fail_Point))
plot_resilience_date <- ggplot() +
                     geom_point(data=filter(failpoints, !Is_Empirical_Strategy),
                                aes(x=Successful_Hatch_Date, y=Fail_Point),
                                colour="lightgray", size=0.5, alpha=0.5) +
                     geom_point(data=filter(failpoints, Is_Empirical_Strategy),
                                aes(x=Successful_Hatch_Date, y=Fail_Point),
                                colour=EMPIRICAL_COLOR, size=0.5, alpha=0.5) +
                     geom_polygon(data=emp_hull_resilience_date,
                                  aes(x=Successful_Hatch_Date, y=Fail_Point),
                                  colour=EMPIRICAL_COLOR, fill="transparent",
                                  linewidth=0.3) +
                     annotate(geom="point",
                              x = mean(filter(failpoints, Is_Empirical_Strategy)$Successful_Hatch_Date),
                              y = mean(filter(failpoints, Is_Empirical_Strategy)$Fail_Point),
                              colour="red", shape="+", size=3, alpha=0.8) +
                     geom_smooth(data=failpoints,
                                 aes(x=Successful_Hatch_Date, y=Fail_Point),
                                 colour="black", se=FALSE,
                                 method="loess", linewidth=0.4) +
                     scale_y_continuous(limits=c(140, 170), breaks=seq(145, 165, by=10)) +               
                     xlab("Hatch date") +
                     ylab("Environmental fail point (kJ/day)") +
                     theme_lt +
                     theme(axis.title=element_text(size=8),
                           axis.text=element_text(size=6))

emp_hull_resilience_hatch <- failpoints |>
                          filter(Is_Empirical_Strategy) |>
                          slice(chull(Rate_Success, Fail_Point))

plot_resilience_hatch <- ggplot() +
                      geom_point(data=filter(failpoints, !Is_Empirical_Strategy),
                                 aes(x=Rate_Success, y=Fail_Point), 
                                 colour="lightgray", size=0.5, alpha=0.5) +
                      geom_point(data=filter(failpoints, Is_Empirical_Strategy),
                                 aes(x=Rate_Success, y=Fail_Point), 
                                 colour=EMPIRICAL_COLOR, size=0.5, alpha=0.5) +
                      geom_polygon(data=emp_hull_resilience_hatch,
                                   aes(x=Rate_Success, y=Fail_Point),
                                   colour=EMPIRICAL_COLOR, fill="transparent",
                                   linewidth=0.3) +
                      annotate(geom="point",
                               x = mean(filter(failpoints, Is_Empirical_Strategy)$Rate_Success),
                               y = mean(filter(failpoints, Is_Empirical_Strategy)$Fail_Point),
                               colour="red", shape="+", size=3, alpha=0.8) +
                      geom_smooth(data=failpoints,
                                  aes(x=Rate_Success, y=Fail_Point),
                                  method="loess", se=FALSE,
                                  colour="black", linewidth=0.4) +
                      scale_x_continuous(limits=c(0.25, 1), breaks=seq(0.25, 1, by=0.25)) +
                      scale_y_continuous(limits=c(140, 170), breaks=seq(145, 165, by=10)) +               
                      xlab("Hatch success rate") +
                      ylab("Environmental fail point (kJ/day)") +
                      theme_lt +
                      theme(axis.title=element_text(size=8),
                        axis.text=element_text(size=6))

design <- "12
           13
           14"

plot_failpoints_combined <- plot_failpoints + plot_resilience_energy + plot_resilience_date + plot_resilience_hatch +
                         plot_layout(widths=c(1, 0.3), design=design, axes="collect")

ggsave(filename="Plots/FIGURE_5.png", plot=plot_failpoints_combined, width=7.5, height=3)

###############################################################
### Change in outcomes across environments
############################################################

# Get rates of four different outcomes 
#   (successful hatch, slow development, cold shock, dead parent)
# excluding the empirical environment, so we have a smooth sample
#   of 130 - 170 by 10 (including 160)
outcomes <- dat |> 
         filter(Foraging_Condition_Mean != 162) |>
         select(Strategy_Combination, Foraging_Condition_Mean, contains("Rate_")) |>
         pivot_longer(cols=contains("Rate_"), names_to="Outcome", values_to="Rate") |>
         mutate(Outcome = str_replace(Outcome, "Rate_", ""))     

plot_outcomes_smooth <- ggplot(outcomes) +
                     geom_smooth(aes(x=Foraging_Condition_Mean, y=Rate, colour=Outcome),
                                 method="loess") +
                     annotate(geom="text", label="Successful", hjust=0, vjust=1, x=155.8, y=0.925, size=3, lineheight=1, colour="black") +
                     annotate(geom="text", label="(Fail)\nCold shock", hjust=0, vjust=1, x=132, y=0.91, size=3, lineheight=1, colour="#7570b3") + 
                     annotate(geom="text", label="(Fail)\nSlow dev.", hjust=0, vjust=1, x=152, y=0.252, size=3, lineheight=1, colour="#1b9e77") +
                     annotate(geom="text", label="(Fail)\nParent dead", hjust=0, vjust=1, x=130.5, y=0.22, size=3, lineheight=1, colour="#d95f02") +
                     scale_colour_manual(values=c("Success"="black",
                                                  "Fail_Egg_Cold"="#7570b3",
                                                  "Fail_Egg_Time"="#1b9e77",
                                                  "Fail_Parent_Dead"="#d95f02")) +
                     scale_y_continuous(limits=c(0, 1), breaks=seq(0, 1, by=0.25)) +
                     xlab("Environmental condition (kJ/day)") +
                     ylab("Outcome rate") +
                     guides(colour="none") +
                     theme_lt

plot_outcome_success <- ggplot(filter(outcomes, Outcome=="Success")) +
                     geom_line(aes(x=Foraging_Condition_Mean, y=Rate, 
                                   group=Strategy_Combination),
                               colour="black", alpha=0.25, linewidth=0.1) +
                     annotate(geom="text", label="Successful", hjust=0, vjust=1, x=130, y=1.0, size=3, lineheight=1, colour="black") +
                     scale_y_continuous(limits=c(0, 1), breaks=seq(0, 1, by=0.25)) +
                     xlab("Environmental condition (kJ/day)") +
                     ylab("Outcome rate") +
                     guides(colour="none") +
                     theme_lt

plot_outcome_cold <- ggplot(filter(outcomes, Outcome=="Fail_Egg_Cold")) +
                  geom_line(aes(x=Foraging_Condition_Mean, y=Rate, 
                                group=Strategy_Combination),
                            colour="#7570b3", alpha=0.25, linewidth=0.1)  +
                  annotate(geom="text", label="Cold\nshock", hjust=1, vjust=1, x=170, y=1.0, size=3, lineheight=1, colour="#7570b3") +
                  scale_y_continuous(limits=c(0, 1), breaks=seq(0, 1, by=0.25)) +
                  xlab("Environmental condition (kJ/day)") +
                  ylab("Outcome rate") +
                  guides(colour="none") +
                  theme_lt

plot_outcome_time <- ggplot(filter(outcomes, Outcome=="Fail_Egg_Time")) +
                  geom_line(aes(x=Foraging_Condition_Mean, y=Rate, 
                                group=Strategy_Combination),
                            colour="#1b9e77", alpha=0.25, linewidth=0.1)  +
                  annotate(geom="text", label="Slow\ndevelopment", hjust=0, vjust=1, x=130, y=1.0, size=3, lineheight=1, colour="#1b9e77") +
                  scale_y_continuous(limits=c(0, 1), breaks=seq(0, 1, by=0.25)) +
                  xlab("Environmental condition (kJ/day)") +
                  ylab("Outcome rate") +
                  guides(colour="none") +
                  theme_lt

plot_outcome_dead <- ggplot(filter(outcomes, Outcome=="Fail_Parent_Dead")) +
                  geom_line(aes(x=Foraging_Condition_Mean, y=Rate, 
                                group=Strategy_Combination),
                            colour="#d95f02", alpha=0.25, linewidth=0.25)  +
                  annotate(geom="text", label="Parent\ndead", hjust=0, vjust=1, x=130, y=1.0, size=3, lineheight=1, colour="#d95f02") +
                  scale_y_continuous(limits=c(0, 1), breaks=seq(0, 1, by=0.25)) +
                  xlab("Environmental condition (kJ/day)") +
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
ggsave(filename="Plots/FIGURE_6.png", plot=plot_outcomes, width=7.5, height=3)