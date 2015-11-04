context("script")

test_that("defaults", {
  args <- worker_parse_args(c("--target", "foo"))

  expect_that(args$config, equals("stateliner.json"))
  expect_that(args$address, equals("localhost:5555"))
  expect_that(args$source, equals(NULL))
  expect_that(args$package, equals(NULL))
  expect_that(args$target, equals("foo"))
  expect_that(args$verbose, equals(FALSE))
})

test_that("target is required", {
  expect_that(worker_parse_args(character(0)),
              throws_error("target must be given"))
})

test_that("script options", {
  opts <- c("--source", "target.R", "--target", "nll", "--verbose")
  args <- worker_parse_args(opts)

  expect_that(args$config, equals("stateliner.json"))
  expect_that(args$address, equals("localhost:5555"))
  expect_that(args$source, equals("target.R"))
  expect_that(args$package, equals(NULL))
  expect_that(args$target, equals("nll"))
  expect_that(args$verbose, is_true())

  f <- worker_main_get_target(args)
  expect_that(f, is_a("function"))
  expect_that(f(0), equals(0))

  e <- new.env(parent=baseenv())
  sys.source(args$source, e)
  x <- runif(10)
  expect_that(f(x), equals(e[[args$target]](x)))
})
