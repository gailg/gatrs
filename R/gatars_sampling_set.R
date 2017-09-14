#' @title Create sampling sets for genome resampling
#' 
#' @description Each column in \code{genotype} corresponds to a row in \code{bim}, and both 
#' correspond to a marker or snp. After removing the target markers, we want to form, 
#' from the remaining snps, \code{MMM} sampling sets, one for each of the target markers.  
#' The two conditions we require of the sampling sets are \strong{the matching requirement:}
#' the snps in the sampling set for a target marker has minor allele frequencies that 
#' match closely with that of the target marker, and \strong{the independence requirement:}
#' a snp chosen from one sampling set is statistically independent of a snp chosen from a 
#' second sampling set and all sampling set snps are independent of the target markers.
#' 
#' @details We assume that hotspots from Myers et.al. cut the genome into independent segments, 
#' and so snps residing within two consecutive hotspots are independent of snps residing 
#' within another two consecutive hotspots. Defining a segment to be a set of snps that 
#' all lie within two consecutive hotspots, we obtain a (large) set of independent segments. 
#' If we assign each segment to at most one target marker, we insure that the \code{MMM}
#' sampling sets are independent, satisfying the independence requirement.
#' 
#' The next step is to assign independent segments to sampling sets so that each segment can 
#' contribute as many matching snps as possible to the sampling set it is assigned to, 
#' and also so that the minimum size across all sampling sets is maximized.
#' 
#' A segment can contribute to a target marker if it contains at least one snp that 
#' matches the target marker. If a segment can contribute to only one target marker, 
#' it is an easy decision to assign that segment to that target marker. However, if 
#' a segment can contribute to multiple target markers, then we need to decide which 
#' of the target markers we should assign it to.
#'
#' It turns out that there are many independent segments, and it is convenient to make 
#' the decision randomly according to a probability function \code{p = c(p[1], ... p[MMM])}
#' which assigns the segment to target marker \code{mmm} with probability \code{p[mmm]}.
#' 
#' Let \code{count[mmm]} count the number of snps in the segment that match target marker 
#' \code{mmm}. We can use different ways to build assignment probability functions \code{p}
#' which depends on \code{count} We may use \code{p[mmm] = count[mmm]} (normalized) 
#' if we are using the counts for weights or \code{p[mmm] = 1(count[mmm] > 0)} if not. 
#' We may or may not divide by \code{popularity}, the popularity of sampling set 
#' \code{mmm}, defined to be the sum of the \code{count[mmm]} over all the segments. 
#' We may or may not further adjust by dividing by \code{expected[mmm]}, the “expected” 
#' number of snps in each sampling set gotten by summing \code{p[mmm] * count[mmm]} over 
#' all the segments (each segment giving a possibly different \code{count[mmm]}).
#' 
#' When using a given probability function \code{p}, we often find that a few target 
#' markers have “deficient” sampling sets (their sizes being quite small compared 
#' to the sizes of other target snps). The probability \code{p} can be adjusted slightly 
#' to give these deficient target markers some additional weight: If a segment has no 
#' markers that match the deficient markers, keep \code{p} as before; otherwise zero out 
#' all \code{p[mmm]} except those corresponding to the deficient ones.
#' 
#' Because sampling sets gotten by assigning a segment to a target marker mm with 
#' probability pmpm can vary from try to try, we can try several times and choose the one 
#' assemblage of sampling sets that gives us the maximum of the minimum sampling set size.
#' 
#' @param bim A data.frame containing (at least) the three columns \code{chromosome},
#' \code{snp}, and \code{bp}, and \code{LLL} rows corresponding to a very large number
#' of \code{LLL} markers.  These markers include the target markers and those used to 
#' build the sampling sets.  The \code{lll}-throw of \code{bim} summarizes the 
#' \code{lll}-th marker or snp and corresponds to the \code{lll}-th column of 
#' \code{genotype}.  The object \code{bim} could be the .bim file from plink.
#'
#' @param genotype A matrix with \code{NNN} rows and \code{LLL} columns, whose 
#' \code{(nnn, lll)}-th element records either the number (0, 1 or 2) of minor alleles 
#' of snp \code{lll} found in the \code{nnn}-th subject or an indicator (0 or 1) 
#' for the \code{nnn}-th person carrying at least one minor allele at snp \code{lll}. 
#' The \code{lll}-th column of \code{genotype} corresponds to the \code{lll}-th row of 
#' \code{bim}. The matrix \code{genotype} could be gotten by reading in the .bed file 
#' from plink after massaging genotype information into either dosage or carriage. 
#' (Distinguish the object \code{genotype} here, containing target markers AND 
#' sampling set snps with the “genotype matrix” denoted \eqn{G} in the manuscript, 
#' the matrix containing just the target markers.)
#' 
#' @param target_markers A character vector of length \code{MMM} that is a subset 
#' of the column \code{bim$snp}. This vector names the target markers.
#' 
#' @param hotspot The \pkg{gatars} package provides this data set for your 
#' convenience.  This data.frame contains (at least) the columns \code{chromosome}
#' and \code{center}; \code{chromosome} describes the number of the chromosome 
#' (\code{1:22}), and \code{center} describes the location of hotspots.
#' 
#' @param epsilon_on_log_scale A positive real number used to parametrize the matching.
#' When creating the \code{mmm}-th sampling set for a target marker with minor allele
#' frequency \code{pi[mmm]}, only those markers whose minor allele frequencies falling
#' in the interval \code{pi[mmm] * [1 - epsilon_on_log_scale, 1 + epsilon_on_log_scale]}
#' can be included in the sampling set.
#' 
#' @template gatars_sampling_set_examples
#' @export
gatars_sampling_set = function(
  bim,
  genotype,
  target_markers,
  exclusion_region,
  hotspot,
  epsilon_on_log_scale = 0.02
){
  params_sampling_set = params_sampling_set_fn(
    bim,
    genotype,
    target_markers,
    exclusion_region,
    hotspot,
    epsilon_on_log_scale)
  answer = sampling_set_fn(params_sampling_set)
  class(answer) = c("gatars_sampling_set", class(answer))
  answer
}