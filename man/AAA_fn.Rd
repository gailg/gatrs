% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/AAA_fn.R
\name{AAA_fn}
\alias{AAA_fn}
\title{Calculate \code{A_alpha} in equation (7) of the manuscript}
\usage{
AAA_fn(alpha_B, alpha_S, alpha_T, MMM)
}
\arguments{
\item{alpha_B}{A real number in the closed interval \code{[0, 1]}.
alpha_B + alpha_S + alpha_T should sum to 1.}

\item{alpha_S}{A real number in the closed interval \code{[0, 1]}.}

\item{alpha_T}{A real number in the closed interval \code{[0, 1]}.}

\item{MMM}{A positive integer equal to the length of \code{target_markers}
in \code{gatars_sampling_set}}
}
\value{
A matrix of dimension \code{(2 * MMM)} by \code{(2 * MMM)}
}
\description{
Calculate \code{A_alpha} in equation (7) of the manuscript
}
\examples{
AAA_fn(1, 0, 0, 3)
AAA_fn(0, 1, 0, 3)
AAA_fn(0, 0, 1, 3)
}
