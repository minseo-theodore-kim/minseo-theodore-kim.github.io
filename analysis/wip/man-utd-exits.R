# =====================================================================
# STEP 1. 데이터 구축 + 기술통계 + 대응표본 검정
# Is exiting Manchester United good for a player?
# =====================================================================
mu <- data.frame(
  player = c("Dean Henderson","Eric Bailly","Alex Telles","Anthony Martial",
             "Jesse Lingard","Anthony Elanga","Mason Greenwood","Aaron Wan-Bissaka",
             "Scott McTominay","Jadon Sancho","Antony","Marcus Rashford"),
  year   = c(2022,2022,2022,2024,2022,2023,2023,2024,2024,2024,2025,2025),
  age    = c(25,28,29,28,29,21,21,26,27,23,24,27),
  pos    = c("GK","DF","DF","FW","MF","FW","FW","DF","MF","FW","FW","FW"),
  loan   = c(1,1,1,0,0,0,1,0,0,1,1,1),   # 1 = 임대, 0 = 완전이적
  pre1   = c(6.8,6.7,6.9,6.8,7.0,6.7,6.8,7.1,6.9,7.1,6.9,7.0),  # 맨유 마지막-2 시즌
  pre2   = c(6.6,6.7,7.1,6.3,6.5,6.5,6.8,7.0,5.8,6.4,6.7,7.1),  # 맨유 마지막 시즌
  post1  = c(6.7,6.7,6.8,6.9,6.6,6.9,7.2,7.3,7.4,7.4,7.6,7.3),
  post2  = c(6.5,6.7,7.5,6.3,7.0,7.0,7.2,6.7,7.1,7.1,7.8,7.6),
  stringsAsFactors = FALSE
)
mu$pre  <- rowMeans(mu[,c("pre1","pre2")])   # 이적 전 2시즌 평균
mu$post <- rowMeans(mu[,c("post1","post2")]) # 이적 후 2시즌 평균
mu$d    <- mu$post - mu$pre                  # 대응 차이(paired difference)

cat("\n[표 1] 선수별 이적 전/후 평균 평점\n")
print(format(mu[,c("player","pos","loan","pre","post","d")], nsmall=3), row.names=FALSE)

n <- nrow(mu); dbar <- mean(mu$d); s <- sd(mu$d); se <- s/sqrt(n)
cat(sprintf("\nn = %d | mean(d) = %.4f | sd(d) = %.4f | SE = %.4f\n", n, dbar, s, se))
cat(sprintf("상승 %d명 / 하락 %d명 / 동일 %d명\n",
            sum(mu$d>0), sum(mu$d<0), sum(mu$d==0)))

cat("\n--- (a) 대응표본 t검정 (paired t-test) ---\n")
print(t.test(mu$post, mu$pre, paired=TRUE))
cat(sprintf("Cohen's dz = %.3f\n", dbar/s))

cat("\n--- (b) Wilcoxon 부호순위검정 (Wilcoxon signed-rank test) ---\n")
print(suppressWarnings(wilcox.test(mu$post, mu$pre, paired=TRUE, exact=FALSE)))

cat("\n--- (c) 부호검정 (sign test) ---\n")
pos <- sum(mu$d>0); nz <- sum(mu$d!=0)
print(binom.test(pos, nz, p=0.5))

cat("\n--- (d) 정규성 확인 (Shapiro-Wilk normality test) ---\n")
print(shapiro.test(mu$d))


set.seed(2025)

# 주사위 36번 던져 "1이 나온 횟수"를 세는 실험
roll <- function(reps) rbinom(reps, size = 36, prob = 1/6)

cat("이론값 (theoretical):  평균 =", 36*(1/6),
    " 표준편차 =", round(sqrt(36*(1/6)*(5/6)), 4), "\n\n")

for (N in c(20, 100, 1000, 10000, 100000)) {
  x <- roll(N)
  cat(sprintf("N = %6d회 반복 →  평균 = %.4f   표준편차 = %.4f\n",
              N, mean(x), sd(x)))
}


# =====================================================================
# STEP 2. 전수 순열검정 (exact sign-flip permutation test)
#   H0: 이적은 기량에 영향이 없다 → 선수 내부에서 '전/후' 라벨 교환 가능
#   교환 = d의 부호 반전 → 2^12 = 4,096가지 배치를 전부 열거
# =====================================================================
d <- c(-0.10, 0.00, 0.15, 0.05, 0.05, 0.35,
       0.40, -0.05, 0.90, 0.50, 0.90, 0.40)
n <- length(d)

# 4096 x 12 부호행렬: 가능한 모든 (+1/-1) 조합을 전부 생성
signs <- as.matrix(expand.grid(rep(list(c(-1, 1)), n)))
cat("총 배치 수:", nrow(signs), "= 2^", n, "\n\n", sep="")

# --- 통계량 (A) 평균 차이 ---------------------------------------------
obs_mean  <- mean(d)
perm_mean <- as.vector(signs %*% d) / n
p_mean    <- mean(abs(perm_mean) >= abs(obs_mean) - 1e-12)

# --- 통계량 (B) 부호순위합 (Wilcoxon) ---------------------------------
r <- numeric(n); nz <- d != 0
r[nz] <- rank(abs(d[nz]))              # d=0 관측치는 순위에서 제외
obs_sr  <- sum(sign(d) * r)
perm_sr <- as.vector(signs %*% r)
p_sr    <- mean(abs(perm_sr) >= abs(obs_sr) - 1e-12)

# --- 통계량 (C) 부호합 (sign test) ------------------------------------
obs_sg  <- sum(sign(d))
perm_sg <- as.vector(signs %*% abs(sign(d)))
p_sg    <- mean(abs(perm_sg) >= abs(obs_sg) - 1e-12)

cat(sprintf("(A) 평균 d      관측 %+.4f   정확 p = %.5f\n", obs_mean, p_mean))
cat(sprintf("(B) 부호순위    W+ = %.0f      정확 p = %.5f\n", sum(r[d>0]), p_sr))
cat(sprintf("(C) 부호합      %+d          정확 p = %.5f\n", obs_sg, p_sg))

# --- 귀무분포 시각화 ---------------------------------------------------
hist(perm_mean, breaks = 60, col = "grey85", border = "white",
     main = "귀무분포: 4,096가지 부호배치에서의 평균 d",
     xlab = "permuted mean(d)")
abline(v = c(-obs_mean, obs_mean), col = "firebrick", lwd = 2, lty = 2)


# =====================================================================
# STEP 3. 평균회귀(regression to the mean) 편향 검증
#   질문: "탈맨 효과"가 아니라 "부진한 선수를 골라 판 것"의 부산물 아닌가?
# =====================================================================
mu <- data.frame(
  player = c("Henderson","Bailly","Telles","Martial","Lingard","Elanga","Greenwood",
             "Wan-Bissaka","McTominay","Sancho","Antony","Rashford"),
  pos  = c("GK","DF","DF","FW","MF","FW","FW","DF","MF","FW","FW","FW"),
  loan = c(1,1,1,0,0,0,1,0,0,1,1,1),          # 1=임대
  down = c(0,1,1,1,1,0,1,0,1,1,1,0),          # 1=리그 수준 하향
  pre1 = c(6.8,6.7,6.9,6.8,7.0,6.7,6.8,7.1,6.9,7.1,6.9,7.0),   # 맨유 마지막-2
  pre2 = c(6.6,6.7,7.1,6.3,6.5,6.5,6.8,7.0,5.8,6.4,6.7,7.1),   # 맨유 마지막
  post1= c(6.7,6.7,6.8,6.9,6.6,6.9,7.2,7.3,7.4,7.4,7.6,7.3),
  post2= c(6.5,6.7,7.5,6.3,7.0,7.0,7.2,6.7,7.1,7.1,7.8,7.6))
mu$pre  <- rowMeans(mu[,c("pre1","pre2")])
mu$post <- rowMeans(mu[,c("post1","post2")])
mu$d    <- mu$post - mu$pre

# ---------------------------------------------------------------------
# 3-A. 기준시즌 민감도 (baseline sensitivity)
#   방출 결정에 가까운 시즌을 기준으로 삼을수록 효과가 커진다면 = RTM 신호
# ---------------------------------------------------------------------
cat("=== 3-A. 기준시즌 민감도 ===\n")
lab <- c(pre1="마지막-2시즌", pre="2시즌 평균", pre2="마지막 시즌")
est <- lo <- hi <- pv <- setNames(numeric(3), names(lab))
for (b in names(lab)) {
  g <- mu$post - mu[[b]]; tt <- t.test(g)
  est[b]<-mean(g); lo[b]<-tt$conf.int[1]; hi[b]<-tt$conf.int[2]; pv[b]<-tt$p.value
  cat(sprintf("%-12s 기준: %+.4f  95%%CI[%+.3f,%+.3f]  p=%.4f\n",
              lab[b], est[b], lo[b], hi[b], pv[b]))
}

# ---------------------------------------------------------------------
# 3-B. 평균회귀 진단 회귀 (RTM diagnostic regression)
# ---------------------------------------------------------------------
cat("\n=== 3-B. 진단 회귀 ===\n")
m <- lm(d ~ pre, data = mu)
print(summary(m))
cat(sprintf("r(pre, d) = %.3f\n", cor(mu$pre, mu$d)))
cat(sprintf("[대조] pre1 기준 회귀 기울기 = %.3f (p=%.4f)\n",
            coef(lm(I(post-pre1) ~ pre1, data=mu))[2],
            summary(lm(I(post-pre1) ~ pre1, data=mu))$coefficients[2,4]))

# ---------------------------------------------------------------------
# 3-C. 분산 성분 추정 (variance components)
#   같은 선수의 두 시즌 차이 -> 시즌간 변동 sigma_w
# ---------------------------------------------------------------------
cat("\n=== 3-C. 분산 성분 ===\n")
vw_pre  <- mean((mu$pre1 - mu$pre2)^2)/2      # Var(A-B)=2*sigma_w^2
vw_post <- mean((mu$post1 - mu$post2)^2)/2
sw <- sqrt((vw_pre + vw_post)/2)
sb2 <- var(mu$pre) - sw^2/2                   # 관측분산 = sigma_b^2 + sigma_w^2/2
cat(sprintf("sigma_w (시즌간 변동)  = %.4f\n", sw))
cat(sprintf("관측 pre 분산          = %.4f\n", var(mu$pre)))
cat(sprintf("함의 sigma_b^2         = %.4f  -> sigma_b = %.3f\n", sb2, sqrt(max(0,sb2))))
cat(sprintf("신뢰도 reliability R   = %.3f\n", max(0,sb2)/(max(0,sb2)+sw^2/2)))

# ---------------------------------------------------------------------
# 3-D. 몬테카를로: "이적 효과 = 0" 인 가상 세계
# ---------------------------------------------------------------------
sim <- function(nsim=8000, N=25, k=12, sb=0.20, sw=0.2926, sel="pre2") {
  g1 <- g <- g2 <- numeric(nsim)
  for (i in 1:nsim) {
    th <- rnorm(N, 6.75, sb)                    # 진짜 실력 (변하지 않음)
    p1 <- th + rnorm(N,0,sw); p2 <- th + rnorm(N,0,sw)
    crit <- if (sel=="pre2") p2 else (p1+p2)/2  # 방출 기준
    s <- order(crit)[1:k]                       # 부진한 k명을 내보냄
    q1 <- th[s] + rnorm(k,0,sw)                 # 이적 후: 실력 동일, 노이즈만 새로
    q2 <- th[s] + rnorm(k,0,sw)
    po <- (q1+q2)/2
    g1[i] <- mean(po - p1[s])
    g[i]  <- mean(po - (p1[s]+p2[s])/2)
    g2[i] <- mean(po - p2[s])
  }
  list(pre1=g1, pre=g, pre2=g2)
}

cat("\n=== 3-D. 몬테카를로 (효과=0 가상세계) ===\n")
set.seed(20250903)
cat(sprintf("%-8s %-4s | %9s %9s %9s | %9s\n","sigma_b","N","pre1기준","pre기준","pre2기준","P(>=관측)"))
for (sb in c(0.05,0.10,0.15,0.20,0.25)) for (N in c(18,25,35)) {
  r <- sim(8000, N=N, sb=sb)
  cat(sprintf("%-8.2f %-4d | %+9.4f %+9.4f %+9.4f | %9.4f\n",
              sb, N, mean(r$pre1), mean(r$pre), mean(r$pre2), mean(r$pre >= 0.2958)))
}
cat("\n[대안] 방출 기준 = 2시즌 평균인 경우\n")
for (sb in c(0.10,0.20)) for (N in c(25,35)) {
  r <- sim(8000, N=N, sb=sb, sel="pre")
  cat(sprintf("%-8.2f %-4d | %+9.4f %+9.4f %+9.4f | %9.4f\n",
              sb, N, mean(r$pre1), mean(r$pre), mean(r$pre2), mean(r$pre >= 0.2958)))
}

# ---------------------------------------------------------------------
# 3-E. 부트스트랩 + 하위집단
# ---------------------------------------------------------------------
cat("\n=== 3-E. 부트스트랩 & 하위집단 ===\n")
set.seed(1); bs <- replicate(20000, mean(sample(mu$d, 12, replace=TRUE)))
cat(sprintf("bootstrap 95%%CI [%.3f, %.3f]\n", quantile(bs,.025), quantile(bs,.975)))
cat(sprintf("임대 %+.3f vs 완전이적 %+.3f (p=%.3f)\n",
            mean(mu$d[mu$loan==1]), mean(mu$d[mu$loan==0]), t.test(d~loan,data=mu)$p.value))
cat(sprintf("리그하향 %+.3f vs 동급이상 %+.3f (p=%.3f)\n",
            mean(mu$d[mu$down==1]), mean(mu$d[mu$down==0]), t.test(d~down,data=mu)$p.value))

# ---------------------------------------------------------------------
# 3-F. 그래프 4종
# ---------------------------------------------------------------------
par(mfrow=c(2,2), mar=c(4.5,4.5,3,1))

## (1) 회귀 그래프: 이적 전 평점 vs 상승폭
plot(mu$pre, mu$d, pch=19, col="steelblue", cex=1.3,
     xlab="Pre-transfer rating (2-season mean)", ylab="Change  d = post - pre",
     main="(1) RTM diagnostic regression")
abline(m, col="firebrick", lwd=2)
abline(h=0, lty=3, col="grey50")
text(mu$pre, mu$d, mu$player, pos=4, cex=0.55, col="grey30")
legend("topright", bty="n", cex=0.75,
       legend=sprintf("slope=%.2f  r=%.2f  p=%.3f",
                      coef(m)[2], cor(mu$pre,mu$d), summary(m)$coefficients[2,4]))

## (2) 기준시즌 민감도
bp <- barplot(est, ylim=c(-0.1,0.85), col=c("grey75","steelblue","firebrick"),
              names.arg=c("vs season -2","vs 2-szn mean","vs final season"),
              ylab="Estimated gain", main="(2) Baseline sensitivity")
arrows(bp, lo, bp, hi, angle=90, code=3, length=0.06, lwd=2)
abline(h=0, lty=2)
text(bp, hi+0.06, sprintf("p=%.3f", pv), cex=0.8)

## (3) 몬테카를로 귀무분포
set.seed(7); r <- sim(20000, N=25, sb=0.20)
hist(r$pre, breaks=60, col="grey85", border="white",
     main="(3) Monte Carlo: no-effect world", xlab="Simulated gain (pre baseline)")
abline(v=0.2958, col="firebrick", lwd=2.5)
abline(v=mean(r$pre), col="steelblue", lwd=2, lty=2)
legend("topright", bty="n", cex=0.75, lty=c(1,2), lwd=2,
       col=c("firebrick","steelblue"),
       legend=c("observed +0.296", sprintf("RTM only %+.3f", mean(r$pre))))

## (4) 선수별 이적 전후 변화
plot(NA, xlim=c(0.8,2.2), ylim=range(c(mu$pre,mu$post))+c(-.05,.05), xaxt="n",
     xlab="", ylab="FotMob season rating", main="(4) Individual trajectories")
axis(1, at=1:2, labels=c("Man Utd","New club"))
for (i in 1:nrow(mu))
  lines(1:2, c(mu$pre[i], mu$post[i]), lwd=2,
        col=ifelse(mu$d[i]>0, adjustcolor("steelblue",.8), adjustcolor("firebrick",.8)))
points(rep(1,12), mu$pre, pch=19); points(rep(2,12), mu$post, pch=19)
text(2.05, mu$post, mu$player, pos=4, cex=0.5, xpd=NA)
par(mfrow=c(1,1))


# =====================================================================
# STEP 4. 효과 분해 및 검정력 분석 (수정판)
# =====================================================================
d  <- c(-0.10,0.00,0.15,0.05,0.05,0.35,0.40,-0.05,0.90,0.50,0.90,0.40)  # 2시즌평균 기준
g1 <- c(-0.20,0.00,0.25,-0.20,-0.20,0.25,0.40,-0.10,0.35,0.15,0.80,0.45) # pre1 기준

cat("=== 관측 효과의 분해 ===\n")
obs <- mean(d); rtm_lo <- 0.097; rtm_hi <- 0.195
cat(sprintf("관측 총 상승폭              : %+.4f (sd=%.4f)\n", obs, sd(d)))
cat(sprintf("평균회귀 기여 (시뮬레이션)  : %+.3f ~ %+.3f\n", rtm_lo, rtm_hi))
cat(sprintf("잔여 효과 (residual)        : %+.3f ~ %+.3f\n", obs-rtm_hi, obs-rtm_lo))
cat(sprintf("RTM-robust 추정 (pre1 기준) : %+.4f (sd=%.4f, p=%.4f)\n\n",
            mean(g1), sd(g1), t.test(g1)$p.value))

cat("=== 검정력 (power), n=12 ===\n")
for (delta in c(0.10, 0.15, mean(g1), 0.20, obs)) {
  cat(sprintf("참 효과 %+.4f | sd=0.3441 -> power=%.4f | sd=0.3142 -> power=%.4f\n",
              delta,
              power.t.test(n=12, delta=delta, sd=sd(d),  type="paired")$power,
              power.t.test(n=12, delta=delta, sd=sd(g1), type="paired")$power))
}

cat("\n=== power=0.80 달성에 필요한 n ===\n")
cat(sprintf("d 기준    (delta=%.4f, sd=%.4f) : n = %.1f\n", obs, sd(d),
            power.t.test(delta=obs, sd=sd(d), power=.8, type="paired")$n))
cat(sprintf("pre1 기준 (delta=%.4f, sd=%.4f) : n = %.1f   <-- 권장\n", mean(g1), sd(g1),
            power.t.test(delta=mean(g1), sd=sd(g1), power=.8, type="paired")$n))