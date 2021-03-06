#' Succinct conditional evaluation and assignment
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' \code{?} is an in-line if/else operator
#'
#' @details
#' The syntax for ? is as follows:
#'
#' \code{condition ? value_if_true : value_if_false}
#'
#' The condition is evaluated TRUE or FALSE as a Boolean expression.
#' On the basis of the evaluation of the Boolean condition, the entire expression
#' returns `value_if_true` if `condition` is true, but `value_if_false` otherwise.
#' In the case where the condition is a vector/matrix of Boolean values, the
#' function returns a vector/matrix where each element is either `value_if_true`
#' or `value_if_false` based on the truthiness of the elements of the logical
#' matrix on the left-hand side.
#'
#' Who has time for if/else?
#'
#' @usage lhs ? rhs
#'
#' @param lhs A logical expression, vector or matrix.
#' @param rhs A pair of values separated by a colon i.e. `value_if_true : value_if_false`.
#' @return One of the values in `rhs`, depending on the truthiness of `lhs`.
#'
#' @examples
#' # Conditional evaluation
#' 4 > 3 ? "it_was_true":"it_was_false"
#' # > "it_was_true"
#'
#' FALSE ? "it_was_true":"it_was_false"
#' # > "it_was_false"
#'
#' # Vectorised evaluation
#' c(4, 2) < 3 ? "it_was_true":"it_was_false"
#' # > "it_was_false" "it_was_true"
#'
#' # Conditional assignment with `<-`
#' x <- 4 > 3 ? "it_was_true":"it_was_false"
#' x
#' # > "it_was_true"
#'
#' # Conditional assignment with `=`
#' y <- 3 > 4 ? "it_was_true":"it_was_false"
#' y
#' # > "it_was_false"
#'
#' # Chaining `?` statements
#' z <- FALSE ? "true":(FALSE ? "false,true":(TRUE ? "false,false,true":"all false"))
#' z
#' # > "false,false,true"
#' @importFrom utils help
#' @export
`?` <- function(lhs, rhs) {
  lexpr <- substitute(lhs, environment())
  rexpr <- substitute(rhs, environment())

  # If no rhs passed, call help on lhs to restore the natural behaviour of `?`
  if (missing(rexpr)) {
    return(utils::help(as.character(lexpr)))
  } else if (rexpr[[1]] != as.name(":")) {
    stop(
      "Colon `:` operator missing from right hand of expression"
    )
  }

  # If lexpr an assignment, we evaluate the conditional (3rd element)
  lhs_tree <- as.list(lexpr)
  if (is_assignment(lhs_tree)) lhs <- eval(lexpr[[3]])

  # We bypass the original function of `:` and assign its arguments to a vector
  rhss <- c(rexpr[[2]], rexpr[[3]])

  # If `lhs` is scalar, and `rhs` values are vector `ifelse` will only return
  # the first elements of the value vectors. If given a scalar condition, we
  # want to be able to return the entire value.
  if (length(lhs) > 1) {
    r <- ifelse(lhs, eval(rhss[[1]]), eval(rhss[2]))
  } else {
    r <- eval(rhss[[2 - as.numeric(lhs)]])
  }

  # If `lhs` was assignment we replace the condition with the result `r` in the
  # original lhs syntax tree, and call in the parent environment
  if (is_assignment(lhs_tree)) {
    lexpr[[3]] <- r
    eval.parent(lexpr)
  } else {
    # otherwise we return the result
    r
  }
}
