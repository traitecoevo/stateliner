context("analysis")

test_that("chain manipulation", {

  expect_that(length(stateline_sample_names()), equals(5))
  expect_that(length(stateline_sample_names(rep("a",5))), equals(10))
  expect_that(is.character(stateline_sample_names()), is_true())
  expect_that(is.vector(stateline_sample_names()), equals(TRUE))

  path <- "sample_output"
  nstacks <- 2
  ncols <- 36
  nrows <- 200
  sample_names <- c("lma","rho","theta","a_l1","a_l2","a_r1","omega","mu_lma",
    "mu_rho","mu_theta","mu_a_l1","mu_a_l2","mu_a_r1","mu_omega",
    "s2_lma","s2_rho","s2_theta","s2_a_l1","s2_a_l2","s2_a_r1",
    "s2_omega","s2_Al_H","s2_As_Al","s2_Mr_Al","s2_H_Mso","s2_H_Ms",
    "s2_H_Ast","s2_H0","s2_Hm")

  expect_that(load_chains(path, nstacks=nstacks), not(throws_error()))

  # load chains without merging
  s1 <- load_chains(path, nstacks=nstacks)
  expect_that(length(s1), equals(nstacks))
  expect_that(is.list(s1), is_true())
  expect_that(is.list(s1[[nstacks]]), is_true())
  expect_that(is.data.frame(s1[[nstacks]]), is_true())
  for(i in seq_len(nstacks)) {
    expect_that(all(stateline_sample_names() %in% names(s1[[i]])),
        is_true())
    expect_that(nrow(s1[[i]]), equals(nrows))
    expect_that(ncol(s1[[i]]), equals(ncols))
  }

  s1 <- load_chains(path, nstacks=nstacks)
  expect_that(length(s1), equals(nstacks))
  expect_that(is.list(s1), is_true())
  expect_that(is.list(s1[[nstacks]]), is_true())
  expect_that(is.data.frame(s1[[nstacks]]), is_true())
  for(i in seq_len(nstacks)) {
    expect_that(all(stateline_sample_names() %in% names(s1[[i]])),
        is_true())
    expect_that(nrow(s1[[i]]), equals(nrows))
    expect_that(ncol(s1[[i]]), equals(ncols))
  }

  # loading and merging chains
  s2 <- load_chains(path, nstacks=nstacks, merge=TRUE)
  expect_that(length(s2), equals(ncols))
  expect_that(is.list(s2), is_true())
  expect_that(is.list(s2[[nstacks]]), is_false())
  expect_that(is.data.frame(s2), is_true())
  expect_that(all(stateline_sample_names() %in% names(s2)), is_true())
  expect_that(s2, equals(merge_chains(s1)))
  expect_that(all(stateline_sample_names() %in% names(s2)),
        is_true())
  expect_that(nrow(s2), equals(nstacks*nrows))
  expect_that(ncol(s2), equals(ncols))

  # load chains with specified sample names
  s3 <- load_chains(path, nstacks=nstacks, merge=TRUE,
    sample_names = sample_names)
  expect_that(length(s2), equals(length(s3)))
  expect_that(all(s2==s3), is_true())
  expect_that(names(s2), not(equals(names(s3))))

  # thinning chains
  expect_that(remove_warmup(s1, 0), equals(s1))
  expect_that(remove_warmup(s2, 0), equals(s2))
  warmup <- 0.5*nrows
  s1t <- remove_warmup(s1, warmup)
  s2t <- remove_warmup(s2, warmup)
  expect_that(s2t, equals(merge_chains(s1t)))
  expect_that(ncol(s2t), equals(ncols))
  expect_that(nrow(s2t), equals(nstacks*(nrows-warmup)))
  expect_that(names(s2t), equals(names(s2)))
  expect_that(all(s2t[["iteration"]] > warmup), is_true())

  for(i in seq_len(nstacks)) {
    expect_that(ncol(s1t[[i]]), equals(ncols))
    expect_that(nrow(s1t[[i]]), equals(nrows-warmup))
    expect_that(names(s1t[[i]]), equals(names(s1[[i]])))
    expect_that(all(s1t[[i]][["iteration"]] > warmup), is_true())
  }

  #drop columns
  drop <- c("lma","rho","theta","a_l1","a_l2","a_r1","omega")
  s4 <-  drop_columns(s3, drop)
  expect_that(all(!drop %in% names(s4)), is_true())
  expect_that(all( setdiff(sample_names, drop) %in% names(s4)), is_true())
  expect_that(nrow(s3), equals(nrow(s4)))
})
