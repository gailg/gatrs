#' @title Simulate null observations of the optimized statistics
#' 
#' @description Accumulate a matrix with \code{N_simulated_nulls_interval}
#' rows and a column for each of the optimized statistics.  Each row
#' contains the optimized statistics for one simulated genotype matrix.
#' The reason this function looks so complicated is there are two 
#' \code{while} loops.  The inside loop generates a genotype matrix
#' called \code{genotype_sim} and then checks to see if it has full rank.
#' If not, it tries again; there is a limit of 1000 tries, and it counts
#' the number of bad tries before it successfully gets a matrix of full rank.
#' The outside loop accumulates \code{N_simulated_nulls_interval} good
#' tries.
#' 
#' @param MMM A positive integer equal to the length of \code{target_markers}
#' in \code{gatars_sampling_set}
#' 
#' @param N_simulated_nulls_interval A positive integer equal to the number
#' of rows of simulated optimized statistics desired.
#' 
#' @param optimized_names A character vector naming the optimized statistcs,
#' e.g. \code{c("BS", "BT", "ST", "BST")}.
#' 
#' @param Phi A numerical matrix of dimension \code{2} by \code{2}.
#' \code{Phi_{k_1, k_2} = y_{k_1} Psi y_{k_2}}.  
#' This  matrix is a useful intermediate calculation for getting
#' \code{V_z}: \code{V_z = kronecker(Phi, W_VG_W)}. 
#' It is of dimension \code{2} by \code{2} because there are two entities 
#' \code{y_1} and \code{y_2}.
#' 
#' @param sampling_set #' A list of \code{MMM} matrices, one matrix for each target marker.
#' The \code{mmm}-th matrix is the sampling set for the \code{mmm}-th
#' target marker and has \code{NNN} rows and up to \code{1000} columns, each 
#' column containing a column from \code{genotype}.  These columns
#' do not intersect with any of the target markers or exclusion regions
#' and the minor allele frequencies of the columns in \code{mmm}-th sampling set match
#' the minor allele frequency of the \code{mmm}-th target marker. One of the objects
#' returned by \code{gatars_sampling_set}.
#' 
#' @param theta A vector of length \code{2} that is the initial value of the
#' reparametrization of alpha when I am finding
#' minimum p-value in the full triangle \code{(alpha_B, alpha_S, alpha_T)}
#' 
#' @param WWW A diagonal (numerical) matrix of dimension \code{MMM} by \code{MMM}
#' with the diagonals equal to the \code{weights}.  (The user will specify
#' \code{weights} in her call to \code{gatars_test_size}.)
#' 
#' @param y_1 A numerical vector of length \code{NNN} equal to what is referred
#' to in the manuscript as \code{y}, the vector of subjects' coded trait 
#' phenotypes.
#' 
#' @param y_2 A numerical vector of length \code{NNN} equal to what is referred
#' to in the manuscript as \code{mu}, the vector of user-specified phenotype
#' predictions. 
#'
#' @param statistics A character vector reflecting which optimized statistics you
#' would like \code{uno_experimento_fn} to compute.
#' 
#' @return A \code{list} containing the two objects
#' \itemize{
#' \item{\code{simulated}: } {
#' A matrix with \code{N_simulated_nulls_interval} rows and a column for each of the
#' optimized statistics.  Each row contains the optimized statistcs for one simulated
#' genotype matrix.
#' }
#' 
#' \item{\code{so_far_so_good}: } {
#' A logical equal to \code{TRUE} if the function successfully obtained 
#' \code{N_simulated_nulls_interval} rows of simulated optimized statistics.
#' To construct each row, only 1000 bad tries are allowed, so if 
#' \code{genome_resampling_fn} ever exceeds 1000, the function aborts.
#' }
#' }
#' 
#' @examples 
#' library(Matrix)
#' bim = gatars_example$bim
#' genotype = gatars_example$genotype
#' phenotype = gatars_example$phenotype
#' Psi = gatars_example$Psi
#' target_markers = gatars_example$target_markers[3:5]
#' g_target = genotype[, target_markers]
#' MMM = ncol(g_target)
#' NNN = nrow(g_target)
#' e_g_target_1 = colMeans(g_target)
#' p_target = e_g_target_1/2
#' e_g_target = matrix(rep(e_g_target_1, nrow(g_target)), nrow = nrow(g_target), byrow = TRUE)
#' y_1 = yyy = phenotype$y
#' y_2 = mu = phenotype$mu
#' Phi = Phi_fn(Psi, y_1, y_2)
#' www_num = rep(1, MMM)
#' www = www_num/sum(www_num) * MMM
#' WWW = diag(www)
#' zzz_etc = zzz_and_first_two_moments_fn(g_target, Phi, WWW, y_1, y_2)
#' zzz = zzz_etc$zzz
#' mu_z = zzz_etc$mu_z
#' V_z = zzz_etc$V_z
#' AAA = AAA_fn(1, 0, 0, MMM)
#' theta_init = rep(pi/3, 2)
#' statistics = c("BS", "BT", "ST", "BST")
#' bo = basic_and_optimized_lu_fn(g_target, Phi, theta_init, WWW, y_1, y_2, statistics)
#' bo$xxx
#' bo$theta
#' theta = bo$theta
#' x_observed = bo$xxx
#' calculate_optimized = TRUE
#' epsilon = 0.01
#' exclusion_region = NULL
#' sampling_set = gatars_sampling_set(
#'   bim, epsilon, exclusion_region,
#'   genotype, hotspot, target_markers)
#' print(sampling_set)
#' sampling_set = sampling_set$sampling_set
#' str(sampling_set)
#' set.seed(1)
#' N_simulated_nulls_interval = 7
#' optimized_names = names(x_observed)
#' sss = genome_resampling_fn(MMM, N_simulated_nulls_interval, optimized_names, Phi, 
#'                            sampling_set, theta, WWW, y_1, y_2, statistics)
#' sss
#' str(sss)
#' 
#' @export
genome_resampling_fn = function(
  MMM,
  N_simulated_nulls_interval,
  optimized_names,
  Phi,
  sampling_set,
  theta, 
  WWW,
  y_1,
  y_2,
  statistics
){
  simulated = data.frame(
    matrix(NA, nrow = N_simulated_nulls_interval, ncol = length(statistics)))
  names(simulated) = optimized_names
  so_far_so_good = TRUE
  n_sim = 1
  while(so_far_so_good & n_sim <= N_simulated_nulls_interval){
    still_looking_for_genotype_sim = TRUE
    N_bad_genotype_sim = 0
    while(still_looking_for_genotype_sim){
      genotype_sim = do.call(cbind, lapply(sampling_set, function(this_snp){
        this_snp[, sample(1:ncol(this_snp), 1)]
      }))
      if(rankMatrix(genotype_sim) == MMM) {
        good_genotype_sim = TRUE
        still_looking_for_genotype_sim = FALSE
      } else {
        print("genotype_sim not full rank")
        N_bad_genotype_sim = N_bad_genotype_sim + 1
        if(N_bad_genotype_sim > 1000) {
          good_genotype_sim = FALSE
          still_looking_for_genotype_sim = FALSE
        }
      }
    }
    if(good_genotype_sim){
      bo = basic_and_optimized_lu_fn(genotype_sim, Phi, theta, WWW, y_1, y_2, statistics)
      one_row_in_simulated = bo$x_observed
      simulated[n_sim, ] = one_row_in_simulated
      n_sim = n_sim + 1
    } else {
      so_far_so_good = FALSE
    }
  }
  list(
    simulated = simulated,
    so_far_so_good = so_far_so_good
  )
}