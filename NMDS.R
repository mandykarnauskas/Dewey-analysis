#########################################################
#  M. Karnauskas - 30 June 2020                         #
#  Code for running the "Dewey analysis"                #
#  Processing of charter boat social media              #
#  NMDS and ANOSIM code                                 #
#########################################################

# Set directory ----------------------------------------
rm(list=ls())
setwd("C:/Users/mandy.karnauskas/Desktop/participatory_workshops/Dewey_analysis")

# Install libraries ------------------------------------
if ("vegan" %in% available.packages() == FALSE) { install.packages("vegan") } 
if ("viridis" %in% available.packages() == FALSE) { install.packages("viridis") } 

library(vegan)
library(MASS)
library(viridis)
library(yarrr)

# Load data --------------------------------------------
dfl <- read.table("Charter_SouthFloridaKeys_9_22_20_906Count.csv", 
                header = T, sep = ",", check.names = F, quote = "")
dnc <- read.table("Charter_NCVA_100520.csv", 
                header = T, sep = ",", check.names = F, quote = "")

head(dfl)
head(dnc)

#d <- dfl
d <- dnc

# ONLY for analysis of two regions together ------------

dfl[is.na(dfl)] <- 0
dnc[is.na(dnc)] <- 0

head(dfl)
head(dnc)
names(dnc)[which(names(dnc) %in% names(dfl))]
names(dnc)[-which(names(dnc) %in% names(dfl))]

# modify names so that they match 
names(dfl)[grep("Tilefish", names(dfl))] <- "Tilefish" 
names(dfl)[grep("Spanish", names(dfl))] <- "Spanish_Mackerel" 

dnc$tunas <- dnc$Tuna_Complex
dfl$tunas <- dfl$Blackfin_Tuna + dfl$Skipjack_Tuna      # lump tunas

dfl$groupers <- rowSums(dfl[,grep("Grouper", names(dfl))], na.rm = T)
dnc$groupers <- dnc$Grouper_Complex + dnc$Black_Sea_Bass  # lump groupers

names(dnc)[which(names(dnc) %in% names(dfl))]     # check names
names(dnc)[-which(names(dnc) %in% names(dfl))]
dnc <- dnc[which(names(dnc) %in% names(dfl))]
names(dnc)[-which(names(dnc) %in% names(dfl))]

dfl <- dfl[,-grep("Tuna", names(dfl))]  # remove lumped columns
dfl <- dfl[,-grep("Grouper", names(dfl))]

match(names(dnc), names(dfl))
dfl2 <- dfl[match(names(dnc), names(dfl))]  # sort columns in NC to match FL
head(dfl2)
cbind(names(dfl2), names(dnc))
table(names(dfl2) == names(dnc))

d <- rbind(dfl2, dnc)        # combine into single data frame

# output files for QAQC check
#dfl_check <- dfl[round(runif(45, min = 1, max = 905)),]
#dnc_check <- dnc[round(runif(17, min = 1, max = 1330)),]
#write.table(dfl_check, file = "checkFL.csv", sep = ",", row.names = F)
#write.table(dnc_check, file = "checkNC.csv", sep = ",", row.names = F, append = T)

# assign other variables ------------------------------------
names(d)

table(d$region, useNA = "always")
table(d$marina, useNA = "always")
table(d$company, useNA = "always")
table(d$photo_ID, useNA = "always")
table(d$year, useNA = "always")
table(d$month, useNA = "always")
table(d$day, useNA = "always")
table(d$photo_type, useNA = "always")
dim(d)
names(d)

d[is.na(d)] <- 0           # convert NAs to zeros
dim(d)
which(rowSums(d[,9:(ncol(d))]) == 0)

names(d)[grep("mahi", tolower(names(d)))]
d$totDolphin <- rowSums(d[grep("mahi", tolower(names(d)))], na.rm = T)
d <- d[,-grep("mahi", tolower(names(d)))]

names(d)[9:ncol(d)]

d1 <- d[,9:(ncol(d))]     # separate object with spp counts only

#seas <- cut(d$month, breaks = c(0, 3.5, 6.5, 9.5, 12.5))  # approximate seasons
#labs <- c("Jan-Mar", "Apr-Jun", "Jul-Sep", "Oct-Dec")
seas <- cut(d$month, breaks = c(0, 5.5, 7.5, 9.5, 12.5))  # approximate seasons
labs <- c("Jan-May", "Jun-Jul", "Aug-Sep", "Oct-Dec")
d$mclass <- factor(labs[as.numeric(seas)], levels = labs)

d$reg2 <- NA                                              # manually define regions
d$reg2[grep("Hatteras", d$marina)] <- "Hatteras"
d$reg2[which(d$marina == "Oregon Inlet Fishing Center")] <- "Wanchese"
d$reg2[which(d$marina == "Virginia Beach Fishing Center")] <- "Virginia Beach"
d$reg2[which(d$marina == "Pirate's Cove Marina")] <- "Wanchese"
d$reg2[which(d$marina == "Sensational Sportfishing")] <- "Morehead"
r1 <- c("Miami", "Hollywood", "Ft. Lauderdale", "Pompano Beach", "Deerfield Beach")
r2 <- c("Boynton Beach", "West Palm Beach", "Riviera Beach", "Jupiter")
r3 <- c("Islamorada", "Key Largo", "Key West", "Marathon")
d$reg2[which(d$marina %in% r1)] <- "Miami - Deerfield"
d$reg2[which(d$marina %in% r2)] <- "Boynton - Jupiter"
d$reg2[which(d$marina %in% r3)] <- "FL Keys"
table(d$reg2, useNA = "always")
table(d$marina, d$reg2)
table(d$mclass, useNA = "always")
table(d$mclass, d$region)

d$reg2 <- factor(d$reg2, levels = c("FL Keys", "Miami - Deerfield", "Boynton - Jupiter", 
                                    "Morehead", "Hatteras", "Wanchese", "Virginia Beach"))
                          
d$mon <- d$month                       # group months with few samples
table(d$mon, useNA = "always")
d$mon[d$mon <= 4] <- 4
d$mon[d$mon >= 10] <- 10
d$mon2 <- month.abb[d$mon]
d$mon2[which(d$mon2 == "Apr")] <- "Jan-Apr"
d$mon2[which(d$mon2 == "Oct")] <- "Oct-Dec"
d$mon2 <- factor(d$mon2, levels = c("Jan-Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct-Dec"))
table(d$mon2, d$reg2, useNA = "always")
table(d$mon2, d$month, useNA = "always")

table(d$year)                         # group years with few samples
d$yr2 <- as.character(d$year)
d$yr2[which(d$year <= 2017)] <- "2013-17"
table(d$yr2, useNA = "always")
table(d$yr2, d$year, useNA = "always")

# operations to spp matrix prior to NMDS -----------------
dim(d1)
plot(colSums(d1))

sort(colSums(d1 != 0) / nrow(d1) * 100)   # look at occurrence rates
hist(colSums(d1 != 0) / nrow(d1) * 100, breaks = 40)
which(colSums(d1 != 0) / nrow(d1) * 100 < 1)
which(colSums(d1 != 0) / nrow(d1) * 100 >= 1)

splis <- which(colSums(d1 != 0) / nrow(d1) * 100 >= 1) 
splis
d2 <- d1[splis]
dim(d2) 
head(d2)

djit <- d2 + abs(rnorm(prod(dim(d2)), sd=0.01))  # jitter data because some exact like entries
save(djit, file = "NC_NMDS_input.RData")

#for (i in 1:ncol(d1))  { d1[,i] <- d1[,i] / max(d1[,i]) }  # scale by max abundance

# NMDS ----------------------------------
#pc1 <- metaMDS(djit, k = 3, autotransform = T, trymax = 25, noshare = 0)

d1.dist <- vegdist(djit, method = "bray")
pc <- isoMDS(d1.dist, k = 2, trace = T, tol = 1e-3)
#pc <- isoMDS(d1.dist, k = 3, trace = T, tol = 1e-3)

#pc3 <- isoMDS(d1.dist, k = 3, trace = T, tol = 1e-3)
#pc4 <- isoMDS(d1.dist, k = 4, trace = T, tol = 1e-3)
#pc5 <- isoMDS(d1.dist, k = 5, trace = T, tol = 1e-3)
#pc6 <- isoMDS(d1.dist, k = 6, trace = T, tol = 1e-3)

#plot(c(2:6), c(pc$stress, pc3$stress, pc4$stress, pc5$stress, pc6$stress), type = "b")

# ANOSIM ---------------------------
reg.ano <- anosim(d1.dist, d$region)
reg2.ano <- anosim(d1.dist, d$reg2)
mar.ano <- anosim(d1.dist, d$marina)
yr.ano <- anosim(d1.dist, d$yr2)
mon.ano <- anosim(d1.dist, d$mon2)
sea.ano <- anosim(d1.dist, d$mclass)

summary(reg.ano)
summary(reg2.ano)
summary(mar.ano)
summary(yr.ano)
summary(mon.ano)
summary(sea.ano)

save(reg.ano, reg2.ano, mar.ano, yr.ano, mon.ano, sea.ano, file = "ANOSIMres.RData")

Rvals <- c(reg.ano$statistic, reg2.ano$statistic, mar.ano$statistic, 
           yr.ano$statistic, mon.ano$statistic, sea.ano$statistic)

# plot ANOSIM results -------------------------

par(mfrow=c(3,2), mex = 1.0, mar = c(11,5,2,1))

plot(reg.ano, las = 2, xlab = "", ylab = "")
plot(reg2.ano,las = 2, xlab = "", ylab = "")
plot(mar.ano, las = 2, xlab = "", ylab = "")
plot(yr.ano,  las = 2, xlab = "", ylab = "")
plot(mon.ano, las = 2, xlab = "", ylab = "")
plot(sea.ano, las = 2, xlab = "", ylab = "")

# ordination plots -------------------

par(mfrow=c(3,2), mex = 1.0, mar = c(2,3,2,1))

cols <- transparent(alphabet(20), trans.val = 0.5)
factors <- c("region", "reg2", "marina", "yr2", "mon2", "mclass")
labs <- c("state", "subregion", "marina", "year", "month", "season")

for (i in 1:6)  {
  fact <- d[,which(names(d) == factors[i])]
  
  ta <- table(as.numeric(as.factor(fact)), fact); ta
  plot(pc$points[,1], pc$points[,2], col = cols[as.numeric(as.factor(fact))], 
       main = labs[i], pch = 16, cex = 0.6) #, xlim = c(-1, 1))  #  xlim = c(-0.8, 0.8))
  ordiellipse(pc, fact, col = cols, lwd = 2, kind = "sd", label = F)
  legend("bottomleft", ncol = 1, colnames(ta), col = cols[as.numeric(rownames(ta))], pch = 16, cex = 1)
  text(x = 0.6, y = -0.5, paste("R =", round(Rvals[i], 2)), cex = 1.2)
    }

# final ordination plot -----------------------------------

png(filename="NMDS_NC.png", units="in", width=7, height=7, pointsize=12, res=72*4)
cexs <- c(1, 1, 1, 1, 1, 1)

par(mfrow=c(2,2), mex = 1.0, mar = c(2,3,2,1))
for (i in c(1, 2, 4, 5))  {
  fact <- d[,which(names(d) == factors[i])]
  ta <- table(as.numeric(as.factor(fact)), fact); ta

  cols <- rainbow(nrow(ta))
  cols2 <- transparent(rainbow(nrow(ta)), trans.val = 0.6)
    
  plot(pc$points[,1], pc$points[,2], col = cols2[as.numeric(as.factor(fact))], 
       main = labs[i], pch = 19, cex = 0.5, xlim = c(-0.7, 0.7), ylim = c(-0.8, 1), xlab = "", ylab = "")
  ordiellipse(pc, fact, col = cols, lwd = 3, kind = "sd", label = F)
  if (i == 5) { a <- 3 } else { a <- 2 }
  legend("bottomleft", ncol = a, colnames(ta), col = cols[as.numeric(rownames(ta))], 
         pch = 15, cex = cexs[i], bty = "n", y.intersp = 1)
  text(x = -0.55, y = 0.95, paste("R =", round(Rvals[i], 2)), cex = 1.2)
  }

dev.off()


# NMDS sensitivity analysis for distance method -----------

met <- c("manhattan", "euclidean", "canberra", "clark", "bray", "jaccard", "gower", 
         "altGower", "horn", "binomial", "kulczynski", "raup")  #"morisita", "mountford", "chao", "cao")

par(mfrow=c(4,3), mex=0.5, mar = c(2,3,3,1))

for (i in 1:length(met)) {
  d1.dist <- vegdist(djit, method = met[i])
  pc <- isoMDS(d1.dist, k = 2, trace = T, tol = 1e-3)

  plot(pc$points[,1], pc$points[,2], col = as.numeric(as.factor(d$reg2)), pch=16, cex=0.5)
  ordiellipse(pc, d$reg2, col = 1:4, lwd=2, kind = "sd", label = T)
  mtext(side = 3, paste(met[i], "    stress = ", round(pc$stress)), cex=0.8)
}

# ANOSIM sensitivity analysis for distance methods ----------------

met <- c("manhattan", "canberra", "clark", "bray", "jaccard", "gower", "horn",  
         "binomial", "kulczynski", "raup")   #"morisita", "mountford", "chao", "cao")

ano.res <- NA

for (i in 1:length(met)) {
  d1.dist <- vegdist(djit, method = met[i])
  
  #  yr.ano  <- anosim(d1.dist, d$year)
  sea.ano <- anosim(d1.dist, d$mclass)
  #  mon.ano <- anosim(d1.dist, d$mon2)
  mar.ano <- anosim(d1.dist, d$marina)
  reg.ano <- anosim(d1.dist, d$region)
  reg2.ano <- anosim(d1.dist, d$reg2)
  
  res <- c(sea.ano$statistic, mar.ano$statistic, reg.ano$statistic, reg2.ano$statistic)
  p <- c(sea.ano$signif, mar.ano$signif, reg.ano$signif, reg2.ano$signif)
  resp <- c(res, p)
  ano.res <- cbind(ano.res, resp)  
  cat(met[i])
}
ano.res

# The end ------------------------------