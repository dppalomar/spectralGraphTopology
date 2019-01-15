library(igraph)
library(corrplot)
library(spectralGraphTopology)
library(pals)
library(extrafont)
set.seed(0)

N <- 20
T <- 30 * N
K <- 4
P <- diag(1, K)
# K-component graph
mgraph <- sample_sbm(N, pref.matrix = P, block.sizes = c(rep(N / K, K)))
E(mgraph)$weight <- runif(gsize(mgraph), min = 0, max = 1)
Ltrue <- as.matrix(laplacian_matrix(mgraph))
Wtrue <- diag(diag(Ltrue)) - Ltrue
# Erdo-Renyi as noise model
p <- .35
a <- .45
erdos_renyi <- erdos.renyi.game(N, p)
E(erdos_renyi)$weight <- runif(gsize(erdos_renyi), min = 0, max = a)
Lerdo <- as.matrix(laplacian_matrix(erdos_renyi))
# Noisy Laplacian
Lnoisy <- Ltrue + Lerdo
Wnoisy <- diag(diag(Lnoisy)) - Lnoisy
Y <- MASS::mvrnorm(T, mu = rep(0, N), Sigma = MASS::ginv(Lnoisy))
graph <- learnLaplacianGraphTopology(cov(Y), K, w0 = "qp", beta = 20*N, ub = 2*N,
                            alpha = 1e-1, maxiter = 100000)
est_net <- graph_from_adjacency_matrix(graph$W, mode = "undirected", weighted = TRUE)
noisy_net <- graph_from_adjacency_matrix(Wnoisy, mode = "undirected", weighted = TRUE)
true_net <- graph_from_adjacency_matrix(Wtrue, mode = "undirected", weighted = TRUE)
colors <- brewer.blues(20)
c_scale <- colorRamp(colors)
E(est_net)$color = apply(c_scale(E(est_net)$weight / max(E(est_net)$weight)), 1, function(x) rgb(x[1]/255, x[2]/255, x[3]/255))
E(noisy_net)$color = apply(c_scale(E(noisy_net)$weight / max(E(noisy_net)$weight)), 1, function(x) rgb(x[1]/255, x[2]/255, x[3]/255))
E(true_net)$color = apply(c_scale(E(true_net)$weight / max(E(true_net)$weight)), 1, function(x) rgb(x[1]/255, x[2]/255, x[3]/255))

print(relativeError(Ltrue, graph$Lw))
print(Fscore(Ltrue, graph$Lw, 1e-3))
print(graph$convergence)
print(graph$beta)
print(graph$lambda)

gr = .5 * (1 + sqrt(5))
setEPS()
postscript("..latex/figures/est_graph.ps", family = "Times", height = 5, width = gr * 3.5)
plot(est_net, vertex.label = NA, vertex.size = 3)
dev.off()
setEPS()
postscript("..latex/figures/noisy_graph.ps", family = "Times", height = 5, width = gr * 3.5)
plot(noisy_net, vertex.label = NA, vertex.size = 3)
dev.off()
setEPS()
postscript("..latex/figures/true_graph.ps", family = "Times", height = 5, width = gr * 3.5)
plot(true_net, vertex.label = NA, vertex.size = 3)
dev.off()
setEPS()
postscript("..latex/figures/est_mat.ps", family = "Times", height = 5, width = gr * 3.5)
corrplot(graph$W / max(graph$W), is.corr = FALSE, method = "square", addgrid.col = NA, tl.pos = "n", cl.cex = 1.25)
dev.off()
setEPS()
postscript("..latex/figures/noisy_mat.ps", family = "Times", height = 5, width = gr * 3.5)
corrplot(Wnoisy / max(Wnoisy), is.corr = FALSE, method = "square", addgrid.col = NA, tl.pos = "n", cl.cex = 1.25)
dev.off()
setEPS()
postscript("..latex/figures/true_mat.ps", family = "Times", height = 5, width = gr * 3.5)
corrplot(Wtrue / max(Wtrue), is.corr = FALSE, method = "square", addgrid.col = NA, tl.pos = "n", cl.cex = 1.25)
dev.off()

colors <- c("#706FD3", "#FF5252", "#33D9B2")
setEPS()
postscript("..latex/figures/bd_trend.ps", family = "ComputerModern", height = 5, width = gr * 3.5)
plot(c(1:length(graph$loglike)), graph$loglike, type = "b", lty = 1, pch = 15, cex=.75, col = colors[1],
     xlab = "Iteration Number", ylab = "", ylim=c(0, 15))
grid()
lines(c(1:length(graph$loglike)), graph$obj_fun, type = "b", xaxt = "n", lty = 2, pch=16, cex=.75, col = colors[2])
lines(c(1:length(graph$loglike)), graph$obj_fun - graph$loglike, type = "b", xaxt = "n", lty = 3, pch=17, cex=.75,
      col = colors[3])
legend("topright", legend = c("likelihood", "posterior", "prior"),
       col=colors, pch=c(15, 16, 17), lty=c(1, 2, 3), bty="n")
dev.off()
embed_fonts("..latex/figures/bd_trend.ps", outfile="..latex/figures/bd_trend.ps")